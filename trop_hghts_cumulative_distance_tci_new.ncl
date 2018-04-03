load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; trop_hghts.ncl                                    
; Patrick Duran                                           
; 21 January 2016
; Pulls data from .edit files and plots vertical cross-sections
; of various tropopause quantities 
;
; 1/16/16: Code currently uses drop lat and lon to compute distance
;          from flight center at all levels (i.e. does not account
;          for sonde drift). Also, sondes that were dropped before
;          the aircraft passed the eye are manually set negative,
;          so be sure to change that for each flight leg.
;----------------------------------------------------------------;

storm    = "joaquin"
date     = "20151002"
transect = "transect1"
minhght  = 9000   ;Minimum height to pull (m)
maxhght  = 18000  ;Maximum height to pull (m)
dz       = 100
nlevels  = (maxhght-minhght)/dz+1
sondedir = "/nfs/jm13/pduran/dropsondes/onr/edit/"+storm+"/"+date+"/"
listfile = "/nfs/jm13/pduran/dropsondes/onr/edit/"+storm+"/"+date+"/"+transect
prefix   = "A"
suffix   = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
outdir  = "/jm13/pduran/web/tci/cross_sections/"+storm+"/"+date+"/"+transect+"/"
interp   = 1   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate

system("mkdir "+outdir)

;infiles = systemfunc("ls "+sondedir+prefix+"*"+suffix)
infiles = sondedir+systemfunc("cat "+listfile)
nfiles  = dimsizes(infiles)

z        = new((/nfiles,nlevels/),"float")
w        = new((/nfiles,nlevels/),"float")
theta    = new((/nfiles,nlevels/),"float")
thetae   = new((/nfiles,nlevels/),"float")
thetav   = new((/nfiles,nlevels/),"float")
n2       = new((/nfiles,nlevels/),"float")
tempc    = new((/nfiles,nlevels/),"float")
merid_v  = new((/nfiles,nlevels/),"float")
lats     = new((/nfiles,nlevels/),"float")
lons     = new((/nfiles,nlevels/),"float")
plotdata = new((/nlevels,nfiles/),"float")
dropdist = new(nfiles,"float")
cp_temp  = new(nfiles,"float")
cp_pres  = new(nfiles,"float")
pres_at_17 = new(nfiles,"float")
cp_hght  = new(nfiles,"float")
cp_theta = new(nfiles,"float")
droplat  = new(nfiles,"float")
droplon  = new(nfiles,"float")
trop_z   = new(nfiles,"float")
z@_FillValue        = -9999.0
theta@_FillValue    = -9999.0
thetae@_FillValue   = -9999.0
thetav@_FillValue   = -9999.0
plotdata@_FillValue = -9999.0
cp_temp@_FillValue  = -9999.0
cp_pres@_FillValue  = -9999.0
pres_at_17@_FillValue = -9999.0
cp_hght@_FillValue  = -9999.0
cp_theta@_FillValue = -9999.0
trop_z@_FillValue   = -9999.0
n2@_FillValue       = -9999.0
droplat@_FillValue  = -9999.0
droplon@_FillValue  = -9999.0

dropdist = 0.
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

   ;Compute maximum sonde drift for this sonde (ignore any drifts > 1000 km because the gc_latlon
   ;function does not search for missing values....for some stupid reason (did I say that out loud?)
   subsetmin = min((/ind(hght.eq.minhght),minind(hght)/))
   subsetmax = min((/ind(hght.eq.maxhght),maxind(hght)/))
   drifts  := (gc_latlon(lat(subsetmax),lon(subsetmax),lat(subsetmin:subsetmax),lon(subsetmin:subsetmax),2,-4))
   maxdrift = max(drifts(ind(drifts.lt.1000)))
   print("Maximum drift for sonde "+unixi+": "+maxdrift)

   nhghts = tointeger(min((/dimsizes(hght),maxhght/1000./)))
   ;Compute some moisture variables
   es = 6.11*10^((7.5*tc(0:nhghts-1))/(237.3+tc(0:nhghts-1)))	;Saturation vapor pressure
   ws = 621.97*(es/(p(0:nhghts-1)-es))		;Saturation mixing ratio  (g/kg) 
   w(i,0:nhghts-1) = rh(0:nhghts-1)*ws/100/1000	;Water vapor mixing ratio (kg/kg)
   tk = tc(0:nhghts-1)+273.15			;Temperature in Kelvin
;   tropopt = True
;   tropopt@lapsec=1.0
;   trop_p = trop_wmo(p(::-1),tk(::-1),0,tropopt)	;Pressure at the WMO tropopause
;   trop_p@_FillValue = -999

   ;Set or compute all of the variables
   z       (i,0:nhghts-1) = hght(0:nhghts-1)
   theta   (i,0:nhghts-1) = (tc(0:nhghts-1)+273.15)*(1000/p(0:nhghts-1))^0.286
   thetae  (i,0:nhghts-1) = theta(i,0:nhghts-1)+(2510400/1004)*w(i,0:nhghts-1)
   tempc   (i,0:nhghts-1) = tc(0:nhghts-1)
   merid_v (i,0:nhghts-1) = v(0:nhghts-1)
   cp_temp (i) = min(tc)
   cp_pres (i) = p(minind(tc))
   if(max(hght).ge.17000)then
      pres_at_17(i) = p(ind(hght.eq.17000))
   end if
   cp_hght (i) = hght(minind(tc))/1000
   cp_theta(i) = (cp_temp(i)+273.15)*(1000/p(minind(tc)))^0.286

   ;Static stability (Brunt-Vaisala frequency squared)
   g = 9.80665
;   thetav(i,:)    = theta(i,:)*(1+0.61*w(i,:))
   dthetadz = center_finite_diff(theta(i,:),100,False,0)
   n2(i,:) = g/theta(i,:)*dthetadz

   ;Get the tropopause height from tropopause pressure by linear interpolation
   if(min(p).lt.200.and..not.ismissing(cp_pres(i)))then
      diffs = abs(p-cp_pres(i))
      diffs_sort = diffs(ind(.not.ismissing(diffs)))
      qsort(diffs_sort)
      p1 = p(ind(diffs.eq.diffs_sort(0)))
      p2 = cp_pres(i)
      p3 = min(p(ind(diffs.eq.diffs_sort(1))))
      z1 = min(hght(ind(diffs.eq.diffs_sort(0))))
      z3 = min(hght(ind(diffs.eq.diffs_sort(1))))
      z2 = (p2-p1)*(z3-z1)/(p3-p1)+z1
      trop_z(i) = z2/1000
      delete([/diffs,diffs_sort/])
   else
      trop_z(i) = trop_z@_FillValue
   end if

   ;Assign latitudes and longitudes
   lats(i,0:nhghts-1) = lat(0:nhghts-1)
   lons(i,0:nhghts-1) = lon(0:nhghts-1)

   ;Compute cumulative distance from the first sonde drop
   if(i.gt.0)then
      dropdist(i) = dropdist(i-1) + gc_latlon(droplat(i-1),droplon(i-1),droplat(i),droplon(i),2,4)
   end if

   ;Clean up
   delete([/data,p,tc,td,u,v,hght,rh,lat,lon,es,ws,tk/])
end do

;Set thresholds for cold point temperature and height to eliminate
;sondes that don't have data in upper levels
cp_hght = where(cp_temp.gt.-60,cp_hght@_FillValue,cp_hght)
cp_pres = where(cp_temp.gt.-60,cp_pres@_FillValue,cp_pres)
pres_at_17 = where(cp_temp.gt.-60,pres_at_17@_FillValue,pres_at_17)
cp_theta= where(cp_temp.gt.-60,cp_theta@_FillValue,cp_theta)
cp_temp = where(cp_temp.gt.-60,cp_temp@_FillValue,cp_temp)

;Compute distance from storm center
;gc_latlon doesn't check for missing values, so we'll just perform a
;quick fix by setting all distances greater than 2000 km to missing
;dist = dist + gc_latlon(centerlat,centerlon,lats,lons,2,4)
;dropdist = gc_latlon(centerlat,centerlon,droplat,droplon,2,4)
;dist@_FillValue = -9999.
;dropdist@_FillValue = -9999.
;dist = where(dist.gt.2000,dist@_FillValue,dist)
;dropdist = where(dropdist.gt.2000,dropdist@_FillValue,dropdist)
;dropdist(0:12) = dropdist(0:12)*-1.

;-------------------------------------------------------;
;Create arrays for plotting and set coordinate variables;
;-------------------------------------------------------;
;EQUIVALENT POTENTIAL TEMPERATURE
plotthetae = transpose(thetae)
plotthetae!0 = "height"
plotthetae!1 = "radius"
plotthetae&height = fspan(minhght,maxhght,nlevels)/1000.
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

;STATIC STABILITY
plotn2 = transpose(n2)*10000  ;Convert to more readable units (10^-4 s^-2)
copy_VarMeta(plotthetae,plotn2)

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
   plotn2      = linmsg(plotn2,0)
   trop_z      = linmsg(trop_z,0)
   cp_temp = linmsg(cp_temp,0)
   cp_pres = linmsg(cp_pres,0)
   pres_at_17 = linmsg(pres_at_17,0)
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
wks = gsn_open_wks("png",outdir+"thetae"+out_suffix)
gsn_define_colormap(wks,"WhiteGreen")
res = True
res@tiMainString = "Equivalent Potential Temperature (K)   "+storm+"  "+date+"  "+transect
res@tiYAxisString = "Height (km)"
res@tiXAxisString = "Distance along flight track (km)"
res@tiMainFontHeightF = 0.02
res@tiXAxisFontHeightF = 0.02
res@tiYAxisFontHeightF = 0.02
res@trYMinF = minhght/1000.
res@trYMaxF = maxhght/1000.
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
;res@gsnXAxisIrregular2Linear = True
thetae_img = gsn_csm_contour(wks,plotthetae,res)

;Overlay lines that represent drop locations
;liney = new((/dimsizes(dropdist),2/),"float")
;linex = liney
;locs  = new(dimsizes(dropdist),"graphic")
;do i=0,dimsizes(locs)-1
;   linex(i,:) = dropdist(i)
;   liney(i,0) = res@trYMinF
;   liney(i,1) = res@trYMaxF
;   lineres = False
;   locs(i) = gsn_add_polyline(wks,thetae_img,linex(i,:),liney(i,:),lineres)
;end do
draw(thetae_img)
frame(wks)

;POTENTIAL TEMPERATURE
wks = gsn_open_wks("png",outdir+"theta"+out_suffix)
res@tiMainString = "Potential Temperature (K)   "+storm+"  "+date+"  "+transect
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
wks = gsn_open_wks("png",outdir+"temperature"+out_suffix)
res@tiMainString = "Temperature (C)   "+storm+"  "+date+"  "+transect
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
wks = gsn_open_wks("png",outdir+"v"+out_suffix)
gsn_define_colormap(wks,"BlWhRe")
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = -60
res@cnMaxLevelValF = 60
res@tiMainString = "Meridional velocity (m/s)   "+storm+"  "+date+"  "+transect
merid_v_img = gsn_csm_contour(wks,plotmerid_v,res)
draw(merid_v_img)
frame(wks)

;STATIC STABILITY
wks = gsn_open_wks("png",outdir+"staticstability"+out_suffix)
gsn_define_colormap(wks,"WhiteGreen")
delete([/res@cnMinLevelValF,res@cnMaxLevelValF,res@cnLevelSpacingF/])
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = 0
res@cnMaxLevelValF = 10
res@cnLevelSpacingF = 0.5
res@trYMinF = 9
res@trYMaxF = 18
res@cnLinesOn = False
res@tiMainString = "Brunt-Vaisala Frequency Squared (10~S~-4~N~ s~S~-2~N~)"
stab_img = gsn_csm_contour(wks,plotn2,res)
;Overlay lines that represent drop locations
liney  = new((/dimsizes(dropdist),2/),"float")
linex  = liney
labelx = new(floattoint(ceil(dimsizes(dropdist)/2.)),"float")
labely = labelx
labely = res@trYMinF+0.25
locs   = new(dimsizes(dropdist),"graphic")
j=0
do i=0,dimsizes(locs)-1
   if(i.eq.0.or.mod(i,2).eq.0)then   ;We will only make labels for every other sonde loc
      labelx(j) = dropdist(i)
      j=j+1
   end if
   linex(i,:) = dropdist(i)
   liney(i,0) = res@trYMinF
   liney(i,1) = res@trYMaxF
   lineres = True
   lineres@gsLineColor = "red"
;   lineres@gsLineThicknessF = 3
   locs(i) = gsn_add_polyline(wks,stab_img,linex(i,:),liney(i,:),lineres)
end do

;Overlay digits that represent drop locations
text = tostring(ispan(1,nfiles,2))   ;Only make a label for every other sonde location
txres = True
txres@txFont = 30
txres@txFontHeightF = 0.01
txres@txFontColor = "black"
dum = gsn_add_text(wks,stab_img,text,labelx,labely,txres)
draw(stab_img)
frame(wks)

;COLD POINT TEMPERATURE VS. R
wks = gsn_open_wks("png",outdir+"cold_point_temp"+out_suffix)
xyres = True
xyres@gsnMaximize = True
xyres@tiMainString = "Cold Point Temperature   "+storm+"  "+date+"  "+transect
xyres@tiXAxisString = "Distance along flight track (km)"
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
xyres@tmYMajorGrid = True
xyres@tmYMajorGridLineColor = "gray"
xyres@tmYMajorGridLineDashPattern = 1
xyres@tmXMajorGrid = True
xyres@tmXMajorGridLineColor = xyres@tmYMajorGridLineColor
xyres@tmXMajorGridLineDashPattern = xyres@tmYMajorGridLineDashPattern
cp_temp_plot = gsn_csm_xy(wks,dropdist,cp_temp,xyres)

;COLD POINT POTENTIAL TEMPERATURE VS. R
wks = gsn_open_wks("png",outdir+"cold_point_theta"+out_suffix)
xyres@tiMainString = "Cold Point Potential Temperature   "+storm+"  "+date+"  "+transect
xyres@tiYAxisString = "Potential Temperature (K)"
xyres@trYMinF = 350.
xyres@trYMaxF = 450.
cp_theta_plot = gsn_csm_xy(wks,dropdist,cp_theta,xyres)

;COLD POINT HEIGHT VS. R
wks = gsn_open_wks("png",outdir+"cold_point_height"+out_suffix)
xyres@tiMainString = "Cold Point Height   "+storm+"  "+date+"  "+transect
xyres@tiYAxisString = "Height (km)"
xyres@trYMinF = 13.
xyres@trYMaxF = 18.5
xyres@xyLineColor = "orange"
cp_hght_plot = gsn_csm_xy(wks,dropdist,cp_hght,xyres)

;PRESSURE AT THE COLD POINT
wks = gsn_open_wks("png",outdir+"cold_point_pres"+out_suffix)
xyres@tiMainString = "Pressure at the cold point   "+storm+"  "+date+"  "+transect
xyres@tiYAxisString = "Pressure (mb)"
xyres@trYMinF = 50.
xyres@trYMaxF = 150.
xyres@trYReverse = True
xyres@xyYStyle = "Log"
xyres@xyLineColor = "blue"
xyres@tmYLMode = "Explicit"
xyres@tmYLValues = (/50,60,70,80,90,100,110,120,130,140,150/)
xyres@tmYLLabels = tostring(xyres@tmYLValues)
cp_pres_plot = gsn_csm_xy(wks,dropdist,cp_pres,xyres)

;PRESSURE AT 17 KM
wks = gsn_open_wks("png",outdir+"17km_pres"+out_suffix)
xyres@tiMainString = "Pressure at 17km altitude   "+storm+"  "+date+"  "+transect
pres_at_17_plot = gsn_csm_xy(wks,dropdist,pres_at_17,xyres)
