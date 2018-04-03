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
;          for sonde drift.
;----------------------------------------------------------------;

storm    = "patricia"
date     = "20151023"
transect = "transect1"
maxhght  = 20000  ;Maximum height to pull (m)
dz       = 100
nlevels  = maxhght/dz+1
sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"
listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"+transect
prefix   = "A"
suffix   = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
outdir   = "/jm13/pduran/web/tci/cross_sections/"+storm+"/"+date+"/"+transect+"/"
interp   = 1   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate
type      = 1   ;Plot as total distance from start of flight let (0) or
                ;distance from storm center (1)?
cloudtempdir  = "/jm13/pduran/onr/ir/tb/"
cloudtempfile = cloudtempdir+"ir-Tb-drops-"+storm+"-"+date+"-"+transect

if(date.eq."20151021")then
   centerlat = 13.42    ;Determined by looking at meridional velocity from dropsondes
   centerlon = -99.38   ;Note that this lat/lon is not actually at a drop location
   centersonde = 5      ;The line number in the listfile where the center sonde is
else if(date.eq."20151022")then
   centerlat = 15.13    ;Determined by meridional velocity
   centerlon = -104.18
   centersonde = 13 
else if(date.eq."20151023")then
   centerlat = 18.61	;Determined by IR imagery
   centerlon = -105.22
   centersonde = 14
else if(date.eq."20151002")then
   centerlat = 23.83	;Determined by combination of QC notes and meridional velocity
   centerlon = -74.65
   centersonde = 9
else if(date.eq."20151003")then
   centerlat = 26.18	;Determined by combination of QC notes and meridional velocity
   centerlon = -71.28
   centersonde = 7
else if(date.eq."20151004")then
   centerlat = 31.81	;Determine by IR imagery
   centerlon = -66.48
   centersonde = 10	;Note that I chopped off some sondes from the high-density transect
end if
end if
end if
end if
end if
end if

system("mkdir "+outdir)

;Get IR brightness temperatures for each sonde
irtb = stringtofloat(systemfunc("awk '{print $1}' "+cloudtempfile))

;Get dropsonde data from each sonde
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
cp_theta = new(nfiles,"float")
droplat  = new(nfiles,"float")
droplon  = new(nfiles,"float")
trop_z   = new(nfiles,"float")
ircloudtop = new(nfiles,"float")
z@_FillValue        = -9999.0
theta@_FillValue    = -9999.0
thetae@_FillValue   = -9999.0
thetav@_FillValue   = -9999.0
plotdata@_FillValue = -9999.0
cp_temp@_FillValue  = -9999.0
cp_pres@_FillValue  = -9999.0
pres_at_17@_FillValue = -9999.0
cp_theta@_FillValue = -9999.0
trop_z@_FillValue   = -9999.0
n2@_FillValue       = -9999.0
ircloudtop@_FillValue = -9999.0

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

   nhghts = dimsizes(hght)

   ;Compute some moisture variables
   es = 6.11*10^((7.5*tc)/(237.3+tc))	;Saturation vapor pressure
   ws = 621.97*(es/(p-es))		;Saturation mixing ratio  (g/kg) 
   w(i,0:nhghts-1) = rh*ws/100/1000	;Water vapor mixing ratio (kg/kg)
   tk = tc+273.15			;Temperature in Kelvin
;   tropopt = True
;   tropopt@lapsec=1.0
;   trop_p = trop_wmo(p(::-1),tk(::-1),0,tropopt)	;Pressure at the WMO tropopause
;   trop_p@_FillValue = -999

   ;Set or compute all of the variables
   z       (i,0:nhghts-1) = hght
   theta   (i,0:nhghts-1) = (tc+273.15)*(1000/p)^0.286
   thetae  (i,0:nhghts-1) = theta(i,0:nhghts-1)+(2510400/1004)*w(i,0:nhghts-1)
   tempc   (i,0:nhghts-1) = tc
   merid_v (i,0:nhghts-1) = v
   cp_temp (i) = min(tc)
   cp_pres (i) = p(minind(tc))
   if(cp_pres(i).gt.200)then
      cp_pres(i) = cp_pres@_FillValue
   end if
   if(max(hght).ge.17000)then
      pres_at_17(i) = p(ind(hght.eq.17000))
   end if
   cp_theta(i) = (cp_temp(i)+273.15)*(1000/cp_pres(i))^0.286

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

   ;Get the cloud top heights using IR brightness temperatures
   ;We do this by getting the lowest level at which the difference between
   ;the IR brightness temperature and the sounding temperature is minimized.
   ;We get the minimum by taking the first derivative of the differences
   ;and finding the lowest level at which the derivative goes from negative
   ;to positive above 9 km.
   ircloudtop(i) = hght(minind(abs(tc-irtb(i)))) / 1000.
;   diffs2 := abs(tc - irtb(i))
;   ddiffsdz := center_finite_diff(diffs2,100,False,0)
;   ircloudtop(i) = hght(min(ind(ddiffsdz(90:).gt.0))+90) / 1000.

   ;Assign latitudes and longitudes
   lats(i,0:nhghts-1) = lat
   lons(i,0:nhghts-1) = lon

   ;Compute cumulative distance from the first sonde drop
   if(i.gt.0.and.type.eq.0)then
      dropdist(i) = dropdist(i-1) + gc_latlon(droplat(i-1),droplon(i-1),droplat(i),droplon(i),2,4)
   end if

   ;Clean up
   delete([/data,p,tc,td,u,v,hght,rh,lat,lon,es,ws,tk/])
end do
print(ircloudtop)
;Set thresholds for cold point temperature and height to eliminate
;sondes that don't have data in upper levels
cp_pres    = where(cp_temp.gt.-60,cp_pres@_FillValue,cp_pres)
pres_at_17 = where(cp_temp.gt.-60,pres_at_17@_FillValue,pres_at_17)
cp_theta   = where(cp_temp.gt.-60,cp_theta@_FillValue,cp_theta)
cp_temp    = where(cp_temp.gt.-60,cp_temp@_FillValue,cp_temp)
ircloudtop = where(ircloudtop.lt.12,ircloudtop@_FillValue,ircloudtop)

;Compute distance from storm center
;gc_latlon doesn't check for missing values, so we'll just perform a
;quick fix by setting all distances greater than 2000 km to missing
if(type.eq.1)
;   dist = dist + gc_latlon(centerlat,centerlon,lats,lons,2,4)
   dropdist = gc_latlon(centerlat,centerlon,droplat,droplon,2,4)
;   dist@_FillValue = -9999.
   dropdist@_FillValue = -9999.
;   dist = where(dist.gt.2000,dist@_FillValue,dist)
   dropdist = where(dropdist.gt.2000,dropdist@_FillValue,dropdist)
   dropdist(0:(centersonde-1)) = dropdist(0:(centersonde-1))*-1.
   totaldist = round(dropdist(dimsizes(dropdist)-1) - dropdist(0),0) ;Total distance along transect
end if
;print(dropdist)

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

;STATIC STABILITY
plotn2 = transpose(n2)*10000  ;Convert to more readable units (10^-4 s^-2)
copy_VarMeta(plotthetae,plotn2)

;COLD POINT TEMPERATURE, POTENTIAL TEMPERATURE AND HEIGHT
;plotcp_temp = transpose(cp_temp)
;copy_VarMeta(plotthetae,plotcp_temp)
;plotcp_theta = transpose(cp_theta)
;copy_VarMeta(plotthetae,plotcp_theta)

;------------------------------------------------------------------;
;Interpolate across missing values in radius, if option is selected;
;------------------------------------------------------------------;
if(interp.eq.1)then
   ;These will ultimately be boolean arrays; 0 where no interpolation is
   ;performed and 2 where interpolation is performed
   missingpts_thetae  = plotthetae
   missingpts_theta   = plottheta
   missingpts_tempc   = plottempc
   missingpts_merid_v = plotmerid_v
   missingpts_plotn2  = plotn2
   missingpts_trop_z  = trop_z  ;Don't need to create missing value boolean
                                ;arrays for other tropopause values because
                                ;wherever trop_z is missing, those are, too
   missingpts_ircloudtop = ircloudtop
   ;Perform linear interpolation
   plotthetae        = linmsg(plotthetae,0)
   plottheta         = linmsg(plottheta,0)
   plottempc         = linmsg(plottempc,0)
   plotmerid_v       = linmsg(plotmerid_v,0)
   plotn2            = linmsg(plotn2,0)
   trop_z_interp     = linmsg(trop_z,0)   ;When plotting the tropopause heights, we
   cp_temp_interp    = linmsg(cp_temp,0)  ;will first plot trop_z_interp using
   cp_pres_interp    = linmsg(cp_pres,0)  ;dashed lines, and then trop_z using solid
   cp_theta_interp   = linmsg(cp_theta,0) ;so we have dashed lines where missing vals are.
   ircloudtop_interp = linmsg(ircloudtop,0)

   ;Set boolean arrays. We will plot these arrays using hatching where
   ;interpolation is performed and overlay them on the r-z plots.
   missingpts_thetae     = where(ismissing(missingpts_thetae).and..not.ismissing(plotthetae),2,0)
   missingpts_theta      = where(ismissing(missingpts_theta).and..not.ismissing(plottheta),2,0)
   missingpts_tempc      = where(ismissing(missingpts_tempc).and..not.ismissing(plottempc),2,0)
   missingpts_merid_v    = where(ismissing(missingpts_merid_v).and..not.ismissing(plotmerid_v),2,0)
   missingpts_plotn2     = where(ismissing(missingpts_plotn2).and..not.ismissing(plotn2),2,0)
   missingpts_trop_z     = where(ismissing(missingpts_trop_z).and..not.ismissing(trop_z_interp),2,0)
   missingpts_ircloudtop = where(ismissing(missingpts_ircloudtop).and..not.ismissing(ircloudtop_interp),2,0)
   out_suffix  = "_interp"
else
   out_suffix = "_nointerp"
end if
;print(trop_z)

;--------------;
;Draw the plots;
;--------------;
;SET SOME RESOURCES FOR HATCHING
hatch_res = True
hatch_res@gsnDraw = False
hatch_res@gsnFrame = False
hatch_res@cnFillOn = True
hatch_res@cnInfoLabelOn = False
hatch_res@cnLinesOn = False
hatch_res@cnLineLabelsOn = False
hatch_res@lbLabelBarOn = False
hatch_res@cnLevelSelectionMode = "ManualLevels"
hatch_res@cnMinLevelValF = 1
hatch_res@cnMaxLevelValF = 2
hatch_res@cnLevelSpacingF = 1 
hatch_res@cnMonoFillPattern = True
;hatch_res@cnMonoFillColor = True
hatch_res@cnFillPattern = 12
hatch_res@cnFillColors = (/-1,1,1,1,1,1/)
hatch_res@cnFillBackgroundColor = -1  ;Make background transparent

;EQUIVALENT POTENTIAL TEMPERATURE
wks_thetae = gsn_open_wks("png",outdir+"thetae"+out_suffix)
gsn_define_colormap(wks_thetae,"WhiteGreen")
res = True
;res@tiMainString = "Equivalent Potential Temperature (K)   "+str_capital(storm)+"  "+date+"  "+transect
res@tiMainOn = False
res@tiYAxisOn = False
res@gsnStringFontHeightF = 0.018
if(date.eq."20151002".or.date.eq."20151021")then
   res@tiYAxisString = "Height (km)"
   res@gsnLeftString = "d) Total distance = "+totaldist+" km"
else
   res@tiYAxisOn = False
;   res@tmYLLabelsOn = False
   if(date.eq."20151003".or.date.eq."20151022")then
      res@gsnLeftString = "e) Total distance = "+totaldist+" km"
   else if (date.eq."20151004".or.date.eq."20151023")then
      res@gsnLeftString = "f) Total distance = "+totaldist+" km"
   end if
   end if
end if
if(type.eq.0)then
   res@tiXAxisString = "Distance along flight track (km)"
else if(type.eq.1)then
   res@tiXAxisString = "Distance from storm center (km)"
end if
end if
res@tiMainFontHeightF = 0.017
res@tiXAxisFontHeightF = 0.017
res@tiYAxisFontHeightF = 0.017
res@trYMinF = 9.
res@trYMaxF = 18.5
res@cnLevelSpacingF = 5.0
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = 320
res@cnMaxLevelValF = 370
res@cnFillOn = True
res@cnInfoLabelOn = False
res@cnLinesOn = False
res@cnLineLabelsOn = False
res@lbLabelBarOn = False
res@lbOrientation = "Vertical"
res@tmYROn = False
res@tmXTOn = False
res@tmXBLabelFontHeightF = 0.016
res@tmYLLabelFontHeightF = 0.016
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False
hatch_plot = gsn_csm_contour(wks_thetae,missingpts_thetae,hatch_res)
thetae_img = gsn_csm_contour(wks_thetae,plotthetae,res)
overlay(thetae_img,hatch_plot)

;POTENTIAL TEMPERATURE WITH TROPOPAUSE HEIGHT AND CLOUD TOP HEIGHT OVERLAY
wks_theta = gsn_open_wks("png",outdir+"theta"+out_suffix)
res@tiMainString = "Potential Temperature (K)   "+str_capital(storm)+"  "+date+"  "+transect
;if(date.eq."20151002".or.date.eq."20151021")then
;   res@gsnLeftString = "d)"
;else if(date.eq."20151003".or.date.eq."20151022")then
;   res@gsnLeftString = "e)"
;else if(date.eq."20151004".or.date.eq."20151023")then
;end if
;end if
;end if
res@cnLinesOn = True
res@cnLevelSpacingF = 4.0
res@cnMinLevelValF = 300;350;350
res@cnMaxLevelValF = 425;380;425
theta_img = gsn_csm_contour(wks_theta,plottheta,res)
tropres = True
tropres@gsLineColor = "blue"
tropres@gsLineThicknessF = 6.
tropres_interp = tropres
tropres_interp@gsLineDashPattern = 16
cloudtopres = tropres
cloudtopres@gsLineColor = "magenta"
cloudtopres@gsLineDashPattern = 15
hatch_plot       = gsn_csm_contour(wks_theta,missingpts_theta,hatch_res)
trophghts_interp1 = gsn_add_polyline(wks_theta,theta_img,dropdist,trop_z_interp,tropres_interp)
trophghts1        = gsn_add_polyline(wks_theta,theta_img,dropdist,trop_z,tropres)
cloudtophghts     = gsn_add_polyline(wks_theta,theta_img,dropdist,ircloudtop,cloudtopres)
;Add vertical line at x=0
overlay(theta_img,hatch_plot)


;TEMPERATURE WITH TROPOPAUSE HEIGHT OVERLAY
wks_tempc = gsn_open_wks("png",outdir+"temperature"+out_suffix)
res@tiMainString = "Temperature (C)   "+str_capital(storm)+"  "+date+"  "+transect
res@cnMaxLevelValF = 30
res@cnMinLevelValF = -80
res@cnLevelSpacingF = 2

;res@cnMaxLevelValF = -70
;res@cnMinLevelValF = -85
;res@cnLevelSpacingF = 0.5
;res@trYMinF = 16.
;res@trYMaxF = 18.
;res@cnLineLabelsOn = True

tempc_img = gsn_csm_contour(wks_tempc,plottempc,res)
tropres = True
tropres@gsLineColor = "yellow"
tropres_interp = tropres
tropres_interp@gsLineDashPattern = 15
hatch_plot       = gsn_csm_contour(wks_tempc,missingpts_tempc,hatch_res)
trophghts_interp2 = gsn_add_polyline(wks_tempc,tempc_img,dropdist,trop_z_interp,tropres_interp)
trophghts2        = gsn_add_polyline(wks_tempc,tempc_img,dropdist,trop_z,tropres)
overlay(tempc_img,hatch_plot)

;MERIDIONAL VELOCITY
wks = gsn_open_wks("png",outdir+"v"+out_suffix)
gsn_define_colormap(wks,"BlWhRe")
vres = res
vres@cnLevelSelectionMode = "ManualLevels"
vres@cnMinLevelValF = -60
vres@cnMaxLevelValF = 60
vres@tiMainString = "Meridional velocity (m/s)   "+storm+"  "+date+"  "+transect
vres@trYMinF = 0.
hatch_res_v = hatch_res
hatch_res_v@trYMinF = 0.
hatch_plot = gsn_csm_contour(wks,missingpts_merid_v,hatch_res_v)
merid_v_img = gsn_csm_contour(wks,plotmerid_v,vres)
overlay(merid_v_img,hatch_plot)

;STATIC STABILITY
wks_stab = gsn_open_wks("png",outdir+"stab+cp_trop_hght"+out_suffix)
gsn_define_colormap(wks_stab,"WhiteGreen")
delete([/res@cnMinLevelValF,res@cnMaxLevelValF,res@cnLevelSpacingF/])
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = 0
res@cnMaxLevelValF = 10.0
res@cnLevelSpacingF = 1.0
res@trYMinF = 9
res@trYMaxF = 18.5
res@cnLinesOn = False
res@tiMainString = "Brunt-Vaisala Frequency Squared (10~S~-4~N~ s~S~-2~N~) and Cold Point Height"
if(date.eq."20151002".or.date.eq."20151021")then
   res@tiYAxisOn = True
   res@tiYAxisString = "Height (km)"
   res@gsnLeftString = "a) Total distance = "+totaldist+" km"
else
   res@tiYAxisOn = False
;   res@tmYLLabelsOn = False
   if(date.eq."20151003".or.date.eq."20151022")then
      res@gsnLeftString = "b) Total distance = "+totaldist+" km"
   else if (date.eq."20151004".or.date.eq."20151023")then
      res@gsnLeftString = "c) Total distance = "+totaldist+" km"
   end if
   end if
end if
stab_img = gsn_csm_contour(wks_stab,plotn2,res)
tropres = True
tropres@gsLineColor = "blue"
tropres_interp = tropres
tropres_interp@gsLineDashPattern = 16
cloudtopres = tropres
cloudtopres@gsLineColor = "magenta"
cloudtopres@gsLineDashPattern = 15
hatch_plot = gsn_csm_contour(wks_stab,missingpts_plotn2,hatch_res)
trophghts_interp = gsn_add_polyline(wks_stab,stab_img,dropdist,trop_z_interp,tropres_interp)
trophghts        = gsn_add_polyline(wks_stab,stab_img,dropdist,trop_z,tropres)
cloudtophghts2   = gsn_add_polyline(wks_stab,stab_img,dropdist,ircloudtop,cloudtopres)
overlay(stab_img,hatch_plot)

;COLD POINT TEMPERATURE VS. R
wks_cptemp = gsn_open_wks("png",outdir+"cold_point_temp"+out_suffix)
xyres = True
xyres@gsnMaximize = True
xyres@gsnDraw = False
xyres@gsnFrame = False
xyres@xyDashPattern = 15 
xyres@tiMainString = "Cold Point Temperature   "+str_capital(storm)+"  "+date+"  "+transect
if(type.eq.0)then
   res@tiXAxisString = "Distance along flight track (km)"
else if(type.eq.1)then
   res@tiXAxisString = "Distance from storm center (km)"
end if
end if
xyres@tiYAxisString = "Temperature (C)"
xyres@tiMainFontHeightF = 0.02
xyres@tiXAxisFontHeightF = 0.02
xyres@tiYAxisFontHeightF = 0.02
xyres@trYMinF = -85.
xyres@trYMaxF = -65.
xyres@xyLineColor = "red"
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
cp_temp_plot_int = gsn_csm_xy(wks_cptemp,dropdist,cp_temp_interp,xyres)
cp_temp_plot     = gsn_csm_xy(wks_cptemp,dropdist,cp_temp,xyres_noint)
overlay(cp_temp_plot_int,cp_temp_plot)
draw(cp_temp_plot_int)
frame(wks_cptemp)

;COLD POINT HEIGHT VS. R
wks_cpz = gsn_open_wks("png",outdir+"cold_point_height"+out_suffix)
xyres@tiMainString = "Cold Point Height   "+str_capital(storm)+"  "+date+"  "+transect
xyres@tiYAxisString = "Height (km)"
xyres@trYMinF = 9.
xyres@trYMaxF = 18.5
xyres@xyLineColor = "black"
xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
xyres_noint@xyDashPattern = 0
cp_hght_plot_int = gsn_csm_xy(wks_cpz,dropdist,trop_z_interp,xyres)
cp_hght_plot     = gsn_csm_xy(wks_cpz,dropdist,trop_z,xyres_noint)
overlay(cp_hght_plot_int,cp_hght_plot)
draw(cp_hght_plot_int)
frame(wks_cpz)

;COLD POINT POTENTIAL TEMPERATURE VS. R
wks_cptheta = gsn_open_wks("png",outdir+"cold_point_theta"+out_suffix)
xyres@tiMainString = "Cold Point Potential Temperature   "+str_capital(storm)+"  "+date+"  "+transect
xyres@tiYAxisString = "Potential Temperature (K)"
xyres@trYMinF = 350.
xyres@trYMaxF = 450.
xyres@xyLineColor = "orange"
xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
xyres_noint@xyDashPattern = 0
cp_theta_plot_int = gsn_csm_xy(wks_cptheta,dropdist,cp_theta_interp,xyres)
cp_theta_plot     = gsn_csm_xy(wks_cptheta,dropdist,cp_theta,xyres_noint)
overlay(cp_theta_plot_int,cp_theta_plot)
draw(cp_theta_plot_int)
frame(wks_cptheta)

;PRESSURE AT THE COLD POINT
wks_cppres = gsn_open_wks("png",outdir+"cold_point_pres"+out_suffix)
xyres@tiMainString = "Pressure at the cold point   "+str_capital(storm)+"  "+date+"  "+transect
xyres@tiYAxisString = "Pressure (mb)"
xyres@trYMinF = 50.
xyres@trYMaxF = 150.
xyres@trYReverse = True
xyres@xyYStyle = "Log"
xyres@xyLineColor = "blue"
xyres@tmYLMode = "Explicit"
xyres@tmYLValues = (/50,60,70,80,90,100,110,120,130,140,150/)
xyres@tmYLLabels = tostring(xyres@tmYLValues)
xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
xyres_noint@xyDashPattern = 0
cp_pres_plot_int = gsn_csm_xy(wks_cppres,dropdist,cp_pres_interp,xyres)
cp_pres_plot     = gsn_csm_xy(wks_cppres,dropdist,cp_pres,xyres_noint)
overlay(cp_pres_plot_int,cp_pres_plot)
draw(cp_pres_plot_int)
frame(wks_cppres)

;OVERLAY LINES AND LABEL THAT REPRESENT DROP LOCATIONS ON EACH PLOT
;AND THEN DRAW ALL OF THE PLOTS
liney  = new((/dimsizes(dropdist),2/),"float")
linex  = liney
labelx = new(floattoint(ceil(dimsizes(dropdist)/2.)),"float")
labely = labelx
labely = res@trYMinF+0.25
locs1   = new(dimsizes(dropdist),"graphic")
locs2  = locs1
locs3  = locs1
locs4  = locs1
locs5  = locs1
j=0
do i=0,dimsizes(locs1)-1
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
;   locs1(i) = gsn_add_polyline(wks_thetae,thetae_img,linex(i,:),liney(i,:),lineres)
;   locs2(i) = gsn_add_polyline(wks_theta,theta_img,linex(i,:),liney(i,:),lineres)
;   locs3(i) = gsn_add_polyline(wks_tempc,tempc_img,linex(i,:),liney(i,:),lineres)
;   locs4(i) = gsn_add_polyline(wks_stab,stab_img,linex(i,:),liney(i,:),lineres)
end do

;Add vertical lines at x=0
zerolineres = True
zerolineres@gsLineDashPattern = 1
zerolineres@gsLineThicknessF = 6.
zeroline_thetae   = gsn_add_polyline(wks_thetae,thetae_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
zeroline_theta    = gsn_add_polyline(wks_theta,theta_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
zeroline_tempc    = gsn_add_polyline(wks_tempc,tempc_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
zeroline_stab_img = gsn_add_polyline(wks_stab,stab_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
zeroline_merid_v  = gsn_add_polyline(wks,merid_v_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)

;Overlay digits that represent drop locations
text = tostring(ispan(1,nfiles,2))   ;Only make a label for every other sonde location
txres = True
txres@txFont = 30
txres@txFontHeightF = 0.015
txres@txFontColor = "black"
dum = gsn_add_text(wks_thetae,thetae_img,text,labelx,labely,txres)
dum = gsn_add_text(wks_theta,theta_img,text,labelx,labely,txres)
dum = gsn_add_text(wks_tempc,tempc_img,text,labelx,labely,txres)
dum = gsn_add_text(wks_stab,stab_img,text,labelx,labely,txres)
dum = gsn_add_text(wks,merid_v_img,text,labelx,labely,txres)

;Draw all of the plots
draw(thetae_img)
draw(theta_img)
draw(tempc_img)
draw(stab_img)
draw(merid_v_img)
frame(wks_thetae)
frame(wks_theta)
frame(wks_tempc)
frame(wks_stab)
frame(wks)
