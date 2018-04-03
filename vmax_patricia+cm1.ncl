load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

;---------------------------------------------------------------;
;vmax_patricia+cm1.ncl
;Patrick Duran
;05 April 2016
;
;Plots maximum total velocity for a CM1 simulation at the lowest
;model level (250 m) along with the best track for Hurricane
;Patricia (2015). 
;---------------------------------------------------------------;

ncfile = "/nfs/jm13/pduran/cm1/cm1r18/run/run02/output/axisym_hurr_15N_28C_stats.nc"
btfile = "/nfs/jm13/pduran/best-tracks/patricia_vmax.dat"
outdir = "/jm13/pduran/web/"
lag = 0   ;Lag between intensification of Patricia and the simulation

;Set X coordinate
time = fspan(0,22920,22920) / 60 ;Data every minute; convert to hours
time_lagged = time + lag

;Get vmax from CM1 file
input = addfile(ncfile,"r")
vmax_cm1 = input->vmax
;vmax_cm1 = runave(vmax_cm1,360,0) ;Apply 6-hour running mean

;Get vmax from Patricia best track file
btvmax = readAsciiTable(btfile,2,"float",0)
btvmax_int = linint1(btvmax(:,0),btvmax(:,1),False,time,0) * 0.514444 ;kt to m/s

;Intensification rate
intrate_cm1 = center_finite_diff(vmax_cm1,time,False,0) * 60 ;Convert to m/s/hr
intrate_bt  = center_finite_diff(btvmax_int,time,False,0) * 60 ;Convert to m/s/hr

;Cross-correlations between intensification rates
corr = esccr(intrate_cm1,intrate_bt,2400)  ;Lag of 20 hours

;Create arrays so we can plot two lines on each plot
plotdata = new((/2,dimsizes(time)/),"float")
plotdata(0,:) = vmax_cm1
plotdata(1,:) = btvmax_int

plotdata_intrate = plotdata
plotdata_intrate(0,:) = intrate_cm1
plotdata_intrate(1,:) = intrate_bt

res = True
res@gsnMaximize = True
res@xyLineThicknessF = 4.
res@xyDashPattern = 2
res@tiXAxisString = "Time (Hours)"
res@tiYAxisString = "Vmax (m/s)"
res@trXMinF = lag
res@trXMaxF = 96.
res@trYMaxF = 100.
res@tmYROn = False
res@tmXTOn = False
res@pmLegendDisplayMode = "Always"
res@pmLegendSide = "Right"
res@pmLegendOrthogonalPosF = -0.31 ;Move legend left
res@pmLegendParallelPosF   = 0.1 ;Move legend down
res@pmLegendWidthF = 0.20
res@pmLegendHeightF = 0.10
res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
res@lgPerimOn = False             ;Turn on/off box around legend
res@lgLabelFontHeightF = 0.02
res@xyExplicitLegendLabels = " CM1"
res@gsnDraw = False
res@gsnFrame = False
wks = gsn_open_wks("png",outdir+"vmax")
plot = gsn_csm_xy(wks,time,plotdata(0,:),res)
res@xyDashPattern = 0
res@pmLegendOrthogonalPosF = -0.28 ;Move legend left
res@pmLegendParallelPosF = 0.05    ;Move legend down
res@xyExplicitLegendLabels = " Patricia"
plot2 = gsn_csm_xy(wks,time_lagged,plotdata(1,:),res)
overlay(plot,plot2)
draw(plot)
frame(wks)

rateres = res
rateres@tiYAxisString = "Intensification Rate (m/s/hr)"
wks = gsn_open_wks("png",outdir+"intrate")
plot = gsn_csm_xy(wks,time,plotdata_intrate,rateres)
