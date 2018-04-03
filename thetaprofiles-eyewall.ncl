load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; theta-differences.ncl                                    
; Patrick Duran                                           
; 22 August 2016
;
; Plots vertical profiles of potential temperature for three
; soundings using input files in editsonde format.
;
;----------------------------------------------------------------;

infiles = new(3,"string")
sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"
infiles(0) = sondedir+"/20151021/A43-151021_1957-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
infiles(1) = sondedir+"/20151022/A23-151022_1823-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
infiles(2) = sondedir+"/20151023/A14-151023_2001-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
subtractavg = 0  ;0=Do not subtract, 1=Subtract layer-averaged theta from profile
normalize   = 0  ;0=Do not normalize, 1=Divide by layer-averaged theta

theta    = new((/3,201/),"float")
avgtheta = new(3,"float")
do i=0,2
   data := readAsciiTable(infiles(i),10,"float",7)
   data@_FillValue = -9999.0
   p    := data(:,0)
   tc   := data(:,1)
   hght := data(:,5)
   tk   := tc + 273.15

   nlines = dimsizes(tk)
   theta(i,:nlines-1) = tk*(1000/p)^0.286
   avgtheta(i) = avg(theta(i,90:170))

   if(subtractavg.eq.1)then
      theta(i,:) = theta(i,:) - avgtheta(i)
   end if
   if(normalize.eq.1)then
      theta(i,:) = theta(i,:) / avgtheta(i)
   end if
end do
print(theta)
print(avgtheta)
printMinMax(theta,0)

;----------------------;
;Set plotting resources;
;----------------------;
wks = gsn_open_wks("png","/jm13/pduran/web/theta_profiles_patricia")
if(normalize.eq.1)then
   wks = gsn_open_wks("png","/jm13/pduran/web/theta_profiles_patricia_normalized")
end if
res  = True
res@tiXAxisString = "Potential Temperature (K)"
if(normalize.eq.1)then
   res@tiXAxisString = "Normalized Potential Temperature"
end if
res@tiYAxisString = "Height (km)"
res@tiXAxisFontHeightF = 0.017
res@tiYAxisFontHeightF = 0.017
res@tmXBLabelFontHeightF = 0.016
res@tmYLLabelFontHeightF = 0.016
res@xyLineColors = (/"blue","orange","red"/)
res@xyLineThicknesses = (/6,6,6/)
res@xyDashPattern = 0
res@tfPolyDrawOrder = "Draw"
res@gsnMaximize = True
res@trXMinF = 364.
res@trXMaxF = 420.
res@trYMinF = 16.
res@trYMaxF = 18.
if(normalize.eq.1)then
   res@trXMinF = 1.0
   res@trXMaxF = 1.2
end if
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
plot = gsn_csm_xy(wks,theta,y,res)

;Now plot only the theta where N^2 > 10^-4 s^-2  with a bolder line and
;overlay it on the plot to highlight the region of the TIL...
theta(0,:170) = theta@_FillValue
theta(0,176:) = theta@_FillValue
theta(1,:) = theta@_FillValue
theta(2,:) = theta@_FillValue
res@xyLineThicknesses = (/18,6,6/)
plot2 = gsn_csm_xy(wks,theta,y,res)
overlay(plot,plot2)
draw(plot)
frame(wks)
