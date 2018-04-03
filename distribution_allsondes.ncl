load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; distribution_allsondes.ncl                                    
; Patrick Duran                                           
; 7/31/2015
; 
; CHANGES
; -------
; 06 October 2015 - P. Duran
; Added a vertical line at x=0
;----------------------------------------------------------------;

opt = 0   ;Set to 0 for raw plots; 1 for perturbation plots


if(opt.eq.0)then
   intordiurnal = "allsondes"
   radbin = "0-1000"
   bottomlev = 11
   toplev = 15
   bottombin = -1
   topbin    = 5
   binintrvl = 0.1
;   infile1 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/biggerbins/low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_stab.txt"
;   infile2 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/biggerbins/low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_shear.txt"
;   infile3 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_stab.txt"
;   infile4 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_shear.txt"
   infile1 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_stab.txt"
   infile2 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_shear.txt"
   infile3 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_stab.txt"
   infile4 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_shear.txt"
   
   
   nbins = toint((topbin-bottombin)/binintrvl)
   
   nrows1 = stringtoint(systemfunc("wc "+infile1+" | awk '{print($1)}'"))
   nrows2 = stringtoint(systemfunc("wc "+infile2+" | awk '{print($1)}'"))
   nrows3 = stringtoint(systemfunc("wc "+infile3+" | awk '{print($1)}'"))
   nrows4 = stringtoint(systemfunc("wc "+infile4+" | awk '{print($1)}'"))
   
   data1 = asciiread(infile1,(/nrows1,1/),"float")
   data2 = asciiread(infile2,(/nrows2,1/),"float")
   data3 = asciiread(infile3,(/nrows3,1/),"float")
   data4 = asciiread(infile4,(/nrows4,1/),"float")
   
   data1_1d = ndtooned(data1)
   data2_1d = ndtooned(data2)
   data3_1d = ndtooned(data3)
   data4_1d = ndtooned(data4)
   
   qsort(data1_1d)
   qsort(data2_1d)
   qsort(data3_1d)
   qsort(data4_1d)
   
   numnonmissing1 = dimsizes(ind(data1_1d.ne.-9999))
   numnonmissing2 = dimsizes(ind(data2_1d.ne.-9999))
   numnonmissing3 = dimsizes(ind(data3_1d.ne.-9999))
   numnonmissing4 = dimsizes(ind(data4_1d.ne.-9999))
   
   y = new((/4,nbins+1/),"float")
   bot_of_bin = bottombin
   do i=0,nbins
      bot_val = bottombin+(binintrvl*i)
      top_val = bot_val+binintrvl
if(i.eq.9)then
print(bot_val)
print(top_val)
end if
      y(0,i) = tofloat(dimsizes(ind(data1_1d.ge.bot_val.and.data1_1d.lt.top_val)))/numnonmissing1*100 
      y(1,i) = tofloat(dimsizes(ind(data2_1d.ge.bot_val.and.data2_1d.lt.top_val)))/numnonmissing2*100 
      y(2,i) = tofloat(dimsizes(ind(data3_1d.ge.bot_val.and.data3_1d.lt.top_val)))/numnonmissing3*100 
      y(3,i) = tofloat(dimsizes(ind(data4_1d.ge.bot_val.and.data4_1d.lt.top_val)))/numnonmissing4*100 
   end do

   x = new((/4,nbins+1/),"float")
   x(0,:) = fspan(bottombin+binintrvl,topbin+binintrvl,nbins+1)
   x(1,:) = fspan(bottombin+binintrvl,topbin+binintrvl,nbins+1)
   x(2,:) = fspan(bottombin+binintrvl,topbin+binintrvl,nbins+1)
   x(3,:) = fspan(bottombin+binintrvl,topbin+binintrvl,nbins+1)

   wks := gsn_open_wks("png","/jm13/pduran/web/pdf_"+intordiurnal+"_"+radbin+"km_"+bottomlev+"-"+toplev+"km_brch_"+bottombin+"-"+topbin)
   xyres = True
   xyres@xyLineColors = (/"red","blue","red","blue"/) 
   xyres@xyLineThicknesses = (/5,5,5,5/)
   xyres@trYMinF = 0.
   xyres@trYMaxF = 20.
   xyres@xyDashPatterns = (/0,0,2,2/)
   xyres@gsnMaximize = True
   xyres@tiYAxisString = "Percent"
   xyres@tiXAxisString = "Stability and Shear Terms"
   xyres@trXMinF = tofloat(bottombin)
   xyres@trXMaxF = tofloat(topbin)
   xyres@tiMainString = "PDF of Stability and Shear    Bin Interval "+binintrvl
   xyres@tmXTOn = False
   xyres@tmYROn = False
   xyres@tiMainOn = False
   xyres@gsnDraw = False
   xyres@gsnFrame = False
   if(radbin.eq."400-1000")then
      xyres@tiYAxisOn = False
   end if
   
   ;Add a legend
   xyres@pmLegendDisplayMode = "Always"
   xyres@pmLegendSide = "Left"
   xyres@pmLegendOrthogonalPosF = -1.19 ;Move legend right
   xyres@pmLegendParallelPosF   = 0.92 ;Move legend down
   xyres@pmLegendWidthF = 0.20
   xyres@pmLegendHeightF = 0.10
   xyres@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
   xyres@lgPerimOn = False             ;Turn on/off box around legend
   xyres@lgLabelFontHeightF = 0.016
   xyres@lgItemOrder = (/3,1,2,0/)
   xyres@xyExplicitLegendLabels = (/"Stability (R~B~b~N~ < 0.25)   n="+numnonmissing1,"Shear (R~B~b~N~ < 0.25)      n="+numnonmissing2,"Stability (R~B~b~N~ >= 0.25) n="+numnonmissing3,"Shear (R~B~b~N~ >= 0.25)    n="+numnonmissing4/)
   
   dum = gsn_csm_xy(wks,x,y,xyres)

   ; Add vertical line at x=0
   lineres = True
   lineres@gsLineThicknessF = 3.
   lineres@gsLineColor = "gray40"
   dum1 = gsn_add_polyline(wks,dum,(/0,0/),(/xyres@trYMinF,xyres@trYMaxF/),lineres)
   
   draw(dum)
   frame(wks)
end if

;--------------;
;   IF OPT=1   ;
;--------------;
if(opt.eq.1)then
   intordiurnal = "intensities"
   radbin = "0-1000"
   bottomlev = 9
   toplev = 17
   bottombin = -3
   topbin    = 3
   binintrvl = 0.1
   ;infile1 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/biggerbins/low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_stab.txt"
   ;infile2 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/biggerbins/low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_shear.txt"
   ;infile3 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_stab.txt"
   ;infile4 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_shear.txt"
   infile1 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_stab_perturbs.txt"
   infile2 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_shear_perturbs.txt"
   infile3 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/ts+td/2015/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_stab_perturbs.txt"
   infile4 = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/ts+td/2015/biggerbins/no_low_rb_sonde_list_"+radbin+"km"+bottomlev+"-"+toplev+"km_shear_perturbs.txt"
   
   
   nbins = toint((topbin-bottombin)/binintrvl)
   
   nrows1 = stringtoint(systemfunc("wc "+infile1+" | awk '{print($1)}'"))
   nrows2 = stringtoint(systemfunc("wc "+infile2+" | awk '{print($1)}'"))
   nrows3 = stringtoint(systemfunc("wc "+infile3+" | awk '{print($1)}'"))
   nrows4 = stringtoint(systemfunc("wc "+infile4+" | awk '{print($1)}'"))
   
   data1 = asciiread(infile1,(/nrows1,1/),"float")
   data2 = asciiread(infile2,(/nrows2,1/),"float")
   data3 = asciiread(infile3,(/nrows3,1/),"float")
   data4 = asciiread(infile4,(/nrows4,1/),"float")
   
   data1_1d = ndtooned(data1)
   data2_1d = ndtooned(data2)
   data3_1d = ndtooned(data3)
   data4_1d = ndtooned(data4)
   
   qsort(data1_1d)
   qsort(data2_1d)
   qsort(data3_1d)
   qsort(data4_1d)
   
   numnonmissing1 = dimsizes(ind(data1_1d.ne.-9999))
   numnonmissing2 = dimsizes(ind(data2_1d.ne.-9999))
   numnonmissing3 = dimsizes(ind(data3_1d.ne.-9999))
   numnonmissing4 = dimsizes(ind(data4_1d.ne.-9999))
   
   y = new((/4,nbins+1/),"float")
   bot_of_bin = bottombin
   do i=0,nbins
      bot_val = bottombin+(binintrvl*i)
      top_val = bot_val+binintrvl
      y(0,i) = tofloat(dimsizes(ind(data1_1d.ge.bot_val.and.data1_1d.lt.top_val)))/numnonmissing1*100 
      y(1,i) = tofloat(dimsizes(ind(data2_1d.ge.bot_val.and.data2_1d.lt.top_val)))/numnonmissing2*100 
      y(2,i) = tofloat(dimsizes(ind(data3_1d.ge.bot_val.and.data3_1d.lt.top_val)))/numnonmissing3*100 
      y(3,i) = tofloat(dimsizes(ind(data4_1d.ge.bot_val.and.data4_1d.lt.top_val)))/numnonmissing4*100 
   end do
   
   x = new((/4,nbins+1/),"float")
   x(0,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2
   x(1,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2
   x(2,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2
   x(3,:) = fspan(bottombin,topbin,nbins+1) - binintrvl/2
   
   wks := gsn_open_wks("png","/jm13/pduran/web/pdf_perturb_nolowrb_"+intordiurnal+"_"+radbin+"km_"+bottomlev+"-"+toplev+"km_brch_"+bottombin+"-"+topbin)
   xyres = True
   xyres@xyLineColors = (/"red","blue","red","blue"/) 
   xyres@xyLineThicknesses = (/5,5,5,5/)
   xyres@trYMinF = 0.
   xyres@trYMaxF = 24.
   xyres@xyDashPatterns = (/0,0,2,2/)
   xyres@gsnMaximize = True
   xyres@tiYAxisString = "Percent"
   xyres@tiXAxisString = "Stability and Shear Terms"
   xyres@trXMinF = tofloat(bottombin)
   xyres@trXMaxF = tofloat(topbin)
   xyres@tiMainString = "PDF of Stability and Shear    Bin Interval "+binintrvl
   xyres@tmXTOn = False
   xyres@tmYROn = False
   xyres@tiMainOn = False
   xyres@gsnDraw = False
   xyres@gsnFrame = False
   if(radbin.eq."400-1000")then
      xyres@tiYAxisOn = False
   end if
   
   ;Add a legend
   xyres@pmLegendDisplayMode = "Always"
   xyres@pmLegendSide = "Left"
   xyres@pmLegendOrthogonalPosF = -1.19 ;Move legend right
   xyres@pmLegendParallelPosF   = 0.92 ;Move legend down
   xyres@pmLegendWidthF = 0.20
   xyres@pmLegendHeightF = 0.10
   xyres@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
   xyres@lgPerimOn = False             ;Turn on/off box around legend
   xyres@lgLabelFontHeightF = 0.016
   xyres@lgItemOrder = (/3,1,2,0/)
   ;xyres@xyExplicitLegendLabels = (/"Stability (R~B~b~N~ < 0.25)   n="+numnonmissing1,"Shear (R~B~b~N~ < 0.25)      n="+numnonmissing2,"Stability (R~B~b~N~ >= 0.25) n="+numnonmissing3,"Shear (R~B~b~N~ >= 0.25)    n="+numnonmissing4/)
   xyres@xyExplicitLegendLabels = (/"Stability Hurricanes (R~B~b~N~ >= 0.25)   n="+numnonmissing1,"Shear Hurricanes (R~B~b~N~ >= 0.25)      n="+numnonmissing2,"Stability TD+TS (R~B~b~N~ >= 0.25) n="+numnonmissing3,"Shear TD+TS (R~B~b~N~ >= 0.25)    n="+numnonmissing4/)
   
   dum = gsn_csm_xy(wks,x,y,xyres)
   

   
   draw(dum)
   frame(wks)
end if
