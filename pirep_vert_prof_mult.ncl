load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

x = (/33,111,121,97,75,98,49,43,53,22,27,23,30,33,59,48,85,117,91,57,23,6,1/)
print(dimsizes(x))
y = (/1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23/)
hght_label_string = (/"0-2","2-4","4-6","6-8","8-10",\
                      "10-12","12-14","14-16","16-18","18-20","20-22","22-24",\
                      "24-26","26-28","28-30","30-32","32-34","34-36","36-38",\
                      "38-40","40-42","42-44","44-46"/)

total = dim_sum(x)

print(total)
print(dimsizes(hght_label_string))

wks = gsn_open_wks("png","pirep_vert_profile_mog")
res = True
res@tiMainString = "Moderate or greater turbulence reports"
res@tmYLLabelsOn = False
res@xyLineThicknessF = 2.
res@tiXAxisString = "Number of MOG turbulence reports"
res@tiYAxisString = "Altitude layers (k ft)"

res@gsnDraw  = False
res@gsnFrame = False
plot = gsn_csm_xy(wks,x,y,res)

txres = True
txres@txFontHeightF = 0.02
text = gsn_add_text(wks,plot,hght_label_string,0,y,txres)


draw(plot)
frame(wks)
