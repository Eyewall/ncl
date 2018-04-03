load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/jm13/pduran/ncl/functions/time_axis_labels.ncl"

;-----------------------------------------------------------;
; totplot.ncl                                    
; Patrick Duran                                           
; 03 April 2016
;
; Will read all overshooting top files (obtained from Sarah
; Griffin/CIMSS) in a given directory and plot the number of
; TOTs detected as a function of time.
;----------------------------------------------------------;

;do j = 0,400,100
minrad = 0    ;Radius from storm center 
maxrad = 400  ;Radius from storm center 
minrad = j
maxrad = j+100
indir  = "/jm13/pduran/tots/patricia/"+minrad+"-"+maxrad+"km/"
outdir = "/jm13/pduran/web/tots/"+minrad+"-"+maxrad+"km/"
norm   = 1    ;0=Plot total # of TOTs, 1=Normalize by area
pi     = 4.0*atan(1.0)

;Set dates and time of four center crossings
centeryear = (/2015,2015,2015,2015/)
centermon  = (/10,10,10,10/)
centerday  = (/21,22,22,23/)
centerhr   = (/19,18,19,20/)
centermin  = (/57,23,05,07/)
centersec  = (/0,0,0,0/)
centerjul  = toint(cd_inv_calendar(centeryear,centermon,centerday,centerhr,\
                                   centermin,centersec,"minutes since 1971-1-1",0))

;Create output directory
system("mkdir "+outdir)

;Compute area of this radial bin
outerarea = pi*maxrad^2
innerarea = pi*minrad^2
area = outerarea-innerarea 

;Initialize variables of arbitrary length
totlats := new(1,"float")
totlons := totlats
tottemp := totlats
totmag  := totlats
anvilz  := totlats
totz    := totlats
totp    := totlats

;Get TOT files and loop through them all
infiles := systemfunc("ls "+indir+"*txt")
nfiles  := dimsizes(infiles)
ntots   := new(nfiles,"float")
time    := new(nfiles,"integer")
do i=0,nfiles-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+nfiles+"    `date`")

   ;Get date and time from TOT filename
   yearday = systemfunc("echo "+infiles(i)+" | awk -F'.' '{print $3}' | cut -c1-7")
   hr      = stringtoint(systemfunc("echo "+infiles(i)+" | awk -F'.' '{print $4}' | cut -c1-2"))
   minu    = stringtoint(systemfunc("echo "+infiles(i)+" | awk -F'.' '{print $4}' | cut -c3-4"))
   greg = yyyyddd_to_yyyymmdd(toint(yearday))
   year = stringtoint(systemfunc("echo "+greg+" | cut -c1-4"))
   mon  = stringtoint(systemfunc("echo "+greg+" | cut -c5-6"))
   day  = stringtoint(systemfunc("echo "+greg+" | cut -c7-8"))
   time(i) = toint(cd_inv_calendar(year,mon,day,hr,minu,0,"minutes since 1971-1-1",0))
   time@units = "minutes since 1971-1-1"

   ;Read TOT data
   nlines = systemfunc("wc "+infiles(i)+" | awk '{print $1}'")
   if(nlines.gt.1)then
      tots := readAsciiTable(infiles(i),7,"float",1)
      totlats := tots(:,0)
      totlons := tots(:,1)
      tottemp := tots(:,2)
      totmag  := tots(:,3)
      anvilz  := tots(:,4)
      totz    := tots(:,5)
      totp    := tots(:,6)
      ntots(i) = dimsizes(totlats)
   else
      totlats := totlons@_FillValue
      totlons := totlats 
      tottemp := totlats 
      totmag  := totlats 
      anvilz  := totlats 
      totz    := totlats 
      totp    := totlats 
      ntots(i) = 0
   end if
end do

;Compute number of TOTs per unit area
ntots_norm := ntots/area

;Set time labels for plotting
timelabels = cd_calendar(time,0)

;Plot graph of the number of TOTs
if(norm.eq.0)then
   wks = gsn_open_wks("png",outdir+"tots_patricia_15min")
else
   wks = gsn_open_wks("png",outdir+"tots_patricia_15min_normalized")
end if
res = True
res@tiMainString  = minrad+"-"+maxrad+" km radial bin"
res@tiMainFontHeightF = 0.014
if(norm.eq.0)then
   res@tiYAxisString = "Number of overshooting tops"
else
   res@tiYAxisString = "Number of overshooting tops per square km"
end if
res@tiXAxisString = "Date/Time"
res@tiXAxisFontHeightF = 0.014
res@tiYAxisFontHeightF = 0.014
res@tmXBLabelFontHeightF = 0.01
res@tmYLLabelFontHeightF = 0.01
res@tmXBLabelAngleF = 30.
res@tmXTOn = False
res@tmYROn = False
res@xyLineThicknessF = 3.
res@trYMinF = 0.
if(norm.eq.0)then
   res@trYMaxF = tofloat(max(ntots))
else
   res@trYMaxF = tofloat(max(ntots_norm))
end if
;if(minrad.eq.0.and.maxrad.eq.500)then
;   res@trYMaxF = 60.
;   maxy = 60.
;else if (minrad.eq.0.and.maxrad.eq.100)then
;   res@trYMaxF = 10.
;   maxy = 10.
;else
;   maxy = 100000.
;end if
;end if
res@gsnMaximize   = True
res@gsnDraw = False
res@gsnFrame = False

restick = True
restick@ttmFormat = "%c %D %H UTC"
restick@ttmAxis   = "XB"
;restick@ttmValues = timelabels
restick@ttmMajorStride = 48
restick@ttmMinorStride = 100000
time_axis_labels(time,res,restick)
if(norm.eq.0)then
   plot = gsn_csm_xy(wks,time,ntots,res)
else
   plot = gsn_csm_xy(wks,time,ntots_norm,res)
end if

;Add lines indicating center crossings
dum = new(dimsizes(centerjul),"graphic")
do i=0,dimsizes(centerjul)-1
   x = (/centerjul(i),centerjul(i)/)
   y = (/res@trYMinF,res@trYMaxF/)
   lineres = True
   lineres@gsLineThicknessF = 4.
   lineres@gsLineDashPattern = 16.
   lineres@gsLineColor = "red"
   dum(i) = gsn_add_polyline(wks,plot,x,y,lineres)
end do
draw(plot)
frame(wks)
;end do
