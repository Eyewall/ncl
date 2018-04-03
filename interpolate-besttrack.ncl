load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/nfs/jm13/pduran/ncl/functions/meteo.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/nfs/jm13/pduran/ncl/functions/interpolate.ncl"
load "/nfs/jm13/pduran/ncl/functions/tan+rad_velocity.ncl"
;----------------------------------------------------------------;
; interpolate-besttrack.ncl                                    
; Patrick Duran                                           
; 31 March 2016
;
; Reads an input file of format:
;20151020 0600  13.4 -94.0   25 1007    0    0    0    0    0    0    0    0    0    0    0    0
;20151020 1200  13.3 -94.2   30 1006    0    0    0    0    0    0    0    0    0    0    0    0
;20151020 1800  13.2 -94.6   30 1006    0    0    0    0    0    0    0    0    0    0    0    0
;20151021 0000  13.1 -95.1   35 1004    0   60    0    0    0    0    0    0    0    0    0    0
;20151021 0600  12.9 -96.2   35 1004   60   60    0   60    0    0    0    0    0    0    0    0
;...
;...
; (A best track file with storm name lines, commas,
;  storm designation, and landfall flags trimmed off,
;  and N and W lat,lons converted to positive/negative.)
;
; Interpolates the lat,lon positions, wind speed, and
; pressure to 1-minute time intervals.
;
; NOTE: This code uses the cd_calendar function to generate
;       the dates and times for output. The NCL website has
;       a note that there is a bug in this function that
;       makes it return the minutes/seconds as 0/60 rather
;       than 1/0. Thus, e.g., 18:21:60 is really 18:22:00.
;       10 April 2017: I've added a fix for this near the bottom
;       of this script.
;----------------------------------------------------------------;

infile  = "/nfs/jm13/pduran/best-tracks/patricia.txt"
outfile = "/nfs/jm13/pduran/best-tracks/patricia-1min.txt"
spacing = 1   ;Time spacing of output file (minutes)

;Read data
posdata = readAsciiTable(infile,18,"float",0)
lat  = posdata(:,2)
lon  = posdata(:,3)
vmax = posdata(:,4)
pmin = posdata(:,5)
year = toint(systemfunc("awk '{print $1}' "+infile+" | cut -c1-4")) 
mon  = toint(systemfunc("awk '{print $1}' "+infile+" | cut -c5-6"))
day  = toint(systemfunc("awk '{print $1}' "+infile+" | cut -c7-8")) 
hour = toint(systemfunc("awk '{print $2}' "+infile+" | cut -c1-2")) 
minu = toint(systemfunc("awk '{print $2}' "+infile+" | cut -c3-4")) 
sec  = minu
sec  = 0

;Convert dates to mixed Julian/Gregorian
juldates = cd_inv_calendar(year,mon,day,hour,minu,sec,"minutes since 1971-1-1",0)

;Set up 1-minute grid
mintime = min(juldates)
maxtime = max(juldates)
ntimes  = toint(maxtime - mintime)
outtimes = fspan(mintime,maxtime,ntimes+1)
outtimes@units = "minutes since 1971-1-1"

;Interpolate to 1-minute grid
lat_interp = linint1(juldates,lat,False,outtimes,0)
lon_interp = linint1(juldates,lon,False,outtimes,0)
vmax_interp= linint1(juldates,vmax,False,outtimes,0)
pmin_interp= linint1(juldates,pmin,False,outtimes,0)

;Convert back to Gregorian for output
jultime_days = outtimes 
gregout = cd_calendar(outtimes,0)

;Need to fix the times when seconds=60
sec60ind = ind(gregout(:,5).eq.60)
gregout(sec60ind,5) = 0
gregout(sec60ind,4) = gregout(sec60ind,4)+1
print(gregout(0:2,:))

;Write to output file
system("echo '    LAT        LON     VMAX     PMIN   YYYY MM DD HH MM JULTIME (min since 1/1/1972)' > header.txt")
writelist = [/lat_interp,lon_interp,vmax_interp,pmin_interp,gregout(:,0),\
              gregout(:,1),gregout(:,2),gregout(:,3),gregout(:,4),outtimes/]
write_table("latslons.tmp","w",writelist,"%10.5f%10.5f%6.3f%8.3f%4.0f%2.0f%2.0f%2.0f%2.0f%8.0f")
system("cat header.txt latslons.tmp > "+outfile)
system("\rm header.txt latslons.tmp")
