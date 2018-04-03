load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;------------------------------------------------------------
;tropopause_height.ncl
;Patrick Duran
;1/14/2014
;
;Calculates the height of the static tropopause using the WMO
;definition by two different methods: One with NCL's trop_wmo
;function, and one by calculating the lapse rate and average
;lapse rates directly in this script. Plots and montages a
;skewT and tlogp plot, with tropopause heights indicated.
;
;------------------------------------------------------------

;-----------------;
;Get list of drops;
;-----------------;
dropdir =  "/jm13/pduran/tropopause/"
ndrops  = stringtoint(systemfunc("ls "+dropdir+" | wc | awk '{print $1}'"))
droplist = systemfunc("ls "+dropdir)

do drop=0,ndrops
   unixdrop = drop + 1
   print("Plotting image "+unixdrop+" of "+ndrops)

   ;------------;
   ;Get sounding;
   ;------------;
   dropfile    = dropdir+droplist(drop)
   system("cp "+dropfile+" dropfile.tmp")
   ndroplevels = stringtoint(systemfunc("cat dropfile.tmp | wc | awk '{print $1}'"))
   dropid = systemfunc("sed -n 4p dropfile.tmp | awk '{print $6}'")
   dattimslash = systemfunc("sed -n 4p dropfile.tmp | awk '{print $9}'")
   dattimsplit = str_split(dattimslash, "/")
   dattim = dattimsplit(0)+"_"+dattimsplit(1)

   DropData  = readAsciiTable("dropfile.tmp",10,"float",7)
   p   = DropData(:,0)
   tc  = DropData(:,1)
   tdc = DropData(:,2)
   z   = DropData(:,5)
   u   = DropData(:,3) * 1.94384449 ;Convert to kt
   v   = DropData(:,4) * 1.94384449
   p@_FillValue = -9999.
   tc@_FillValue = -9999.
   tdc@_FillValue = -9999.
   z@_FillValue = -9999.
   u@_FillValue = (-9999. * 1.94384449)
   v@_FillValue = (-9999. * 1.94384449)

   ;Invert variables, convert units and determine tropopause height
   p_invert = p(::-1)     ;Pressure must be monotonically *increasing*
   tc_invert = tc(::-1)   ;Must also invert temperature so it will match with p
   tk = tc_invert + 273.15       ;Temperature must be Kelvin
   opt = False
   trop_hght = trop_wmo(p_invert,tk,0,opt)    ;Pressure altitude of tropopause [hPa]
   trop_hght_z = z(minind(abs(trop_hght-p)))  ;Altitude of tropopause [m]
   opt@lapsec = 1.0

   ;--------------------;
   ;Calculate lapse rate;
   ;--------------------;
   ztop = max(ind(z))
   tctop = max(ind(tc))
   top = min((/ztop,tctop/))
   z1  = z(0:top-1)   ;Offset height arrays by 1
   z2  = z(1:top)      
   tc1 = tc(0:top-1) ;Offset temperature arrays by 1
   tc2 = tc(1:top)    
   tdiffs = tc2 - tc1  ;Finite temperature differences between each level
   zdiffs = z2 - z1    ;Finite height differences between each level
   lapse_rate = tdiffs / zdiffs   ;Lapse rate [*C/m]
   lapse_rate = lapse_rate * 1000 ;Convert to [*C/km]

firstcriterion_inds = ind(lapse_rate.gt.-2)

   ;Now calculate average lapse rate over 2 km above current level
   ninds = dimsizes(lapse_rate)
   do j=0,dimsizes(firstcriterion_inds)
      avg_lapse_rate = new(ninds,"float")
      index = firstcriterion_inds(j)
      do k=index,index+20
         avg_lapse_rate(k) = avg(lapse_rate(index:k+1))
      end do
      if(.not.any(avg_lapse_rate.lt.-2))then
         tropopause_pressure = p(index)
         break
      end if
   end do

;   tropopause_pressure = p(min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2))))
   print("Their tropopause pressure: "+trop_hght)
   print("My tropopause pressure: "+tropopause_pressure)

   hght = z(0:top-1) ;Height for plotting

   ;------------;
   ;Create SkewT;
   ;------------;
   wks = gsn_open_wks("png","skewt")
   skewtOpts                 = True
   skewtOpts@DrawColAreaFill = False    ; default is False
   skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      STATION ID: "+dropid
   skewtOpts@DrawFahrenheit  = False   ; default is True

   dataOpts           = True     ; options describing data and ploting
   dataOpts@Wthin     = 2        ; plot every n-th wind barb
   skewt_bkgd = skewT_BackGround (wks, skewtOpts)
   skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,u,v,dataOpts)

   draw(skewt_bkgd)
   draw(skewt_data)
   frame(wks)

   ;--------------------------------------------------;
   ;Create TlogP plot with tropopause level indicators;
   ;--------------------------------------------------;
   minT = -75.
   maxT = 35.
   wks = gsn_open_wks("png","tlogp")
   res = True
   res@tiMainString = "DATE/TIME: "+dattim+"      STATION ID: "+dropid
   res@tiXAxisString = "Temperature [C]"
   res@tiYAxisString = "Pressure [mb]"
   res@xyLineColors = "black"
   res@xyLineThicknesses = 3
   res@trYReverse = True        ;Invert the pressure axist
   res@xyYStyle = "Log"         
   res@tmYLMode = "Explicit"   
   res@tfPolyDrawOrder = "Draw"
   res@tmYLValues = (/100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark values
   res@tmYLLabels = (/100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark labels
   res@trXMinF = minT     ;X axis min
   res@trXMaxF = maxT     ;X axis max
   res@trYMinF = 100.   ;Y axis min
   res@trYMaxF = 1020.  ;Y axis max
   res@gsnMaximize = True
   res@gsnDraw = False  
   res@gsnFrame = False 

   plot = gsn_csm_xy(wks,tc,p,res)

   ;------------------------------;
   ;Add tropopause level indicator;
   ;------------------------------;
   lineres = True
   lineres@gsLineColor = "orange"
   lineres@gsLineThicknessF = 4.0
   lineres2 = lineres
   lineres2@gsLineColor = "red"
   x_coord_line = (/minT,maxT/)
   y_coord_line = (/trop_hght,trop_hght/)
   my_y_coord_line = (/tropopause_pressure,tropopause_pressure/)
   line = gsn_add_polyline(wks,plot,x_coord_line,y_coord_line,lineres)
   line2 = gsn_add_polyline(wks,plot,x_coord_line,my_y_coord_line,lineres2)
   draw (plot)
   frame(wks)

   ;Montage the images
      print("Montaging SkewT and TlogP diagrams...")
;      system("montage -geometry 800x800 -trim skewt.png lapse_rate.png "+dattim+"_montage.png")
      system("montage -geometry 800x800 -trim skewt.png tlogp.png "+drop+".png")
      system("\rm skewt.png tlogp.png")

   ;--------------------;
   ;Delete old variables;
   ;--------------------;
   delete(DropData)
   delete(p)
   delete(p_invert)
   delete(tc_invert)
   delete(tk)
   delete(tc)
   delete(tdc)
   delete(z)
   delete(u)
   delete(v)
   delete(z1)
   delete(z2)
   delete(tc1)
   delete(tc2)
   delete(tdiffs)
   delete(zdiffs)
   delete(lapse_rate)
   delete(avg_lapse_rate)
   delete(hght)
   delete(firstcriterion_inds)

end do
