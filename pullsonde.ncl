;---------------------------------------------
; pullsonde.ncl
; Patrick Duran
; 01 February 2017
; 
; Pulls data from a list of dropsonde or rawinsonde
; files and writes to a single netCDF file.
;
; 03 February 2017: Added cold point tropopause to output
;---------------------------------------------

type     = "rawinsonde"
maxrad   = 1000  ;Maximum radius from TCs within which to search for sondes
dz       = 100   ;Vertical spacing of sounding data
listfile = "/nfs/jm13/pduran/hurricanesondes/rawinsondes_0-"+maxrad+"km"
;listfile = "/nfs/jm13/pduran/hurricanesondes/test"
outfile  = "/nfs/jm13/pduran/rawinsondes/sparc/rawinsondes_0-"+maxrad+"km.nc"
gridsatdir = "/nfs/molinarilab_rit/pduran/gridsat/all/"

;-----------------------------;
;Get information from listfile;
;-----------------------------;
print( "Pulling information from listfile...  "+systemfunc("date"))
dropfiles = systemfunc("awk '{print $1}' "+listfile)
;stormyear = systemfunc("awk '{print $2}' "+listfile)
;stormmon  = systemfunc("awk '{print $3}' "+listfile)
;stormday  = systemfunc("awk '{print $4}' "+listfile)
;stormhour = systemfunc("awk '{print $5}' "+listfile)
;stormminu = systemfunc("awk '{print $6}' "+listfile)
stormtype = stringtoint(systemfunc("awk '{print $7}' "+listfile))
stormlat  = stringtofloat(systemfunc("awk '{print $8}' "+listfile))
stormlon  = stringtofloat(systemfunc("awk '{print $9}' "+listfile))
vmax      = stringtoint(systemfunc("awk '{print $10}' "+listfile))
pmin      = stringtoint(systemfunc("awk '{print $11}' "+listfile))
radius    = stringtofloat(systemfunc("awk '{print $12}' "+listfile))
azimuth   = stringtofloat(systemfunc("awk '{print $13}' "+listfile))
stormid   = stringtochar(systemfunc("awk '{print $14}' "+listfile))
stormname = stringtochar(systemfunc("awk '{print $15}' "+listfile))
ndropfiles= dimsizes(dropfiles)

;----------------------------------------;
;Pull data from each individual drop file;
;----------------------------------------;
;Initialize arrays
z        = ispan(0,40000,dz)
nz       = dimsizes(z)
dattim   = new(ndropfiles,"string")
droplat  = new(ndropfiles,"float")
droplon  = new(ndropfiles,"float")
p        = new((/ndropfiles,nz/),"float")
t        = new((/ndropfiles,nz/),"float")
td       = new((/ndropfiles,nz/),"float")
u        = new((/ndropfiles,nz/),"float")
v        = new((/ndropfiles,nz/),"float")
rh       = new((/ndropfiles,nz/),"float")
sondelat = new((/ndropfiles,nz/),"float")
sondelon = new((/ndropfiles,nz/),"float")
cpt      = new(ndropfiles,"float")
cpz      = new(ndropfiles,"float")
maxhght  = new(ndropfiles,"float")
 
;Loop through all sonde files
do i=0,ndropfiles-1
   unixi = i + 1
   print( "Processing sonde "+unixi+" of "+ndropfiles+" for "+listfile+"   "+systemfunc("date"))
   dropfile = dropfiles(i)
   nlines = stringtoint(systemfunc("wc "+dropfile+" | awk '{print $1}'"))
   if(nlines.gt.7)then
      dattim(i)  = systemfunc("grep 'STID =' "+dropfile+" | awk '{print $9}'")
      droplat(i) = stringtofloat(systemfunc("grep 'SLAT =' "+dropfile+" | awk '{print $3}'"))
      droplon(i) = stringtofloat(systemfunc("grep 'SLAT =' "+dropfile+" | awk '{print $6}'"))
      data := readAsciiTable(dropfile,10,"float",7)
      data@_FillValue = -9999.
      ndims = dimsizes(data)
      nrecs = ndims(0)
      p       (i,:nrecs-1) = data(:,0)
      t       (i,:nrecs-1) = data(:,1)
      td      (i,:nrecs-1) = data(:,2)
      u       (i,:nrecs-1) = data(:,3)
      v       (i,:nrecs-1) = data(:,4)
      rh      (i,:nrecs-1) = data(:,6)
      sondelat(i,:nrecs-1) = data(:,7)
      sondelon(i,:nrecs-1) = data(:,8)
      if(.not.all(ismissing(t(i,:))))then
         cpt(i) = t(i,minind(t(i,:)))
         cpz(i) = z(minind(t(i,:)))
         maxhght(i) = z(max(ind(.not.ismissing(t(i,:)))))
      end if
   end if
end do

;Get droptime in Julian format
dattim_split = str_split_csv(dattim,"/",0)
date = dattim_split(:,0)
time = dattim_split(:,1)
yymmdddrop := str_split_by_length(date,2)
hhmmdrop   := str_split_by_length(time,2)
dropyear = yymmdddrop(:,0)
dropmon  = yymmdddrop(:,1)
dropday  = yymmdddrop(:,2)
drophour = hhmmdrop(:,0)
dropminu = hhmmdrop(:,1)
dropsec  = dropminu
dropsec  = 0
dropyear = where(toint(dropyear).lt.60,"20"+dropyear,"19"+dropyear)
droptime = cd_inv_calendar(stringtoint(dropyear),stringtoint(dropmon),stringtoint(dropday),stringtoint(drophour),\
                           stringtoint(dropminu),stringtoint(dropsec),"seconds since 1800-1-1 00:00:00",0)

;Get IR brightness temperatures from GRIDSAT
print( "Getting Gridsat times... "+systemfunc("date"))
satfilenames = systemfunc("ls "+gridsatdir)
satfilenamesplit = str_split_csv(satfilenames,".",3)
satyear = toint(satfilenamesplit(:,1))
satmon  = toint(satfilenamesplit(:,2))
satday  = toint(satfilenamesplit(:,3))
sathour = toint(satfilenamesplit(:,4))
satminu = sathour
satsec  = sathour
satminu = 0
satsec  = 0
sattime = cd_inv_calendar(satyear,satmon,satday,sathour,satminu,satsec,"seconds since 1800-1-1 00:00:00",0)
;Loop through each dropsonde and get the
;corresponding Gridsat IR brightness temperature
irbt = new(dimsizes(droptime),"float")
do i=0,ndropfiles-1
   unixi = i + 1
   print( "Getting Gridsat IR brightness temperature for dropfile "+unixi+" of "+ndropfiles+" "+systemfunc("date"))
   ;Get satellite time closest to sonde time
   diffs = abs(sattime-droptime(i))
   satind = minind(diffs)
   satfilename = satfilenames(satind)
   ;Read variabiles from satfile
   satfile = addfile(gridsatdir+satfilename,"r")
   ir  := satfile->irwin_cdr
   lat := satfile->lat
   lon := satfile->lon
   ;Get closest IR point to sonde location
   lats := onedtond(lat,(/dimsizes(lat),dimsizes(lon)/)) 
   lons := onedtond(lon,(/dimsizes(lat),dimsizes(lon)/)) 
   distances := gc_latlon(droplat(i),droplon(i),lats,lons,2,4)
   latsoned  := ndtooned(lats)
   lonsoned  := ndtooned(lons)
   mindistind:= minind(ndtooned(distances))
   satlat := latsoned(mindistind)
   satlon := lonsoned(mindistind)
   irbt(i)= ir(0,{satlat},{satlon})*ir@scale_factor+ir@add_offset-273.15
   print( irbt(i))
end do
;Assign coordinate variables to arrays
droptime!0 = "dropfiles"
copy_VarCoords(droptime,droplat)
copy_VarCoords(droptime,droplon)
copy_VarCoords(droptime,radius)
copy_VarCoords(droptime,azimuth)
copy_VarCoords(droptime,stormtype)
copy_VarCoords(droptime,stormlat)
copy_VarCoords(droptime,stormlon)
copy_VarCoords(droptime,vmax)
copy_VarCoords(droptime,pmin)
copy_VarCoords(droptime,cpt)
copy_VarCoords(droptime,cpz)
copy_VarCoords(droptime,maxhght)
copy_VarCoords(droptime,irbt)
p!0 = "dropfiles"
p!1 = "height"
p&height    = z
copy_VarCoords(p,t)
copy_VarCoords(p,td)
copy_VarCoords(p,u)
copy_VarCoords(p,v)
copy_VarCoords(p,rh)
copy_VarCoords(p,sondelat)
copy_VarCoords(p,sondelon)
stormid!0 = "dropfiles"
stormid!1 = "ncharid"
stormname!0 = "dropfiles"
stormname!1 = "ncharnm"

;Assign attributes to arrays
droptime@long_name = "time of sonde deployment"
z@long_name = "height above sea level"
z@units = "m"
z@_FillValue = -9999
droplat@long_name = "sonde deployment latitude"
droplat@units = "degrees north"
droplat@_FillValue = -9999
droplon@long_name = "sonde deployment longitude"
droplon@units = "degrees east"
droplon@_FillValue = -9999
radius@long_name = "distance from the nearest TC storm center from HURDAT"
radius@units = "km"
radius@_FillValue = -9999
azimuth@long_name = "azimuth (clockwise from north) from the nearest TC storm center from HURDAT"
azimuth@units = "degrees"
azimuth@_FillValue = -9999
stormid@long_name = "IBTrACS storm serial number"
stormname@long_name = "storm name"
cpt@long_name = "coldest temperature in sounding"
cpt@units = "degrees Celsius"
cpt@_FillValue = -9999
cpz@long_name = "height of coldest temperature in sounding"
cpz@units = "m"
maxhght@long_name = "height of highest temperature observation"
maxhght@units = "m"
maxhght@_FillValue = -9999
irbt@long_name = "Gridsat NOAA FCDR of Brightness Temperature near 11 microns"
irbt@units = "degrees Celsius"
p@long_name = "pressure"
p@units = "hPa"
p@_FillValue = -9999
t@long_name = "temperature"
t@units = "degrees Celsius"
t@_FillValue = -9999
td@long_name = "dew point temperature"
td@units = "degrees Celsius"
td@_FillValue = -9999
u@long_name = "zonal wind"
u@units = "m/s"
u@_FillValue = -9999
v@long_name = "meridional wind"
v@units = "m/s"
v@_FillValue = -9999
rh@long_name = "relative humidity"
rh@units = "percent"
rh@_FillValue = -9999
sondelat@long_name = "sonde latitude"
sondelat@units = "degrees north"
sondelat@_FillValue = -9999
sondelon@long_name = "sonde longitude"
sondelon@units = "degrees east"
sondelon@_FillValue = -9999
stormtype@long_name = "storm type"
stormtype@key = "0=Tropical,1=Subtropical,2=Extratropical,3=Disturbance,4=Conflicting Reports,5=Not Reported,6=Missing"
stormtype@_FillValue = 7
stormlat@long_name = "latitude of the nearest TC storm center from HURDAT"
stormlat@units = "degrees north"
stormlat@_FillValue = -9999
stormlon@long_name = "longitude of nearest TC storm center from HURDAT"
stormlon@units = "degrees east"
stormlon@_FillValue = -9999
vmax@long_name = "maximum sustained wind speed of nearest TC from HURDAT"
vmax@units = "kt"
vmax@_FillValue = -9999
pmin@long_name = "minimum central pressure of nearest TC from HURDAT"
pmin@units = "hPa"
pmin@_FillValue = -9999

;Write to output file
print( "Writing arrays to output file "+outfile)
system("/bin/rm -f "+outfile)
fout = addfile(outfile,"c")
setfileoption(fout,"DefineMode",True)

;Define global attributes
fileatts = True
fileatts@description = "Created by /jm13/pduran/ncl/pullsonde.ncl. Contains "+type+" data for all sondes deployed within "+maxrad+"km of tropical cyclones in the Atlantic basin, using sonde lists produced by /jm13/pduran/ncl/sounding-sort.ncl."
fileattdef(fout,fileatts)

;Define variable attributes
dimNames = (/"dropfiles","height","ncharid","ncharnm"/)
dimSizes = (/dimsizes(dropfiles),dimsizes(z),dimsizes(stormid(0,:)),dimsizes(stormname(0,:))/)
dimUnlim = (/False,False,False,False/)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout,"droptime",typeof(droptime),getvardims(droptime))
filevardef(fout,"droplat",typeof(droplat),getvardims(droplat))
filevardef(fout,"droplon",typeof(droplon),getvardims(droplon))
filevardef(fout,"height",typeof(z),getvardims(p&height))
filevardef(fout,"cpt",typeof(cpt),getvardims(cpt))
filevardef(fout,"cpz",typeof(cpz),getvardims(cpz))
filevardef(fout,"maxhght",typeof(maxhght),getvardims(maxhght))
filevardef(fout,"irbt",typeof(irbt),getvardims(irbt))
filevardef(fout,"p",typeof(p),getvardims(p))
filevardef(fout,"t",typeof(t),getvardims(t))
filevardef(fout,"td",typeof(td),getvardims(td))
filevardef(fout,"u",typeof(u),getvardims(u))
filevardef(fout,"v",typeof(v),getvardims(v))
filevardef(fout,"rh",typeof(rh),getvardims(rh))
filevardef(fout,"sondelat",typeof(sondelat),getvardims(sondelat))
filevardef(fout,"sondelon",typeof(sondelon),getvardims(sondelon))
filevardef(fout,"radius",typeof(radius),getvardims(radius))
filevardef(fout,"azimuth",typeof(azimuth),getvardims(azimuth))
filevardef(fout,"stormid",typeof(stormid),getvardims(stormid))
filevardef(fout,"stormname",typeof(stormname),getvardims(stormname))
filevardef(fout,"stormtype",typeof(stormtype),getvardims(stormtype))
filevardef(fout,"stormlat",typeof(stormlat),getvardims(stormlat))
filevardef(fout,"stormlon",typeof(stormlon),getvardims(stormlon))
filevardef(fout,"vmax",typeof(vmax),getvardims(vmax))
filevardef(fout,"pmin",typeof(pmin),getvardims(pmin))

filevarattdef(fout,"droptime",droptime)
filevarattdef(fout,"droplat",droplat)
filevarattdef(fout,"droplon",droplon)
filevarattdef(fout,"height",z)
filevarattdef(fout,"cpt",cpt)
filevarattdef(fout,"cpz",cpz)
filevarattdef(fout,"maxhght",maxhght)
filevarattdef(fout,"irbt",irbt)
filevarattdef(fout,"p",p)
filevarattdef(fout,"t",t)
filevarattdef(fout,"td",td)
filevarattdef(fout,"u",u)
filevarattdef(fout,"v",v)
filevarattdef(fout,"rh",rh)
filevarattdef(fout,"sondelat",sondelat)
filevarattdef(fout,"sondelon",sondelon)
filevarattdef(fout,"radius",radius)
filevarattdef(fout,"azimuth",azimuth)
filevarattdef(fout,"stormid",stormid)
filevarattdef(fout,"stormname",stormname)
filevarattdef(fout,"stormtype",stormtype)
filevarattdef(fout,"stormlat",stormlat)
filevarattdef(fout,"stormlon",stormlon)
filevarattdef(fout,"vmax",vmax)
filevarattdef(fout,"pmin",pmin)

;Write to the NetCDF file
;NOTE: The (/xxx/) syntax here tells NCL to output only the data
;values to the predefined locations in the file. This greatly
;inproves the efficiency of the writing routine.
fout->height   = (/z/)
fout->droptime = (/droptime/)
fout->droplat  = (/droplat/)
fout->droplon  = (/droplon/)
fout->radius   = (/radius/)
fout->azimuth  = (/azimuth/)
fout->stormid  = (/stormid/)
fout->stormname= (/stormname/)
fout->cpt      = (/cpt/)
fout->cpz      = (/cpz/)
fout->maxhght  = (/maxhght/)
fout->irbt     = (/irbt/)
fout->p        = (/p/)
fout->t        = (/t/)
fout->td       = (/td/)
fout->u        = (/u/)
fout->v        = (/v/)
fout->rh       = (/rh/)
fout->sondelat = (/sondelat/)
fout->sondelon = (/sondelon/)
fout->stormtype = (/stormtype/)
fout->stormlat = (/stormlat/)
fout->stormlon = (/stormlon/)
fout->vmax     = (/vmax/)
fout->pmin     = (/pmin/)
