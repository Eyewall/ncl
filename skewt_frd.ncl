;**************************************************
; skewt_frd.ncl
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "skewt_func.ncl"
;**************************************************

dir = "/jm13/pduran/realtime/drops/"
dropfiles = systemfunc("ls "+dir+"*.frd")
ndropfiles = dimsizes(dropfiles)
droplats = new(ndropfiles,"string")
droplons = new(ndropfiles,"string")

do i=0,ndropfiles-1
   unixi = i + 1
   print("Plotting sonde "+unixi+" of "+ndropfiles)
   dropfile = dropfiles(i)
   ;----------------------;
   ;Get header information;
   ;----------------------;
   dropid  = systemfunc("sed -n 2p "+dropfile+" | awk '{print($5)}'")
   date    = systemfunc("sed -n 4p "+dropfile+" | awk '{print($5)}'")
   time    = systemfunc("sed -n 4p "+dropfile+" | awk '{print($7)}'")
   lat     = systemfunc("sed -n 16p "+dropfile+" | awk '{print($4)}'")+" N"
   lon     = systemfunc("sed -n 17p "+dropfile+" | awk '{print($4)}'")+" W"
   comment = systemfunc("sed -n 12p "+dropfile)

   droplats(i) = systemfunc("echo "+lat+" | awk '{print($1)}'")
   droplons(i) = "-"+systemfunc("echo "+lon+" | awk '{print($1)}'")

   ;------------------------;
   ;Get sounding information;
   ;------------------------;
   DropData = readAsciiTable(dropfile,19,"float",21)
   p    = DropData (:,2)    ; pressure     [mb] 
   tc   = DropData (:,3)    ; temperature  [C]    
   rh   = DropData (:,4)    ; relative humidity [%]
   z    = DropData (:,5)    ; geopotential [m] 
   wspd = DropData (:,7)    ; wind speed   [m/s]    
   wdir = DropData (:,6)    ; meteorological wind dir   
   lats = DropData (:,17)   ; latitudes [deg N]
   lons = DropData (:,18)   ; longitudes [deg E]
   lats@_FillValue = -999
   lons@_FillValue = -999

   ;-------------------;
   ;Calculate variables;
   ;-------------------;
   ;Convert wind speed to kt
   wspd@_FillValue = -999
   wspd = wspd * 1.944

   ;Dewpoint
   tk = tc + 273.15
   tk@_FillValue = -999
   rh@_FillValue = -999
   tdc = dewtemp_trh(tk,rh) - 273.15
   tdc@_FillValue = -999

   ;Maximum wind speed and height of max wind
   vmax = max(wspd)
   vmax_hght = z(maxind(wspd))
   if(vmax_hght.eq.-999)then
      vmax_hght = z(maxind(wspd)-1)
   end if

   ;10 meter wind speed
   z_diff = abs(z - 10)
   if(min(z_diff).lt.10)then
      surface_wind = wspd(minind(z_diff))
   else
      surface_wind = "N/A"
   end if

   ;Sea level pressure
   if(min(z).lt.20)then
      slp = max(p)
   else
      slp = "N/A"
   end if

   ;----------;
   ;Plot SkewT;
   ;----------;
   filename = date+"_"+time
   wks  = gsn_open_wks ("png",filename+"_skewt")
   skewtOpts                 = True
   skewtOpts@DrawColAreaFill = False
   skewtOpts@tiMainString    = "TIME: "+date+"/"+time+"UTC      DROP #: "+unixi 
   skewtOpts@DrawFahrenheit  = False   
   dataOpts           = True
   dataOpts@Wthin     = 60        ; plot every n-th wind barb
   skewt_bkgd = skewT_BackGround (wks,skewtOpts)
   skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,wspd,wdir,dataOpts)
   skewtOpts@gsnDraw = False
   skewtOpts@gsnFrame = False

   ;-----------------------------;
   ;Add text information to SkewT;
   ;-----------------------------;
   txOpts = True
   txOpts@txFont = 21
   txOpts@txFontColor = "black"
   txOpts@txFontHeightF = 0.01
   gsn_text_ndc(wks,"LAT/LON = "+lat+","+lon,.66,.9,txOpts)
   gsn_text_ndc(wks,"Vmax ="+sprintf("%5.1f",vmax)+" kt at "+vmax_hght+"m",.66,.88,txOpts)
   gsn_text_ndc(wks,"10m wind ="+sprintf("%5.1f",surface_wind)+" kt",.66,.86,txOpts)
   gsn_text_ndc(wks,"SLP = "+slp+" mb",.66,.84,txOpts)
   gsn_text_ndc(wks,comment,.66,.82,txOpts)

   draw (skewt_bkgd)
   draw (skewt_data)
   frame(wks)

   delete([/DropData,p,tc,rh,z,wspd,wdir,tk,tdc,z_diff,lats,lons,wks/])
end do

   ;--------------------;
   ;Plot sonde locations;
   ;--------------------;
   droplats_float = stringtofloat(droplats)
   droplons_float = stringtofloat(droplons)
   wks = gsn_open_wks("png","locations")
   res = True
   res@gsnMaximize = True
   res@gsnMajorLatSpacing = 5
   res@gsnMajorLonSpacing = 5
   res@gsnMinorLatSpacing = 1
   res@gsnMinorLonSpacing = 1
   res@mpOutlineBoundarySets = "AllBoundaries"
   res@mpMinLatF = min(droplats_float)-5
   res@mpMaxLatF = max(droplats_float)+5
   res@mpMinLonF = min(droplons_float)-5
   res@mpMaxLonF = max(droplons_float)+5
   res@mpFillOn = True
   res@mpGeophysicalLineThicknessF = 2.
   res@mpGridAndLimbOn = True
   res@mpGridLineDashPattern = 0
   res@mpGridLineThicknessF = 1.
   res@tmXMajorGrid = True
   res@tmYMajorGrid = True
   res@tmXMajorGridLineColor = "black"
   res@tmYMajorGridLineColor = "black"
   res@gsnMaximize = True
   res@tmXTOn = False
   res@tmYROn = False
   res@gsnDraw = False
   res@gsnFrame = False
   plot = gsn_csm_map_ce(wks,res)

   ;-------------------;
   ;Overlay sonde trace;
   ;-------------------;
;   color_table = "MPL_rainbow"
;   polyres = True
;   polyres@gsLineThicknessF = 10.
;   polyres@gsLineColor = color_table
;   dum1 = gsn_add_polyline(wks,plot,lons,lats,polyres)
;   nlines = max(z) / 1000
;   dum = new(nlines,"graphic")
;   do j=0,nlines-1
;      polyres = True
;      polyres@gsLineThicknessF = 10.
;      polyres@gsLineColor = colorlist(linenum)
;   draw(plot)
;   frame(wks)
;   delete([/lats,lons/])

lineres = True
lineres@gsLineColor = "black"
lineres@gsLineThicknessF = 4.
dum1 = gsn_add_polyline(wks,plot,stringtofloat(droplons),stringtofloat(droplats),lineres)

texti = ispan(1,unixi,1)
text = tostring(texti)
polyres = True
polyres@txFontHeightF = .03 
polyres@txFontColor = "red"
dum = gsn_add_text(wks,plot,text,stringtofloat(droplons),stringtofloat(droplats),polyres)

draw(plot)
frame(wks)
