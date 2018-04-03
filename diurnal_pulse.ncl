;**************************************************
; skewt_3.ncl
;
; Concepts illustrated:
;   - Drawing Skew-T plots
;   - Thinning the wind barbs in a Skew-T plot
;   - Customizing the background of a Skew-T plot
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;**************************************************

; --- Read Data ----------------------------------------;
;dropdir = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/processed/sondes/"

iddirs = new(4,"string")
iddirs(0) = "/jm13/pduran/unix_scripts_and_c++/allsondes_00z_avg/"
iddirs(1) = "/jm13/pduran/unix_scripts_and_c++/allsondes_06z_avg/"
iddirs(2) = "/jm13/pduran/unix_scripts_and_c++/allsondes_12z_avg/"
iddirs(3) = "/jm13/pduran/unix_scripts_and_c++/allsondes_18z_avg/"

radii = (/50,150,250,350,450,550,650,750,850,950/)
maxfreqs_alltimes = new((/4,10/),float)
maxfreqs_alltimes_norm = new((/4,10/),float)
do i=0,3
   idfiles = systemfunc("ls "+iddirs(i)+"allsondes*freq.lt.0.25")
   maxfreqs = new(10,"float")
   do j=0,dimsizes(idfiles)-1
      data = readAsciiTable(idfiles(j),3,"float",1)
      percents = data(:,1)
      npercents = dimsizes(percents) - 1
;      maxfreqs(j) = max(percents(100:npercents)) ;Only use data above 10km
      ;Only use data in average if percent >= 5
      indices = ind(percents.ge.5.)
      ;Take average of all percentages >= 5 and between 10 km and 16 km
      maxfreqs(j) = avg(percents(indices(ind((indices.ge.100).and.(indices.le.160)))))
      delete(indices)
   end do
   maxfreqs_alltimes(i,:) = maxfreqs
   ;Normalize by maximum frequency for each time
   maxfreqs_alltimes_norm(i,:) = maxfreqs_alltimes(i,:)/max(maxfreqs)
end do
print(maxfreqs_alltimes)

wks = gsn_open_wks("png","diurnal_pulse")
res = True
res@tiMainString = "Maximum Percent Rb < 0.25 (All Storms)"
res@tiXAxisString = "Radius [km]"
res@tiYAxisString = "Maximum Percent Rb < 0.25"
res@xyLineColors = (/"red","blue","magenta","dark green"/)
res@xyLineThicknesses = (/3,3,3,3/)
res@xyDashPattern = 0
res@tmXBValues = (/100,200,300,400,500,600,700,800,900,1000/)
res@tmXBLabels = (/100,200,300,400,500,600,700,800,900,1000/)

;Add a legend
res@pmLegendDisplayMode = "Always"
res@pmLegendSide = "Right"
res@pmLegendOrthogonalPosF = -0.5 ;Move legend left
res@pmLegendParallelPosF   = 0.5 ;Move legend up
res@pmLegendWidthF = 0.20
res@pmLegendHeightF = 0.10
res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
res@lgPerimOn = False             ;Turn on/off box around legend
res@lgLabelFontHeightF = 0.02
res@xyExplicitLegendLabels = (/"00Z","06Z","12Z","18Z"/)

plot = gsn_csm_xy(wks,radii,maxfreqs_alltimes,res)

;
;
;dropdir =  "/jm13/pduran/allsondes_1dir/"
;suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_QC_QC2"
;identifier = "nonhurricanes"
;;idfiles = systemfunc("ls /jm13/pduran/ncl/*hurricanes*.idlist")
;idfiles = systemfunc("ls /jm13/pduran/unix_scripts_and_c++/"+identifier+"_avg/"+identifier+"*.idlist")
;nidfiles = dimsizes(idfiles)
;
;trop_avgs = new(nidfiles,"string")
;do i=0,nidfiles-1
;   idfile = idfiles(i)
;   ndrops  = stringtoint(systemfunc("wc "+idfile+" | awk '{print $1}'"))
;   mytrops = new(ndrops,"float")    ;Array for my calculated tropopauses
;;   theirtrops = new(ndrops,"float") ;Array for NCL-calculated tropopauses
;   nsondes = 0
;   drop = 0
;   do while(drop.lt.ndrops)
;      unixdrop = drop + 1
;      print("Plotting image "+unixdrop+" of "+ndrops)
;      ;--------;
;      ;Get data;
;      ;--------;
;      stn = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($2)}'")
;      dattime = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($4)}'")
;      dropfile = dropdir+stn+"-"+dattime+suffix
;      system("cp "+dropfile+" dropfile.tmp")
;      ;Replace all -9999 values with -999. This is necessary because the script
;      ;uses floats, for which the missing value flag is -999.
;      system("`sed -i 's/-9999/-999/g' dropfile.tmp`")
;      ndroplevels = stringtoint(systemfunc("cat dropfile.tmp | wc | awk '{print $1}'"))
;      dropid = systemfunc("sed -n 4p dropfile.tmp | awk '{print $6}'")
;      dattimslash = systemfunc("sed -n 4p dropfile.tmp | awk '{print $9}'")
;      dattimsplit = str_split(dattimslash, "/")
;      dattim = dattimsplit(0)+"_"+dattimsplit(1)
;if(stringtoint(systemfunc("wc dropfile.tmp | awk '{print($1)}'")).gt.7)then
;      DropData  = readAsciiTable("dropfile.tmp",10,"float",7)
;      p   = DropData(:,0)
;      tc  = DropData(:,1)
;      tdc = DropData(:,2)
;      z   = DropData(:,5)
;      u   = DropData(:,3) * 1.94384449 ;Convert to kt
;      v   = DropData(:,4) * 1.94384449
;      p@_FillValue = -999.
;      tc@_FillValue = -999.
;      tdc@_FillValue = -999.
;      z@_FillValue = -999.
;      u@_FillValue = (-999. * 1.94384449)
;      v@_FillValue = (-999. * 1.94384449)
;      
;      ;Convert units and determine tropopause height
;      p_invert = p(::-1)     ;Pressure must be monotonically increasing
;      tc_invert = tc(::-1)   ;Must also invert temperature so it will match with p
;      tk = tc_invert + 273.15       ;Temperature must be Kelvin
;      opt = False
;      trop_hght = trop_wmo(p_invert,tk,0,opt)    ;Pressure altitude of tropopause [hPa]
;      trop_hght@_FillValue = -999
;if(.not.ismissing(trop_hght))then
;      trop_hght_z = z(minind(abs(trop_hght-p)))  ;Altitude of tropopause [m]
;end if
;
;      ;--------------------;
;      ;Calculate lapse rate;
;      ;--------------------;
;      ztop = max(ind(z))
;      tctop = max(ind(tc))
;      top = min((/ztop,tctop/))
;      z1  = z(0:top-1)   ;Offset height arrays by 1
;      z2  = z(1:top)      
;      tc1 = tc(0:top-1) ;Offset temperature arrays by 1
;      tc2 = tc(1:top)    
;      tdiffs = tc2 - tc1  ;Finite temperature differences between each level
;      zdiffs = z2 - z1    ;Finite height differences between each level
;      lapse_rate = tdiffs / zdiffs   ;Lapse rate [*C/m]
;      lapse_rate = lapse_rate * 1000 ;Convert to [*C/km]
;      if(.not.all(ismissing(p)))then   
;         ;Now calculate average lapse rate over 2 km above current level
;         ninds = dimsizes(lapse_rate)
;         avg_lapse_rate = new(ninds,"float")
;         do j=0,ninds-21
;;         do j=0,ninds-11
;            avg_lapse_rate(j) = avg(lapse_rate(j:(j+20)))
;;            avg_lapse_rate(j) = avg(lapse_rate(j:(j+10)))
;         end do
;         if(.not.ismissing((min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2))))))then
;            tropopause_pressure = p(min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2))))
;            tropopause_pressure@_FillValue = -999
;            if(.not.ismissing(tropopause_pressure))then
;               tropopause_height = z(min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2))))
;            end if   
;            ;Write to tropopause pressure arrays so that averages may be calculated
;            mytrops(drop) = tropopause_height
;;            theirtrops(drop) = trop_hght_z
;            nsondes = nsondes + 1
;         end if
;
;   
;;      hght = z(0:top-1) ;Height for plotting
;   
;;      ;------------;
;;      ;Create SkewT;
;;      ;------------;
;;      wks = gsn_open_wks("png","skewt")
;;      skewtOpts                 = True
;;      skewtOpts@DrawColAreaFill = False    ; default is False
;;      skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      STATION ID: "+dropid
;;      skewtOpts@DrawFahrenheit  = False   ; default is True
;;   
;;      dataOpts           = True     ; options describing data and ploting
;;      dataOpts@Wthin     = 2        ; plot every n-th wind barb
;;      skewt_bkgd = skewT_BackGround (wks, skewtOpts)
;;      skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,u,v,dataOpts)
;;   
;;      draw(skewt_bkgd)
;;      draw(skewt_data)
;;      frame(wks)
;;   
;;      ;---------------------------------------------;
;;      ;Create lapse rate and average lapse rate plot;
;;      ;---------------------------------------------;
;;      ;Put lapse rate data into one array for plotting on one plot
;;      lrdata = new((/2,top/),float)
;;      lrdata(0,:) = lapse_rate
;;      lrdata(1,:) = avg_lapse_rate 
;;      ;Plot resources
;;      minx = -2.
;;      maxx = 2.
;;      wks = gsn_open_wks("png","lapse_rate")
;;      lrres = True
;;      lrres@tiXAxisString = "Lapse Rate [K/km]"
;;      lrres@tiYAxisString = "Pressure [mb]"
;;      lrres@xyLineColors = (/"dark green","blue"/)
;;      lrres@xyLineThicknesses = (/2,2/)
;;      lrres@xyDashPattern = 0
;;      lrres@trYReverse = True
;;      lrres@xyYStyle = "Log"
;;      lrres@tmYLMode = "Explicit"
;;      lrres@tfPolyDrawOrder = "Draw"
;;      lrres@tmYLValues = (/100,150,200,250,300,350,400,450,500,600,700,800,900,1000/)
;;      lrres@tmYLLabels = (/100,150,200,250,300,350,400,450,500,600,700,800,900,1000/)
;;      lrres@trXMinF = minx
;;      lrres@trXMaxF = maxx
;;      lrres@trYMinF = 100.
;;      lrres@trYMaxF = 1020.
;;   
;;      ;Legend resources
;;      lrres@pmLegendDisplayMode = "Always"
;;      lrres@pmLegendSide = "Right"
;;      lrres@pmLegendOrthogonalPosF = -0.5 ;Move legend left
;;      lrres@pmLegendParallelPosF   = 0.1 ;Move legend down
;;      lrres@pmLegendWidthF = 0.20
;;      lrres@pmLegendHeightF = 0.10
;;      lrres@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
;;      lrres@lgPerimOn = False             ;Turn on/off box around legend
;;      lrres@lgLabelFontHeightF = 0.02
;;      lrres@xyExplicitLegendLabels = (/"Lapse Rate","2km avg. Lapse Rate"/)
;;   
;;      lrres@gsnDraw  = False
;;      lrres@gsnFrame = False
;;      plot = gsn_csm_xy (wks,lrdata,p(0:(top-1)),lrres)
;     
;     ;--------------------------------------------------;
;     ;Create theta-logP plot with tropopause level indicator;
;     ;--------------------------------------------------;
;  ;   minT = -75.
;  ;   maxT = 35.
;  ;   wks = gsn_open_wks("png","tlogp")
;  ;   res = True
;  ;   res@tiMainString = "DATE/TIME: "+dattim+"      STATION ID: "+dropid
;  ;   res@tiXAxisString = "Temperature [C]"
;  ;   res@tiYAxisString = "Pressure [mb]"
;  ;   res@xyLineColors = (/"black"/)
;  ;   res@xyLineThicknesses = (/3/)
;  ;   res@trYReverse = True        ;Invert the pressure axist
;  ;   res@xyYStyle = "Log"         ;Make the pressure axis logarithmic
;  ;   res@tmYLMode = "Explicit"    ;Explicitly set the tick marks and labels below
;  ;   res@tfPolyDrawOrder = "Draw"
;  ;   res@tmYLValues = (/100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark values
;  ;   res@tmYLLabels = (/100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark labels
;  ;   res@trXMinF = minT     ;X axis min
;  ;   res@trXMaxF = maxT     ;X axis max
;  ;   res@trYMinF = 0.   ;Y axis min
;  ;   res@trYMaxF = 18000.  ;Y axis max
;  ;   res@gsnMaximize = True
;  ;   res@gsnDraw = False  ;Don't draw plot until we overlay height labels
;  ;   res@gsnFrame = False ;and tropopause indicator line
;  ;
;  ;   plot = gsn_csm_xy(wks,tc,z,res)
;;  
;;     ;------------------------------;
;;     ;Add tropopause level indicator;
;;     ;------------------------------;
;;      if(.not.ismissing(min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2)))))
;;         lineres = True
;;         lineres@gsLineColor = "orange"
;;         lineres@gsLineThicknessF = 4.0
;;         lineres2 = lineres
;;         lineres2@gsLineColor = "red"
;;         x_coord_line = (/minx,maxx/)
;;         y_coord_line = (/trop_hght,trop_hght/)
;;         my_y_coord_line = (/tropopause_pressure,tropopause_pressure/)
;;         line = gsn_add_polyline(wks,plot,x_coord_line,y_coord_line,lineres)
;;         line2 = gsn_add_polyline(wks,plot,x_coord_line,my_y_coord_line,lineres2)
;;      else
;;         text = "NO DETECTIBLE TROPOPAUSE"
;;         txres = True
;;         txres@txFontHeightF = .025
;;         textplot = gsn_add_text(wks,plot,text,0,300,txres)
;;      end if
;;      draw (plot)
;;      frame(wks)
;;   
;;      ;Montage the images
;;         print("Montaging SkewT and TlogP diagrams...")
;;   ;      system("montage -geometry 800x800 -trim skewt.png lapse_rate.png "+dattim+"_montage.png")
;;         system("montage -geometry 800x800 -trim skewt.png lapse_rate.png "+stn+"-"+dattim+".png")
;;         system("\rm skewt.png lapse_rate.png")
;;   
;;         print(" ")  
;;      delete(lrdata)
;;      delete(hght)
;      if(.not.ismissing((min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2))))))then
;      delete(tropopause_pressure)
;      end if
;      delete(avg_lapse_rate)
;      end if
;      delete(lapse_rate)
;
;      ;--------------------;
;      ;Delete old variables;
;      ;--------------------;
;      delete(DropData)
;      delete(p)
;      delete(p_invert)
;      delete(tc_invert)
;      delete(tk)
;      delete(tc)
;      delete(tdc)
;      delete(z)
;      delete(u)
;      delete(v)
;      delete(z1)
;      delete(z2)
;      delete(tc1)
;      delete(tc2)
;      delete(tdiffs)
;      delete(zdiffs)
;end if
;   drop = drop + 1
;   end do
;   ;Calculate average tropopause for this radial bin and the standard deviation
;   mytrops_avg = avg(mytrops)
;;   theirtrops_avg = avg(theirtrops)
;   mytrops_stddev = dim_stddev(mytrops)
;;   theirtrops_stddev = dim_stddev(theirtrops)
;   
;;   trop_avgs(i) = systemfunc("echo "+idfile+" | colrm 1 34")+"  My avg/stddev: "+mytrops_avg+"/"+mytrops_stddev+"  Their avg/stddev: "+theirtrops_avg+"/"+theirtrops_stddev+"  nsondes: "+nsondes
;   trop_avgs(i) = systemfunc("echo "+idfile+" | colrm 1 34")+"  Average: "+mytrops_avg+"   Standard Deviation: "+mytrops_stddev+"   nsondes: "+nsondes
;   delete(mytrops)
;;   delete(theirtrops)
;   print(trop_avgs)
;end do
;   asciiwrite("trop_avgs_"+identifier+".txt",trop_avgs)
