load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/nfs/jm13/pduran/ncl/functions/meteo.ncl"
load "/jm13/pduran/ncl/functions/interpolate.ncl"

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

storm    = "patricia"
dates    = (/"20151021","20151022","20151023"/)
;dates    = (/"20151002","20151003","20151004"/)
;transect = "transect1" ;TRANSECTS ARE SET BELOW, IN THE DATE LOOP
maxhght  = 20000  ;Maximum height to pull (m)
minhght  = 0   ;Minimum height to use in interpolation function
dz       = 100    ;Grid spacing of the input data
minx     = -200   ;Mininmum x coordinate of the fixed grid to interpolate to
maxx     = 200    ;Maximum x coordinate of the fixed grid to interpolate to
x_spacng = 1      ;Grid spacing of the fixed grid
nradii   = (maxx-minx)/x_spacng+1
nlevels  = maxhght/dz+1
prefix   = "A"
suffix   = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
interp   = 1   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate
driftopt = 0   ;Account for sonde drift in interpolation script? (0=No,1=Yes)
type     = 1   ;Plot as total distance from start of flight let (0) or
                ;distance from storm center (1)?
assumerh = 1   ;Assume a constant RH for the whole profile? 0=no, 1=yes
rhconst  = 90  ;Relative humidity to be used in thetae calculation

;----------------------;
;Loop through all dates;
;----------------------;
cp_temp     = new((/dimsizes(dates),nradii/),"float")
cp_theta    = new((/dimsizes(dates),nradii/),"float")
cp_pres     = new((/dimsizes(dates),nradii/),"float")
irbt        = new((/dimsizes(dates),nradii/),"float")
dropdist    = new((/dimsizes(dates),nradii/),"float")
cp_temp@_FillValue     = -9999
cp_theta@_FillValue    = -9999
cp_pres@_FillValue     = -9999
do i=0,dimsizes(dates)-1
   date = dates(i)
   if(date.eq."20151021")
      transect = "transect2"
   else
      transect = "transect1"
   end if
   if(date.eq."20151021")then
      if(transect.eq."transect1")
         centerlat = 13.38   ;Transect 1 did not have a center crossing!!
         centerlon = -99.26
         centersonde = 7
   ;      centerlat = 13.41    
   ;      centerlon = -99.34   
   ;      centersonde = 6      
      else    ;Transect 2
         centerlat = 12.97   ;Sonde location nearest the 19:50 UTC NOAA-43
         centerlon = -99.13  ;vortex message center location (12.98,-99.20)
         centersonde = 5     ;Also zero wind center in sondes...
      end if
   else if(date.eq."20151022")then
      centerlat = 15.13      ;Sonde nearest the zero wind center.   
      centerlon = -104.18
      centersonde = 13
   ;   centerlat = 15.17     ;Upper-tropospheric pressure minimum
   ;   centerlon = -104.24
   ;   centersonde = 12
   else if(date.eq."20151023")then
   ;   centerlat = 18.58     ;Upper-tropospheric pressure minimum
   ;   centerlon = -105.20
   ;   centersonde = 13
      centerlat = 18.61      ;Sonde nearest the zero wind center   
      centerlon = -105.22
      centersonde = 14
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
   minxpatricia = -102
   maxxpatricia = 145
   minxjoaquin  = -174
   maxxjoaquin  = 124

   sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"
   listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"+transect
   outdir   = "/jm13/pduran/web/tci/cross_sections/"+storm+"/"
   irbtfile = "/jm13/pduran/onr/ir/tb/ir-Tb-drops-"+storm+"-"+date+"-"+transect

   ;------------------------------------;
   ;Loop through all files for this date;
   ;------------------------------------;
   infiles := sondedir+systemfunc("cat "+listfile)
   nfiles  := dimsizes(infiles)
   irtb    := stringtofloat(systemfunc("awk '{print $1}' "+irbtfile))
   p    := new((/nfiles,nlevels/),"float")
   tc   := new((/nfiles,nlevels/),"float")
   td   := new((/nfiles,nlevels/),"float")
   u    := new((/nfiles,nlevels/),"float")
   v    := new((/nfiles,nlevels/),"float")
   hght := new((/nfiles,nlevels/),"float")
   rh   := new((/nfiles,nlevels/),"float")
   lat  := new((/nfiles,nlevels/),"float")
   lon  := new((/nfiles,nlevels/),"float")
   droplats := new(nfiles,"float")
   droplons := new(nfiles,"float")

   do j=0,nfiles-1
      data := readAsciiTable(infiles(j),10,"float",7)
      data@_FillValue = -9999.0
      nhghts = dimsizes(data(:,5))
      p   (j,:nhghts-1) = data(:,0)
      tc  (j,:nhghts-1) = data(:,1)
      td  (j,:nhghts-1) = data(:,2)
      u   (j,:nhghts-1) = data(:,3)
      v   (j,:nhghts-1) = data(:,4)
      hght(j,:nhghts-1) = data(:,5)
      rh  (j,:nhghts-1) = data(:,6)
      lat (j,:nhghts-1) = data(:,7)
      lon (j,:nhghts-1) = data(:,8)

      ;Get drop latitude and longitude from header
      droplats(j) = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $3}'"))
      nfields = stringtoint(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print NF}'"))
      if(nfields.eq.9)then
         droplons(j) = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $5}' | sed 's/=//'"))
      else
         droplons(j) = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $6}'"))
      end if
   end do

   dropdistances = fspan(minx,maxx,nradii)

   ;Interpolate all of the variables to a fixed radial grid
   print("Interpolating to the fixed grid...")
   vars = interpolate(nlevels,nradii,dropdistances,minhght,maxhght,centerlat,centerlon,centersonde,p,tc,td,u,v,hght,rh,lat,lon,droplats,droplons,driftopt)   
   pres          := vars[0]
   tempc         := vars[1]
   dwpc          := vars[2]
   zonal_v       := vars[3]
   merid_v       := vars[4]
   rh            := vars[5]
   lats          := vars[6]
   lons          := vars[7]
   droplocs      := vars[8]
   missingpts_p  := vars[9]
   missingpts_tc := vars[10]
   missingpts_ir := vars[11]
   missingpts_u  := vars[12]
   missingpts_v  := vars[13]
   missingpts_rh := vars[14]
   missingpts_lat:= vars[15]
   missingpts_lon:= vars[16]
   dropxcoords   := vars[17]

   dropdist(i,:nfiles-1) = dropxcoords

   ;Compute theta and thetae
   hght_fixedgrid = fspan(0,maxhght,nlevels)/1000.
   theta := (tempc+273.15)*(1000/pres)^0.286
   es := 6.11*10^((7.5*tempc)/(237.3+tempc))   ;Saturation vapor pressure
   ws := 621.97*(es/(pres-es))              ;Saturation mixing raitio  (g/kg) 
   if(assumerh.eq.0)then
      w := rh*ws/100/1000  ;Water vapor mixing ratio (kg/kg)
   else
      w := rhconst*ws/100/1000
   end if
   tk := tempc+273.15
print(tempc(199,:))
   do j=0,nradii-1
      ;Tropopause quantities   dimensioned [nfiles x nradii]
      if(.not.all(ismissing(tempc(j,:))))then
         cp_temp (i,j) = min(tempc(j,:))
         cp_pres (i,j) = pres(j,minind(tempc(j,:)))
         if(cp_pres(i,j).gt.150)then
            cp_pres(i,j) = cp_pres@_FillValue
         end if
         cp_theta(i,j) = theta(j,minind(tempc(j,:)))
      end if
;      irbt    (i,j) = irtb(j,:)
   end do 
print(cp_temp(2,:))
   ;---------------------------------;
   ;Set unrealistic values to missing;
   ;---------------------------------;
   cp_temp = where(cp_temp.gt.-60,cp_temp@_FillValue,cp_temp)
   cp_pres = where(cp_temp.gt.-60,cp_pres@_FillValue,cp_pres)
   cp_theta= where(cp_temp.gt.-60,cp_theta@_FillValue,cp_theta)

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
   xyres@tiXAxisString = "Distance from storm center (km)"
end if
end if
xyres@tiYAxisOffsetXF = 0.01
xyres@gsnStringFontHeightF = 0.018
xyres@gsnLeftString = "a)"
xyres@tiYAxisFontHeightF = 0.017
xyres@tiYAxisString = "Cold Point Temperature (C)"
xyres@tiMainFontHeightF = 0.02
xyres@tiXAxisFontHeightF = 0.02
xyres@tiYAxisFontHeightF = 0.02
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
xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
xyres_noint@xyDashPattern = 0
plres = True
plres@gsLineColor = "orange"
plres@gsLineThicknessF = 10
btres = True
btres@gsLineColor = "blue"
btres@gsLineDashPattern = 15
btres@gsLineThicknessF = 10
cp_temp_plot_int = gsn_csm_xy(temp_wks,dropdistances,cp_temp_interp(0,:),xyres)
;dum1 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdistances,irbt(0,:),btres)
dum2 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdistances,cp_temp_interp(1,:),plres)
btres@gsLineColor = "orange"
;dum3 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdistances,irbt(1,:),btres)
plres@gsLineColor = "red"
dum4 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdistances,cp_temp_interp(2,:),plres)
btres@gsLineColor = "red"
;dum5 = gsn_add_polyline(temp_wks,cp_temp_plot_int,dropdistances,irbt(2,:),btres)

;COLD POINT POTENTIAL TEMPERATURE VS. R
theta_wks = gsn_open_wks("png",outdir+"cold_point_theta"+out_suffix)
xythetares = xyres
xythetares@gsnLeftString = "c)"
xythetares@tiYAxisString = "Cold Point Potential Temperature (K)"
xythetares@trYMinF = 340
xythetares@trYMaxF = 420
xyres_noint = xythetares   ;Non-interpolated field will be plotted with solid line
xyres_noint@xyDashPattern = 0
cp_theta_plot_int = gsn_csm_xy(theta_wks,dropdistances,cp_theta_interp(0,:),xythetares)
plres@gsLineColor = "orange"
dum6 = gsn_add_polyline(theta_wks,cp_theta_plot_int,dropdistances,cp_theta_interp(1,:),plres)
plres@gsLineColor = "red"
dum7 = gsn_add_polyline(theta_wks,cp_theta_plot_int,dropdistances,cp_theta_interp(2,:),plres)

;PRESSURE AT THE COLD POINT
pres_wks = gsn_open_wks("png",outdir+"cold_point_pres"+out_suffix)
xypres = True
xypres@gsnStringFontHeightF = 0.018
xypres@gsnLeftString = "b)"
xypres@tiYAxisFontHeightF = 0.017
xypres@tiXAxisFontHeightF = 0.017
xypres@tiYAxisOffsetXF = 0.01

xypres@gsnMaximize = True
xypres@gsnDraw = False
xypres@gsnFrame = False
if(type.eq.0)then
   xypres@tiXAxisString = "Distance along flight track (km)"
else if(type.eq.1)then
   xypres@tiXAxisString = "Distance from storm center (km)"
end if
end if
xypres@tiMainFontHeightF = 0.02
xypres@tiXAxisFontHeightF = 0.02
xypres@tiYAxisFontHeightF = 0.02
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
cp_pres_plot_int = gsn_csm_xy(pres_wks,dropdistances,cp_pres_interp(0,:),xypres)
plres@gsLineColor = "orange"
dum8 = gsn_add_polyline(pres_wks,cp_pres_plot_int,dropdistances,cp_pres_interp(1,:),plres)
plres@gsLineColor = "red"
dum9 = gsn_add_polyline(pres_wks,cp_pres_plot_int,dropdistances,cp_pres_interp(2,:),plres)

;IR BRIGHTNESS TEMPERATURE MINUS COLD POINT TEMPERATURE
;diffres = xyres
;diffres@gsnLeftString = "c)"
;diffres@tiYAxisString = "IR Brightness Temperature minus Cold Point Temperature (C)"
;diffres@tiYAxisFontHeightF = 0.015
;diffwks = gsn_open_wks("png",outdir+"irtb_minus_cpt"+out_suffix)
;diffres@trYMinF = -8
;diffres@trYMaxF = 34
;diff_plot = gsn_csm_xy(diffwks,dropdistances,diff(0,:),diffres)
;plres@gsLineColor = "orange"
;dum100 = gsn_add_polyline(diffwks,diff_plot,dropdistances,diff(1,:),plres)
;plres@gsLineColor = "red"
;dum110 = gsn_add_polyline(diffwks,diff_plot,dropdistances,diff(2,:),plres)

;Add vertical lines at x=0
zerolineres = True
zerolineres@gsLineDashPattern = 1
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
frame(temp_wks)
frame(theta_wks)
frame(pres_wks)
;frame(diffwks)
