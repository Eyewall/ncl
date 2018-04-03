load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; distribution_intensity.ncl                                    
; Patrick Duran                                           
; 7/22/2015
;----------------------------------------------------------------;

infile1 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/biggerbins/allhurricanes_0-400.idlist_brch_radbin0-3.txt"
infile2 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/ts+td/2015/biggerbins/ts+td_0-400.idlist_brch_radbin0-3.txt"
;infile1 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/00z/2015/biggerbins/allsondes_00z_0-400km_brch_radbin0-3.txt"
;infile2 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/12z/2015/biggerbins/allsondes_12z_0-400km_brch_radbin0-3.txt"
intordiurnal = "intensity"
bottomlev = 10 ;Bottom level (km) of composite
toplev    = 16 ;Top level (km) of composite
bottombin = 0
topbin    = 5
binintrvl = 0.1
nbins = toint((topbin-bottombin)/binintrvl)

system("sed -e 1,5d "+infile1+" > infile1.tmp")
system("sed -e 1,5d "+infile2+" > infile2.tmp")
nrows1 = stringtoint(systemfunc("wc infile1.tmp | awk '{print($1)}'"))
ncols1 = stringtoint(systemfunc("awk -F' ' '{print NF ; exit}' infile1.tmp"))
nrows2 = stringtoint(systemfunc("wc infile2.tmp | awk '{print($1)}'"))
ncols2 = stringtoint(systemfunc("awk -F' ' '{print NF ; exit}' infile2.tmp"))

data1 = asciiread("infile1.tmp",(/nrows1,ncols1/),"float")
data2 = asciiread("infile2.tmp",(/nrows2,ncols2/),"float")
subset_data1 = data1(:,bottomlev*10:toplev*10)
subset_data2 = data2(:,bottomlev*10:toplev*10)

data1_1d = ndtooned(subset_data1)
data2_1d = ndtooned(subset_data2)

qsort(data1_1d)
qsort(data2_1d)

numnonmissing1 = dimsizes(ind(data1_1d.ne.-9999))
numnonmissing2 = dimsizes(ind(data2_1d.ne.-9999))

y = new((/2,nbins+1/),"float")
do i=0,nbins
   bot_val = binintrvl*i
   top_val = binintrvl*i + binintrvl
   y(0,i) = tofloat(dimsizes(ind(data1_1d.ge.bot_val.and.data1_1d.lt.top_val)))/numnonmissing1*100 
   y(1,i) = tofloat(dimsizes(ind(data2_1d.ge.bot_val.and.data2_1d.lt.top_val)))/numnonmissing2*100 
end do

x = new((/2,nbins+1/),"float")
x(0,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2
x(1,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2

wks := gsn_open_wks("png","/jm13/pduran/web/pdf_"+intordiurnal+"_0-400km_"+bottomlev+"-"+toplev+"km_brch_"+bottombin+"-"+topbin)
xyres = True
xyres@xyLineColors = (/"red","blue"/) 
xyres@xyLineThicknesses = (/5,5/)
xyres@trYMinF = 0.
xyres@trYMaxF = 6.
xyres@xyDashPattern = 0
xyres@gsnMaximize = True
xyres@tiYAxisString = "Percent"
xyres@tiXAxisString = "Bulk Richardson Number"
xyres@trXMinF = tofloat(bottombin)
xyres@trXMaxF = tofloat(topbin)
xyres@tiMainString = "PDF of BRCH    Bin Interval "+binintrvl

;Add a legend
xyres@pmLegendDisplayMode = "Always"
xyres@pmLegendSide = "Left"
xyres@pmLegendOrthogonalPosF = -1 ;Move legend right
xyres@pmLegendParallelPosF   = 0.92 ;Move legend down
xyres@pmLegendWidthF = 0.20
xyres@pmLegendHeightF = 0.10
xyres@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
xyres@lgPerimOn = False             ;Turn on/off box around legend
xyres@lgLabelFontHeightF = 0.02
;xyres@xyExplicitLegendLabels = (/"00 UTC; n="+numnonmissing1,"12 UTC; n="+numnonmissing2/)
xyres@xyExplicitLegendLabels = (/"Hurricanes; n="+numnonmissing1,"TD+TS; n="+numnonmissing2/)

dum = gsn_csm_xy(wks,x,y,xyres)
