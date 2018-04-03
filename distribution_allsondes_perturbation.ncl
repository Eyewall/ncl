load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; distribution_allsondes_perturbation.ncl                                    
; Patrick Duran                                           
; 8/8/2015
; Plots probability distributions of the perturbations from the
; mean stability and shear for all rawinsondes between user-
; selected levels within the 400 km radius of TCs.
; Four curves to a plot: Stability and shear for each of two
; classifications (intensity or diurnal classifications)
;
; CHANGES
; -------
; 06 October 2015 - P. Duran
;    Added thin vertical line at x=0
;----------------------------------------------------------------;


type = "diurnal"    ;Intensity or diurnal?
bottomlev = 11
toplev = 15
bottombin = -3
topbin    = 3
binintrvl = 0.1
minrad = 0
maxrad = 400

n_iterations = (maxrad-minrad)/100
bottomind = bottomlev*10
topind    = toplev*10

;Get directories for stability and shear averages and raw stability and shear values
if(type.eq."intensity")then
   avgs_dir1 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/avgs/"
   avgs_dir2 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/ts+td/2015/avgs/"
   raw_dir1  = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/rzfiles/"
   raw_dir2  = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/ts+td/2015/rzfiles/"
   idlistorkm = "idlist"
else if (type.eq."diurnal")then
   avgs_dir1 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/00z/2015/avgs/"
   avgs_dir2 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/12z/2015/avgs/"
   raw_dir1  = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/00z/2015/rzfiles/"
   raw_dir2  = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/12z/2015/rzfiles/"
   idlistorkm = "km"
end if
end if

do j=0,n_iterations-1
   ;Read in averages
   infile_avgs1  = systemfunc("ls "+avgs_dir1+"averages_radbin_"+j)
   infile_avgs2  = systemfunc("ls "+avgs_dir2+"averages_radbin_"+j)
   avgs1  = readAsciiTable(infile_avgs1,4,"float",1)
   avgs2  = readAsciiTable(infile_avgs2,4,"float",1)
   avgs1_subset = avgs1(bottomind:topind,:) 
   avgs2_subset = avgs2(bottomind:topind,:)
   avgs1_subset@_FillValue = -9999.
   avgs2_subset@_FillValue = -9999.
   stabavgs1  = avgs1_subset(:,1)
   stabavgs2  = avgs2_subset(:,1)
   shearavgs1 = avgs1_subset(:,2)
   shearavgs2 = avgs2_subset(:,2)

   ;Read in raw values
   infile_stab1  = systemfunc("ls "+raw_dir1+"*"+idlistorkm+"_stab_radbin"+j+".txt")
   infile_stab2  = systemfunc("ls "+raw_dir2+"*"+idlistorkm+"_stab_radbin"+j+".txt")
   infile_shear1 = systemfunc("ls "+raw_dir1+"*"+idlistorkm+"_shear_radbin"+j+".txt")
   infile_shear2 = systemfunc("ls "+raw_dir2+"*"+idlistorkm+"_shear_radbin"+j+".txt")
   stab1  = readAsciiTable(infile_stab1,201,"float",5)
   stab2  = readAsciiTable(infile_stab2,201,"float",5)
   shear1 = readAsciiTable(infile_shear1,201,"float",5)
   shear2 = readAsciiTable(infile_shear2,201,"float",5)
   stab1@_FillValue  = -9999.
   stab2@_FillValue  = -9999.
   shear1@_FillValue = -9999.
   shear2@_FillValue = -9999.
   stab1_subset  = stab1(:,bottomind:topind)
   stab2_subset  = stab2(:,bottomind:topind)
   shear1_subset = shear1(:,bottomind:topind)
   shear2_subset = shear2(:,bottomind:topind)

   ;Subtract average values from raw values to get perturbations and make a 1-d array
   stabavgs1_conform = conform(stab1_subset,stabavgs1,1)
   stabavgs2_conform = conform(stab2_subset,stabavgs2,1)
   shearavgs1_conform = conform(shear1_subset,shearavgs1,1)
   shearavgs2_conform = conform(shear2_subset,shearavgs2,1)
   stab_perturbs1  = stab1_subset - stabavgs1_conform
   stab_perturbs2  = stab2_subset - stabavgs2_conform
   shear_perturbs1 = shear1_subset - shearavgs1_conform
   shear_perturbs2 = shear2_subset - shearavgs2_conform

   ;Make arrays 1-d and print to output files 
   stab_perturbs1_1d  = ndtooned(stab_perturbs1)
   stab_perturbs2_1d  = ndtooned(stab_perturbs2)
   shear_perturbs1_1d = ndtooned(shear_perturbs1)
   shear_perturbs2_1d = ndtooned(shear_perturbs2)
   
   asciiwrite("stab_perturb1_"+j+".tmp",stab_perturbs1_1d)
   asciiwrite("stab_perturb2_"+j+".tmp",stab_perturbs2_1d)
   asciiwrite("shear_perturb1_"+j+".tmp",shear_perturbs1_1d)
   asciiwrite("shear_perturb2_"+j+".tmp",shear_perturbs2_1d)

   delete([/stab1,stab2,shear1,shear2/])
   delete([/stabavgs1_conform,stabavgs2_conform,shearavgs1_conform,shearavgs2_conform/])
   delete([/stab_perturbs1,stab_perturbs2,shear_perturbs1,shear_perturbs2/])
   delete([/stab_perturbs1_1d,stab_perturbs2_1d,shear_perturbs1_1d,shear_perturbs2_1d/])
   delete([/stab1_subset,stab2_subset,shear1_subset,shear2_subset/])
end do

;Read in the temporary files created above and plot distributions
system("cat stab_perturb1_*tmp > stab_perturb1.tmp")
system("cat stab_perturb2_*tmp > stab_perturb2.tmp")
system("cat shear_perturb1_*tmp > shear_perturb1.tmp")
system("cat shear_perturb2_*tmp > shear_perturb2.tmp")
nlines1 = stringtoint(systemfunc("wc stab_perturb1.tmp | awk '{print($1)}'"))
nlines2 = stringtoint(systemfunc("wc stab_perturb2.tmp | awk '{print($1)}'"))
nlines3 = stringtoint(systemfunc("wc shear_perturb1.tmp | awk '{print($1)}'"))
nlines4 = stringtoint(systemfunc("wc shear_perturb2.tmp | awk '{print($1)}'"))
stab_perturb1  = asciiread("stab_perturb1.tmp",nlines1,"float")
stab_perturb2  = asciiread("stab_perturb2.tmp",nlines2,"float")
shear_perturb1 = asciiread("shear_perturb1.tmp",nlines1,"float")
shear_perturb2 = asciiread("shear_perturb2.tmp",nlines2,"float")

;Sort the arrays 
qsort(stab_perturb1)
qsort(stab_perturb2)
qsort(shear_perturb1)
qsort(shear_perturb2)

;Get number of values
numnonmissing1 = dimsizes(ind(stab_perturb1.ne.-9999))
numnonmissing2 = dimsizes(ind(stab_perturb2.ne.-9999))
numnonmissing3 = dimsizes(ind(shear_perturb1.ne.-9999))
numnonmissing4 = dimsizes(ind(shear_perturb2.ne.-9999))

;Separate into bins
nbins = toint((topbin-bottombin)/binintrvl)
y = new((/4,nbins+1/),"float")
bot_of_bin = bottombin
do i=0,nbins
   bot_val = bottombin+(binintrvl*i)
   top_val = bot_val+binintrvl
   y(0,i) = tofloat(dimsizes(ind(stab_perturb1.ge.bot_val.and.stab_perturb1.lt.top_val)))/numnonmissing1*100 
   y(1,i) = tofloat(dimsizes(ind(stab_perturb2.ge.bot_val.and.stab_perturb2.lt.top_val)))/numnonmissing2*100 
   y(2,i) = tofloat(dimsizes(ind(shear_perturb1.ge.bot_val.and.shear_perturb1.lt.top_val)))/numnonmissing3*100 
   y(3,i) = tofloat(dimsizes(ind(shear_perturb2.ge.bot_val.and.shear_perturb2.lt.top_val)))/numnonmissing4*100 
end do

sum1 = sum(y(0,:))
sum2 = sum(y(1,:))
sum3 = sum(y(2,:))
sum4 = sum(y(3,:))
print(sum1)
print(sum2)
print(sum3)
print(sum4)

x = new((/4,nbins+1/),"float")
x(0,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2
x(1,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2
x(2,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2
x(3,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2

wks := gsn_open_wks("png","/jm13/pduran/web/pdf_perturbs_"+type+"_"+minrad+"-"+maxrad+"km_"+bottomlev+"-"+toplev+"km_brch_"+bottombin+"-"+topbin)
xyres = True
xyres@gsnDraw = False
xyres@gsnFrame = False
xyres@xyLineColors = (/"red","blue","red","blue"/) 
xyres@xyLineThicknesses = (/5,5,5,5/)
xyres@trYMinF = 0.
xyres@trYMaxF = 12.
xyres@xyDashPatterns = (/0,0,2,2/)
xyres@gsnMaximize = True
xyres@tiYAxisString = "Percent"
xyres@tiXAxisString = "Perturbation Stability and Shear Terms"
xyres@trXMinF = tofloat(bottombin)
xyres@trXMaxF = tofloat(topbin)
xyres@tiMainString = "PDF of Stability and Shear    Bin Interval "+binintrvl
xyres@tmXTOn = False
xyres@tmYROn = False
xyres@tiMainOn = False

;Add a legend
xyres@pmLegendDisplayMode = "Always"
xyres@pmLegendSide = "Left"
xyres@pmLegendOrthogonalPosF = -1.19 ;Move legend right
xyres@pmLegendParallelPosF   = 0.92 ;Move legend down
xyres@pmLegendWidthF = 0.20
xyres@pmLegendHeightF = 0.10
xyres@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
xyres@lgPerimOn = True             ;Turn on/off box around legend
xyres@lgPerimColor = "Background"
xyres@lgPerimFill = 0
xyres@lgPerimFillColor = "Background"
xyres@lgLabelFontHeightF = 0.016
xyres@lgItemOrder = (/3,1,2,0/)
if(type.eq."intensity")then
   xyres@xyExplicitLegendLabels = (/"Stability; Hurricanes   n="+numnonmissing1,"Shear; Hurricanes      n="+numnonmissing3,"Stability; TD+TS         n="+numnonmissing2,"Shear; TD+TS            n="+numnonmissing4/)
else if(type.eq."diurnal")then
   xyres@xyExplicitLegendLabels = (/"Stability; 00 UTC       n="+numnonmissing1,"Shear; 00 UTC          n="+numnonmissing3,"Stability; 12 UTC       n="+numnonmissing2,"Shear; 12 UTC          n="+numnonmissing4/)
end if
end if

dum = gsn_csm_xy(wks,x,y,xyres)

; Add vertical line at x=0
lineres = True
lineres@gsLineThicknessF = 3.
lineres@gsLineColor = "gray40"
dum1 = gsn_add_polyline(wks,dum,(/0,0/),(/xyres@trYMinF,xyres@trYMaxF/),lineres)

draw(dum)
frame(wks)

system("\rm *perturb*tmp")
