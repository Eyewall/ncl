load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; cross_section.ncl                                    
; Patrick Duran                                           
; 16 January 2016
; Pulls data from .edit files and plots vertical cross-sections
; of the observations along a flight leg, centered on a given point.
;
; 1/16/16: Code currently uses drop lat and lon to compute distance
;          from storm center at all levels (i.e. does not account
;          for sonde drift). Also, sondes that were dropped before
;          the aircraft passed the eye are manually set negative,
;          so be sure to change that for each flight leg.
;----------------------------------------------------------------;

maxhght   = 20000  ;Maximum height to pull (m)
dz        = 100
nlevels   = maxhght/dz+1
sondedir  = "/nfs/jm13/pduran/dropsondes/onr/edit/20151023/"
listfile  = "/nfs/jm13/pduran/dropsondes/onr/edit/20151023/transect1"
prefix    = "A"
suffix    = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
centerlat = 18.59    ;These latitudes and longitudes were obtained by OUR center
centerlon = -105.21  ;drops, NOT TCVitals
outfile   = "/jm13/pduran/web/tci/cross_sections/patricia_20151023/transect1/"
interp    = 1   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate

;infiles = systemfunc("ls "+sondedir+prefix+"*"+suffix)
infiles = sondedir+systemfunc("cat "+listfile)
nfiles  = dimsizes(infiles)

z        = new((/nfiles,nlevels/),"float")
theta    = new((/nfiles,nlevels/),"float")
thetae   = new((/nfiles,nlevels/),"float")
tempc    = new((/nfiles,nlevels/),"float")
merid_v  = new((/nfiles,nlevels/),"float")
lats     = new((/nfiles,nlevels/),"float")
lons     = new((/nfiles,nlevels/),"float")
plotdata = new((/nlevels,nfiles/),"float")
cp_temp  = new(nfiles,"float")
cp_hght  = new(nfiles,"float")
cp_theta = new(nfiles,"float")
droplat  = new(nfiles,"float")
droplon  = new(nfiles,"float")
trop_z   = new(nfiles,"float")
z@_FillValue        = -9999.0
theta@_FillValue    = -9999.0
thetae@_FillValue   = -9999.0
plotdata@_FillValue = -9999.0
cp_temp@_FillValue  = -9999.0
cp_hght@_FillValue  = -9999.0
cp_theta@_FillValue = -9999.0
trop_z@_FillValue   = -9999.0

do i=0,nfiles-1
   unixi = i+1
   print("Processing sonde "+unixi+" of "+nfiles)
   ;Read input file and assign variables
   data = readAsciiTable(infiles(i),10,"float",7)
   data@_FillValue = -9999.0
   p    = data(:,0)
   tc   = data(:,1)
   td   = data(:,2)
   u    = data(:,3)
   v    = data(:,4)
   hght = data(:,5)
   rh   = data(:,6)
   lat  = data(:,7)
   lon  = data(:,8)

   ;Get drop latitude and longitude from header
   droplat(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $3}'"))
   nfields = stringtoint(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print NF}'"))
   if(nfields.eq.9)then
      droplon(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $5}' | sed 's/=//'"))
   else
      droplon(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $6}'"))
   end if

   ;Compute some moisture variables
   es = 6.11*10^((7.5*tc)/(237.3+tc))	;Saturation vapor pressure
   ws = 621.97*(es/(p-es))		;Saturation mixing ratio  (g/kg) 
   w  = rh*ws/100/1000			;Water vapor mixing ratio (kg/kg)
   tk = tc+273.15			;Temperature in Kelvin
   tropopt = True
   tropopt@lapsec=1.0
   trop_p = trop_wmo(p(::-1),tk(::-1),0,tropopt)	;Pressure at the WMO tropopause
   trop_p@_FillValue = -999

   ;Set or compute all of the variables
   nhghts = dimsizes(hght)
   z       (i,0:nhghts-1) = hght
   theta   (i,0:nhghts-1) = (tc+273.15)*(1000/p)^0.286
   thetae  (i,0:nhghts-1) = theta(i,0:nhghts-1)+(2510400/1004)*w
   tempc   (i,0:nhghts-1) = tc
   merid_v (i,0:nhghts-1) = v
   cp_temp (i) = min(tc)
   cp_hght (i) = hght(minind(tc))/1000
   cp_theta(i) = (cp_temp(i)+273.15)*(1000/p(minind(tc)))^0.286

   ;Get the tropopause height from tropopause pressure by linear interpolation
   if(min(p).lt.200.and..not.ismissing(trop_p))then
      diffs = abs(p-trop_p)
      diffs_sort = diffs(ind(.not.ismissing(diffs)))
      qsort(diffs_sort)
      p1 = p(ind(diffs.eq.diffs_sort(0)))
      p2 = trop_p
      p3 = p(ind(diffs.eq.diffs_sort(1)))
      z1 = hght(ind(diffs.eq.diffs_sort(0)))
      z3 = hght(ind(diffs.eq.diffs_sort(1)))
      z2 = (p2-p1)*(z3-z1)/(p3-p1)+z1
      trop_z(i) = z2/1000
      delete([/diffs,diffs_sort/])
   else
      trop_z(i) = trop_z@_FillValue
   end if

   ;Assign latitudes and longitudes
   lats(i,0:nhghts-1) = lat
   lons(i,0:nhghts-1) = lon

   ;Clean up
   delete([/data,p,tc,td,u,v,hght,rh,lat,lon,es,ws,w,tk/])
end do

;Set thresholds for cold point temperature and height to eliminate
;sondes that don't have data in upper levels
cp_temp = where(cp_temp.gt.-50,cp_temp@_FillValue,cp_temp)
cp_hght = where(cp_temp.gt.-50,cp_hght@_FillValue,cp_hght)
cp_theta= where(cp_temp.gt.-50,cp_theta@_FillValue,cp_theta)

;Compute distances from TC center
;gc_latlon doesn't check for missing values, so we'll just perform a
;quick fix by setting all distances greater than 2000 km to missing
dist = gc_latlon(centerlat,centerlon,lats,lons,2,4)
dropdist = gc_latlon(centerlat,centerlon,droplat,droplon,2,4)
dist@_FillValue = -9999.
dropdist@_FillValue = -9999.
dist = where(dist.gt.2000,dist@_FillValue,dist)
dropdist = where(dropdist.gt.2000,dropdist@_FillValue,dropdist)
dropdist(0:12) = dropdist(0:12)*-1.

;-------------------------------------------------------;
;Create arrays for plotting and set coordinate variables;
;-------------------------------------------------------;
;EQUIVALENT POTENTIAL TEMPERATURE
plotthetae = transpose(thetae)
plotthetae!0 = "height"
plotthetae!1 = "radius"
plotthetae&height = fspan(0,maxhght,nlevels)/1000.
plotthetae&radius = dropdist

;POTENTIAL TEMPERATURE
plottheta = transpose(theta)
copy_VarMeta(plotthetae,plottheta)

;TEMPERATURE
plottempc = transpose(tempc)
copy_VarMeta(plotthetae,plottempc)

;WIND SPEED
plotmerid_v = transpose(merid_v)
copy_VarMeta(plotthetae,plotmerid_v)

;COLD POINT TEMPERATURE, POTENTIAL TEMPERATURE AND HEIGHT
;plotcp_temp = transpose(cp_temp)
;copy_VarMeta(plotthetae,plotcp_temp)
;plotcp_hght = transpose(cp_hght)
;copy_VarMeta(plotthetae,plotcp_hght)
;plotcp_theta = transpose(cp_theta)
;copy_VarMeta(plotthetae,plotcp_theta)

;------------------------------------------------------------------;
;Interpolate across missing values in radius, if option is selected;
;------------------------------------------------------------------;
if(interp.eq.1)then
   plotthetae  = linmsg(plotthetae,0)
   plottheta   = linmsg(plottheta,0)
   plottempc   = linmsg(plottempc,0)
   plotmerid_v = linmsg(plotmerid_v,0)
   trop_z      = linmsg(trop_z,0)
   cp_temp = linmsg(cp_temp,0)
   cp_hght = linmsg(cp_hght,0)
   cp_theta= linmsg(cp_theta,0)
   out_suffix  = "_interp"
else
   out_suffix = "_nointerp"
end if

;--------------;
;Draw the plots;
;--------------;
;EQUIVALENT POTENTIAL TEMPERATURE
wks = gsn_open_wks("png",outfile+"_thetae"+out_suffix)
gsn_define_colormap(wks,"WhiteGreen")
res = True
res@tiMainString = "Equivalent Potential Temperature (K)"
res@tiYAxisString = "Height (km)"
res@tiXAxisString = "Distance from storm center (km)"
res@tiMainFontHeightF = 0.02
res@tiXAxisFontHeightF = 0.02
res@tiYAxisFontHeightF = 0.02
res@trYMinF = 0.
res@trYMaxF = 18.
res@cnLevelSpacingF = 5.0
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = 300
res@cnMaxLevelValF = 370
res@cnFillOn = True
res@cnLinesOn = False
res@lbOrientation = "Vertical"
res@tmYROn = False
res@tmXTOn = False
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False
thetae_img = gsn_csm_contour(wks,plotthetae,res)
   ;Overlay lines that represent drop locations
   liney = new((/dimsizes(dropdist),2/),"float")
   linex = liney
   locs  = new(dimsizes(dropdist),"graphic")
   do i=0,dimsizes(locs)-1
      linex(i,:) = dropdist(i)
      liney(i,0) = res@trYMinF
      liney(i,1) = res@trYMaxF
      lineres = False
      locs(i) = gsn_add_polyline(wks,thetae_img,linex(i,:),liney(i,:),lineres)
   end do
draw(thetae_img)
frame(wks)

;POTENTIAL TEMPERATURE
wks = gsn_open_wks("png",outfile+"_theta"+out_suffix)
res@tiMainString = "Potential Temperature (K)"
res@cnLinesOn = True
res@cnLevelSpacingF = 2.0
res@cnMaxLevelValF = 410
theta_img = gsn_csm_contour(wks,plottheta,res)
tropres = True
tropres@gsLineColor = "darkgreen"
tropres@gsLineThicknessF = 8.
trophghts = gsn_add_polyline(wks,theta_img,dropdist,trop_z,tropres)
draw(theta_img)
frame(wks)

;TEMPERATURE WITH TROPOPAUSE HEIGHT OVERLAY
wks = gsn_open_wks("png",outfile+"_temperature"+out_suffix)
res@tiMainString = "Temperature (C)"
res@cnMaxLevelValF = 30
res@cnMinLevelValF = -80
res@cnLevelSpacingF = 2
tempc_img = gsn_csm_contour(wks,plottempc,res)
tropres = True
tropres@gsLineColor = "yellow"
tropres@gsLineThicknessF = 8.
trophghts = gsn_add_polyline(wks,tempc_img,dropdist,trop_z,tropres)
draw(tempc_img)
frame(wks)

;MERIDIONAL VELOCITY
wks = gsn_open_wks("png",outfile+"_v"+out_suffix)
gsn_define_colormap(wks,"BlWhRe")
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = -60
res@cnMaxLevelValF = 60
res@tiMainString = "Meridional velocity (m/s)"
merid_v_img = gsn_csm_contour(wks,plotmerid_v,res)
draw(merid_v_img)
frame(wks)

;COLD POINT TEMPERATURE VS. R
wks = gsn_open_wks("png",outfile+"cold_point_temp"+out_suffix)
xyres = True
xyres@gsnMaximize = True
xyres@tiMainString = "Cold Point Temperature"
xyres@tiXAxisString = "Distance from storm center (km)"
xyres@tiYAxisString = "Temperature (C)"
xyres@tiMainFontHeightF = 0.02
xyres@tiXAxisFontHeightF = 0.02
xyres@tiYAxisFontHeightF = 0.02
xyres@trYMinF = -85.
xyres@trYMaxF = -65.
xyres@xyLineColor = "red"
xyres@xyLineThicknessF = 8
xyres@tmXTOn = False
xyres@tmYROn = False
cp_temp_plot = gsn_csm_xy(wks,dropdist,cp_temp,xyres)

;COLD POINT POTENTIAL TEMPERATURE VS. R
wks = gsn_open_wks("png",outfile+"cold_point_theta"+out_suffix)
xyres@tiMainString = "Cold Point Potential Temperature"
xyres@tiYAxisString = "Potential Temperature (K)"
xyres@trYMinF = 350.
xyres@trYMaxF = 450.
cp_theta_plot = gsn_csm_xy(wks,dropdist,cp_theta,xyres)

;COLD POINT HEIGHT VS. R
wks = gsn_open_wks("png",outfile+"cold_point_height"+out_suffix)
xyres@tiMainString = "Cold Point Height"
xyres@tiYAxisString = "Height (km)"
xyres@trYMinF = 15.
xyres@trYMaxF = 18.5
xyres@xyLineColor = "orange"
cp_hght_plot = gsn_csm_xy(wks,dropdist,cp_hght,xyres)
