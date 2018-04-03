load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"

;sonde1 = "/jm13/pduran/dropsondes/hs3/D20120914_225650_recomp_P.1QC.eol"
;sonde2 = "/jm13/pduran/dropsondes/hs3/D20120915_074506_recomp_P.1QC.eol"
;sonde1 = "/jm13/pduran/dropsondes/hs3/D20120914_224108_recomp_P.2QC.eol"
;sonde2 = "/jm13/pduran/dropsondes/hs3/D20120914_231355_recomp_P.2QC.eol"
sonde1 = "/nfs/jm13/pduran/dropsondes/onr/eol/rt_20151022-182225-0-B-8BFC.dat.eol"
sonde2 = "/nfs/jm13/pduran/dropsondes/onr/eol/rt_20151022-190509-0-A-9E2D.dat.eol"


DropData1 = readAsciiTable(sonde1,17,"float",14)
DropData2 = readAsciiTable(sonde2,17,"float",14)

p1  = DropData1(:,4)
p2  = DropData2(:,4)
tc1 = DropData1(:,5)
tc2 = DropData2(:,5)
p1@_FillValue  = -999
p2@_FillValue  = -999
tc1@_FillValue = -999
tc2@_FillValue = -999

nlevs = dimsizes(p1)
tdiffs = new(nlevs,"float")
tdiffs@_FillValue = -999
do i=0,nlevs-1
   pdiffs = p2 - p1(i)
   if(.not.ismissing(min(abs(pdiffs))))then
      if(min(abs(pdiffs)).lt.0.5)then
         tc2_minind = minind(abs(p2 - p1(i)))
         tdiffs(i) = tc2(tc2_minind) - tc1(i)
      end if
   end if
end do

n_nomissing = dimsizes(ind(.not.ismissing(tdiffs)))
tdiffs_nomissing = new(n_nomissing,"float")
p1_nomissing = tdiffs_nomissing
k = 0
do j=0,nlevs-1
   if(.not.ismissing(tdiffs(j)))then
      tdiffs_nomissing(k) = tdiffs(j)
      p1_nomissing(k) = p1(j)
      k = k + 1
   end if
end do

tdiffs_smth = smooth_121(tdiffs_nomissing,0,10)
p1_smth     = smooth_121(p1_nomissing,0,10)
;tdiffs_smth = tdiffs_nomissing
;p1_smth = p1_nomissing

;Plot vertical profile of differences
;filename = "20120915_074506_minus_20120914_225650_tdiff"
filename = "transect2-transect1_eye"
wks  = gsn_open_wks ("png",filename)
res = True
;res@tiMainString = "0345 LST (Overnight) minus 1856 LST (Daytime)"
res@tiMainString = "Transect2 minus Transect1"
res@tiMainOffsetYF = -0.035
res@tiMainFontHeightF = 0.02
res@tiXAxisString = "Temperature Difference (K)"
res@tiYAxisString = "Pressure (mb)"
res@xyLineColor = "red"
res@xyLineThicknesses = 3
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False

res@tmYLMode = "Explicit"
res@tmYLValues = (/75,100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark values
res@tmYLLabels = (/75,100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark labels
res@tmYROn = False
res@tmXTOn = False
res@tmXBAutoPrecision = False
res@tmXBPrecision = 1
res@trXMinF = -6.
res@trXMaxF = 6.
res@trYMinF = 75.
res@trYMaxF = 1020.
res@trYReverse = True
res@xyYStyle = "Log"
plot = gsn_csm_xy(wks,tdiffs_smth,p1_smth,res)

;Add zero indicator line
lineres = True
lineres@gsLineColor = "black"
lineres@gsLineThicknessF = 3.
lineres@gsLineDashPattern = 16
line_plot = gsn_add_polyline(wks,plot,(/0,0/),(/res@trYMinF,res@trYMaxF/),lineres)

;Add cloud top height lines
;cloudhghts = (/133.7,142.7/)
;cloudhghts = (/144.0,110.0/)
;legend_labels = (/"Cloud Top at 1856 LST","Cloud Top at 0345 LST"/)
;legend_labels = (/"Cloud Top over Thick Cirrus","Cloud Top at Cirrus Edge"/)
;colors = (/"midnightblue","orange"/)
;cloudlines = new(dimsizes(cloudhghts),"graphic")
;do line=0,dimsizes(cloudhghts)-1
;   cloudhght = cloudhghts(line)
;   cloudres = True
;   cloudres@gsLineColor = colors(line)
;   cloudres@gsLineThicknessF = 6.
;   cloudlines(line) = gsn_add_polyline(wks,plot,(/res@trXMinF,res@trXMaxF/),(/cloudhght,cloudhght/),cloudres)
;end do

;Add text to label cloud tops
;txres = True
;txres@txFontHeightF = 0.02
;txres@amJust = "CenterLeft"
;txres@txFont = 22
;txres@txFontColor = colors(0)
;;txdum1 = gsn_add_text(wks,plot,legend_labels(0),0.1,cloudhghts(0)+10,txres)
;txdum1 = gsn_add_text(wks,plot,legend_labels(0),-5.8,cloudhghts(0)+10,txres)
;txres@txFontColor = colors(1)
;txdum2 = gsn_add_text(wks,plot,legend_labels(1),-5.8,cloudhghts(1)+8,txres)
   
draw(plot)
frame(wks)

system("mv "+filename+".png /jm13/pduran/web/")
