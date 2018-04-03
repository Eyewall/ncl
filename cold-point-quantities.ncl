load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/nfs/jm13/pduran/ncl/functions/meteo.ncl"

;----------------------------------------------------------------;
; cold-point-quantities.ncl                                    
; Patrick Duran                                           
; 07 May 2016
; Pulls data from .edit files and plots various quantitues of the
; cold point tropopause (pressure, temperature, theta) along a
; recon flight track. Also computes the maxmimum boundary layer
; equivalent potential temperature and plots it.
;
; 05/07/16: Code currently uses drop lat and lon to compute distance
;           from flight center at all levels (i.e. does not account
;           for sonde drift). Also, sondes that were dropped before
;           the aircraft passed the eye are manually set negative,
;           so be sure to change that for each flight leg.
; 06/08/16: Added functionality to compute and plot the maxmimum
;           boundary layer equivalent potential temperature for
;           each sonde in each flight, either using relative
;           humidity from the sonde or an assumed value (rhconst).
;----------------------------------------------------------------;

storm     = "patricia"
dates     = (/"20151021","20151022","20151022","20151023"/)
transects = (/"transect2","transect1","transect2","transect1"/)
;dates    = (/"20151002","20151003","20151004"/)
;transect = "transect1" ;;THIS IS NOW DEFINED IN THE LOOP BELOW
prefix   = "A"
suffix   = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
interp   = 1   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate
type      = 1   ;Plot as total distance from start of flight let (0) or
                ;distance from storm center (1)?
assumerh = 1   ;Assume a constant RH for the whole profile? 0=no, 1=yes
rhconst  = 90  ;Relative humidity to be used in thetae calculation
axisorient = 1 ;X-Axis orientation (0=Leftmost side represents the first sonde in the
               ;                      transect, 1=Leftmost side is West

;----------------------;
;Loop through all dates;
;----------------------;
cp_temp     = new((/dimsizes(dates),100/),"float")
cp_theta    = new((/dimsizes(dates),100/),"float")
cp_pres     = new((/dimsizes(dates),100/),"float")
irbt        = new((/dimsizes(dates),100/),"float")
maxblthetae = new((/dimsizes(dates),100/),"float")
dropdist    = new((/dimsizes(dates),100/),"float")
cp_temp@_FillValue     = -9999
cp_theta@_FillValue    = -9999
cp_pres@_FillValue     = -9999
maxblthetae@_FillValue = -9999
dropdist@_FillValue    = -9999
do i=0,dimsizes(dates)-1
   ;----------------------------------------------------;
   ;Set appropriate storm center locations for each date;
   ;----------------------------------------------------;  
   date = dates(i)
   transect = transects(i)
   if(date.eq."20151021")then
      if(transect.eq."transect1")
         centerlat = 13.38   ;Transect 1 did not have a center crossing!!
         centerlon = -99.26
         centersonde = 7
         if(axisorient.eq.1)then
            centersonde = 16
         end if
      else    ;Transect 2
         centerlat = 12.99   ;Sonde location nearest the 19:50 UTC NOAA-43
         centerlon = -99.27  ;vortex message center location (12.98,-99.20)
         centersonde = 7     ;Also zero wind center in sondes...
         if(axisorient.eq.1)then
            centersonde = 21
         end if
      end if
   else if(date.eq."20151022")then
      if(transect.eq."transect1")then
         centerlat = 15.09      ;Sonde nearest the interpolated center location for VORTEX msgs   
         centerlon = -104.12
         centersonde = 14
      else   ;Transect 2
         centerlat = 15.23      ;Sonde nearest the interpolated center location for VORTEX msgs
         centerlon = -104.22
         centersonde = 16
      end if
   else if(date.eq."20151023")then
      centerlat = 18.61      ;Sonde nearest the zero wind center   
      centerlon = -105.22
      centersonde = 14
      if(axisorient.eq.1)then
         centersonde = 32
      end if
   else if(date.eq."20151002")then
      centerlat = 23.83    ;Determined by combination of QC notes and meridional velocity
      centerlon = -74.65
      centersonde = 9
   else if(date.eq."20151003")then
      centerlat = 26.18    ;Determined by combination of QC notes and meridional velocity
      centerlon = -71.28
      centersonde = 7
   else if(date.eq."20151004")then
      centerlat = 31.81    ;Determine by IR imagery
      centerlon = -66.48
      centersonde = 10     ;Note that I chopped off some sondes from the high-density transect
   end if
   end if
   end if
   end if
   end if
   end if
   minxpatricia = -152
   maxxpatricia = 105;58;56
   minxjoaquin  = -174
   maxxjoaquin  = 124

   date = dates(i)
   sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/storm-relative/rad+tan-vel/"
   listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/storm-relative/rad+tan-vel/"+transect
   outdir   = "/jm13/pduran/web/tci/cross_sections/"+storm+"/"
   irbtfile = "/jm13/pduran/onr/ir/tb/ir-Tb-drops-"+storm+"-"+date+"-"+transect
   
   ;------------------------------------;
   ;Loop through all files for this date;
   ;------------------------------------;
   infiles := sondedir+systemfunc("cat "+listfile)
   nfiles  := dimsizes(infiles)
   ;If axisorient=1, we need to invert the X axis on 10/21 and 10/23
   if(axisorient.eq.1)then
      if(date.eq."20151021".or.date.eq."20151023")then
         infiles = infiles(::-1)
      end if
   end if
;   irtb    := stringtofloat(systemfunc("awk '{print $1}' "+irbtfile))
;   if(axisorient.eq.1)then
;      if(date.eq."20151021".or.date.eq."20151023")then
;         irtb = irtb(::-1)
;      end if
;   end if
   do j=0,nfiles-1
      data := readAsciiTable(infiles(j),10,"float",7)
      data@_FillValue = -9999.0
      p    := data(:,0)
      tc   := data(:,1)
      td   := data(:,2)
      u    := data(:,3)
      v    := data(:,4)
      hght := data(:,5)
      rh   := data(:,6)
      lat  := data(:,7)
      lon  := data(:,8)

      ;Get drop latitude and longitude from header
      droplat = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $3}'"))
      nfields = stringtoint(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print NF}'"))
      if(nfields.eq.9)then
         droplon = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $5}' | sed 's/=//'"))
      else
         droplon = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $6}'"))
      end if

      ;Compute theta and thetae
      theta := (tc+273.15)*(1000/p)^0.286
      es := 6.11*10^((7.5*tc)/(237.3+tc))   ;Saturation vapor pressure
      ws := 621.97*(es/(p-es))              ;Saturation mixing raitio  (g/kg) 
      if(assumerh.eq.0)then
         w := rh*ws/100/1000  ;Water vapor mixing ratio (kg/kg)
      else
         w := rhconst*ws/100/1000
      end if
      tk := tc+273.15
;      thetae := theta_eqv(tk,w,1000,p)
;      maxblthetae(i,j) = max(thetae(ind(hght.le.1000)))

      ;Tropopause quantities
      cp_temp (i,j) = min(tc)
      cp_pres (i,j) = p(minind(tc))
      cp_theta(i,j) = theta(minind(tc))
;      irbt    (i,j) = irtb(j) 

      ;-------------------------------------------------;
      ;Compute drop location distances from storm center;
      ;-------------------------------------------------;
      if(type.eq.1)
         dropdist(i,j) = gc_latlon(centerlat,centerlon,droplat,droplon,2,4)
      end if
   end do ;Files loop

   ;---------------------------------;
   ;Set unrealistic values to missing;
   ;---------------------------------;
   cp_temp = where(cp_pres.gt.150,cp_temp@_FillValue,cp_temp)
;   cp_temp = where(cp_temp.gt.-60,cp_temp@_FillValue,cp_temp)
   cp_pres = where(cp_temp.gt.-60,cp_pres@_FillValue,cp_pres)
   cp_theta= where(cp_temp.gt.-60,cp_theta@_FillValue,cp_theta)
   dropdist = where(dropdist.gt.2000,dropdist@_FillValue,dropdist)
   dropdist(i,0:(centersonde-1)) = dropdist(i,0:(centersonde-1))*-1.  ;Set drops before center to negative

   ;------------------------------------------------------------------;
   ;Interpolate across missing values in radius, if option is selected;
   ;------------------------------------------------------------------;
                                       ;When plotting the tropopause quantities, we
   cp_temp_interp := linmsg(cp_temp,0)  ;will first plot cp_temp_interp using
   cp_pres_interp := linmsg(cp_pres,0)  ;dashed lines, and then cp_temp using solid
   cp_theta_interp:= linmsg(cp_theta,0) ;so we have dashed lines where missing vals are.
end do ;Dates loop

;----------------------------------------;
;Compute difference between IR brightness;
;temperature and cold point temperature  ;
;----------------------------------------;
diff = irbt-cp_temp_interp

;------------;
;CREATE PLOTS;
;------------;
;COLD POINT TEMPERATURE VS. R
out_suffix = "_interp"
temp_wks = gsn_open_wks("png",outdir+"cold_point_temp"+out_suffix)
xyres = True
xyres@gsnMaximize = True
xyres@gsnDraw = False
xyres@gsnFrame = False
if(type.eq.0)then
   xyres@tiXAxisString = "Distance along flight track (km)"
else if(type.eq.1)then
   xyres@tiXAxisString = "W             Distance from storm center (km)             E"
end if
end if
xyres@tiYAxisOffsetXF = 0.01
xyres@gsnStringFontHeightF = 0.018
xyres@gsnLeftString = "a)"
xyres@tiYAxisString = "Cold Point Temperature (C)"
xyres@tiMainFontHeightF = 0.02
xyres@tiXAxisFontHeightF = 0.019
xyres@tiYAxisFontHeightF = 0.019
xyres@tmXBLabelFontHeightF = 0.019
xyres@tmYLLabelFontHeightF = 0.019
if(storm.eq."patricia")then
   xyres@trXMinF = minxpatricia 
   xyres@trXMaxF = maxxpatricia
else
   xyres@trXMinF = minxjoaquin 
   xyres@trXMaxF = maxxjoaquin
end if
if(storm.eq."patricia")then
   xyres@trYMinF = -84
   xyres@trYMaxF = -69.
else
   xyres@trYMinF = -81
   xyres@trYMaxF = -72
end if
xyres@xyLineColor = "blue"
xyres@xyLineThicknessF = 10
xyres@tmXTOn = False
xyres@tmYROn = False
xyres@tmYMajorGrid = True
xyres@tmYMajorGridLineColor = "gray"
xyres@tmYMajorGridLineDashPattern = 1
xyres@tmXMajorGrid = True
xyres@tmXMajorGridLineColor = xyres@tmYMajorGridLineColor
xyres@tmXMajorGridLineDashPattern = xyres@tmYMajorGridLineDashPattern
;NOTE: Can't do legends like a typical x-y plot because all but one of the lines
;      are attached as polylines, since the x coordinates are different for each.
;      Will instead add polylines and text boxes to the plot later in the script
;      that act as a legend.
;xyres@pmLegendDisplayMode = "Always"
;xyres@pmLegendSide = "Left"
;xyres@lgPerimOn = False
;xyres@pmLegendOrthogonalPosF = 1.0 ;Move legend right
;xyres@pmLegendParallelPosF   = 0.9 ;Move legend up
;label1 = "Oct 21"
;label2 = "Oct 22 Transect 1"
;label3 = "Oct 22 Transect 2"
;label4 = "Oct 23 Transect 1"
;xyres@xyExplicitLegendLabels = (/label1,label2,label3,label4/)
xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
xyres_noint@xyDashPattern = 0
plres = True
plres@gsLineColor = "green4"
plres@gsLineThicknessF = 10
btres = True
btres@gsLineColor = "blue"
btres@gsLineDashPattern = 15
btres@gsLineThicknessF = 10
cp_temp_plot_int = gsn_csm_xy(temp_wks,dropdist(0,:),cp_temp_interp(0,:),xyres)
;dum1 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdist(0,:),irbt(0,:),btres)
dum2 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdist(1,:),cp_temp_interp(1,:),plres)
;dum3 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdist(1,:),irbt(1,:),btres)
plres@gsLineColor = "orange"
dum4 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdist(2,:),cp_temp_interp(2,:),plres)
plres@gsLineColor = "red"
dum5 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdist(3,:),cp_temp_interp(3,:),plres)

;ADD LEGEND
lineres = True
txres   = True
lgcolors = (/"blue","green4","orange","red"/)
lgtext   = (/"21 October","22 October Transect 1","22 October Transect 2","23 October"/)
xcoords  = (/-150,-135/)
ycoords  = (/-69.,-69./)
dumline  = new(dimsizes(lgcolors),graphic)
dumtext  = dumline
do k=0,dimsizes(lgcolors)-1
   ycoords = ycoords-0.5
   lineres@gsLineColor = lgcolors(k)
   lineres@gsLineThicknessF = 10
   txres@txJust = "CenterLeft"
   txres@txFontHeightF = 0.019
   dumline(k) = gsn_add_polyline(temp_wks,cp_temp_plot_int,xcoords,ycoords,lineres)
   dumtext(k) = gsn_add_text(temp_wks,cp_temp_plot_int,lgtext(k),xcoords(1)+5,ycoords(0),txres)
end do

;COLD POINT POTENTIAL TEMPERATURE VS. R
theta_wks = gsn_open_wks("png",outdir+"cold_point_theta"+out_suffix)
xythetares = xyres
xythetares@gsnLeftString = "c)"
xythetares@tiYAxisString = "Cold Point Potential Temperature (K)"
xythetares@trYMinF = 370
xythetares@trYMaxF = 420
xyres_noint = xythetares   ;Non-interpolated field will be plotted with solid line
xyres_noint@xyDashPattern = 0
cp_theta_plot_int = gsn_csm_xy(theta_wks,dropdist(0,:),cp_theta_interp(0,:),xythetares)
plres@gsLineColor = "green4"
dum6 = gsn_add_polyline(theta_wks,cp_theta_plot_int,dropdist(1,:),cp_theta_interp(1,:),plres)
plres@gsLineColor = "orange"
dum7 = gsn_add_polyline(theta_wks,cp_theta_plot_int,dropdist(2,:),cp_theta_interp(2,:),plres)
plres@gsLineColor = "red"
dum8 = gsn_add_polyline(theta_wks,cp_theta_plot_int,dropdist(3,:),cp_theta_interp(3,:),plres)

;PRESSURE AT THE COLD POINT
pres_wks = gsn_open_wks("png",outdir+"cold_point_pres"+out_suffix)
xypres = True
xypres@tiXAxisFontHeightF = 0.019
xypres@tiYAxisFontHeightF = 0.019
xypres@tmXBLabelFontHeightF = 0.019
xypres@tmYLLabelFontHeightF = 0.019
xypres@gsnStringFontHeightF = 0.018
xypres@gsnLeftString = "b)"
xypres@tiYAxisOffsetXF = 0.01

xypres@gsnMaximize = True
xypres@gsnDraw = False
xypres@gsnFrame = False
if(type.eq.0)then
   xypres@tiXAxisString = "Distance along flight track (km)"
else if(type.eq.1)then
   xypres@tiXAxisString = "W             Distance from storm center (km)             E"
end if
end if
xypres@tiMainFontHeightF = 0.02
if(storm.eq."patricia")then
   xypres@trXMinF = minxpatricia
   xypres@trXMaxF = maxxpatricia
else
   xypres@trXMinF = minxjoaquin
   xypres@trXMaxF = maxxjoaquin
end if
xypres@xyLineThicknessF = 10
xypres@tmXTOn = False
xypres@tmYROn = False
xypres@tmYMajorGrid = True
xypres@tmYMajorGridLineColor = "gray"
xypres@tmYMajorGridLineDashPattern = 1
xypres@tmXMajorGrid = True
xypres@tmXMajorGridLineColor = xypres@tmYMajorGridLineColor
xypres@tmXMajorGridLineDashPattern = xypres@tmYMajorGridLineDashPattern
xypres_noint = xypres   ;Non-interpolated field will be plotted with solid line
xypres_noint@xyDashPattern = 0
xypres@tiYAxisString = "Cold Point Pressure (hPa)"
xypres@trYReverse = True
xypres@xyLineColor = "blue"
if(storm.eq."patricia")
   xypres@trYMinF = 75
   xypres@trYMaxF = 106
   xypres@tmYLMode = "Explicit"
   xypres@tmYLValues = (/75,80,85,90,95,100,106/)
else
   xypres@trYMinF = 75
   xypres@trYMaxF = 115
   xypres@tmYLMode = "Explicit"
   xypres@tmYLValues = (/75,80,85,90,95,100,105,110,115/)
end if
xypres@tmYLLabels = tostring(xypres@tmYLValues)
xypres@xyYStyle = "Log"
xypres_noint = xypres   ;Non-interpolated field will be plotted with solid line
xypres_noint@xyDashPattern = 0
cp_pres_plot_int = gsn_csm_xy(pres_wks,dropdist(0,:),cp_pres_interp(0,:),xypres)
plres@gsLineColor = "green4"
dum9 = gsn_add_polyline(pres_wks,cp_pres_plot_int,dropdist(1,:),cp_pres_interp(1,:),plres)
plres@gsLineColor = "orange"
dum10 = gsn_add_polyline(pres_wks,cp_pres_plot_int,dropdist(2,:),cp_pres_interp(2,:),plres)
plres@gsLineColor = "red"
dum11 = gsn_add_polyline(pres_wks,cp_pres_plot_int,dropdist(3,:),cp_pres_interp(3,:),plres)

;IR BRIGHTNESS TEMPERATURE MINUS COLD POINT TEMPERATURE
;diffres = xyres
;diffres@gsnLeftString = " "
;diffres@tiYAxisString = "IR Brightness Temperature minus Cold Point Temperature (C)"
;diffres@tiYAxisFontHeightF = 0.015
;diffwks = gsn_open_wks("png","temp_ir-cpt")
;diffres@trYMinF = -8
;diffres@trYMaxF = 16
;diff_plot = gsn_csm_xy(diffwks,dropdist(0,:),diff(0,:),diffres)
;plres@gsLineColor = "orange"
;dum100 = gsn_add_polyline(diffwks,diff_plot,dropdist(1,:),diff(1,:),plres)
;plres@gsLineColor = "red"
;dum110 = gsn_add_polyline(diffwks,diff_plot,dropdist(2,:),diff(2,:),plres)

;MAXIMUM BOUNDARY LAYER EQUIVALENT POTENTIAL TEMPERATURE
;wks_blthetae = gsn_open_wks("png",outdir+"max_BLthetae"+out_suffix)
;thetaeres = xyres
;thetaeres@gsnLeftString = " "
;thetaeres@tiMainOn = True
;thetaeres@tiMainString = "Maximum Boundary Layer (z<=1000 m) Thetae (Assuming RH=90%)"
;thetaeres@tiMainFontHeightF = 0.015
;thetaeres@tiYAxisString = "Equivalent Potential Temperature (K)"
;thetaeres@tmYLMode = "Manual"
;thetaeres@trYMinF = 340
;thetaeres@trYMaxF = 420
;thetaeres@xyLineColor = "blue"
;blthetae_plot = gsn_csm_xy(wks_blthetae,dropdist(0,:),maxblthetae(0,:),thetaeres)
;plres@gsLineColor = "orange"
;dum120 = gsn_add_polyline(wks_blthetae,blthetae_plot,dropdist(1,:),maxblthetae(1,:),plres)
;plres@gsLineColor = "red"
;dum130 = gsn_add_polyline(wks_blthetae,blthetae_plot,dropdist(2,:),maxblthetae(2,:),plres)

;Add vertical lines at x=0
zerolineres = True
zerolineres@gsLineDashPattern = 16
zerolineres@gsLineThicknessF = 6.
zeroline_temp     = gsn_add_polyline(temp_wks,cp_temp_plot_int,(/0,0/),(/xyres@trYMinF,xyres@trYMaxF/),zerolineres)
zeroline_theta    = gsn_add_polyline(theta_wks,cp_theta_plot_int,(/0,0/),(/xythetares@trYMinF,xythetares@trYMaxF/),zerolineres)
zeroline_pres     = gsn_add_polyline(pres_wks,cp_pres_plot_int,(/0,0/),(/xypres@trYMinF,xypres@trYMaxF/),zerolineres)
;zeroline_diff     = gsn_add_polyline(diffwks,diff_plot,(/0,0/),(/diffres@trYMinF,diffres@trYMaxF/),zerolineres)
;zeroline_blthetae = gsn_add_polyline(wks_blthetae,blthetae_plot,(/0,0/),(/thetaeres@trYMinF,thetaeres@trYMaxF/),zerolineres)

draw(cp_temp_plot_int)
draw(cp_theta_plot_int)
draw(cp_pres_plot_int)
;draw(diff_plot)
;draw(blthetae_plot)
frame(temp_wks)
frame(theta_wks)
frame(pres_wks)
;frame(diffwks)
;frame(wks_blthetae)

;system("montage -trim -geometry +0+0 temp_ir-cpt.png "+outdir+"irtb_minus_cpt"+out_suffix+".png")
;system("\rm temp_ir-cpt.png")
