load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; brch_percentiles.ncl                                    
; Patrick Duran                                           
; 6/17/2015
;----------------------------------------------------------------;

vars = (/"brch","stab","shear"/)
radbin = 1 
nrads   = 9
nbins   = 29
nlevels = 201   ;Number of vertical levels in the dataset
                   ;Corresponds to number of columns in input files
inputdir1 = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/00z/200kmbins/overlap/rzfiles/"
inputdir2 = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/12z/200kmbins/overlap/rzfiles/"
outputdir = "/jm13/pduran/ncl/histograms/automatic_gen/"

;Loop through vars
do k=0,dimsizes(vars)-1
   var = vars(k)

   ;Get files
   brchfiles_hurr = systemfunc("ls "+inputdir1+"*"+var+"*")
   brchfiles_tstd = systemfunc("ls "+inputdir2+"*"+var+"*")

   ;Loop through files
   percentages_hurr = new((/nrads,nbins-1/),"float")
   percentages_tstd = new((/nrads,nbins-1/),"float")
   do i=0,nrads-1
      unixi = i + 1
      ;Each of these three arrays are [nsondes]x[nlevels]
      brcharray_hurr  = readAsciiTable(brchfiles_hurr(i),nlevels,"float",5)
      brcharray_tstd  = readAsciiTable(brchfiles_tstd(i),nlevels,"float",5)
      brcharray_hurr@_FillValue = -9999.
      brcharray_tstd@_FillValue = -9999.
   
      brcharray_hurr := where(brcharray_hurr.lt.-10.,brcharray_hurr@_FillValue,brcharray_hurr)
      brcharray_tstd := where(brcharray_tstd.lt.-10.,brcharray_tstd@_FillValue,brcharray_tstd)
   
      hist_array_hurr = ndtooned(brcharray_hurr(:,90:150))
      hist_array_tstd = ndtooned(brcharray_tstd(:,90:150))
      hist_array_hurr@_FillValue = -9999.
      hist_array_tstd@_FillValue = -9999.
   
      wks = gsn_open_wks("png",outputdir+"histogram_diurnal_"+var+"_radbin_"+unixi)
      res = True
      res@gsnHistogramComputePercentages = True
      res@gsnHistogramBinIntervals = fspan(-2,5,nbins)
      hurr_hist = gsn_histogram(wks,hist_array_hurr,res)
      tstd_hist = gsn_histogram(wks,hist_array_tstd,res)
      percentages_hurr(i,:) = hurr_hist@PercentagesNoMissing
      percentages_tstd(i,:) = tstd_hist@PercentagesNoMissing
      delete([/brcharray_hurr,brcharray_tstd,hist_array_hurr,hist_array_tstd/])
   end do    ;Radial bin loop
   
   nrads_plot = 2
   x = new((/nrads_plot,nbins-1/),"float")
   do j=0,nrads_plot-1
      x(j,:) = fspan(-2,5,nbins-1)
   end do
   ;y = percentages_hurr
   ;y = percentages_tstd
   y = (/percentages_hurr(radbin,:),percentages_tstd(radbin,:)/)
   
   colors = (/"red","orange","yellow","green","cadetblue1","cyan","purple","brown","black"/)
   thicknesses = (/3,3,3,3,3,3,3,3,3/)
   wks := gsn_open_wks("png","/jm13/pduran/web/histogram_"+var+"_diurnal_10-15km_100-300km")
   xyres = True
   xyres@xyLineColors = colors(0:2) 
   xyres@xyLineThicknesses = (/5,5/)
   xyres@trYMinF = 0.
   xyres@trYMaxF = 40.
   xyres@xyDashPattern = 0
   xyres@gsnMaximize = True
   xyres@tiXAxisString = var
   xyres@tiYAxisString = "Percent"
   
   ;Add a legend
   xyres@pmLegendDisplayMode = "Always"
   xyres@pmLegendSide = "Left"
   xyres@pmLegendOrthogonalPosF = -0.5 ;Move legend right
   xyres@pmLegendParallelPosF   = 0.92 ;Move legend down
   xyres@pmLegendWidthF = 0.20
   xyres@pmLegendHeightF = 0.10
   xyres@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
   xyres@lgPerimOn = False             ;Turn on/off box around legend
   xyres@lgLabelFontHeightF = 0.02
   xyres@xyExplicitLegendLabels = (/"00 UTC","12 UTC"/)
   
   dum = gsn_csm_xy(wks,x,y,xyres)
end do
