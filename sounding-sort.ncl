;------------------------------------------------
; sounding-sort.ncl
; Patrick Duran
; 31 January 2017
; 
; Reads in a series of sounding files from an
; input directory and determines whether the
; sonde was deployed within 3 hours of a TC
; in the HURDAT database. If so, determines
; if it was deployed within a user-defined
; maximum radius and prints output to a single
; output file for each radial band.

;HURDAT file format:
;19490611,0000,TS,20.2,N,106.3,W,45,-999
;19490611,0600,TS,20.2,N,106.4,W,45,-999
;19490611,1200,TS,20.2,N,106.7,W,45,-999
;19490611,1800,TS,20.3,N,107.7,W,45,-999
;19490612,0000,TS,20.4,N,108.6,W,45,-999
;19490612,0600,TS,20.5,N,109.4,W,45,-999
;...
;...

;Output file format:
;Sondefilename HURDATyear HURDATmonth HURDATday HURDAThour HURDATminu HURDATcategory HURDATlat HURDATlon HURDATvmax HURDATpmin radius(distance between sonde and nearest TC storm center) azimuth(from sonde to TC; clockwise from north)

;--------------
;03 April 2017
;Added option to use ibtracks file instead of hurdat
;--------------

;------------------------------------------------

bttype = 1  ;0=HURDAT ascii file; 1=IBTrACS netcdf file
hurdatfile = "/nfs/jm13/pduran/best-tracks/ATL+EPAC-1851-2016.txt"
ibtracsfile= "/nfs/jm13/pduran/best-tracks/Allstorms.ibtracs_all.v03r10.nc"
type       = "eol"  ;"eol" or "edit"
dropdir    = "/nfs/jm13/pduran/dropsondes/hs3/eol/allsondes/"
;dropdir    = "/nfs/jm13/pduran/rawinsondes/sparc/allsondes/"
;dropdir    = "/nfs/jm13/pduran/rawinsondes/sparc/test2/"
minrad     = 0     ;Minimum radius within which to search (km)
maxrad     = 1000  ;Maximum radius within which to search (km)
deltarad   = 100   ;Spacing of radii (km)
outdir     = "/jm13/pduran/hurricanesondes/"
radtodeg   = 360/(2*3.141592)

;----------------;
;Read HURDAT file;
;----------------;
if(bttype.eq.0)then
   print( "Reading HURDAT file "+hurdatfile)
   inputlines = readAsciiTable(hurdatfile,1,"string",0)
   hurdatlines= inputlines(:,0)
   hurdat   = str_split_csv(hurdatlines,",",0)
   yyyymmdd = str_split_by_length(hurdat(:,0),(/4,2,2/))  ;Date
   hhmm     = str_split_by_length(hurdat(:,1),2)          ;Time
   year     = stringtoint(yyyymmdd(:,0))                  ;Year
   mon      = stringtoint(yyyymmdd(:,1))                  ;Month
   day      = stringtoint(yyyymmdd(:,2))                  ;Day
   hour     = stringtoint(hhmm(:,0))                      ;Hour
   minu     = stringtoint(hhmm(:,1))                      ;Minute
   sec      = minu
   sec      = 0
   category = hurdat(:,2)  ;Storm category
   lats     = hurdat(:,3)  ;Latitudes
   nors     = hurdat(:,4)  ;North or South?
   lons     = hurdat(:,5)  ;Longitudes
   eorw     = hurdat(:,6)  ;East or West?
   vmax     = hurdat(:,7)  ;Maximum wind (kt)
   pmin     = toint(hurdat(:,8))  ;Minimum pres (mb)
   juldate  = cd_inv_calendar(year,mon,day,hour,minu,sec,"seconds since 1800-1-1 00:00:00",0)
else  ;Read IBTrACS netcdf file
   center = 0 ;0=HURDAT Atlantic Database (see /jm13/pduran/best-tracks/NetCDF_Key_v03r04.pdf)
   print( "Reading IBTrACS file "+ibtracsfile)
   infile = addfile(ibtracsfile,"r")  
   stormnumin  = infile->storm_sn     ;IBTrACS storm serial number
   stormnamein = infile->name         ;Storm name
   categoryin  = infile->nature_for_mapping  ;Storm type
   juldatein   = infile->source_time  ;Days since 1858-11-17 00:00:00"
   latsin      = infile->source_lat   ;Storm center latitude (hundredths of a degree)
   lonsin      = infile->source_lon   ;Storm center longitude (hundredths of a degree)
   vmaxin      = infile->source_wind  ;Maximum sustained wind speed (kt)
   pminin      = infile->source_pres  ;Minimum central pressure (mb)
   ;Get strings of storm serial numbers and names
   stormnum  = tostring(stormnumin)
   stormname = tostring(stormnamein)
   ;Get only the observations from the Atlantic HURDAT
   lati = tofloat(latsin(:,:,center))
   loni = tofloat(lonsin(:,:,center))
   vmaxi = tofloat(vmaxin(:,:,center))
   pmini = tofloat(pminin(:,:,center))
   ;Multiply lats,lons,vmax,pmin by their scale factors
   latsi = lati*latsin@scale_factor 
   lonsi = loni*lonsin@scale_factor 
   vmaxi = vmaxi*vmaxin@scale_factor 
   pmini = pmini*pminin@scale_factor 
   ;Make storm number and storm name arrays the same dimension sizes as
   ;lats, lons, vmax, and pmin arrays.
   varsizes = dimsizes(latsi)
   snumi  = new(varsizes,"string")
   snamei = new(varsizes,"string")
   ;Loop through times and set storm numbers for each time
   do i=0,varsizes(1)-1
      snumi (:,i) = stormnum
      snamei(:,i) = stormname
   end do
   ;Make arrays 1-D so we can use ind functions later
   juldate = ndtooned(juldatein) 
   lat  = ndtooned(latsi) 
   lon  = ndtooned(lonsi) 
   vmax = ndtooned(vmaxi) 
   pmin = ndtooned(pmini) 
   snum = ndtooned(snumi)
   sname= ndtooned(snamei)
   category = ndtooned(categoryin)
   ;Get date and time of each IBTrACS observation
   juldate@units = juldatein@units
   datetime = tostring(toint(cd_calendar(juldate,0)))
   year = stringtoint(datetime(:,0))
   mon  = stringtoint(datetime(:,1))
   day  = stringtoint(datetime(:,2))
   hour = stringtoint(datetime(:,3))
   minu = stringtoint(datetime(:,4))
end if

if(bttype.eq.0)then
   ;---------------------------------------------;
   ;Convert lats,lons to floats and multiply lons
   ;by -1 if they're West longtiudes.
   ;---------------------------------------------;
   lat = stringtofloat(lats)
   lon = stringtofloat(lons)
   westloninds = ind(eorw.eq."W")
   lon(westloninds) = lon(westloninds)*-1.
end if

;--------------------------;
;Read dropsonde information;
;--------------------------;
print( "Reading sonde files...This could take a while...   "+systemfunc("date"))
if(type.eq."eol")then
   dropfiles = systemfunc("ls "+dropdir+"*eol")
   dropyear = systemfunc("cat "+dropdir+"*eol | grep -i 'UTC Launch Time' | awk '{print $5}' | sed 's/,//g'")
   dropmon  = systemfunc("cat "+dropdir+"*eol | grep -i 'UTC Launch Time' | awk '{print $6}' | sed 's/,//g'")
   dropday  = systemfunc("cat "+dropdir+"*eol | grep -i 'UTC Launch Time' | awk '{print $7}' | sed 's/,//g'")
   drophour = systemfunc("cat "+dropdir+"*eol | grep -i 'UTC Launch Time' | awk '{print $8}' | awk -F':' '{print $1}'")
   dropminu = systemfunc("cat "+dropdir+"*eol | grep -i 'UTC Launch Time' | awk '{print $8}' | awk -F':' '{print $2}'")
   dropsec  = systemfunc("cat "+dropdir+"*eol | grep -i 'UTC Launch Time' | awk '{print $8}' | awk -F':' '{print $3}'")
   droplonss= systemfunc("cat "+dropdir+"*eol | grep -i 'Launch Location' | awk '{print $6}' | sed 's/,//g'")
   droplatss= systemfunc("cat "+dropdir+"*eol | grep -i 'Launch Location' | awk '{print $9}' | sed 's/,//g'")
   droplats = stringtofloat(droplatss)
   droplons = stringtofloat(droplonss)
else
   dropfiles = systemfunc("find "+dropdir+" -type f -name '*edit'")
   dattim = systemfunc("find "+dropdir+" -type f -name '*edit' -exec cat {} + | grep -i 'TIME =' | awk '{print $NF}'")
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
   droplatss= systemfunc("find "+dropdir+" -type f -name '*edit' -exec cat {} + | grep -i 'SLAT =' | awk '{print $3}'")
   droplonss= systemfunc("find "+dropdir+" -type f -name '*edit' -exec cat {} + | grep -i 'SLAT =' | awk '{print $6}'")
   ;Some dropsonde files have NaNs for latitudes.
   ;This causes "SLON" to be read as the latitude.
   ;Replace all occurrences of SLON with missing values.
   ;Do the same for SLAT=B.
   droplatss@_FillValue = "-9999"
   droplonss@_FillValue = "-9999"
   droplatss = where(droplatss.eq."SLON",droplatss@_FillValue,droplatss)
   droplonss = where(droplonss.eq."B",droplonss@_FillValue,droplonss)
   droplats = stringtofloat(droplatss)
   droplons = stringtofloat(droplonss)
   droplats@_FillValue = -9999.
   ;Convert 2-digit year to 4 digits
   dropyear = where(toint(dropyear).lt.60,"20"+dropyear,"19"+dropyear)
end if
dropjuldate= cd_inv_calendar(stringtoint(dropyear),stringtoint(dropmon),stringtoint(dropday),stringtoint(drophour),\
                             stringtoint(dropminu),stringtoint(dropsec),juldate@units,0)
;print( dropyear)
;print( dropmon)
;print( dropday)
;print( drophour)
;print( dropminu)
;print( dropjuldate)
;print( droplats)
;print( droplons)

;---------------------------------------------------
;Loop through all sondes, compute time differences
;and distances from TC tracks, and print information
;to the proper output file.
;---------------------------------------------------
;Outer loop is looping through all radii
do k=minrad,maxrad,deltarad
   innerrad = k
   outerrad = innerrad+deltarad
   if(type.eq."eol")then
      outfile  = outdir+"/hs3-sondes_"+innerrad+"-"+outerrad+"km"
   else
      outfile  = outdir+"/rawinsondes_"+innerrad+"-"+outerrad+"km"
   end if
   system("rm "+outfile)
   nsondes = dimsizes(dropfiles)
   do i=0,nsondes-1
      unixi = i + 1
      print( "Processing sonde "+unixi+" of "+nsondes+" for "+innerrad+"-"+outerrad+"km radial band ")
      dropfile   = dropfiles(i)
      print( dropfile)
      timediffs  = abs(juldate-dropjuldate(i))
      inds := ind(timediffs.le.0.125)
;      print( sname(inds))
      ;print( inds)
      if(.not.all(ismissing(inds)))then
;         print( year(inds))
;         print( mon(inds))
;         print( day(inds))
;         print( hour(inds))
;         print( minu(inds))
         ;Compute distance between sonde and all storm centers
         droplat = droplats(i)
         droplon = droplons(i)
         distances := gc_latlon(droplat,droplon,lat(inds),lon(inds),2,4)
         ;If sonde is in specified radial band, find radius and azimuth and print to output file
         if(any(distances.ge.innerrad.and.distances.lt.outerrad))then
            index = minind(distances)
            if(distances(index).ge.innerrad)then
               hurdatind = inds(index)
               radius = distances(index)
               ;Compute azimuth. To get the x distance for the trig, we will take the average
               ;of the x distance at the dropsonde latitude and the storm center latitude.
               xdist = gc_latlon(droplat,lon(hurdatind),droplat,droplon,2,4)
               xdist2= gc_latlon(lat(hurdatind),lon(hurdatind),lat(hurdatind),droplon,2,4)
               xdist = avg((/xdist,xdist2/))
               if(radius.ne.0)then
                  if(droplat.ge.lat(hurdatind).and.droplon.ge.lon(hurdatind))then
                     azimuth = asin(xdist/radius)*radtodeg
                  else if(droplat.le.lat(hurdatind).and.droplon.ge.lon(hurdatind))then
                     azimuth = 90+acos(xdist/radius)*radtodeg
                  else if(droplat.le.lat(hurdatind).and.droplon.le.lon(hurdatind))then
                     azimuth = 180+asin(xdist/radius)*radtodeg
                  else if(droplat.ge.lat(hurdatind).and.droplon.le.lon(hurdatind))then
                     azimuth = 270+acos(xdist/radius)*radtodeg
                  end if
                  end if
                  end if
                  end if
               else 
                     azimuth = 0
               end if
               ;Write to output file
               if(bttype.eq.0)then
                  outstr = dropfiles(i)+" "+yyyymmdd(hurdatind,0)+" "+yyyymmdd(hurdatind,1)+" "+yyyymmdd(hurdatind,2)\
                          +" "+hhmm(hurdatind,0)+" "+hhmm(hurdatind,1)+" "+category(hurdatind)+" "+lats(hurdatind)+" "\
                          +sprintf("%6.1f",lon(hurdatind))+" "+vmax(hurdatind)+" "+sprinti("%4.1i",pmin(hurdatind))+" "\
                          +sprintf("%6.1f",radius)+" "+sprintf("%6.1f",azimuth)
               else
                  outstr = dropfiles(i)+" "+year(hurdatind)+" "+mon(hurdatind)+" "+day(hurdatind)+" "+hour(hurdatind)+\
                           " "+minu(hurdatind)+" "+category(hurdatind)+" "+sprintf("%6.1f",lat(hurdatind))+" "+\
                           sprintf("%6.1f",lon(hurdatind))+" "+vmax(hurdatind)+" "+pmin(hurdatind)+" "+\
                           sprintf("%6.1f",radius)+" "+sprintf("%6.1f",azimuth)+" "+snum(hurdatind)+" "+\
                           sname(hurdatind)
               end if
               print( outstr)
               system("echo "+outstr+" >> "+outfile)
            end if
         end if
      end if
   end do 
end do
