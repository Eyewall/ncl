load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/nfs/jm13/pduran/ncl/functions/meteo.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/nfs/jm13/pduran/ncl/functions/interpolate.ncl"
load "/nfs/jm13/pduran/ncl/functions/tan+rad_velocity.ncl"
;----------------------------------------------------------------;
; interpolate-centerposition.ncl                                    
; Patrick Duran                                           
; 13 November 2016
;
; Reads an input file of format:
;  lat      lon    yyyy mm dd HH MM SS Source
;------- --------- ---- -- -- -- -- -- ------
;12.9833  -99.2000 2015 10 21 19 50 19 N43RF
;13.1333  -99.4833 2015 10 21 20 41 42 N43RF
;14.9833 -104.0333 2015 10 22 17 38 56 N43RF
;...
;...
; Interpolates the lat,lon positions to a user-specified time
; spacing and writes to a user-specified output file.
;
; NOTE: This code uses the cd_calendar function to generate
;       the dates and times for output. The NCL website has
;       a note that there is a bug in this function that
;       makes it return the minutes/seconds as 0/60 rather
;       than 1/0. Thus, e.g., 18:21:60 is really 18:22:00.
;
; 13 September 2017: Added functionality to interpolate recon-based
;                    center estimate track from HRD to 1-second int.
;----------------------------------------------------------------;

type    = 1  ;0=Reads on input file of format specified in the header comment above
             ;1=Reads a trak file from HRD (e.g. http://www.aoml.noaa.gov/hrd/Storm_pages/patricia2015/patricia.trak)
if(type.eq.0)then
   infile  = "/nfs/jm13/pduran/recon-positions/patricia_vortex.txt"
   outfile = "/nfs/jm13/pduran/recon-positions/patricia_vortex_interp-1sec.txt"
else if(type.eq.1)then
   infile  = "/nfs/jm13/pduran/recon-positions/patricia.trak"
   outfile = "/nfs/jm13/pduran/recon-positions/patricia_hrd_interp_1sec.txt"
end if
end if
spacing = 1   ;Time spacing of output file (seconds)

;Read data
if(type.eq.0)then
   posdata = readAsciiTable(infile,9,"float",2)
   lat  = posdata(:,0)
   lon  = posdata(:,1)
   year = toint(posdata(:,2))
   mon  = toint(posdata(:,3))
   day  = toint(posdata(:,4))
   hour = toint(posdata(:,5))
   minu = toint(posdata(:,6))
   sec  = toint(posdata(:,7))
else if(type.eq.1)then
   year = toint(systemfunc("awk '{print $1}' "+infile+" | sed -e '1,3d' | awk -F'/' '{print $3}'"))
   day  = toint(systemfunc("awk '{print $1}' "+infile+" | sed -e '1,3d' | awk -F'/' '{print $2}'"))
   mon  = toint(systemfunc("awk '{print $1}' "+infile+" | sed -e '1,3d' | awk -F'/' '{print $1}'"))
   hour = toint(systemfunc("awk '{print $2}' "+infile+" | sed -e '1,3d' | awk -F':' '{print $1}'"))
   minu = toint(systemfunc("awk '{print $2}' "+infile+" | sed -e '1,3d' | awk -F':' '{print $2}'"))
   sec  = toint(systemfunc("awk '{print $2}' "+infile+" | sed -e '1,3d' | awk -F':' '{print $3}'"))
   lat  = tofloat(systemfunc("awk '{print $3}' "+infile+" | sed -e '1,3d'"))
   lon  = tofloat(systemfunc("awk '{print $5}' "+infile+" | sed -e '1,3d'"))
end if
end if

print(hour)  ;For some reason, the script breaks without this print statement!!
;Convert dates to mixed Julian/Gregorian
juldates = cd_inv_calendar(year,mon,day,hour,minu,sec,"seconds since 1971-1-1",0)

;Set up 1-minute grid
mintime = min(juldates)
maxtime = max(juldates)
ntimes  = toint(maxtime - mintime)
outtimes = fspan(mintime,maxtime,ntimes+1)
outtimes@units = "seconds since 1971-1-1"

;Interpolate to 1-minute grid
lat_interp = linint1(juldates,lat,False,outtimes,0)
lon_interp = linint1(juldates,lon,False,outtimes,0)

;Convert back to Gregorian for output
jultime_days = outtimes 
gregout = cd_calendar(outtimes,0)

;Write to output file
system("echo '    LAT        LON    YYYY MM DD HH MM SS' > header.txt")
writelist = [/lat_interp,lon_interp,gregout(:,0),gregout(:,1),gregout(:,2),gregout(:,3),\
              gregout(:,4),gregout(:,5)/]
write_table("latslons.tmp","w",writelist,"%10.5f%10.5f%4.0f%2.0f%2.0f%2.0f%2.0f%2.0f")
system("cat header.txt latslons.tmp > "+outfile)
system("\rm header.txt latslons.tmp")
