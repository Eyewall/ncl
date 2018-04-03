load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/nfs/jm13/pduran/ncl/functions/interpolate.ncl"

;---------------------------------------------
; dtdz.ncl
; Patrick Duran
; 10 October 2016
; 
; Plots a vertical profile of dt/dz for two
; soundings.
; 
;---------------------------------------------

infile1 = "/jm13/pduran/dropsondes/acapulco+manzanillo_october2015_mean_sounding"
infile2 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/20151021/A40-151021_1955-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"

data1 = readAsciiTable(infile1,3,"float",2)
data2 = readAsciiTable(infile2,10,"float",7)

t1 = data1(:,1)
t2 = data2(:,1)
z1 = data1(:,0)
z2 = data2(:,5)

t1@_FillValue = -9999.
t2@_FillValue = -9999.
z1@_FillValue = -9999.
z2@_FillValue = -9999.

;Compute dt/dz
dtdz1 = center_finite_diff(t1,z1,False,0)
dtdz2 = center_finite_diff(t2,z2,False,0)

;Convert to K/km
dtdz1 = dtdz1*1000.
dtdz2 = dtdz2*1000.

;Put into one array for plotting
plotdata = new((/2,201/),"float")
plotdata(0,0:dimsizes(dtdz1)-1) = dtdz1
plotdata(1,0:dimsizes(dtdz2)-1) = dtdz2

;Vertical coordinate
y = fspan(0,20,201)

;Plot
wks = gsn_open_wks("png","/jm13/pduran/web/dtdz.png")
res = True
res@tiYAxisString = "Height (km)"
res@tiXAxisString = "dt/dz (K/km)"
res@tiXAxisFontHeightF = 0.017
res@tiYAxisFontHeightF = 0.017
res@tmXBLabelFontHeightF = 0.016
res@tmYLLabelFontHeightF = 0.016
res@xyLineColors = (/"black","blue"/)
res@xyLineThicknesses = (/6,6/)
res@xyDashPatterns = 0
res@gsnMaximize = True
res@trXMinF = -10.
res@trXMaxF = 30.5
res@trYMinF = 14.
res@trYMaxF = 20.
res@tmYROn = False
res@tmXTOn = False
res@tmYMajorGrid = True
res@tmYMajorGridLineColor = "gray"
res@tmYMajorGridLineDashPattern = 1
res@tmXMajorGrid = True
res@tmXMajorGridLineColor = res@tmYMajorGridLineColor
res@tmXMajorGridLineDashPattern = res@tmYMajorGridLineDashPattern
plot = gsn_csm_xy(wks,plotdata,y,res)

;T vs. z
plotdata_t = plotdata
plotdata_t(0,0:dimsizes(t1)-1) = t1
plotdata_t(1,0:dimsizes(t2)-1) = t2
wks1 = gsn_open_wks("png","/jm13/pduran/web/tvsz.png")
res@tiXAxisString = "T (C)"
res@trXMinF = -83
res@trXMaxF = -60
plot = gsn_csm_xy(wks1,plotdata_t,y,res)
