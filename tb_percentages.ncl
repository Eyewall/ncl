load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; tb_percentages.ncl                                    
; Patrick Duran                                           
; 5/23/2015
; This script will plot an x-y graph with brightness temperatures
; on the x axis and percentages on the y axis for 3 sounding
; structure classifications (smooth, sharp, and multiple
; tropopauses.)
;----------------------------------------------------------------;

opt = 0     ;Option for plotting - 0=Pct. in each radial bin; 1=Cumul. Dist. Func.
            ;                      2=Prob. Dist. Func.
binsize = 10 ;Size of each radial bin; used for opt=2
radii = "0-500km" 
infile = "/jm13/pduran/hs3/ir/tb/sonde_ir_threshold_vals_"+binsize+"Cbins_"+radii+".txt"
outdir = "/jm13/pduran/web/"
outfilesuffix = binsize+"Cbins_"+radii
data = readAsciiTable(infile,6,"float",5)

thresh    = data(:,0)
smooth    = data(:,1)
sharp     = data(:,2)
multi     = data(:,3)
uncertain = data(:,4)
total     = data(:,5)

percentages = new((/3,dimsizes(data(:,0))/),"float")
if(opt.eq.0)then
   percentages(0,:) = multi/total*100
   percentages(1,:) = sharp/total*100
   percentages(2,:) = smooth/total*100
   wks = gsn_open_wks("png",outdir+"tb_percentages_"+outfilesuffix)
   title = "Percent   "+"Binsize "+binsize+"C   Radii "+radii
else if(opt.eq.1)then
   do i=0,dimsizes(data(:,0))-1
      if(multi(dimsizes(multi)-1).ne.0)then
         percentages(0,i) = multi(i)/multi(dimsizes(multi)-1)*100
      end if
      if(sharp(dimsizes(sharp)-1).ne.0)then
         percentages(1,i) = sharp(i)/sharp(dimsizes(sharp)-1)*100
      end if
      if(uncertain(dimsizes(uncertain)-1).ne.0)then
         percentages(2,i) = smooth(i)/smooth(dimsizes(smooth)-1)*100
      end if
   end do
   wks = gsn_open_wks("png",outdir+"tb_cdf_"+outfilesuffix)
   title = "CDF   "+"Binsize "+binsize+"C   Radii "+radii
else if(opt.eq.2)then
   thresh(0) = ((thresh(0)-binsize)+thresh(0))/2
   percentages(0,0) = multi(0)/multi(dimsizes(multi)-1)*100
   percentages(1,0) = sharp(0)/sharp(dimsizes(sharp)-1)*100
   percentages(2,0) = smooth(0)/smooth(dimsizes(smooth)-1)*100
   do i=1,dimsizes(data(:,0))-1
      thresh(i) = (thresh(i)+thresh(i-1))/2
      percentages(0,i) = (multi(i)-multi(i-1))/multi(dimsizes(multi)-1)*100
      percentages(1,i) = (sharp(i)-sharp(i-1))/sharp(dimsizes(sharp)-1)*100
      percentages(2,i) = (smooth(i)-smooth(i-1))/smooth(dimsizes(smooth)-1)*100
   end do
   wks = gsn_open_wks("png",outdir+"tb_pdf_"+outfilesuffix)
   title = "PDF   "+"Binsize "+binsize+"C   Radii "+radii
end if
end if
end if

;----------------------;
;Set plotting resources;
;----------------------;
res  = True
res@gsnMaximize = True
res@tiXAxisString = "IR Brightness Temperature (~S~o~N~C)"
res@tiYAxisString = "Percent"
res@xyLineColors = (/"blue","orange","red"/)
res@xyLineThicknesses = (/5,5,5/)
res@xyDashPattern = 0

if(opt.eq.0)then
   res@trYMinF = 0.
   res@trYMaxF = 70.
   res@trXMinF = -80.
   res@trXMaxF = 30.
else if(opt.eq.1)then
   res@trYMaxF = 100.
   res@trXMinF = -75.
   res@trXMaxF = 30.
else if(opt.eq.2)then
   res@trYMinF = 0.
   res@trYMaxF = 45.
   res@trXMinF = -80.
   res@trXMaxF = 30.
end if
end if
end if

;------------;
;Add a legend;
;------------;
;res@tiMainString = title
res@pmLegendDisplayMode = "Always"
res@pmLegendSide = "Right"
;res@pmLegendOrthogonalPosF = -0.48 ;Move legend left
;res@pmLegendParallelPosF   = 0.1 ;Move legend down
;if(opt.eq.2)then
   res@pmLegendOrthogonalPosF = -1.0 ;Move legend left
   res@pmLegendParallelPosF   = 0.9 ;Move legend up
;end if
res@pmLegendWidthF = 0.30
res@pmLegendHeightF = 0.12
res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
res@lgPerimOn = False             ;Turn on/off box around legend
res@lgLabelFontHeightF = 0.02
label1 = "Smooth (N = "+smooth(dimsizes(smooth)-1)+")"
label2 = "Sharp (N = "+sharp(dimsizes(sharp)-1)+")"
label3 = "Multiple (N = "+multi(dimsizes(multi)-1)+")"
res@xyExplicitLegendLabels = (/label3,label2,label1/)
if(opt.eq.2)then
;   res@lgLegendOn = False
   res@tmXBMode = "Explicit"
;   res@xyLineColors = (/"white","white","white"/)
   res@tmXBValues = thresh
   res@tmXBLabels = (/"-80 to -70","-70 to -60","-60 to -50","-50 to -40",\
                    "-40 to -30","-30 to -20","-20 to -10","-10 to 0",\
                    "0 to 10","10 to 20","20 to 30"/)
   res@tmXBLabelFontHeightF = 0.015
   res@tmXBLabelAngleF = 90
end if
res@tmYROn = False
res@tmXTOn = False
res@gsnDraw = False
res@gsnFrame = False
plot = gsn_csm_xy (wks,thresh,percentages,res)
draw(plot)
frame(wks)
