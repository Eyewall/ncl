load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

file1 = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/00z/avg/200kmbins/allsondes_00z_0-200km.ncnt.125.avgedit"
file2 = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/12z/avg/200kmbins/allsondes_12z_0-200km.ncnt.134.avgedit"

data1 = readAsciiTable(file1,28,"float",7)
data2 = readAsciiTable(file2,28,"float",7)

hght     =  data2(:,5) / 1000
data = new((/6,201/),float)
data@_FillValue = -9999.
data(0,:) = data1(:,9)   ;Stability from file1
data(1,:) = data1(:,11)  ;Shear from file1
data(2,:) = data1(:,10)  ;BRCH from file1
data(3,:) = data2(:,9)   ;Stability from file2
data(4,:) = data2(:,11)  ;Shear from file2
data(5,:) = data2(:,10)  ;BRCH from file2 

wks = gsn_open_wks("png","stabshear_overlay_0-200km")
res = True
res@tiXAxisString = "Shear and Stability Terms"
res@tiYAxisString = "Height [km]"
res@xyLineColors = (/"red","blue","black","red","blue","black"/)
res@xyLineThicknesses = (/2,2,3,2,2,3/)
res@xyDashPatterns = (/0,0,0,1,1,1/)

;----------------------------;
;Set x and y axis min and max;
;----------------------------;
res@trXMinF = 0.
res@trXMaxF = 5.
res@trYMinF = 9.
res@trYMaxF = 17.

   ;------------;
   ;Add a legend;
   ;------------;
;   res@pmLegendDisplayMode = "Always"
;   res@pmLegendSide = "Right"
;   res@pmLegendOrthogonalPosF = -0.5 ;Move legend left
;   res@pmLegendParallelPosF   = 0.1 ;Move legend down
;   res@pmLegendWidthF = 0.20
;   res@pmLegendHeightF = 0.10
;   res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
;   res@lgPerimOn = False             ;Turn on/off box around legend
;   res@lgLabelFontHeightF = 0.02
;   res@xyExplicitLegendLabels = (/"Stability","Shear"/)
;
;   res@gsnDraw  = False
;   res@gsnFrame = False
   plot = gsn_csm_xy (wks,data,hght,res)
;
;   ;-----------------------------;
;   ;Add BRCH<0.25 indicator lines;
;   ;-----------------------------;
;   lineres = True
;   lineres@gsLineColor   = "magenta"
;   lineres@gsLineThicknessF = 7.0
;   lines = new(brch25ind_size,graphic)
;   x_coord_line = new(2,float)
;   y_coord_line = new(2,float)
;   x_coord_line = (/0.,4./)
;   i=0
;   if(.not.all(ismissing(brch25ind)))
;      do while (i.lt.brch25ind_size)
;         y_coord_line = (/pres(brch25ind(i)),pres(brch25ind(i))/)
;	 print(y_coord_line)
;         lines(i) = gsn_add_polyline(wks,plot,x_coord_line,y_coord_line,lineres)
;         delete(y_coord_line)
;         i=i+1
;      end do
;   end if
