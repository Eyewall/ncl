load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/nfs/jm13/pduran/ncl/functions/meteo.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/nfs/jm13/pduran/ncl/functions/interpolate.ncl"
load "/nfs/jm13/pduran/ncl/functions/tan+rad_velocity.ncl"
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
; 7/21/16: Added maxmimum BL thetae in whole transect as a dark
;          contour in the theta cross-section. NOTE: For this
;          to work, minhght must be set to 0.
; 11/17/16:Modified sondedir, listfile, and suffix to use
;          editfiles with storm-relative winds.
; 11/18/16:Modified sondedir, listfile, and suffix to use
;          editfiles with storm-relative radial and tangential
;          velocities. Also disables rad+tan vel computation here.
; 12/08/16:Removed dashed line that represents maximum BL thetae,
;          per discussion with John M. on 12/07.
;          Made y axis labels explicit to focus only on the layer
;          immediately surrounding the tropopause.
;----------------------------------------------------------------;

storm    = "patricia"
date     = "20151023"
transect = "transect1"
maxhght  = 20000  ;Maximum height to pull (m)
minhght  = 0   ;Minimum height to use in interpolation function
dz       = 100    ;Grid spacing of the input data
minx     = -500   ;Mininmum x coordinate of the fixed grid to interpolate to
maxx     = 500    ;Maximum x coordinate of the fixed grid to interpolate to
x_spacng = 1      ;Grid spacing of the fixed grid
nradii   = (maxx-minx)/x_spacng+1
nlevels  = maxhght/dz+1
tropfile = "trophghts"+date+"_"+transect
;sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/storm-relative/rad+tan-vel/"
sondedir = "/nfs/jm13/pduran/dropsondes/hs3/edit/2012/nadine4/"
listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/storm-relative/rad+tan-vel/"+transect
prefix   = "A"
suffix   = "-GLOBALHAWK_HS3-100m-noEC-mfx500-sm0x-loc.edit"
outdir   = "/jm13/pduran/web/tci/cross_sections/"+storm+"/"+date+"/"+transect+"/fixedgrid/"
interp   = 1   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate
driftopt = 0   ;Account for sonde drift in interpolation script? (0=No,1=Yes)
               ;NOTE: This does not currently work properly...
type     = 1   ;Plot as total distance from start of flight leg (0) or
               ;distance from storm center (1)? ;DOESN'T DO ANYTHING RIGHT NOW
assumerh = 1   ;Assume a constant RH for the whole profile? 0=no, 1=yes
rhconst  = 90  ;Relative humidity used if assumerh=1
divopt   = 1   ;How to compute divergence? (0=Cartesian coords, 1=Cyclindrical coords)
;vertcoord= 1   ;Vertical coordinate for plotting. (0=Height, 1=Pressure)
axisorient = 1 ;X-Axis orientation (0=Leftmost side represents the first sonde in the
               ;                      transect, 1=Leftmost side is West

if(date.eq."20151021")then
   if(transect.eq."transect1")
      centerlat = 13.56   ;Transect 1 did not have a center crossing, so I've set the
      centerlon = -99.74  ;"center sonde" to be the first sonde in the transect. Thus, the
      centersonde = 1     ;"radii" returned will simply be the distance from the first sonde.
      axisorient  = 0
   else	   ;Transect 2
      centerlat = 12.99   ;Sonde nearest the interpolated center location for VORTEX msgs
      centerlon = -99.27  ;Also zero wind center in sondes... 
      centersonde = 7     
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
   if(transect.eq."transect1")then
      centerlat = 18.61      ;Sonde nearest the zero wind center AND nearest VORTEX track	
      centerlon = -105.22
      centersonde = 14
      if(axisorient.eq.1)then
         centersonde = 32
      end if
   else   ;Transect 2
      centerlat = 20.75      ;This is not actually the storm center, since this transect is
      centerlon = -109.28    ;not a center crossing. Rather, I've set the "center sonde" to
      centersonde = 1        ;be the first sonde in the transect. Thus, the "radii" returned
   end if                    ;will simply be the distance from the first sonde.
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

;infiles = sondedir+systemfunc("cat "+listfile)
infiles = systemfunc("ls "+sondedir+"*edit")
nfiles  = dimsizes(infiles)

;Read interpolated best track file
trackdata = readAsciiTable("/jm13/pduran/recon-positions/patricia_vortex_interp-1sec-20151022.txt",8,"float",1)
stormlats = trackdata(:,0)
stormlons = trackdata(:,1)

;If axisorient=1, we need to invert the X axis on 10/21 and 10/23
if(axisorient.eq.1)
   if(date.eq."20151021".or.(date.eq."20151023".and.transect.eq."transect1"))then
      infiles = infiles(::-1)
   end if
end if

droplats = new(nfiles,"float")
droplons = new(nfiles,"float")
distancetocenter = new(nfiles,"float")
maxdrift = new((/nfiles/),"float")
z        = new((/nfiles,nlevels/),"float")
tc       = new((/nfiles,nlevels/),"float")
p        = new((/nfiles,nlevels/),"float")
plotdata = new((/nlevels,nfiles/),"float")
z@_FillValue        = -9999.0
tc@_FillValue    = -9999.0
plotdata@_FillValue = -9999.0
td = tc
u  = tc
v  = tc
hght = tc
rh = tc
lat = tc
lon = tc
thetae_drops = tc
maxblthetae_drops = new(nfiles,"float")

print(infiles)
do i=0,nfiles-1
   unixi = i+1
   print("Processing sonde "+unixi+" of "+nfiles)
   ;Read input file and assign variables
   data := readAsciiTable(infiles(i),10,"float",7)
   data@_FillValue = -9999.0
   nhghts = dimsizes(data(:,5))
   p   (i,:nhghts-1) = data(:,0)
   tc  (i,:nhghts-1) = data(:,1)
   td  (i,:nhghts-1) = data(:,2)
   u   (i,:nhghts-1) = data(:,3)  ;11/17/16: Now radial velocity
   v   (i,:nhghts-1) = data(:,4)  ;11/17/16: Now tangential velocity
   hght(i,:nhghts-1) = data(:,5)
   rh  (i,:nhghts-1) = data(:,6)
   lat (i,:nhghts-1) = data(:,7)
   lon (i,:nhghts-1) = data(:,8)
   droplats(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $3}' "))
   nfields = stringtoint(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print NF}'"))
   if(nfields.eq.9)then
      droplons(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $5}' | sed 's/=//'"))
   else
      droplons(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $6}'"))
   end if

   ;Compute distances between storm track and dropsonde locations
   distancetocenter(i) = min(gc_latlon(droplats(i),droplons(i),stormlats,stormlons,2,4))

   ;Compute sonde drift above 16 km (ignore any drifts > 1000 km because the gc_latlon
   ;function does not search for missing values...for some stupid reason (did I say that out loud?)
;   drifts = gc_latlon(droplats(i),droplons(i),lat(i,160:),lon(i,160:),2,4)
   ;THESE DRIFTS REPRESENT THE MAXIMUM DRIFTS THROUGH THE WHOLE DEPTH OF THE DROP
   drifts = gc_latlon(droplats(i),droplons(i),lat(i,:),lon(i,:),2,4)
   maxdrift(i) = max(drifts(ind(drifts.lt.1000)))
end do

;Compute distances between successive drop positions
dropdists = new(nfiles-1,float)
do i=0,nfiles-2
   dropdists(i) = gc_latlon(droplats(i),droplons(i),droplats(i+1),droplons(i+1),2,4)
end do
print(droplats)
print(droplons)
print(dropdists)
exit

;Create array of drop distances for the fixed grid
;If flight is from north to south, we multiply by -1 (because the 
;interpolation script assumes distance is negative north of the
;storm center) and then flip all of the arrays.
dropdistances = fspan(minx,maxx,nradii)
dropdist = new((/nradii,nlevels/),"float")
dropdist = conform(dropdist,dropdistances,0)

;We must compute vertical gradients *before* we interpolate
;to the fixed grid because if there are missing values to
;interpolate across in the presence of large horizontal
;temperature gradients, radial interpolation can create a
;discontinuity where the missing values begin, which leads
;to strong artifical maxima in vertical gradients...
;So here we will compute dT/dz and Brunt-Vaisala frequency.
dtdz = center_finite_diff(tc,100,False,0) * 100 ;K/100 m
g  = 9.80665
tk = tc+273.15
theta = tk*(1000/p)^0.286
dthetadz = center_finite_diff(theta,100,False,0)
n2 = g/theta*dthetadz

;Interpolate all of the variables to a fixed radial grid
print("Interpolating to the fixed grid...")
vars = interpolate(nlevels,nradii,dropdistances,minhght,maxhght,centerlat,centerlon,centersonde,p,tc,td,u,v,theta,dtdz,n2,hght,rh,lat,lon,droplats,droplons,driftopt)
pres           = vars[0]
tempc          = vars[1]
dewpc          = vars[2]
rad_v          = vars[3]
tan_v          = vars[4]
zonal_v        = pres@_FillValue ;Set to missing because we're no longer reading in zonal and merid v
merid_v        = pres@_FillValue
;zonal_v        = vars[3]
;merid_v        = vars[4]
theta_int     := vars[5]
dtdz          := vars[6]
n2            := vars[7]
rh_fixed       = vars[8]
lats           = vars[9]
lons           = vars[10]
droplocs       = vars[11]
missingpts_p   = vars[12]
missingpts_tc  = vars[13]
missingpts_td  = vars[14]
missingpts_u   = vars[15]
missingpts_v   = vars[16]
;missingpts_theta=vars[17]
missingpts_dtdz= vars[18]
missingpts_n2  = vars[19]
missingpts_rh_fixed = vars[20]
missingpts_lat = vars[21]
missingpts_lon = vars[22]
dropxcoords    = vars[23]  ;Dimensioned [nfiles]

;Compute distance between each dropsonde
;separation = new(dimsizes(droplocs)-2,"float")
;do i=0,dimsizes(droplocs)-2
;   separation(i) = droplocs(i+1)-droplocs(i)
;end do 
;print(dropxcoords)
;print(theta(:,150))
;print(separation)
;printMinMax(separation,0)
;sepavg = avg(separation)
;print(sepavg)

;Compute radial potential temperature advection
;on the uniform grid
dthetadr  = center_finite_diff_n(theta_int,dropdistances,False,0,0) / 1000.
centerind = nradii/2
dthetadr(0:centerind,:) = dthetadr(0:centerind,:)*-1
theta_adv = -rad_v*dthetadr*1000 ;Units K/hr
theta_adv = smooth_121(theta_adv,0,10)  ;Smooth

;Compute some moisture variables for the sondes
es_sondes = 6.11*10^((7.5*tc)/(237.3+tc))
ws_sondes = 621.97*(es_sondes/(p-es_sondes))
if(assumerh.eq.0)then
   w_sondes = rh*ws_sondes/100/1000   ;Water vapor mixing ratio (kg/kg)
else
   w_sondes = rhconst*ws_sondes/100/1000
end if

;Compute some moisture variables for the fixed grid
es = 6.11*10^((7.5*tempc)/(237.3+tempc))	;Saturation vapor pressure
ws = 621.97*(es/(pres-es))		;Saturation mixing raitio  (g/kg) 
if(assumerh.eq.0)then
   w = rh_fixed*ws_/100/1000	;Water vapor mixing ratio (kg/kg)
   rh_array = rh_fixed
else
   w = rhconst*ws/100/1000
   rh_array = conform(rh,rhconst,-1)
end if

;Set or compute all of the variables
cp_temp  = new(nfiles,"float")
cp_temp@_FillValue = -9999.
cp_pres      = cp_temp 
cp_theta     = cp_temp 
trop_z       = cp_temp 
maxblthetae  = new(nradii,"float")
maxblthetaey = new(nradii,"float")
hght_fixedgrid = fspan(0,maxhght,nlevels)/1000.
z_interp = conform(tempc,hght_fixedgrid,1)
tempk = tempc+273.15
theta := tempk*(1000/pres)^0.286
thetae = theta
maxt = maxblthetae_drops
do i=0,nfiles-1
   if(.not.all(ismissing(tempc(i,:))))then
      cp_temp (i) = min(tc(i,:))
      cp_pres (i) = p(minind(tc(i,:)))
      if(cp_pres(i).gt.150)then
         cp_pres(i) = cp_pres@_FillValue
      end if
      cp_theta(i) = (cp_temp(i)+273.15)*(1000/cp_pres(i))^0.286
   end if
   thetae_drops(i,:) = theta_eqv(tc(i,:)+273.15,rh_array(i,:),w_sondes(i,:),1000,p(i,:),1)
   maxblthetae_drops(i) = max(thetae_drops(i,ind(hght(i,:).le.1000.)))
   maxt(i) = max(tc(i,ind(hght(i,:).le.1000.)))+273.15
end do







;Use Dave's values for max BL theta-e
if(date.eq."20151021")then
   max_maxblthetae = 359.8
else if(date.eq."20151022")then
   max_maxblthetae = 371.1
else if(date.eq."20151023")then
   max_maxblthetae = 396.4
end if
end if
end if






;Get the y coordinates for the maxblthetae contour in the upper-troposphere
do i=0,nradii-1
   if(.not.all(ismissing(tempc(i,:))))then
      maxblthetaey(i) = hght_fixedgrid((minind(abs(theta(i,:)-max_maxblthetae))))
   end if
end do
;print("Smoothing the maximum BL thetae line...")
maxblthetaey = smooth_121(maxblthetaey,0,10)  ;Smooth the line...
cp_pres!0 = "radii"
cp_pres&radii = dropxcoords

;Compute velocities in cylindrical coordinates
;vel_cylin = tanradvel(centerlat,centerlon,lats,lons,zonal_v,merid_v)
;tan_v = vel_cylin[0]
;rad_v = vel_cylin[1]

;Compute divergence using the selected coordinate system
if(divopt.eq.0) ;Cartesian coordinates
   lats_div = lats
   lons_div = lons
;   do k=0,nradii-1
;      lats_div(k,:) = droplats(k)
;      lons_div(k,:) = droplons(k)
;   end do

   ;We need to get the velocities to be dimensioned nlevels x nlats x lons
   ;because the uv2dv_cfd function requires it. 
   div_cart       = new((/nlevels,nradii,nradii/),"float")
   zonalv_divcalc = new((/nlevels,nradii,nradii/),"float")
   meridv_divcalc = new((/nlevels,nradii,nradii/),"float")
   div_cart@_FillValue     = -9999.
   zonalv_divcalc@_FillValue = -9999.
   meridv_divcalc@_FillValue = -9999.
   zonalv_divcalc = conform(zonalv_divcalc,transpose(zonal_v),(/0,1/))
   meridv_divcalc = conform(meridv_divcalc,transpose(merid_v),(/0,1/))

   do k=0,nlevels-1
      div_cart(k,:,:) = uv2dv_cfd(zonalv_divcalc(k,:,:),meridv_divcalc(k,:,:),lats_div(:,k),lons_div(:,k),2)
   end do
   divergence = transpose(div_cart(:,:,0))
   ;uv2dv_cfd yields infinite numbers in a few places. So set very large and
   ;very small values to missing.
   divergence = where(divergence.gt.1000,divergence@_FillValue,divergence)
   divergence = where(divergence.lt.-1000,divergence@_FillValue,divergence)
else if(divopt.eq.1)then ;Cylindrical coordinates, assuming axisymmetry
   divergence = new((/nradii,nlevels/),"float")
   divergence@_FillValue = -9999.
   dropdist_m = dropdist * 1000.
   do i=0,nradii-2
   ;   divergence(i,:) = (abs(dropdist_m(i+1,:))*rad_v(i+1,:)-abs(dropdist_m(i,:))*rad_v(i,:))\
   ;                     /(0.5*(abs(dropdist_m(i,:))+abs(dropdist_m(i+1,:)))*(abs(dropdist_m(i+1,:)\
   ;                     -dropdist_m(i,:))))
    divergence(i,:) = (dropdist_m(i+1,:)*rad_v(i+1,:)-dropdist_m(i,:)*rad_v(i,:))\
                        /(0.5*(dropdist_m(i,:)+dropdist_m(i+1,:))*(dropdist_m(i+1,:)\
                        -dropdist_m(i,:)))
   end do
end if
end if




divergence = where(dropdist_m.lt.0,divergence*-1,divergence)
;Apply 1-2-1 smoother in the radial direction 10 times to divergence
print("Smoothing the divergence...")
divergence = smooth_121(divergence,0,10)
divergence = divergence*10000
printMinMax(divergence,False)

;Get the tropopause height from tropopause pressure by linear interpolation
do i=0,dimsizes(cp_pres)-1
   if(min(p).lt.200.and..not.ismissing(cp_pres(i)).and.dimsizes(ind(.not.ismissing(pres(i,:)))).gt.1)then
      diffs = abs(pres(i,:)-cp_pres(i))
      diffs_sort = diffs(ind(.not.ismissing(diffs)))
      qsort(diffs_sort)
      p1 = pres(i,ind(diffs.eq.diffs_sort(0)))
      p2 = cp_pres(i)
      p3 = min(pres(i,ind(diffs.eq.diffs_sort(1))))
      z1 = min(z_interp(i,ind(diffs.eq.diffs_sort(0))))
      z3 = min(z_interp(i,ind(diffs.eq.diffs_sort(1))))
      z2 = (p2-p1)*(z3-z1)/(p3-p1)+z1
      trop_z(i) = z2
      delete([/diffs,diffs_sort/])
   else
      trop_z(i) = trop_z@_FillValue
   end if
end do





delete(trop_z)

nlines   = stringtoint(systemfunc("wc "+tropfile+" | awk '{print $1}'"))
trop_z   = asciiread(tropfile,nlines,"float")
trop_z@_FillValue = -9999
if(date.eq."20151021".or.date.eq."20151023")then
   if(axisorient.eq.1)then
      trop_z = trop_z(::-1)
   end if
end if








;Set thresholds for cold point temperature and height to eliminate
;sondes that don't have data in upper levels
cp_pres = where(cp_temp.gt.-60,cp_pres@_FillValue,cp_pres)
cp_theta= where(cp_temp.gt.-60,cp_theta@_FillValue,cp_theta)
cp_temp = where(cp_temp.gt.-60,cp_temp@_FillValue,cp_temp)

;Compute total distance along the transect
totaldist = round(max(droplocs)-min(droplocs),0)

;-------------------------------------------------------;
;Create arrays for plotting and set coordinate variables;
;-------------------------------------------------------;
;POTENTIAL TEMPERATURE
plottheta = transpose(theta)
plottheta!0 = "height"
plottheta!1 = "radius"
plottheta&height = fspan(0,maxhght,nlevels)/1000.
plottheta&radius = dropdistances

;TEMPERATURE
plottempc = transpose(tempc)
copy_VarMeta(plottheta,plottempc)

;TANGENTIAL VELOCITY
plottan_v = transpose(tan_v)
copy_VarMeta(plottheta,plottan_v)

;RADIAL VELOCITY
plotrad_v = transpose(rad_v)
copy_VarMeta(plottheta,plotrad_v)

;RADIAL ADVECTION OF POTENTIAL TEMPERATURE
plottheta_adv = transpose(theta_adv)
copy_VarMeta(plottheta,plottheta_adv)

;DIVERGENCE
plotdiv = transpose(divergence)
copy_VarMeta(plottheta,plotdiv)

;WIND SPEED
;plotmerid_v = transpose(merid_v)
;copy_VarMeta(plottheta,plotmerid_v)

;STATIC STABILITY
plotn2 = transpose(n2)*10000  ;Convert to more readable units (10^-4 s^-2)
copy_VarMeta(plottheta,plotn2)

;dT/dz
plotdtdz = transpose(dtdz)
copy_VarMeta(plottheta,plotdtdz)

;PRESSURE
plotpres = transpose(pres)
copy_VarMeta(plottheta,plotpres)

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
;   missingpts_thetae  = plotthetae
;   missingpts_tan_v   = plottan_v
;   missingpts_rad_v   = plotrad_v
;   missingpts_div     = plotdiv
;   missingpts_theta   = plottheta
;   missingpts_merid_v = plotmerid_v
   missingpts_plotn2  = plotn2
   missingpts_plotdtdz  = plotdtdz
   missingpts_trop_z  = trop_z  ;Don't need to create missing value boolean
                                ;arrays for other tropopause values because
                                ;wherever trop_z is missing, those are, too
   ;Theta advection is missing wherever t or u is missing
   missingpts_theta_adv = missingpts_tc
   missingpts_theta_adv = where(missingpts_tc.eq.2.or.missingpts_u.eq.2,2,0)

   ;Perform linear interpolation
;   plotthetae     = linmsg(plotthetae,0)
   plottan_v      = linmsg(plottan_v,0)
   plotrad_v      = linmsg(plotrad_v,0)
   plottheta_adv  = linmsg(plottheta_adv,0)
   plotdiv        = linmsg(plotdiv,0)
   plottheta      = linmsg(plottheta,0)
;   plottempc      = linmsg(plottempc,0)
;   plotmerid_v    = linmsg(plotmerid_v,0)
   plotn2         = linmsg(plotn2,0)
   plotdtdz       = linmsg(plotdtdz,0)
   cp_temp_interp = linmsg(cp_temp,0)  ;will first plot trop_z_interp using
   cp_pres_interp = linmsg(cp_pres,0)  ;dashed lines, and then trop_z using solid
   cp_theta_interp= linmsg(cp_theta,0) ;so we have dashed lines where missing vals are.

   ;Set boolean arrays. We will plot these arrays using hatching where
   ;interpolation is performed and overlay them on the r-z plots.
   missingpts_theta := transpose(missingpts_tc)
   missingpts_tempc  = transpose(missingpts_tc)
   missingpts_merid_v= transpose(missingpts_u);where(ismissing(missingpts_merid_v).and..not.ismissing(plotmerid_v),2,0)
   missingpts_tan_v  = transpose(missingpts_v);where(ismissing(missingpts_tan_v).and..not.ismissing(plottan_v),2,0)
   missingpts_rad_v  = transpose(missingpts_u);where(ismissing(missingpts_rad_v).and..not.ismissing(plotrad_v),2,0)
   missingpts_theta_adv:=transpose(missingpts_theta_adv)
   missingpts_div    = transpose(missingpts_u);where(ismissing(missingpts_div).and..not.ismissing(plotdiv),2,0)
   missingpts_plotn2 = transpose(missingpts_tc)
   missingpts_plotdtdz = transpose(missingpts_tc)

   out_suffix  = "_interp"
else
   out_suffix = "_nointerp"
end if

;Apply 1-2-1 smoother in the radial direction to the radial velocity
;plotrad_v = smooth_121(plotrad_v,1,20)

;--------------;
;Draw the plots;
;--------------;
;SET SOME RESOURCES FOR HATCHING
hatch_res = True
hatch_res@tiYAxisOn = False
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
;hatch_res@cnMissingValFillColor = "black"
;hatch_res@cnMissingValFillPattern = 12

;EQUIVALENT POTENTIAL TEMPERATURE
;wks_thetae = gsn_open_wks("png",outdir+"thetae"+out_suffix)
;gsn_define_colormap(wks_thetae,"WhiteGreen")
res = True
res@tiMainString = "Equivalent Potential Temperature (K)   "+str_capital(storm)+"  "+date+"  "+transect
res@tiMainOn = False
res@gsnStringFontHeightF = 0.018
;if(date.eq."20151023")then
;   res@tmYLOn = False
;   hatch_res@tmYLOn = False
;end if
res@gsnLeftString = "Potential Temperature (K) "+date+" "+transect
if(date.eq."20151002".or.date.eq."20151021")then
   res@tiYAxisString = "Height (km)"
   res@gsnLeftString = "a) Total distance = "+totaldist+" km"
else
   res@tiYAxisOn = False
   if(date.eq."20151003".or.date.eq."20151022")then
      res@gsnLeftString = "e) Total distance = "+totaldist+" km"
   else if (date.eq."20151004".or.date.eq."20151023")then
      res@gsnLeftString = "c) Total distance = "+totaldist+" km"
   end if
   end if
end if
if(date.eq."20151021")then
   res@tiXAxisString    = "W                 Distance from storm center (km)                    E"
   if(transect.eq."transect1")then
      res@tiXAxisString = "W                   Distance along transect (km)                     E"
   end if
else if(date.eq."20151022")then
   res@tiXAxisString = "NW                Distance from storm center (km)                SE"
   if(transect.eq."transect2")then
      res@tiXAxisString = "SW                Distance from storm center (km)                NE"
   end if
else if(date.eq."20151023")then
   res@tiXAxisString = "NW                Distance from storm center (km)                SE"
   if(transect.eq."transect2")then
      res@gsnLeftString = " "
      res@tiXAxisString = "NW                  Distance along transect (km)                 SE"
   end if
end if
end if
end if

res@tiMainFontHeightF = 0.017
res@tiXAxisFontHeightF = 0.017
res@tiYAxisFontHeightF = 0.017
res@trYMinF = 16.
res@trYMaxF = 18.5
res@trXMinF = min(droplocs)
res@trXMaxF = max(droplocs)
res@tmYLMode = "Explicit"
res@tmYLValues = (/16.0,16.5,17.0,17.5,18.0,18.5/)
res@tmYLLabels = (/"16.0","16.5","17.0","17.5","18.0","18.5"/)
res@tmYLMinorValues = fspan(16,18.5,26)
res@tmYLPrecision = 1
res@cnLevelSpacingF = 5.0
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = 320.
res@cnMaxLevelValF = 370.
res@cnFillOn = True
res@cnInfoLabelOn = False
res@cnLinesOn = False
res@cnLineLabelsOn = True
res@lbLabelBarOn = False
res@lbOrientation = "Vertical"
res@lbAutoManage = "False"
res@lbLabelFontHeightF = 0.020
res@tmYROn = False
res@tmXTOn = False
res@tmXBLabelFontHeightF = 0.016
res@tmYLLabelFontHeightF = 0.016
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False
res@cnMissingValFillColor = "black"
res@cnMissingValFillPattern = 12

;hatch_plot = gsn_csm_contour(wks_thetae,missingpts_thetae,hatch_res)
;thetae_img = gsn_csm_contour(wks_thetae,plotthetae,res)
;overlay(thetae_img,hatch_plot)

;POTENTIAL TEMPERATURE WITH TROPOPAUSE HEIGHT OVERLAY
wks_theta = gsn_open_wks("png",outdir+"theta"+out_suffix)
wks_gravwave = gsn_open_wks("png",outdir+"gravitywaves.png")
gsn_define_colormap(wks_theta,"WhiteYellowOrangeRed")
thetares = res
thetares@tiYAxisOn = True
thetares@tiYAxisString = "Height (km)"
thetares@gsnRightString = "~F33~q~F21~ (K)"
if(date.eq."20151021")then
   thetares@gsnLeftString = "a) Total distance = "+totaldist+" km"
   thetares@gsnLeftString = "a) 21 October 1952-2009 UTC"
else if(date.eq."20151022")then
;   dtres@tiYAxisOn = False
   if(transect.eq."transect1")then
      thetares@gsnLeftString = "b) Total distance = "+totaldist+" km"
      thetares@gsnLeftString = "b) 22 October 1815-1827 UTC"
   else
      thetares@gsnLeftString = "c) Total distance = "+totaldist+" km"
      thetares@gsnLeftString = "c) 22 October 1857-1913 UTC"
   end if
else if(date.eq."20151023")then
;   dtres@tiYAxisOn = False
   thetares@gsnLeftString = "d) Total distance = "+totaldist+" km"
   thetares@gsnLeftString = "d) 23 October 1957-2012 UTC"
end if
end if
end if

thetares@cnLinesOn = True
thetares@cnLevelSpacingF = 2.0
thetares@cnMinLevelValF = 364;350;350
thetares@cnMaxLevelValF = 425;380;425
theta_img = gsn_csm_contour(wks_theta,plottheta,thetares)

tropres = True
tropres@gsLineColor = "dark green"
tropres@gsLineThicknessF = 18.
tropres_interp = tropres
tropres_interp@gsLineDashPattern = 15
hatch_plot       = gsn_csm_contour(wks_theta,missingpts_theta,hatch_res)
hatch_plot2      = gsn_csm_contour(wks_gravwave,missingpts_theta,hatch_res)
trophghts1       = gsn_add_polyline(wks_theta,theta_img,dropxcoords,trop_z,tropres)
gravwaveres = thetares
gravwaveres@lbLabelBarOn = False
gravwaveres@gsnLeftString = " "
gravwaveres@tiYAxisOn = True
gravwaveres@tiYAxisString = "Height (km)"
gravwave_img = gsn_csm_contour(wks_gravwave,plottheta,gravwaveres)
trophghtsgrav= gsn_add_polyline(wks_gravwave,gravwave_img,dropxcoords,trop_z,tropres)
overlay(theta_img,hatch_plot)
overlay(gravwave_img,hatch_plot2)

;TEMPERATURE WITH TROPOPAUSE HEIGHT OVERLAY
wks_tempc = gsn_open_wks("png",outdir+"temperature"+out_suffix)
res@tiMainString = "Temperature (C)   "+str_capital(storm)+"  "+date+"  "+transect
res@cnMaxLevelValF = -60
res@cnMinLevelValF = -80
res@cnLevelSpacingF = 1
res@cnLinesOn = True

;res@cnMaxLevelValF = -70
;res@cnMinLevelValF = -85
;res@cnLevelSpacingF = 0.5
;res@cnLineLabelsOn = True
tempc_img = gsn_csm_contour(wks_tempc,plottempc,res)
tropres = True
tropres@gsLineColor = "yellow"
tropres_interp = tropres
tropres_interp@gsLineDashPattern = 15
hatch_plot       = gsn_csm_contour(wks_tempc,missingpts_tempc,hatch_res)
trophghts2        = gsn_add_polyline(wks_tempc,tempc_img,dropxcoords,trop_z,tropres)
overlay(tempc_img,hatch_plot)

;PRESSURE
preswks = gsn_open_wks("png",outdir+"pressure")
presres = res
presres@tiMainOn = False
presres@cnMinLevelValF = 80
presres@cnMaxLevelValF = 1000
presres@cnLevelSpacingF = 10.
presres@trYMinF = 0
presres@trYMaxF = 18.5
res@trXMinF = min(droplocs) 
res@trXMaxF = max(droplocs)
;presres@trXMinF = -40
;presres@trXMaxF = 40
presres@lbLabelBarOn = True
presplot = gsn_csm_contour(preswks,plotpres,presres)

;TANGENTIAL VELOCITY
tanvwks = gsn_open_wks("png",outdir+"tangential_v"+out_suffix)
gsn_define_colormap(tanvwks,"BlWhRe")
vres = res
vres@cnLevelSelectionMode = "ManualLevels"
vres@tiMainString = "Tangential velocity (ms~S~-1~N~)   "+storm+"  "+date+"  "+transect
vres@tiMainString = "b) Tangential velocity (ms~S~-1~N~) 22 October Transect 1"
if(date.eq."20151022".and.transect.eq."transect2")then
   vres@tiMainString = "d) Tangential velocity (ms~S~-1~N~) 22 October Transect 2"
end if
vres@gsnLeftString = vres@tiMainString
vres@cnMinLevelValF = -18.
vres@cnMaxLevelValF = 18.
vres@cnLinesOn = True
vres@tmYLMode = "Explicit"
vres@tmYLValues = (/16.0,16.5,17.0,17.5,18.0,18.5/)
vres@tmYLLabels = (/"16.0","16.5","17.0","17.5","18.0","18.5"/)
vres@tmYLMinorValues = fspan(16,18.5,26)
vres@tmYLPrecision = 1
vres@trYMinF = 16.
vres@trYMaxF = 18.5
vres@tiYAxisOn = True
;if(date.ne."20151021")then
;   vres@tiYAxisOn = False
;end if
vres@tiYAxisString = "Height (km)"
vres@gsnMaximize = True
vres@lbOrientation = "Vertical"
hatch_res_v = hatch_res
hatch_res_v@tmYLMode = "Explicit"
hatch_res_v@tmYLValues = (/16.0,16.5,17.0,17.5,18.0,18.5/)
hatch_res_v@tmYLLabels = (/"16.0","16.5","17.0","17.5","18.0","18.5"/)
tropres@gsLineColor = "dark green"
hatch_plot = gsn_csm_contour(tanvwks,missingpts_tan_v,hatch_res_v)
tan_v_img = gsn_csm_contour(tanvwks,plottan_v,vres)
trophghts4 = gsn_add_polyline(tanvwks,tan_v_img,dropxcoords,trop_z,tropres)
overlay(tan_v_img,hatch_plot)

;RADIAL VELOCITY
radvwks = gsn_open_wks("png",outdir+"radial_v"+out_suffix)
gsn_define_colormap(radvwks,"BlWhRe")
vres@tiMainString = "Radial velocity (ms~S~-1~N~)   "+storm+"  "+date+"  "+transect
vres@tiMainString = "a) Radial velocity (ms~S~-1~N~) 22 October Transect 1"
if(date.eq."20151022".and.transect.eq."transect2")then
   vres@tiMainString = "c) Radial velocity (ms~S~-1~N~) 22 October Transect 2"
end if
vres@gsnLeftString = vres@tiMainString
vres@cnLevelSpacingF = 1.
vres@cnMinLevelValF = -13.
vres@cnMaxLevelValF = 13.
hatch_plot = gsn_csm_contour(radvwks,missingpts_rad_v,hatch_res_v)
rad_v_img = gsn_csm_contour(radvwks,plotrad_v,vres)
trophghts5 = gsn_add_polyline(radvwks,rad_v_img,dropxcoords,trop_z,tropres)
overlay(rad_v_img,hatch_plot)

;dT/dz
dtdzwks = gsn_open_wks("png",outdir+"dtdz"+out_suffix)
gsn_define_colormap(dtdzwks,"dtdz_colors")
dtres = vres
dtres@tiYAxisOn = True
dtres@gsnRightString = "dT/dz (K/100 m)"
if(date.eq."20151021")then
   dtres@gsnLeftString = "a) Total distance = "+totaldist+" km"
   dtres@gsnLeftString = "a) 21 October 1952-2009 UTC"
else if(date.eq."20151022")then
;   dtres@tiYAxisOn = False
   if(transect.eq."transect1")then
      dtres@gsnLeftString = "b) Total distance = "+totaldist+" km"
      dtres@gsnLeftString = "b) 22 October 1815-1827 UTC"
   else
      dtres@gsnLeftString = "c) Total distance = "+totaldist+" km"
      dtres@gsnLeftString = "c) 22 October 1857-1913 UTC"
   end if
else if(date.eq."20151023")then
;   dtres@tiYAxisOn = False
   dtres@gsnLeftString = "d) Total distance = "+totaldist+" km"
   dtres@gsnLeftString = "d) 23 October 1957-2012 UTC"
end if
end if
end if
dtres@trYMinF = 16.
dtres@trYMaxF = 18.5
dtres@tmYLMode = "Explicit"
dtres@tmYLValues = (/16.0,16.5,17.0,17.5,18.0,18.5/)
dtres@tmYLLabels = (/"16.0","16.5","17.0","17.5","18.0","18.5"/)
dtres@tmYLMinorValues = fspan(16,18.5,26)
dtres@tmYLPrecision = 1
dtres@cnMinLevelValF = -1.
dtres@cnMaxLevelValF = 5.
dtres@cnLevelSpacingF = 0.25
dtres@gsnContourZeroLineThicknessF = 0.
dtres@lbOrientation = "Vertical"
hatch_plot = gsn_csm_contour(dtdzwks,missingpts_tempc,hatch_res_v)
dtdz_img  = gsn_csm_contour(dtdzwks,plotdtdz,dtres)
trophghts3 = gsn_add_polyline(dtdzwks,dtdz_img,dropxcoords,trop_z,tropres)
overlay(dtdz_img,hatch_plot)

;DIVERGENCE
divwks = gsn_open_wks("png",outdir+"div"+out_suffix)
gsn_define_colormap(divwks,"BlWhRe")
divres = vres
divres@gsnLeftString = "Divergence (10^-4 1/s)   "+storm+"  "+date+"  "+transect
divres@tmYLMode = "Explicit"
divres@tmYLValues = (/16.0,16.5,17.0,17.5,18.0,18.5/)
divres@tmYLLabels = (/"16.0","16.5","17.0","17.5","18.0","18.5"/)
divres@tmYLMinorValues = fspan(16,18.5,26)
divres@tmYLPrecision = 1
;divres@gsnMaximize = True
divres@trYMinF = 12.
divres@cnMinLevelValF = -50.
divres@cnMaxLevelValF = 50.
divres@cnLevelSpacingF = 2.
divres@cnLinesOn = True
divres@lbLabelBarOn = True
divres@lbOrientation = "Vertical"
hatch_plot = gsn_csm_contour(divwks,missingpts_rad_v,hatch_res_v)
div_img    = gsn_csm_contour(divwks,plotdiv,divres)
overlay(div_img,hatch_plot)

;POTENTIAL TEMPERATURE ADVECTION
advwks = gsn_open_wks("png",outdir+"adv"+out_suffix)
advres = divres
advres@gsnLeftString = "Radial advection of Potential Temperature (K/h)"
advres@cnMinLevelValF = -2.
advres@cnMaxLevelValF = 2.
advres@cnLevelSpacingF = 0.1
hatch_plot = gsn_csm_contour(advwks,missingpts_theta_adv,hatch_res_v)
adv_img    = gsn_csm_contour(advwks,plottheta_adv,advres)
overlay(adv_img,hatch_plot)

;STATIC STABILITY
wks_stab = gsn_open_wks("png",outdir+"stab+cp_trop_hght"+out_suffix)
gsn_define_colormap(wks_stab,"WhiteGreen")
delete([/res@cnMinLevelValF,res@cnMaxLevelValF,res@cnLevelSpacingF/])
stabres = dtres
stabres@cnLevelSelectionMode = "ManualLevels"
stabres@cnMinLevelValF = 0
stabres@cnMaxLevelValF = 10.0
stabres@cnLevelSpacingF = 1.0
stabres@cnLineLabelsOn = False
stabres@cnLinesOn = False
stabres@tiMainString = "Brunt-Vaisala Frequency Squared (10~S~-4~N~ s~S~-2~N~) and Cold Point Height"
stabres@gsnRightString = "N~S~2~N~ (10~S~-4~N~ s~S~-2~N~)"
stabres@tiYAxisOn = False
if(date.eq."20151002".or.date.eq."20151021")then
   stabres@tiYAxisString = "Height (km)"
   stabres@gsnLeftString = "e)"
   stabres@gsnLeftString = "e) 21 October 1952-2009 UTC"
else
   if(date.eq."20151003".or.date.eq."20151022")then
      if(transect.eq."transect1")then
         stabres@gsnLeftString = "f)"
         stabres@gsnLeftString = "f) 22 October 1815-1827 UTC"
      else
         stabres@gsnLeftString = "g)"
         stabres@gsnLeftString = "g) 22 October 1857-1913 UTC"
      end if
   else if (date.eq."20151004".or.date.eq."20151023")then
      stabres@gsnLeftString = "h)"
      stabres@gsnLeftString = "h) 23 October 1957-2012 UTC"
   end if
   end if
end if
stab_img = gsn_csm_contour(wks_stab,plotn2,stabres)
tropres = True
tropres_interp = tropres
tropres_interp@gsLineDashPattern = 15
tropres@gsLineColor = "yellow"
hatch_plot = gsn_csm_contour(wks_stab,missingpts_plotn2,hatch_res)
trophghts        = gsn_add_polyline(wks_stab,stab_img,dropxcoords,trop_z,tropres)
overlay(stab_img,hatch_plot)

;;COLD POINT TEMPERATURE VS. R
;wks_cptemp = gsn_open_wks("png",outdir+"cold_point_temp"+out_suffix)
;xyres = True
;xyres@gsnMaximize = True
;xyres@gsnDraw = False
;xyres@gsnFrame = False
;xyres@xyDashPattern = 15 
;xyres@tiMainString = "Cold Point Temperature   "+str_capital(storm)+"  "+date+"  "+transect
;if(type.eq.0)then
;   res@tiXAxisString = "Distance along flight track (km)"
;else if(type.eq.1)then
;   res@tiXAxisString = "Distance from storm center (km)"
;end if
;end if
;xyres@tiYAxisString = "Temperature (C)"
;xyres@tiMainFontHeightF = 0.02
;xyres@tiXAxisFontHeightF = 0.02
;xyres@tiYAxisFontHeightF = 0.02
;xyres@trYMinF = -85.
;xyres@trYMaxF = -65.
;xyres@xyLineColor = "red"
;xyres@xyLineThicknessF = 10
;xyres@tmXTOn = False
;xyres@tmYROn = False
;xyres@tmYMajorGrid = True
;xyres@tmYMajorGridLineColor = "gray"
;xyres@tmYMajorGridLineDashPattern = 1
;xyres@tmXMajorGrid = True
;xyres@tmXMajorGridLineColor = xyres@tmYMajorGridLineColor
;xyres@tmXMajorGridLineDashPattern = xyres@tmYMajorGridLineDashPattern
;xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
;xyres_noint@xyDashPattern = 0
;cp_temp_plot     = gsn_csm_xy(wks_cptemp,dropdistances,cp_temp,xyres_noint)
;draw(cp_temp_plot)
;frame(wks_cptemp)
;
;;COLD POINT HEIGHT VS. R
;wks_cpz = gsn_open_wks("png",outdir+"cold_point_height"+out_suffix)
;xyres@tiMainString = "Cold Point Height   "+str_capital(storm)+"  "+date+"  "+transect
;xyres@tiYAxisString = "Height (km)"
;xyres@trYMinF = 12.
;xyres@trYMaxF = 18.5
;xyres@xyLineColor = "black"
;xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
;xyres_noint@xyDashPattern = 0
;cp_hght_plot     = gsn_csm_xy(wks_cpz,dropdistances,trop_z,xyres_noint)
;draw(cp_hght_plot)
;frame(wks_cpz)
;
;;COLD POINT POTENTIAL TEMPERATURE VS. R
;wks_cptheta = gsn_open_wks("png",outdir+"cold_point_theta"+out_suffix)
;xyres@tiMainString = "Cold Point Potential Temperature   "+str_capital(storm)+"  "+date+"  "+transect
;xyres@tiYAxisString = "Potential Temperature (K)"
;xyres@trYMinF = 350.
;xyres@trYMaxF = 450.
;xyres@xyLineColor = "orange"
;xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
;xyres_noint@xyDashPattern = 0
;cp_theta_plot     = gsn_csm_xy(wks_cptheta,dropdistances,cp_theta,xyres_noint)
;draw(cp_theta_plot)
;frame(wks_cptheta)
;
;;PRESSURE AT THE COLD POINT
;wks_cppres = gsn_open_wks("png",outdir+"cold_point_pres"+out_suffix)
;xyres@tiMainString = "Pressure at the cold point   "+str_capital(storm)+"  "+date+"  "+transect
;xyres@tiYAxisString = "Pressure (mb)"
;xyres@trYMinF = 50.
;xyres@trYMaxF = 150.
;xyres@trYReverse = True
;xyres@xyYStyle = "Log"
;xyres@xyLineColor = "blue"
;xyres@tmYLMode = "Explicit"
;xyres@tmYLValues = (/50,60,70,80,90,100,110,120,130,140,150/)
;xyres@tmYLLabels = tostring(xyres@tmYLValues)
;xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
;xyres_noint@xyDashPattern = 0
;cp_pres_plot     = gsn_csm_xy(wks_cppres,dropdist(:,0),cp_pres,xyres_noint)
;draw(cp_pres_plot)
;frame(wks_cppres)

;OVERLAY LINE THAT REPRESENTS THE MAXIMUM BL THETA-E CONTOUR IN THE UPPER
;TROPOSPHERE (ROUGHLY SHOWS HOW HIGH SUFACE-BASED CONVECTION CAN REACH)
;AS OF 8 DEC 2016, JOHN M. AND I DECIDED TO REMOVE THIS FROM PAPER
;thetalineres = True
;thetalineres@gsLineThicknessF = 9.
;thetalineres@gsLineDashPattern = 14.
;thetaline = gsn_add_polyline(wks_theta,theta_img,dropdistances,maxblthetaey,thetalineres)

;OVERLAY LINES AND LABEL THAT REPRESENT DROP LOCATIONS ON EACH PLOT
;AND THEN DRAW ALL OF THE PLOTS
miny = min(res@tmYLValues)
maxy = max(res@tmYLValues) 
labelx = new(floattoint(ceil(dimsizes(droplocs)/2.)),"float")
labely = labelx
labely = miny+0.11
labely16 = 16.04
vlabely = miny+0.11
vlabely16 = 16.04
;labely = miny+0.03
lines  = new(nfiles+100,"graphic")
j=0
do i=0,dimsizes(droplocs)-1
   if(i.eq.0.or.mod(i,2).eq.0)then   ;We will only make labels for every other sonde loc
      labelx(j) = droplocs(i)
      j=j+1
   end if
;   linex = dropxcoords(i,:)
;   liney = dropxcoords&height
;   lineres = True
;   lineres@gsLineColor = "red"
;   lineres@gsLineThicknessF = 5.
;   line := gsn_add_polyline(wks_tempc,tempc_img,linex,liney,lineres)
;   if(dimsizes(line).eq.1)then
;      lines(i) = line
;   else
;      nk = dimsizes(line)
;      do k=0,nk-1
;         lines(i+k) = line(k) 
;      end do
;   end if
end do

;Add vertical lines at x=0
zerolineres = True
zerolineres@gsLineDashPattern = 16
zerolineres@gsLineThicknessF = 6.

;zeroline_thetae   = gsn_add_polyline(wks_thetae,thetae_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
zeroline_theta    = gsn_add_polyline(wks_theta,theta_img,(/0,0/),(/miny,maxy/),zerolineres)
zeroline_tempc    = gsn_add_polyline(wks_tempc,tempc_img,(/0,0/),(/miny,maxy/),zerolineres)
zeroline_stab_img = gsn_add_polyline(wks_stab,stab_img,(/0,0/),(/  miny,maxy/),zerolineres)
zeroline_dtdz_img = gsn_add_polyline(dtdzwks,dtdz_img,(/0,0/),(/   miny,maxy/),zerolineres)
;zeroline_merid_v  = gsn_add_polyline(wks,merid_v_img,(/0,0/),(/   miny,maxy/),zerolineres)
zeroline_tan_v  = gsn_add_polyline(tanvwks,tan_v_img,(/0,0/),(/    miny,maxy/),zerolineres)
zeroline_rad_v  = gsn_add_polyline(radvwks,rad_v_img,(/0,0/),(/    miny,maxy/),zerolineres)
zeroline_div    = gsn_add_polyline(divwks,div_img,(/0,0/),(/       miny,maxy/),zerolineres)
zeroline_adv    = gsn_add_polyline(advwks,adv_img,(/0,0/),(/       miny,maxy/),zerolineres)
zeroline_gravwav= gsn_add_polyline(wks_gravwave,gravwave_img,(/0,0/),(/miny,maxy/),zerolineres)

;Overlay digits that represent drop locations
text = tostring(ispan(1,nfiles,2))   ;Only make a label for every other sonde location
txres = True
txres@txFont = 30
txres@txFontHeightF = 0.015
txres@txFontColor = "black"

;dum = gsn_add_text(wks_thetae,thetae_img,text,labelx,labely,txres)
dum = gsn_add_text(wks_theta,theta_img,text,labelx,labely16,txres)
dum = gsn_add_text(wks_tempc,tempc_img,text,labelx,labely16,txres)
dum = gsn_add_text(wks_stab,stab_img,text,labelx,labely16,txres)
dum = gsn_add_text(dtdzwks,dtdz_img,text,labelx,labely16,txres)
;dum = gsn_add_text(wks,merid_v_img,text,labelx,labely,txres)
dum = gsn_add_text(preswks,presplot,text,labelx,labely16,txres)
dum = gsn_add_text(radvwks,rad_v_img,text,labelx,vlabely16,txres)
dum = gsn_add_text(tanvwks,tan_v_img,text,labelx,vlabely16,txres)
dum = gsn_add_text(divwks,div_img,text,labelx,vlabely16,txres)
dum = gsn_add_text(advwks,adv_img,text,labelx,vlabely16,txres)
dum = gsn_add_text(wks_gravwave,gravwave_img,text,labelx,labely16,txres)

;Draw all of the plots
;draw(thetae_img)
draw(theta_img)
draw(tempc_img)
draw(stab_img)
;draw(merid_v_img)
draw(rad_v_img)
draw(tan_v_img)
draw(div_img)
draw(adv_img)
draw(dtdz_img)
;draw(presplot)
;frame(wks_thetae)
frame(wks_theta)
frame(wks_tempc)
frame(wks_stab)
;frame(wks)          ;Corresponds to meridional velocity
;frame(preswks)
frame(radvwks)
frame(tanvwks)
frame(divwks)
frame(advwks)
frame(dtdzwks)

draw(gravwave_img)
frame(wks_gravwave)

;LOOP THROUGH ALL HEIGHTS AND GET THE MINIMUM PRESSURE AT EACH LEVEL
;printVarSummary(plotpres)
;pmin_inds = new(nlevels,"float")
;do j=0,nlevels-1
;   pmin_inds(j) = minind(plotpres(j,:))
;end do
;print(pmin_inds)
