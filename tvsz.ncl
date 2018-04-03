load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/nfs/jm13/pduran/ncl/functions/interpolate.ncl"

;---------------------------------------------
; dtdz.ncl
; Patrick Duran
; 05 January 2016
; 
; Plots a vertical profile of T for all files
; listed in a given list file (editsonde fmt.)
; 
;---------------------------------------------

indir  = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/20151023/"
outdir   = "/nfs/jm13/pduran/web/tci/tvsz/"
listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/20151023/transect1"
files = systemfunc("cat "+listfile)
nfiles = dimsizes(files)

do i=0,nfiles-1
   unixi = i+1
   print("Plotting sounding "+unixi+" of "+nfiles)
   infile = files(i) 
   data := readAsciiTable(indir+infile,10,"float",7)
   data@_FillValue = -9999.
   t := data(:,1)
   z := data(:,5) / 1000.   ;Convert to km

   ;Get difference between two smallest values
   tsort := t
   qsort(tsort)
   tsort_nonmissing := tsort(ind(.not.ismissing(tsort)))
   diff = tsort_nonmissing(1) - tsort_nonmissing(0)
   
   ;Plot
   wks = gsn_open_wks("png",outdir+unixi)
   res = True
   res@tiYAxisString = "Height (km)"
   res@tiXAxisString = "T (C)"
;   res@gsnLeftString = "Difference between two smallest temperatures: "+diff+" deg C"
   res@tiXAxisFontHeightF = 0.017
   res@tiYAxisFontHeightF = 0.017
   res@tmXBLabelFontHeightF = 0.016
   res@tmYLLabelFontHeightF = 0.016
   res@xyLineColor = "blue"
   res@xyLineThicknessF = 6
   res@xyDashPatterns = 0
   res@gsnMaximize = True
   res@trXMinF = -82.
   res@trXMaxF = -65.
   res@trYMinF = 16.
   res@trYMaxF = 18.5
   res@tmYROn = False
   res@tmXTOn = False
   res@tmYMajorGrid = True
   res@tmYMajorGridLineColor = "gray"
   res@tmYMajorGridLineDashPattern = 1
   res@tmXMajorGrid = True
   res@tmXMajorGridLineColor = res@tmYMajorGridLineColor
   res@tmXMajorGridLineDashPattern = res@tmYMajorGridLineDashPattern
   plot = gsn_csm_xy(wks,t,z,res)
end do
