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
;
;17 JUNE 2017: For some reason, the flight times indicator
;              lines do not plot correctly if I use a 300
;              km extent and a max BT of -70...No clue why
;              this is happening. Changing only the threshes
;              to include BTs out to 30 C "fixes" the problem.
;              Works fine for extent=100. Perplexing...
;------------------------------------------------------

;Set the dropsonde satcenter track files and McIdas area file path
opt = 1  ;Set to 0 to plot a single contoured frequency by time diagram
         ;Set to 1 to plot a line graph for each satellite time
satpath   = "/nfs/jm13/pduran/sat/patricia/"
outputdir = "/nfs/jm13/pduran/web/patriciair/"
tablefile = "/nfs/jm13/pduran/sat/tables/coeff.txt"
trackfile = "/jm13/pduran/best-tracks/patricia-1min.txt"
extent    = 500               ;Radius within which to search for IR Tb pixels
;threshes  = fspan(-91,-69,12) ;Units degrees C
threshes  = fspan(-91,23,58) ;Units degrees C
print(threshes)
;exit
;colors    = (/"red","orange","green","blue","purple","brown","black"/) ;Used only if plotopt=1
colors    = (/"blue","orange","red"/)

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
;Loop through all satellite files and all IR threshes;
;----------------------------------------------------;
satfiles  = systemfunc("ls "+satpath+"*nc")
nsatfiles = dimsizes(satfiles)
nthreshes = dimsizes(threshes)-1
time      = new(nsatfiles,"double")
percent   = new((/nsatfiles,nthreshes/),"float")
do i=0,nsatfiles-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+nsatfiles+"     `date`")

   ;Load netCDF file
   f = addfile(satfiles(i),"r")

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
   sathr  = systemfunc("echo "+satfiles(i)+" | awk -F'/' '{print $NF}' | cut -c 17-18")
   satmin = systemfunc("echo "+satfiles(i)+" | awk -F'/' '{print $NF}' | cut -c 19-20")
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

      ;------------------------------------------------------------;
      ;Loop through IR thresholds and get percent coverage for each;
      ;------------------------------------------------------------;
      indices   := ind(distances.lt.extent)
      npixels    = tofloat(dimsizes(indices))
      Tb_domain := TbC_1d(indices)
      do j=0,nthreshes-1
         percent(i,j) = tofloat(dimsizes(ind(Tb_domain.ge.threshes(j).and.Tb_domain.lt.threshes(j+1))))/npixels*100
      end do   ;Loop through IR thresholds
   end if   ;Flag that checks if satellite image time is in track file
   total = sum(percent(i,:))
   print( total)
end do   ;Loop through satellite files

;----------------------------------------;
;Define coordinate variables for plotting;
;----------------------------------------;
midpoints = new(dimsizes(threshes)-1,"float")
do k=0,dimsizes(threshes)-2
   midpoints(k) = (threshes(k+1)+threshes(k))/2.
end do
print(midpoints)
percent!0  = "t"
percent!1  = "Tb"
percent&t  = time
percent&Tb = midpoints

;----------------------------------------;
;PLOT CONTOURED FREQUENCY BY TIME DIAGRAM;
;----------------------------------------;
wks_percent = gsn_open_wks("png",outputdir+"CFTD_0-"+extent+"km")
gsn_define_colormap(wks_percent,"MPL_Blues")
res = True
res@tiMainString  = "Contoured Frequency by Time Diagram (0-"+extent+" km radius)"
res@tiXAxisString = "IR brightness temperature (~F34~0~F21~C)"
res@tiYAxisString = "Date/Time (UTC)"
res@tiMainFontHeightF = 0.014
res@tiXAxisFontHeightF = 0.014
res@tiYAxisFontHeightF = 0.014
res@tmXBLabelFontHeightF = 0.01
res@tmYLLabelFontHeightF = 0.01
res@tmXTOn = False
res@tmYROn = False
res@trXMinF = midpoints(0)
res@trXMaxF = threshes(nthreshes-1)
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = 0.
res@cnMaxLevelValF = 10.
res@cnLevelSpacingF = 0.5
res@cnLinesOn = False
res@cnFillOn = True
res@lbOrientation = "Vertical"
res@lbTitleFontHeightF = 0.013
res@lbLabelFontHeightF = 0.013
res@lbBoxMinorExtentF = 0.1
res@pmLabelBarOrthogonalPosF = 0.005
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False

restick = True
restick@ttmFormat = "%c %D %H%M"
restick@ttmAxis   = "YL"
restick@ttmMajorStride = 48
restick@ttmMinorStride = 12
time_axis_labels(time,res,restick)

plot_percent = gsn_csm_contour(wks_percent,percent,res)
print(time)
;-----------------------------------------------------------; 
;Add lines and text indicating center crossings to each plot;
;-----------------------------------------------------------;
dum  = new(dimsizes(centerjul),"graphic")
dum1 = new(dimsizes(centerjul),"graphic")
text = (/"21 October Transect","22 October Transect 1","22 October Transect 2","23 October Transect"/)
do i=0,dimsizes(centerjul)-1
   ;Lines
   y = (/centerjul(i),centerjul(i)/)
   print( y)
   x = (/res@trXMinF,res@trXMaxF/)
   lineres = True
   lineres@gsLineThicknessF = 4.
   lineres@gsLineDashPattern = 16.
   lineres@gsLineColor = "black"
   dum (i) = gsn_add_polyline(wks_percent,plot_percent,x,y,lineres)
   ;Text
   txy = y(0)-110
   txx = -89.8
   txres = True
   txres@txJust = "CenterLeft"
   txres@txFontHeightF = 0.014
   if(i.eq.2)then
      txy = y(0)+110
   end if
   dum1(i) = gsn_add_text(wks_percent,plot_percent,text(i),txx,txy,txres)
print( txy)
end do
draw(plot_percent)
frame(wks_percent)
