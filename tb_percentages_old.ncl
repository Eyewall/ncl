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

opt = 2   ;Option for plotting - 0=Prob Dist. Func.; 1=Cumul. Dist. Func.
binsize = 10 ;Size of each radial bin; used for opt=2
infile = "/jm13/pduran/hs3/ir/tb/sonde_ir_threshold_vals.txt"
;outdir = "/jm13/pduran/hs3/ir/tb/"
outdir = "/jm13/pduran/web/"
data = readAsciiTable(infile,6,"float",5)

thresh    = data(:,0)
smooth    = data(:,1)
sharp     = data(:,2)
multi     = data(:,3)
uncertain = data(:,4)
total     = data(:,5)

percentages = new((/4,dimsizes(data(:,0))/),"float")
if(opt.eq.0)then
   percentages(0,:) = uncertain/total*100
   percentages(1,:) = multi/total*100
   percentages(2,:) = sharp/total*100
   percentages(3,:) = smooth/total*100
   wks = gsn_open_wks("png",outdir+"tb_percentages")
else if(opt.eq.1)then
   do i=0,dimsizes(data(:,0))-1
      if(uncertain(dimsizes(uncertain)-1).ne.0)then
         percentages(0,i) = uncertain(i)/uncertain(dimsizes(uncertain)-1)*100
      end if
      if(multi(dimsizes(multi)-1).ne.0)then
         percentages(1,i) = multi(i)/multi(dimsizes(multi)-1)*100
      end if
      if(sharp(dimsizes(sharp)-1).ne.0)then
         percentages(2,i) = sharp(i)/sharp(dimsizes(sharp)-1)*100
      end if
      if(uncertain(dimsizes(uncertain)-1).ne.0)then
         percentages(3,i) = smooth(i)/smooth(dimsizes(smooth)-1)*100
      end if
      wks = gsn_open_wks("png",outdir+"tb_cdf")
   end do
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
   wks = gsn_open_wks("png",outdir+"tb_pdf")
end if
end if
end if
print(percentages)
;----------------------;
;Set plotting resources;
;----------------------;
res  = True
res@gsnMaximize = True
res@tiXAxisString = "IR Brightness Temperature (~S~o~N~C)"
res@tiYAxisString = "Percent"
res@xyLineColors = (/"green","blue","orange","red"/)
res@xyLineThicknesses = (/5,5,5,5/)
res@xyDashPattern = 0

if(opt.eq.0)then
   res@trYMinF = 0.
   res@trYMaxF = 70.
   res@trXMinF = -80.
   res@trXMaxF = 30.
else if(opt.eq.1)then
   res@trYMaxF = 100.
   res@trXMinF = -75.
   res@trXMaxF = 25.
else if(opt.eq.2)then
   res@trYMinF = 0.
   res@trYMaxF = 25.
   res@trXMinF = -80.
   res@trXMaxF = 30.
end if
end if
end if

;------------;
;Add a legend;
;------------;
res@pmLegendDisplayMode = "Always"
res@pmLegendSide = "Right"
res@pmLegendOrthogonalPosF = -0.48 ;Move legend left
res@pmLegendParallelPosF   = 0.1 ;Move legend down
res@pmLegendWidthF = 0.30
res@pmLegendHeightF = 0.12
res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
res@lgPerimOn = False             ;Turn on/off box around legend
res@lgLabelFontHeightF = 0.02
label1 = "Smooth (N = "+smooth(dimsizes(smooth)-1)+")"
label2 = "Sharp (N = "+sharp(dimsizes(sharp)-1)+")"
label3 = "Multiple (N = "+multi(dimsizes(multi)-1)+")"
label4 = "Uncertain (N = "+uncertain(dimsizes(uncertain)-1)+")"
res@xyExplicitLegendLabels = (/label4,label3,label2,label1/)
res@tmYROn = False
res@tmXTOn = False
res@gsnDraw = False
res@gsnFrame = False
plot = gsn_csm_xy (wks,thresh,percentages,res)
draw(plot)
frame(wks)
