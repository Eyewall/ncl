load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/jm13/pduran/ncl/radar/scripts/functions/rangering.ncl"
load "/jm13/pduran/ncl/functions/time_axis_labels.ncl"

;------------------------------------------------------
;Patrick Duran
;08 April 2017
;
;Reads in all netCDF files in a directory and gets the
;the percent of the area covered by brightness temps
;colder than a threshold value within a radius from
;a center point defined by a trackfile.
;------------------------------------------------------

;Set the dropsonde satcenter track files and McIdas area file path
satpath   = "/nfs/jm13/pduran/sat/patricia/"
outputdir = "/nfs/jm13/pduran/web/patriciair/"
tablefile = "/nfs/jm13/pduran/sat/tables/coeff.txt"
trackfile = "/jm13/pduran/best-tracks/patricia-1min.txt"
extents   = fspan(0,105,22)  ;Units  km, 5-km bin widths
;extents   = fspan(0,205,42)  ;Units  km, 5-km bin widths
;extents   = fspan(0,305,62)  ;Units  km, 5-km bin widths
thresh    = -80 ;Units degrees C
plotopt   = 2   ;Set to 0 to plot a separate line graph for each radial bin
                ;Set to 1 to plot a single plot with a different-colored line for each radial bin
                ;Set to 2 to plot a Hovmoller-style radius vs. time plot
colors    = (/"red","orange","green","blue","purple","brown","black"/) ;Used only if plotopt=1

;If plotopt=1, make sure we have enough colors to plot
if(plotopt.eq.1)
   if(dimsizes(colors).lt.dimsizes(extents)-1)then
      print("THERE ARE NOT ENOUGH COLORS DEFINED TO PLOT GRAPH...EXITING.")
      exit
   end if
end if

;Set dates and time of four center crossings
centeryear = (/2015,2015,2015,2015/)
centermon  = (/10,10,10,10/)
centerday  = (/21,22,22,23/)
centerhr   = (/19,18,19,20/)
centermin  = (/57,23,05,07/)
centersec  = (/0,0,0,0/)
centerjul  = toint(cd_inv_calendar(centeryear,centermon,centerday,centerhr,\
                                   centermin,centersec,"minutes since 1971-1-1",0))

;Get the genesis and dissipation times from track file
mintime = stringtofloat(systemfunc("sed -n 2p "+trackfile+" | awk '{print $10}'"))
maxtime = stringtofloat(systemfunc("tail -1 "+trackfile+" | awk '{print $10}'"))

;Read the satellite coefficient table file
table = readAsciiTable(tablefile,8,"float",(/2,13/))

;----------------------------------------------------;
;Loop through all satellite files and all radial bins;
;----------------------------------------------------;
satfiles  = systemfunc("ls "+satpath)
nsatfiles = dimsizes(satfiles)
nbins     = dimsizes(extents)-1
time    = new(nsatfiles,"double")
Tb_avg  = new((/nbins,nsatfiles/),"float")
percent = new((/nbins,nsatfiles/),"float")
do i=0,nsatfiles-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+nsatfiles+"     `date`")

   ;Load netCDF file
   f = addfile(satpath+satfiles(i),"r")

   ;Get data from netCDF file
   satdate = f->crDate
   sattime = f->crTime
   ir := f->data(0,:,:)    ;float
   latitude := f->lat      ;float
   longitude := f->lon     ;float
   yyddd = f->imageDate   ;int
   hhmmss = f->imageTime  ;int
   sat = f->sensorID      ;char
   band = f->bands        ;int

   ;Get date and time of satellite imagery
   satyear := toint(systemfunc("echo "+satdate+" | cut -c 1-4"))
   satday  := toint(systemfunc("echo "+satdate+" | colrm 1 4"))
   satdate := monthday(satyear,satday)
   if(sizeof(satdate).eq.3)then
      satmon = systemfunc("echo "+satdate+" | cut -c 1")
      satday := systemfunc("echo "+satdate+" | colrm 1 1")
   else
      satmon = systemfunc("echo "+satdate+" | cut -c 1-2")
      satday := systemfunc("echo "+satdate+" | colrm 1 2")
   end if
   sathr = systemfunc("echo "+satfiles(i)+" | cut -c 17-18")
   satmin = systemfunc("echo "+satfiles(i)+" | cut -c 19-20")
   satsec = satmin
   satsec = 0

   ;Check if time is in the track file
   flag = 0   ;If 0, will proceed 
   time(i) = cd_inv_calendar(toint(satyear),toint(satmon),toint(satday),toint(sathr),\
                                toint(satmin),toint(satsec),"minutes since 1971-1-1",0)
   lines  = systemfunc("grep -i "+time(i)+" "+trackfile)
   if(ismissing(lines))then
      print("Satellite time is not in track file...Moving to next image.")
      flag = 1
   else
      centerlat = systemfunc("echo "+lines+" | awk '{print $1}'")
      centerlon = systemfunc("echo "+lines+" | awk '{print $2}'")
   end if

   if(flag.eq.0)
      ;-------------------------------------------------------------------------------------------------;
      ;CALCULATE BRIGHTNESS TEMPERATURE FROM RAW GVAR SATELLITE COUNTS                                  ;
      ;Helpful documentation:                                                                           ;
      ;http://www.ncdc.noaa.gov/sites/default/files/attachments/Satellite-Frequently-Asked-Questions.pdf;
      ;https://www.ssec.wisc.edu/mcidas/doc/users_guide/2010.2/app_c-1.html                             ;
      ;http://www.ospo.noaa.gov/Operations/GOES/calibration/gvar-conversion.html                        ; 
      ;-------------------------------------------------------------------------------------------------;
      ir = ir/32    ;Convert 16-bit to 10-bit

      ;Constants for calibration equations
      c1 = .00001191066  ;Units [mW/(m^2-sr-cm^-4)]
      c2 = 1.438833      ;Units [K/cm^-1]

      ;Now get the sensor-dependent calibration coefficients
      ;See table file at top of script for variable names
      index = ind((table(:,0).eq.sat).and.(table(:,2).eq.band))
      if(ismissing(index))then
         print("ERROR: Coefficients for this satellite not in table file "+tablefile)
         print("       McIdas Satellite Number: "+sat+"  Channel: "+band)
         exit
      end if
      coeffs = table(index,:)
      b = coeffs(3)
      m = coeffs(4)
      n = coeffs(5)
      A = coeffs(6)
      B = coeffs(7)

      ;Calculate radiance
      r:= (ir-b)/m
      r:= where(r.le.0,r@_FillValue,r)  ;Where radiance is negative or zero, set to missing

      ;Calculate effective temperature
      ;(First determining whether argument of log is negative; if so, set to missing)
      arg_before := new(dimsizes(ir),"float")
      arg_before := 1+(c1*n^3)/r
      arg := where((arg_before.eq.0).or.(arg_before.eq.162965.4),arg_before@_FillValue,arg_before)
      Teff := (c2*n)/log(arg)

      ;Calculate brightness temperature
      Tb := A+B*Teff
      TbC := Tb-273.15

      ;------------------------------------------------;
      ;Give lat and lon units and assign missing values;
      ;------------------------------------------------;
      latitude@units="degrees_north"
      longitude@units="degrees_east"
      latitude@_FillValue =  2.143289e+09
      longitude@_FillValue =  2.143289e+09

      ;---------------------------------------------------
      ;Compute distance of each IR pixel from center point
      ;---------------------------------------------------
      TbC_1d    := ndtooned(TbC)
      lats_1d   := ndtooned(latitude)
      lons_1d   := ndtooned(longitude)
      distances := gc_latlon(stringtofloat(centerlat),stringtofloat(centerlon),lats_1d,lons_1d,2,4)

      ;--------------------------------------------------------------;
      ;Loop through all radial bins and get percent coverage for each;
      ;--------------------------------------------------------------;
      do j=0,nbins-1
         if(min(distances).gt.extents(j+1))then
            percent(j,i) = percent@_FillValue
            Tb_avg (j,i) = Tb_avg@_FillValue
         else
            indices   := ind(distances.ge.extents(j).and.distances.lt.extents(j+1))
            Tb_domain := TbC_1d(indices)
            percent(j,i)= tofloat(dimsizes(ind(Tb_domain.lt.thresh)))/tofloat(dimsizes(Tb_domain))*100
            Tb_avg (j,i)= avg(Tb_domain)
;            npixels = dimsizes(indices)
;print(npixels)
         end if
      end do   ;Loop through radial bins
   end if   ;Flag that checks if satellite image time is in track file
end do   ;Loop through satellite files

if(plotopt.eq.0)then
   ;-------------------------------------------------------------;
   ;Plot percent coverage as a separate graph for each radial bin;
   ;-------------------------------------------------------------;
   do j=0,nbins-1
      unixj = j+1
      print("Plotting image "+unixj+" of "+nbins)
      wks_percent = gsn_open_wks("png",outputdir+"Tbpercent_lt_"+thresh+"C_"+extents(j)+"-"+extents(j+1)+"km")
      res = True
      res@tiMainString  = extents(j)+"-"+extents(j+1)+" km radial bin"
      res@tiMainFontHeightF = 0.014
      res@tiYAxisString = "Percent of pixels colder than "+thresh+" degrees C"
      res@tiXAxisString = "Date/Time"
      res@tiXAxisFontHeightF = 0.014
      res@tiYAxisFontHeightF = 0.014
      res@tmXBLabelFontHeightF = 0.01
      res@tmYLLabelFontHeightF = 0.01
      res@tmXBLabelAngleF = 30.
      res@tmXTOn = False
      res@tmYROn = False
      res@xyLineThicknessF = 3.
      res@trYMinF = 0.
      res@trYMaxF = 100.
      res@gsnMaximize   = True
      res@gsnDraw = False
      res@gsnFrame = False
      
      restick = True
;      restick@ttmFormat = "%c %D %H UTC"
      restick@ttmFormat = "%c %D"
      restick@ttmAxis   = "XB"
      restick@ttmMajorStride = 48
      restick@ttmMinorStride = 100000
      time_axis_labels(time,res,restick)
      plot_percent = gsn_csm_xy(wks_percent,time,percent(j,:),res)
      
      ;-----------------------------------;
      ;Plot average brightness temperature;
      ;-----------------------------------;
      wks_avg = gsn_open_wks("png",outputdir+"Tb_average_"+extents(j)+"-"+extents(j+1)+"km")
      avgres = res
      avgres@tiYAxisString = "Average IR Brightness Temperature (degrees C)"
      avgres@trYMinF = -90.
      avgres@trYMaxF = -20.
      plot_avg = gsn_csm_xy(wks_avg,time,Tb_avg(j,:),avgres)
     
      ;--------------------------------------------------; 
      ;Add lines indicating center crossings to each plot;
      ;--------------------------------------------------;
      dum  = new(dimsizes(centerjul),"graphic")
      dum1 = new(dimsizes(centerjul),"graphic")
      do i=0,dimsizes(centerjul)-1
         x = (/centerjul(i),centerjul(i)/)
         y = (/res@trYMinF,res@trYMaxF/)
         lineres = True
         lineres@gsLineThicknessF = 4.
         lineres@gsLineDashPattern = 16.
         lineres@gsLineColor = "red"
         dum (i) = gsn_add_polyline(wks_percent,plot_percent,x,(/res@trYMinF,res@trYMaxF/),lineres)
         dum1(i) = gsn_add_polyline(wks_avg,plot_avg,x,(/avgres@trYMinF,avgres@trYMaxF/),lineres)
      end do
      draw(plot_percent)
      draw(plot_avg)
      frame(wks_percent)
      frame(wks_avg)
   end do

else if(plotopt.eq.1)then
   print("Plotting images...   `date`")
   wks_percent = gsn_open_wks("png",outputdir+"Tbpercent_multiple_"+extents(0)+"-"+extents(nbins)+"km")
   res = True
   res@tiMainFontHeightF = 0.014
   res@tiYAxisString = "Percent of pixels colder than "+thresh+" degrees C"
   res@tiXAxisString = "Date/Time"
   res@tiXAxisFontHeightF = 0.014
   res@tiYAxisFontHeightF = 0.014
   res@tmXBLabelFontHeightF = 0.01
   res@tmYLLabelFontHeightF = 0.01
   res@tmXBLabelAngleF = 30.
   res@tmXTOn = False
   res@tmYROn = False
   res@xyLineThicknessF = 3.
   res@xyLineColors = colors(:nbins-1)
   res@xyDashPattern = 0.
   res@trYMinF = 0.
   res@trYMaxF = 100.
   res@gsnMaximize   = True
   res@gsnDraw = False
   res@gsnFrame = False

   restick = True
 ;  restick@ttmFormat = "%c %D %H UTC"
   restick@ttmFormat = "%c %D"
   restick@ttmAxis   = "XB"
   restick@ttmMajorStride = 48
   restick@ttmMinorStride = 100000

   time_axis_labels(time,res,restick)
   plot_percent = gsn_csm_xy(wks_percent,time,percent,res)

   ;-----------------------------------;
   ;Plot average brightness temperature;
   ;-----------------------------------;
   wks_avg = gsn_open_wks("png",outputdir+"Tb_average_multiple_"+extents(0)+"-"+extents(nbins)+"km")
   avgres = res
   avgres@tiYAxisString = "Average IR Brightness Temperature (degrees C)"
   avgres@trYMinF = -90.
   avgres@trYMaxF = -20.
   plot_avg = gsn_csm_xy(wks_avg,time,Tb_avg,avgres)

   ;--------------------------------------------------; 
   ;Add lines indicating center crossings to each plot;
   ;--------------------------------------------------;
   dum  = new(dimsizes(centerjul),"graphic")
   dum1 = new(dimsizes(centerjul),"graphic")
   do i=0,dimsizes(centerjul)-1
      x = (/centerjul(i),centerjul(i)/)
      y = (/res@trYMinF,res@trYMaxF/)
      lineres = True
      lineres@gsLineThicknessF = 4.
      lineres@gsLineDashPattern = 16.
      lineres@gsLineColor = "red"
      dum (i) = gsn_add_polyline(wks_percent,plot_percent,x,(/res@trYMinF,res@trYMaxF/),lineres)
      dum1(i) = gsn_add_polyline(wks_avg,plot_avg,x,(/avgres@trYMinF,avgres@trYMaxF/),lineres)
   end do
   draw(plot_percent)
   draw(plot_avg)
   frame(wks_percent)
   frame(wks_avg)

else if(plotopt.eq.2)then
   print("Plotting radius-time diagram...   `date`")

   ;Values for each radial bin are valid at midpoints, so define them   
   midpoints = new(dimsizes(extents)-1,"float")
   do k=0,dimsizes(extents)-2
      midpoints(k) = (extents(k+1)+extents(k))/2
   end do

   ;Define coordinate variables
   Tb_avg!0  = "radius"
   Tb_avg!1  = "time"
   percent!0 = "radius"
   percent!1 = "time"
   Tb_avg&time    = time
   Tb_avg&radius  = midpoints
   percent&time   = time
   percent&radius = midpoints

   ;Leftmost dimension will be on y-axis, so need to flip arrays to make time leftmost dimension
   Tb_avg  := transpose(Tb_avg)
   percent := transpose(percent)

   ;Plot radius-time diagram
   wks_percent = gsn_open_wks("png",outputdir+"Tbpercent_hovmoller_"+extents(0)+"-"+extents(nbins-1)+"km")
   gsn_define_colormap(wks_percent,"MPL_Reds")
   res = True
   res@tiMainString = "Percent of pixels colder than "+thresh+" degrees C"
   res@tiXAxisString = "Radius (km)"
   res@tiYAxisString = "Date/Time (UTC)"
   res@tiMainFontHeightF = 0.014
   res@tiXAxisFontHeightF = 0.014
   res@tiYAxisFontHeightF = 0.014
   res@tmXBLabelFontHeightF = 0.01
   res@tmYLLabelFontHeightF = 0.01
;   res@tmYLLabelAngleF = 60.
   res@tmXTOn = False
   res@tmYROn = False
   res@trXMinF = midpoints(0)
   res@trXMaxF = extents(nbins-1)
   res@cnLevelSelectionMode = "ManualLevels" 
   res@cnMinLevelValF = 0.
   res@cnMaxLevelValF = 100.
   res@cnLevelSpacingF = 10.
   res@cnLinesOn = False
   res@cnFillOn = True
   res@lbOrientation = "Vertical"
   res@lbTitleFontHeightF = 0.013
   res@lbLabelFontHeightF = 0.013
   res@lbBoxMinorExtentF = 0.1
   res@pmLabelBarOrthogonalPosF = 0.005
   res@gsnDraw = False
   res@gsnFrame = False

   ;Set explicit labels for Y axis based on day/hour
   ntickmarks = 16
   lbyears = new(ntickmarks,"integer")
   lbmons  = new(ntickmarks,"integer")
   lbmins  = new(ntickmarks,"integer")
   lbsecs  = new(ntickmarks,"integer")
   lbyears = 2015
   lbmons  = 10
   lbmins  = 0
   lbsecs  = 0
   lbdays  = (/20,20,21,21,21,21,22,22,22,22,23,23,23,23,24,24/)
   lbhrs   = (/"12","18","00","06","12","18","00","06","12","18","00","06","12","18","00","06"/)
   lbcoords = toint(cd_inv_calendar(lbyears,lbmons,lbdays,stringtoint(lbhrs),lbmins,lbsecs,"minutes since 1971-1-1",0))
   labels   = new(ntickmarks,"string")
   labels   = "Oct "+lbdays+" "+lbhrs+" UTC"
print(time)
print(lbcoords)
   res@tmYLMode = "Explicit"
   res@tmYLValues = lbcoords
   res@tmYLLabels = labels 

   ;Draw plot
   plot_percent = gsn_csm_contour(wks_percent,percent,res)

   ;-----------------------------------;
   ;Plot average brightness temperature;
   ;-----------------------------------;
   wks_avg = gsn_open_wks("png",outputdir+"Tb_average_hovmoller_"+extents(0)+"-"+extents(nbins-1)+"km")
   gsn_define_colormap(wks_avg,"avn_extended")
   gsn_reverse_colormap(wks_avg)
   avgres = res
   avgres@tiMainString = "Azimuthally-Averaged IR Brightness Temperature (degrees C)"
   avgres@cnMinLevelValF = -90.
   avgres@cnMaxLevelValF = 38.
   avgres@cnLevelSpacingF = 2.
   avgres@gsnSpreadColors = True
   avgres@gsnSpreadColorStart = 2
   avgres@gsnSpreadColorEnd = 60
   avgres@lbLabelStride = 5.

   plot_avg = gsn_csm_contour(wks_avg,Tb_avg,avgres)

   ;--------------------------------------------------; 
   ;Add lines indicating center crossings to each plot;
   ;--------------------------------------------------;
   dum  = new(dimsizes(centerjul),"graphic")
   dum1 = new(dimsizes(centerjul),"graphic")
   do i=0,dimsizes(centerjul)-1
      y = (/centerjul(i),centerjul(i)/)
      x = (/res@trXMinF,res@trXMaxF/)
      lineres = True
      lineres@gsLineThicknessF = 4.
      lineres@gsLineDashPattern = 16.
      lineres@gsLineColor = "black"
      dum (i) = gsn_add_polyline(wks_percent,plot_percent,x,y,lineres)
      dum1(i) = gsn_add_polyline(wks_avg,plot_avg,x,y,lineres)
   end do
   draw(plot_percent)
   draw(plot_avg)
   frame(wks_percent)
   frame(wks_avg)
end if
end if
end if
