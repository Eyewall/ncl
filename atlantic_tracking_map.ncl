load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

wks_res = "pdf"
wks_res@wkPaperWidthF = 36;48
wks_res@wkPaperHeightF = 24;36
wks_res@wkOrientation = "landscape"
;wks_res = "png"
wks = gsn_open_wks(wks_res,"atlantic_trackmap_2014")
res = True
res@gsnMaximize = True
res@gsnPaperOrientation = "Portrait"
res@gsnMajorLatSpacing = 10
res@gsnMajorLonSpacing = 10
res@gsnMinorLatSpacing = 1
res@gsnMinorLonSpacing = 1
res@mpOutlineBoundarySets = "AllBoundaries"
res@mpMinLatF = 5  
res@mpMaxLatF = 50
res@mpMinLonF = -105
res@mpMaxLonF = -10
res@mpGridLatSpacingF = 1
res@mpGridLonSpacingF = 1
res@mpGridLineColor = "gray"
res@mpFillOn = False
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

names = (/"2014 Atlantic Hurricane Season"/)
namex = (/-55/)   ;x location of name string
namey = (/50/)    ;y location of name string
res = True
res@txFontHeightF = 0.02
res@txJust = "BottomCenter"
res@txPerimOn = True
res@txBackgroundFillColor = "white"
res@txPerimColor = "white"
dum1 = gsn_add_text(wks,plot,names,namex,namey,res)

draw(plot)
frame(wks)
