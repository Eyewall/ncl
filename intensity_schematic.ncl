load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;---------------------------------------------------------;
; intensity_schematic.ncl                                    
; Patrick Duran                                           
; 11/10/2014						  
; Plots a schematic representation of the destabilization
; of the upper troposphere as tropical cyclones intensify,
; due to a raising of the tropopause by strong convection.
;---------------------------------------------------------;

strat   = new((/2,5/),float)
x_strat = new(5,float)
trop    = new((/2,9/),float)
x_trop  = new(9,float)

strat(0,:) = (/7.5,8,9,10,12/)*1.0 + 1   ;Strong TCs stratosphere
strat(1,:) = (/6.5,7,8,9,11/)*1.0       ;Weak TCs stratosphere
x_strat    = (/2.5,3,4,5,7/)*1.0         ;Stratosphere x values
trop(0,:)  = (/7.5,7,6,5,4,3,2,1,0/)*1.0 + 1  ;Strong TCs troposphere
trop(1,:)  = (/6.5,6,5,4,3,2,1,0,-1/)*1.0     ;Weak TCs troposphere
x_trop     = (/2.5,3,4,5,6,7,8,9,10/)*1.0     ;Troposphere x values

;----------------------;
;Set plotting resources;
;----------------------;
wks = gsn_open_wks("png","intensity_schematic")
res  = True
res@tiXAxisString = "Temperature"
res@tiYAxisString = "Height"
res@xyLineColors = (/"red","blue"/)
res@xyLineThicknesses = (/2,2/)
res@xyDashPattern = 0

;----------------------------;
;Set x and y axis min and max;
;----------------------------;
res@trXMinF = 0.
res@trXMaxF = 10.
res@trYMinF = 1.
res@trYMaxF = 11.
res@tmXTOn = False
res@tmXBOn = False
res@tmYLOn = False
res@tmYROn = False
res@gsnDraw = False
res@gsnFrame = False

plot  = gsn_csm_xy(wks,x_strat,strat,res)
plot2 = gsn_csm_xy(wks,x_trop,trop,res)

lineres = True
lineres@gsLineColor   = "dark green"
lineres@gsLineThicknessF = 2.
line1 = gsn_add_polyline(wks,plot2,(/0,10/),(/8.5,8.5/),lineres)
line2 = gsn_add_polyline(wks,plot2,(/0,10/),(/6.5,6.5/),lineres)

polyres = True
polyres@gsFillIndex = 17
polyres@gsFillColor = "dark green"
gsn_polygon(wks,plot2,(/0,10,10,0,0/),(/6.5,6.5,8.5,8.5,6.5/),polyres)

tx = "Shear Max"
txres = True
txres@txFontHeightF = 0.015
txres@txJust = "CenterLeft"
txres@txFontColor = "red"
txres@txBackgroundFillColor = "white"
txres@txPerimOn = "True"
txres@txPerimSpaceF = 0.
txres@txPerimColor = "white"
text = gsn_add_text(wks,plot2,tx,0.5,8.5,txres)
txres@txFontColor = "blue"
text2 = gsn_add_text(wks,plot2,tx,0.5,6.5,txres)
txres@txFontColor = "dark green"
text3 = gsn_add_text(wks,plot2,"Lower stability in strong storms",5,7.5,txres)
txres@txJust = "TopLeft"
txres@txFontColor = "black"
txres@txFontHeightF = 0.03
txres@txPerimSpaceF = 0.3
txres@txPerimColor = "black"
text4 = gsn_add_text(wks,plot2,"a)",0,11,txres)

overlay(plot,plot2)

draw(plot)
frame(wks)
