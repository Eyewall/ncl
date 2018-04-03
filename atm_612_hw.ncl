load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

dt   = 240		;Time to integrate over
zi   = 0.0002		;Initial relative vertical vorticity [1/s]
fi   = 0.0001		;Initial relative Coriolis forcing [1/s]
diva = -0.0001		;Horizontal divergence [1/s]
divb = -0.0002          ;Horizontal divergence [1/s]

time = fspan(0,dt,dt+1)
tsec = time * 60 	;Convert to seconds

data = new((/2,dt+1/),float)
data(0,:) = (zi+fi)*exp(-tsec*diva)
data(1,:) = (zi+fi)*exp(-tsec*divb)
data = data * 100000
print(time)

wks = gsn_open_wks("png","partD")
res  = True
res@tiMainString  = "Question 1D"
res@tiXAxisString = "Time (min)"
res@tiYAxisString = "Vertical Vorticity [x10^-5 s^-1]"
res@xyLineColors = (/"red","blue"/)
res@xyLineThicknesses = (/3,3/)
res@xyDashPattern = 0
res@gsnMaximize = True

;------------;
;Add a legend;
;------------;
res@pmLegendDisplayMode = "Always"
res@pmLegendSide = "Left"
res@pmLegendOrthogonalPosF = -0.55 ;Move legend right
res@pmLegendParallelPosF   = 0.25 ;Move legend up
res@pmLegendWidthF = 0.20
res@pmLegendHeightF = 0.10
res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
res@lgPerimOn = False             ;Turn on/off box around legend
res@lgLabelFontHeightF = 0.02
res@xyExplicitLegendLabels = (/"Part a","Part b"/)

plot = gsn_csm_xy (wks,time,data,res)
