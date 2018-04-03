load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;Load GRIB file - DON'T FORGET THE .GRB POSTSCRIPT!!
wind_file = addfile("od_oper_an_pl_025x025_90N180W90S180E_20121015_20121020_00.grb","r")
;Get data from GRIB file

lat = wind_file->g0_lat_2(::-1)
lon = wind_file->g0_lon_3(:)
times = wind_file->initial_time0(:)
pressures = (/1000,925,850,700,500,300,200/) ;Not using all model levels

;------------------------------------------------------------------------;
;Loop through dattims and pressures to plot all levels and analyses times;
;------------------------------------------------------------------------;
i = 0
do while(i.lt.dimsizes(times))
   j = 0
   do while(j.lt.dimsizes(pressures))
      ;Get current dattim and pressure
      dattimstring = times(i)
      pres = stringtoint(pressures(j))

      ;Get wind components
      u = wind_file->U_GDS0_ISBL(i,{pres},::-1,:)
      v = wind_file->V_GDS0_ISBL(i,{pres},::-1,:)

printVarSummary(u)
printVarSummary(v) 
      ;Get dattim and set output file name
      dattimsplit = str_split(dattimstring,"/")
      year_time = str_split(dattimsplit(2)," ")
      year = year_time(0)
      timesplit = str_split_by_length(year_time(1),1)
      dattim = year+dattimsplit(0)+dattimsplit(1)+" "+"00 UTC"
      filename = year+dattimsplit(0)+dattimsplit(1)+"00_"+pres+"mb"
      if(pres.ne."1000") then
         filename = year+dattimsplit(0)+dattimsplit(1)+"00_0"+pres+"mb"
      end if
      print(pres(0))
      print(filename)

      ;----------------------------------;
      ;Calculate divergence and vorticity;
      ;----------------------------------;
      scale = 1.e05
      ;vort = u			;Retain coordinates
      ;vort = uv2vrF(u,v) * scale
      vort = uv2vr_cfd(u,v,lat,lon,3) * scale
      ;vort@long_name = "vorticity"
      ;vort@units = "scaled"
      ;vort!3 = "lat"
      ;vort!4 = "lon"
      vort!0 = "lat"
      vort!1 = "lon"
      vort&lat = lat
      vort&lon = lon
      vort&lat@long_name = "latitude"
      vort&lat@units = "degrees_north"
      vort&lon@long_name = "longitude"
      vort&lon@units = "degrees_east"
     
      ;--------------;
      ;Plot vorticity;
      ;--------------;
      ;Define domain of plot
      minlat = 5.
      maxlat = 30.
      minlon = -80.
      maxlon = -50.
      
      ;Open workstation
      wks = gsn_open_wks("PNG",filename)
      
      ;Set plotting resources
      res = True
      res@gsnAddCyclic = False
      res@gsnMaximize = True
      res@gsnPaperOrientation = "landscape"

      res@tiMainString = dattim+" ECMWF Vorticity "+pres+" hPa"
      res@tiMainFontHeightF = .02
      res@lbTitleString = "Relative Vorticity [10^-5 s^1]"
      res@lbTitleFontHeightF = .015      
      res@lbTitlePosition = "Bottom"

      res@mpMinLatF = minlat
      res@mpMaxLatF = maxlat
      res@mpMinLonF = minlon
      res@mpMaxLonF = maxlon

      res@cnLevelSelectionMode = "ManualLevels"
      res@cnFillOn = True           ;Color fill
      res@cnLinesOn = False         ;Turn off contours
      res@cnLineLabelsOn = False    ;Turn off contour labels
      res@cnLevelSpacingF = 2.      ;Set contour interval
      res@cnMinLevelValF  = -10.
      res@cnMaxLevelValF  = 10.
      ;res@cnSmoothingOn = True
      ;res@cnSmoothingDistanceF = .0045

      ;Define color map
      gsn_define_colormap(wks,"BlWhRe")
      
      ;plot = gsn_csm_contour_map(wks,vort(0,0,0,:,:),res)
      plot = gsn_csm_contour_map(wks,vort(:,:),res)

      j = j + 1
   end do
   i = i + 1
end do
