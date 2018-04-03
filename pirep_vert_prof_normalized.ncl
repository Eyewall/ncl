load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;------------------------------------------------------------------------;
;pirep_vertical_profile_normalized
;Patrick Duran
;9/13/2013
;Takes a list of altitudes from PIREP turbulence reports above a certain
;threshold (altitudes_class) and a list of altitudes from PIREP reports
;(altitudes_total) which are used to normalize altitudes_class. The input
;altitudes are sorted and a vertical profile plotted of the number of
;turbulence reports in each 2000 ft vertical layer.
;------------------------------------------------------------------------;

nlines_class_string = "6685"
;nlines_class_string = "504"
nlines_total_string = "133057"
nlines_class = stringtoint(nlines_class_string)
nlines_total = stringtoint(nlines_total_string)
altitudes_class = asciiread("/jm13/pduran/pireps/mog_pirep_alts.out",(/nlines_class/),"integer")
altitudes_total = asciiread("/jm13/pduran/pireps/ALL_pirep_alts.out",(/nlines_total/),"integer")
qsort(altitudes_class)
qsort(altitudes_total)

layercount_class = new(23,float)
alt = 4000
i = 0
do while (alt.lt.48000)
   layercount_class(i) = dimsizes(ind((altitudes_class.lt.alt).and.(altitudes_class.ge.(alt-2000))))
   alt = alt + 2000
   i = i + 1
end do

layercount_total = new(23,float)
alt = 4000
i = 0
do while (alt.lt.48000)
   layercount_total(i) = dimsizes(ind((altitudes_total.lt.alt).and.(altitudes_total.ge.(alt-2000))))
   alt = alt + 2000
   i = i + 1
end do

x = layercount_class/layercount_total
print(x)
y = (/1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23/)
hght_label_string = (/"2-4","4-6","6-8","8-10",\
                      "10-12","12-14","14-16","16-18","18-20","20-22","22-24",\
                      "24-26","26-28","28-30","30-32","32-34","34-36","36-38",\
                      "38-40","40-42","42-44","44-46","46-48"/)

total = dim_sum(x)

wks = gsn_open_wks("png","pirep_vert_profile_mog_2k")
res = True
res@tiMainString = "Normalized MOG reports"
res@tmYLLabelsOn = False
res@xyLineThicknessF = 3.
res@tiXAxisString = "Normalized number of MOG turbulence reports"
res@tiYAxisString = "Altitude layers (k ft)"
res@tiYAxisOffsetXF = -.05

res@gsnDraw  = False
res@gsnFrame = False
plot = gsn_csm_xy(wks,x,y,res)

x_ndc = new(dimsizes(x),float)
y_ndc = new(dimsizes(y),float)
datatondc(plot,x,y,x_ndc,y_ndc) ;Get coordinates in NDC

nlines_class_text = "N = "+nlines_class_string
txres = True
txres@txFontHeightF = 0.02
;text = gsn_add_text(wks,plot,hght_label_string,0,y,txres)
;text1 = gsn_add_text(wks,plot,nlines_class_text,500,23,txres)
gsn_text_ndc(wks,hght_label_string,0.15,y_ndc,txres)
gsn_text_ndc(wks,nlines_class_text,0.7,0.75,txres)
;drawNDCGrid(wks)

draw(plot)
frame(wks)
