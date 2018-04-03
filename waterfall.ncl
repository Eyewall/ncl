load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; waterfall.ncl                                    
; Patrick Duran                                           
; 25 May 2017
;
; Plots vertical profiles of temperature for a series of sondes
; with filenames listed in an input file in the form of a
; waterfall plot.
;
;----------------------------------------------------------------;

sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/20151023/"
infiles  = sondedir+systemfunc("cat "+sondedir+"/centermost15")
infiles  = infiles(::-1)
nfiles   = dimsizes(infiles)

tempc = new((/nfiles,201/),"float")
do i=0,nfiles-1
   data := readAsciiTable(infiles(i),10,"float",7)
   data@_FillValue = -9999.0
   p    := data(:,0)
   tc   := data(:,1)
   hght := data(:,5)

   nlines = dimsizes(tc)
   tempc(i,:nlines-1) = tc
end do

tempc(0,:) = tempc(0,:)-35
tempc(1,:) = tempc(1,:)-30
tempc(2,:) = tempc(2,:)-25
tempc(3,:) = tempc(3,:)-20
tempc(4,:) = tempc(4,:)-15
tempc(5,:) = tempc(5,:)-10
tempc(6,:) = tempc(6,:)-5
tempc(7,:) = tempc(7,:)-0
tempc(8,:) = tempc(8,:)+5
tempc(9,:) = tempc(9,:)+10
tempc(10,:) = tempc(10,:)+15
tempc(11,:) = tempc(11,:)+20
tempc(12,:) = tempc(12,:)+25
tempc(13,:) = tempc(13,:)+30
tempc(14,:) = tempc(14,:)+35

;----------------------;
;Set plotting resources;
;----------------------;
wks = gsn_open_wks("png","/jm13/pduran/web/tempc_waterfall_patricia_20151023")
res  = True
res@tiXAxisString = "Temperature (C)"
res@tiYAxisString = "Height (km)"
res@tiXAxisFontHeightF = 0.017
res@tiYAxisFontHeightF = 0.017
res@tmXBLabelFontHeightF = 0.016
res@tmYLLabelFontHeightF = 0.016
;res@xyLineColors = (/"blue","orange","red"/)
res@xyLineThicknessF = 6
res@xyDashPattern = 0
res@tfPolyDrawOrder = "Draw"
res@gsnMaximize = True
res@trXMinF = -120.
res@trXMaxF = -30.
res@trYMinF = 16.
res@trYMaxF = 18.5
res@tmYROn = False
res@tmXTOn = False
res@tmYMajorGrid = True
res@tmYMajorGridLineColor = "gray"
res@tmYMajorGridLineDashPattern = 1
res@tmXMajorGrid = True
res@tmXMajorGridLineColor = res@tmYMajorGridLineColor
res@tmXMajorGridLineDashPattern = res@tmYMajorGridLineDashPattern
res@gsnDraw = False
res@gsnFrame = False

y = fspan(0,20,201)
plot = gsn_csm_xy(wks,tempc,y,res)

;Now plot only the theta where N^2 > 10^-4 s^-2  with a bolder line and
;overlay it on the plot to highlight the region of the TIL...
;theta(0,:170) = theta@_FillValue
;theta(0,176:) = theta@_FillValue
;theta(1,:) = theta@_FillValue
;theta(2,:) = theta@_FillValue
;res@xyLineThicknesses = (/18,6,6/)
;plot2 = gsn_csm_xy(wks,theta,y,res)
;overlay(plot,plot2)
draw(plot)
frame(wks)
