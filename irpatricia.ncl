load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/jm13/pduran/ncl/radar/scripts/functions/rangering.ncl"

;Set the dropsonde satcenter track files and McIdas area file path
satpath   = "/nfs/jm13/pduran/sat/patricia_goes13+goes15/"
outputdir = "/nfs/jm13/pduran/web/patriciair/stormfollowing/"
tablefile = "/nfs/jm13/pduran/sat/tables/coeff.txt"
opt = 1     ;Set to 0 for a fixed domain; 1 for a storm-following domain (set variables below)
trackfile = "/jm13/pduran/best-tracks/patricia-1min.txt"
latextent = 5 ;Distance to plot away from storm center in N/S direction (units degrees)
lonextent = 5 ;Distance to plot away from storm center in E/W direction (units degrees)
rings     = 1 ;Set to 0 to not plot range rings, 1 to plot range rings (set variables below)
radialextent = 500 ;Units km
ringspacing  = 20 ;Units km
presopt = 0  ;Set to 0 to plot imagery normally (as set above); 1 to plot for presentation

if(presopt.eq.1)then
   outputdir   = outputdir+"presentation/"
   radialextent = 300
   ringspacing  = 300   
   ;More settings changed below in plotting section
end if

;As of now, range rings will only work in a storm-following coordinate
if(opt.eq.0)then
   print("NOTICE: RANGE RINGS ONLY AVAILABLE FOR STORM-FOLLOWING COORDINATE.")
   rings = 0
end if

;Read the satellite coefficient table file
table = readAsciiTable(tablefile,8,"float",(/2,13/))

if(opt.eq.0)then
   minlat = 6.0 
   maxlat = 24.0
   minlon = -111.0 
   maxlon = -89.0
end if

satfiles = systemfunc("ls "+satpath)
nsatfiles = dimsizes(satfiles)
do i=0,nsatfiles-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+nsatfiles+"    `date`")

   ;-------------------------------------------;
   ;            Plot satellite image           ;
   ;-------------------------------------------;
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
   satdate := satmon+"/"+satday+"/"+satyear
   sathr = systemfunc("echo "+satfiles(i)+" | cut -c 17-18")
   satmin = systemfunc("echo "+satfiles(i)+" | cut -c 19-20")
   satsec = satmin
   satsec = 0
   sattime := sathr+":"+satmin+" UTC"

   flag = 0   ;If 0, satellite image will be plotted
   if(opt.eq.1)then   ;Determine storm-following domain for plot
      sattimejul = cd_inv_calendar(toint(satyear),toint(satmon),toint(satday),toint(sathr),\
                                   toint(satmin),toint(satsec),"minutes since 1971-1-1",0)
      lines  = systemfunc("grep -i "+sattimejul+" "+trackfile)
      if(ismissing(lines))then
         print("     Satellite time is not in track file...Moving to next image.")
         flag = 1
      else
         centerlat = systemfunc("echo "+lines+" | awk '{print $1}'")
         centerlon = systemfunc("echo "+lines+" | awk '{print $2}'")
         vmax      = systemfunc("echo "+lines+" | awk '{print $3}'")
         pmin      = systemfunc("echo "+lines+" | awk '{print $4}'")
         maxlat = tofloat(centerlat) + latextent
         minlat = tofloat(centerlat) - latextent
         maxlon = tofloat(centerlon) + lonextent
         minlon = tofloat(centerlon) - lonextent
      end if
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
      system("echo Computing radiance   `date`")
      r:= (ir-b)/m
      r:= where(r.le.0,r@_FillValue,r)  ;Where radiance is negative or zero, set to missing
   
      ;Calculate effective temperature
      ;(First determining whether argument of log is negative; if so, set to missing)
      system("echo Computing effective temperature   `date`")
      arg_before := new(dimsizes(ir),"float")
      arg_before := 1+(c1*n^3)/r
      arg := where((arg_before.eq.0).or.(arg_before.eq.162965.4),arg_before@_FillValue,arg_before)
      Teff := (c2*n)/log(arg)
   
      ;Calculate brightness temperature
      system("echo Computing brightness temperature   `date`")
      Tb := A+B*Teff
      TbC := Tb-273.15
   
      ;----------------------;
      ;Give lat and lon units;
      ;----------------------;
      latitude@units="degrees_north"
      longitude@units="degrees_east"
   
      ;---------------------------------------------------;
      ;Convert hhmmss to string, cutting off seconds place;
      ;---------------------------------------------------;
      if(hhmmss.lt.10000)then
         imgtime = "00"+hhmmss
      else if(hhmmss.lt.100000)then
         imgtime = "0"+hhmmss
      else
         imgtime = tostring(hhmmss)
      end if
      end if
      imgtime_noseconds = systemfunc("echo "+imgtime+" | colrm 5 6")
   

    
      filename = outputdir+satyear+satmon+satday+"_"+sathr+satmin+"_ir"
      wks = gsn_open_wks("png",filename)
    
      ;Get AVN satellite colormap and reverse it for plotting.
      gsn_define_colormap(wks,"avn_extended")
      gsn_reverse_colormap(wks)
   
      ;Set some plotting resources
      system("echo Plotting image   `date`")
      res = True
      res@gsnAddCyclic = False
      res@sfXArray := longitude
      res@sfYArray := latitude
      res@tiXAxisString = "Degrees Longitude"
      res@tiYAxisString = "Degrees Latitude"
      res@tiYAxisOn = False
      res@tiXAxisOn = False
      res@gsnLeftString = satdate+"  "+sattime
   ;   res@gsnLeftString = "b) GOES-15   22 October   1830 UTC"
   ;   res@gsnRightString = "Brightness Temperature (~S~o~N~C)"
      res@tiMainFontHeightF = 0.010
      res@tiXAxisFontHeightF = 0.014
      res@tiYAxisFontHeightF = 0.014
      res@tiYAxisOffsetXF    = -0.08
      res@tiXAxisOffsetYF    = -0.06
      res@gsnStringFontHeightF = 0.015
      res@gsnLeftStringOrthogonalPosF = .01
      res@gsnRightStringOrthogonalPosF = .01
    
      res@cnFillOn = True             ;Color fill
      res@cnFillMode = "RasterFill"   ;Raster mode
      res@cnLinesOn = False           ;Turn off contours
      res@cnLevelSelectionMode = "ManualLevels"
      res@cnMinLevelValF = -90.
      res@cnMaxLevelValF = 38.
      res@cnLevelSpacingF = 2.
      res@cnLineLabelsOn = False	;Turn off contour labels
   
      res@gsnSpreadColors = True
      res@gsnSpreadColorStart = 2
      res@gsnSpreadColorEnd = 60
   
      res@mpMinLatF = minlat
      res@mpMaxLatF = maxlat
      res@mpMinLonF = minlon
      res@mpMaxLonF = maxlon

      res@mpGridAndLimbOn = True
      res@mpGridLatSpacingF = 1.
      res@mpGridLonSpacingF = 1.
      res@pmTickMarkDisplayMode = "Always" ;Turn on fancy tickmarks

      if(presopt.ne.1)then
         res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
         res@mpGeophysicalLineThicknessF = 10.0
         res@mpGeophysicalLineColor = "Green"
         res@mpUSStateLineColor = "Green"
      end if
    
      res@lbLabelBarOn = True
      res@lbLabelStride = 5.
      res@lbTitleOn = False
      res@lbTitleString = "~S~o~N~C" ;Deg C
      res@lbTitleFontHeightF = 0.013
      res@lbLabelFontHeightF = 0.013
      res@lbOrientation = "Vertical"
      res@lbBoxMinorExtentF = 0.1
      res@pmLabelBarOrthogonalPosF = 0.005
   
      res@tmXBLabelFontHeightF = 0.013
      res@tmYLLabelFontHeightF = 0.013
   
      res@tmYROn   = "False"
      res@tmXTOn   = "False"
      res@tmYLMode = "Manual"
      res@tmXBMode = "Manual"
      res@tmYLTickStartF = minlat
      res@tmYLTickEndF   = maxlat
      res@tmXBTickStartF = minlon
      res@tmXBTickEndF   = maxlon
      res@tmYLTickSpacingF = 1.
      res@tmXBTickSpacingF = 1.
      print("!!!!!IGNORE ANY TickMarkSetValues WARNING MESSAGES!!!!!")
   
      res@gsnMaximize = True 
      res@gsnDraw  = False		;So we can add poly stuff
      res@gsnFrame = False
      plot = gsn_csm_contour_map(wks,TbC(:,:),res)
   
      cnres = res
      cnres@cnFillOn = False
      cnres@cnLinesOn = True
      cnres@cnInfoLabelOn = False
      cnres@gsnLeftString = " "
      cnres@cnLevelSelectionMode = "ExplicitLevels"
      cnres@cnLevels = (/-82,-84,-86,-88/)
      cnres@cnLineThicknessF = 3.
      cnplot = gsn_csm_contour(wks,TbC,cnres)

      ;Draw range rings, first converting km to degrees lat and lon
      cnlat = stringtofloat(centerlat)
      cnlon = stringtofloat(centerlon)
      nrings = radialextent/ringspacing
      txdum = new(nrings,"graphic")
      do k=1,nrings
         centerlatrad = stringtofloat(centerlat)*(2*3.141592/360.)
         range_lat = k*ringspacing/111.
         range_lon = (k*ringspacing)/(110.567*cos(centerlatrad))
         scale   = range_lon/range_lat
         ringres = True
         ringres@Scale = scale
         ringres@gsLineThicknessF = 2.
         if(presopt.eq.1)then
            ringres@gsLineThicknessF = 6.
         end if
         circle_ll(wks,plot,cnlon,cnlat,range_lat,ringres)
         ;Label every other range ring
         if(k%2.eq.0)then
            rrlabel = tostring(ringspacing*k)+" km"
            print(rrlabel)
            ;txdum(k) = gsn_add_text(wks,plot, 
         end if
      end do
      overlay(plot,cnplot)
      draw(plot)
      frame(wks)
   end if
end do
