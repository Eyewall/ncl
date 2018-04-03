load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/jm13/pduran/ncl/radar/scripts/functions/rangering.ncl"
load "/jm13/pduran/ncl/functions/time_axis_labels.ncl"

;------------------------------------------------------
;Patrick Duran
;17 May 2017
;
;Plots the best track intensity for any storm using
;a 1-minute interpolated file created by interpolate-besttrack.ncl
;of the format:
;    LAT        LON    VMAX   PMIN YYYY MM DD HH MM JULTIME (min since 1/1/1972)
;  13.40000  -94.00000   25   1007 2015 10 20  6  0 23563080
;  13.39972  -94.00056   25   1007 2015 10 20  6  1 23563081
;  13.39944  -94.00111   25   1007 2015 10 20  6  2 23563082
;  .....
;Overlays lines representing the times of aircraft center
;crossings, if desired.
;------------------------------------------------------

storm     = "patricia"
subset    = 0     ;Set to 0 to plot full storm life; 1 to plot subset
units     = "m/s" ;Options: "kt" or "m/s"
trackfile = "/jm13/pduran/best-tracks/"+storm+"-1min.txt"
outputdir = "/jm13/pduran/web/"

if(subset.eq.1)then
   trackfile = "/jm13/pduran/best-tracks/"+storm+"-1min-subset.txt"
end if

;Set dates and time of four center crossings
centeryear = (/2015,2015,2015,2015/)
centermon  = (/10,10,10,10/)
centerday  = (/21,22,22,23/)
centerhr   = (/19,18,19,20/)
centermin  = (/57,23,05,01/)
centersec  = (/0,0,0,0/)
centerjul  = toint(cd_inv_calendar(centeryear,centermon,centerday,centerhr,\
                                   centermin,centersec,"minutes since 1971-1-1",0))

;Get the genesis and dissipation times from track file
mintime = stringtofloat(systemfunc("sed -n 2p "+trackfile+" | awk '{print $10}'"))
maxtime = stringtofloat(systemfunc("tail -1 "+trackfile+" | awk '{print $10}'"))

;Get maximum wind speed and time
vmax = stringtofloat(systemfunc("awk '{print $3}' "+trackfile+" | sed '1d'"))
time = stringtofloat(systemfunc("awk '{print $10}' "+trackfile+" | sed '1d'"))
time@units = "minutes since 1/1/1972"
yaxislabel = "Maximum Wind Speed (kt)"

;Convert units if desired
if(units.eq."m/s")then
   vmax = vmax*0.514444
   yaxislabel = "Maximum Wind Speed (m/s)"
end if

;-------------------------;
;PLOT BEST TRACK INTENSITY;
;-------------------------;
wks = gsn_open_wks("png",outputdir+storm+"-intensity")
if(subset.eq.1)then
   wks = gsn_open_wks("png",outputdir+storm+"-intensity-subset")
end if
res = True
res@tiYAxisString = yaxislabel
res@tiXAxisString = "Date/Time (UTC)"
res@tiMainFontHeightF = 0.014
res@tiXAxisFontHeightF = 0.014
res@tiYAxisFontHeightF = 0.014
res@tmXBLabelFontHeightF = 0.01
res@tmYLLabelFontHeightF = 0.01
res@tmXTOn = False
res@tmYROn = False
res@trXMinF = mintime
res@trXMaxF = maxtime
res@trYMinF = 0.
res@trYMaxF = 100.
res@xyLineThicknessF = 8.
res@xyLineColor = "blue"
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False

restick = True
restick@ttmFormat = "%c %D %H%M"
restick@ttmAxis   = "XB"
restick@ttmMajorStride = 1440
restick@ttmMinorStride = 360
time_axis_labels(time,res,restick)

plot = gsn_csm_xy(wks,time,vmax,res)

;-------------------------------------------;
;Add rectangles indicating storm intensities;
;-------------------------------------------;
;polyx = (/mintime,mintime,maxtime,maxtime/)
;polyy = (/0,17.5,17.5,0/)
;polyres = True
;polyres@gsFillColor = (/94,186,255/)/255.
;polyres@gsFillOpacityF = 0.2
;polyres@tfPolyDrawOrder = "Draw"
;box1 = gsn_add_polygon(wks,plot,polyx,polyy,polyres)
;polyy = (/17.5,32.5,32.5,17.5/)
;polyres@gsFillColor = (/0,250,244/)/255.
;box2 = gsn_add_polygon(wks,plot,polyx,polyy,polyres)
;polyy = (/32.5,42.5,42.5,32.5/)
;polyres@gsFillColor = (/255,255,204/)/255.
;polyres@gsFillOpacityF = 0.8
;box3 = gsn_add_polygon(wks,plot,polyx,polyy,polyres)

;-----------------------------------------------------------; 
;Add lines and text indicating center crossings to each plot;
;-----------------------------------------------------------;
dum  = new(dimsizes(centerjul),"graphic")
dum1 = new(dimsizes(centerjul),"graphic")
text = (/"21 October Transect","22 October Transect 1","22 October Transect 2","23 October Transect"/)
do i=0,dimsizes(centerjul)-1
   ;Lines
   x = (/centerjul(i),centerjul(i)/)
   y = (/res@trYMinF,res@trYMaxF/)
   lineres = True
   lineres@gsLineThicknessF = 4.
   lineres@gsLineDashPattern = 16.
   lineres@gsLineColor = "black"
   lineres@tfPolyDrawOrder = "PostDraw"
   dum (i) = gsn_add_polyline(wks,plot,x,y,lineres)
   ;Text
   txy = y(0)+5
   txx = centerjul(i)+50
   txres = True
   txres@txJust = "BottomLeft"
   txres@txAngleF = 90.
   txres@txFontHeightF = 0.014
   if(i.eq.0.or.i.eq.1)then
      txres@txJust = "BottomRight"
      txx = centerjul(i)-50
   end if
   dum1(i) = gsn_add_text(wks,plot,text(i),txx,txy,txres)
end do

draw(plot)
frame(wks)
