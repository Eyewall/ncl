load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;NOTE: Distances from the storm center are defined such that if
;      the dropsonde location was north of the storm center,
;      the distance is negative, and south of the storm center,
;      the distance is positive.

storm    = "patricia"
date     = "20151021"
transect = "transect1"
minhght  = 9000
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
type     = 1   ;Plot as total distance from start of flight let (0) or
               ;distance from storm center (1)?
assumerh = 1   ;Assume a constant RH for the whole profile? 0=no, 1=yes
rhconst  = 90  ;Relative humidity to be used in thetae calculation

;STORM CENTER LOCATIONS
if(date.eq."20151021")then
   if(transect.eq."transect1")
      centerlat = 13.41
      centerlon = -99.34
      centersonde = 6
   else
      centerlat = 13.03
      centerlon = -99.62
      centersonde = 2
   end if
else if(date.eq."20151022")then
   centerlat = 15.13
   centerlon = -104.18
   centersonde = 13
else if(date.eq."20151023")then
   centerlat = 18.58
   centerlon = -105.20
   centersonde = 13
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

;Read input files
infiles = sondedir+systemfunc("cat "+listfile)
nfiles  = dimsizes(infiles)
p   = new((/nfiles,nlevels/),"float")
p!0 = "radius"
p!1 = "height"
p@_FillValue = -9999.
tc   = p
td   = p
u    = p
v    = p
hght = p
rh   = p
lat  = p
lon  = p
do i=0,nfiles-1
   unixi = i+1
   print("Processing sonde "+unixi+" of "+nfiles)

   ;Read input file and assign variables
   data   := readAsciiTable(infiles(i),10,"float",7) 
   data@_FillValue = -9999.0
   data!0 = "height"
   nhghts = dimsizes(data(:,5))
   p   (i,:nhghts-1) = data(:,0)
   tc  (i,:nhghts-1) = data(:,1)
   td  (i,:nhghts-1) = data(:,2)
   u   (i,:nhghts-1) = data(:,3)
   v   (i,:nhghts-1) = data(:,4)
   hght(i,:nhghts-1) = data(:,5)
   rh  (i,:nhghts-1) = data(:,6)
   lat (i,:nhghts-1) = data(:,7)
   lon (i,:nhghts-1) = data(:,8)
end do

;Compute distances from storm center at each level
;gc_latlon doesn't check for missing values, so we'll just perform a
;quick fix by setting all distances greater than 2000 km to missing
distances = gc_latlon(centerlat,centerlon,lat,lon,2,4)
distances@_FillValue = -9999.
;distances!1 = "height"
;distances&height = fspan(0,maxhght,nlevels)
distances = where(distances.gt.2000,distances@_FillValue,distances)

;If latitude is greater than the center latitude, we define
;the distance to be negative.
distances = where(lat.gt.centerlat,distances*-1,distances)

;Perform the interpolation to the fixed horizontal grid
nradii = 61
p_int  = new((/nradii,nlevels/),"float")
p_int@_FillValue = -9999.
tc_int = p_int
td_int = p_int
u_int  = p_int
v_int  = p_int
rh_int = p_int
lat_int = p_int
lon_int = p_int
radii  = fspan(-150,150,nradii)  ;The coordinate system we're interpolating to

;Loop through each height and interpolate to the fixed horizontal grid
print("NOTE: Monotonicity will fail near the top of the dataset"\
             +" (around 18.5 km for TCI sondes) because missing"\
             +" values start to appear.")
minhghtind = minhght/dz
do i=minhghtind,nlevels-1
   print("Processing level "+i+" of "+nlevels)
   ;Following the convention presented in the NCL documentation
   ;for the linint1 function:
   xo = radii
   fi = p(:,i)
   xi = distances(:,i)
   qsort(xi)   ;xi needs to be monotonically increasing

   ;The following loop checks for repeating values, and adds a very small number
   ;(1 centimeter) to the repeated value to make the array monotonically increasing.
   do j=1,dimsizes(xi)-1
      if(.not.ismissing(xi(j)).and..not.ismissing(xi(j-1)).and.xi(j).le.xi(j-1))then
         xi(j) = xi(j-1)+0.00001
      end if
   end do

   ;If the radial coordinate (xi) is missing, we set fi to missing at the spot.
   ;Need to do this because linint1 does not check for missing values in xi
   missinginds := ind(ismissing(xi))
   if(.not.all(ismissing(missinginds)))
      fi(missinginds) = fi@_FillValue
   end if


   ;Perform the interpolation.
   if(.not.all(ismissing(xi)))then
      ;Pressire
      p_int(:,i) = linint1(xi,fi,False,xo,0)

      ;Temperature
      fi  = tc(:,i)
      if(.not.all(ismissing(missinginds)))
         fi(missinginds) = fi@_FillValue
      end if
      tc_int(:,i)  = linint1(xi,fi,False,xo,0)

      ;Dew point
      fi  = td(:,i)
      if(.not.all(ismissing(missinginds)))
         fi(missinginds) = fi@_FillValue
      end if
      td_int(:,i)  = linint1(xi,fi,False,xo,0)

      ;Zonal velocity
      fi  = u(:,i)
      if(.not.all(ismissing(missinginds)))
         fi(missinginds) = fi@_FillValue
      end if
      u_int(:,i)   = linint1(xi,fi,False,xo,0)

      ;Meridional velocity
      fi = v(:,i)
      if(.not.all(ismissing(missinginds)))
         fi(missinginds) = fi@_FillValue
      end if
      v_int(:,i)   = linint1(xi,fi,False,xo,0)

      ;Relative humidity
      fi = rh(:,i)
      if(.not.all(ismissing(missinginds)))
         fi(missinginds) = fi@_FillValue
      end if
      rh_int(:,i)  = linint1(xi,fi,False,xo,0)

      ;Latitude
      fi = lat(:,i)
      if(.not.all(ismissing(missinginds)))
         fi(missinginds) = fi@_FillValue
      end if
      lat_int(:,i) = linint1(xi,fi,False,xo,0)

      ;Longitude
      fi = lon(:,i)
      if(.not.all(ismissing(missinginds)))
         fi(missinginds) = fi@_FillValue
      end if
      lon_int(:,i) = linint1(xi,fi,False,xo,0)

   end if
end do
p_int!0     = "radii"
p_int!1     = "height"
p_int&radii = radii
p_int&height= fspan(0,maxhght,nlevels)
copy_VarMeta(p_int,tc_int)
print(tc_int)
