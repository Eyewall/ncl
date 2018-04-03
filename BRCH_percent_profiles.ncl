load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

infile1 = "/jm13/pduran/unix_scripts_and_c++/major_avg/major_0to500.idlist.freq.lt.0.25"
infile2 = "/jm13/pduran/unix_scripts_and_c++/major_avg/major_0to500.idlist.freq.lt.1"
file1 = readAsciiTable(infile1,3,"float",1)
file2 = readAsciiTable(infile2,3,"float",1)

   ;-------------------------------------------------------------;
   ;To plot multiple curves, put data into multidimensional array;
   ;-------------------------------------------------------------;
   data = new((/2,201/),"float")
   data(0,:) = file1(:,1)
   data(1,:) = file2(:,1)  
   data@_FillValue = -9999.
print(data)

   hghts = file1(:,0)
   hghts = hghts / 1000 ;Convert to km

;----------------------;
;Set plotting resources;
;----------------------;
wks_res = "ps"
;wks_res@wkOrientation = "portrait"
wks_res@wkPaperWidthF = 3.25
wks_res@wkPaperHeightF = 4.206
wks = gsn_open_wks(wks_res,"brch_pct_major")

res = True
res@gsnMaximize = True
res@gsnPaperOrientation = "portrait"
res@gsnPaperMargin = 0.
;res@tiMainString = "Subcritical RB Percentages (N=80)"
res@tiXAxisString = "Percent"
res@tiYAxisString = "Height (km)"
res@xyLineColors = (/"red","blue"/)
res@xyLineThicknesses = (/3,3/)
res@xyDashPattern = 0
res@trXMinF = 0.     ;X axis min
res@trXMaxF = 70.     ;X axis max
res@trYMinF = 0.   ;Y axis min
res@trYMaxF = 20.  ;Y axis max
res@tmYROn = False
res@tmXTOn = False

;------------;
;Add a legend;
;------------;
res@pmLegendDisplayMode = "Always"
res@pmLegendSide = "Right"
res@pmLegendOrthogonalPosF = -0.325 ;Move legend left
res@pmLegendParallelPosF   = 0.1 ;Move legend down
res@pmLegendWidthF = 0.20
res@pmLegendHeightF = 0.10
res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
res@lgPerimOn = False             ;Turn on/off box around legend
res@lgLabelFontHeightF = 0.02
res@xyExplicitLegendLabels = (/"RB<0.25","RB<1"/)

plot = gsn_csm_xy(wks,data,hghts,res)
