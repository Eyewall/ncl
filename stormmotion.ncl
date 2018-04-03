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
; 21 September 2017
;
; Reads an input file of format:
; Track for Patricia             2015
; Date       Time (UTC)   Latitude     Longitude
; MM/DD/Year HH:MM:SS      (deg)         (deg)
; 10/21/2015 11:53:59     12.902 N     97.383 W
; 10/21/2015 11:56:00     12.901 N     97.388 W
; 10/21/2015 11:57:59     12.901 N     97.394 W
; 10/21/2015 12:00:00     12.900 N     97.400 W
; ...
; ...
; Interpolates the lat,lon positions to a user-specified time
; spacing, computes the storm motion vector and writes to a 
; user-specified output file of format
;
; 1500 102015 13.300  -94.400            -2.0  -0.5
; 1501 102015 13.300  -94.401            -2.0  -0.5
; 1502 102015 13.299  -94.402            -2.0  -0.5
; 1503 102015 13.299  -94.403            -2.0  -0.5
; 1504 102015 13.299  -94.404            -2.0  -0.5
;
; Where the columns from left to right are time (HHMM),
; date (MMDDYY), lat, lon, u_motion (m/s), v_motion (m/s)
;
; NOTE: This code uses the cd_calendar function to generate
;       the dates and times for output. The NCL website has
;       a note that there is a bug in this function that
;       makes it return the minutes/seconds as 0/60 rather
;       than 1/0. Thus, e.g., 18:21:60 is really 18:22:00.
;----------------------------------------------------------------;

infile  = "/nfs/jm13/pduran/recon-positions/patricia_firstlinedeleted.trak"
;outfile = "/nfs/jm13/pduran/recon-positions/patricia_storm-motion.txt"
outfile = "/nfs/jm13/pduran/recon-positions/gdtrk-realtime-15p-1min-000.datx"
spacing = 1   ;Time spacing of output file (minutes)
smth    = 60  ;Number of points to include in running mean

;Read data
year = toint(systemfunc("awk '{print $1}' "+infile+" | sed -e '1,3d' | awk -F'/' '{print $3}'"))
day  = toint(systemfunc("awk '{print $1}' "+infile+" | sed -e '1,3d' | awk -F'/' '{print $2}'"))
mon  = toint(systemfunc("awk '{print $1}' "+infile+" | sed -e '1,3d' | awk -F'/' '{print $1}'"))
hour = toint(systemfunc("awk '{print $2}' "+infile+" | sed -e '1,3d' | awk -F':' '{print $1}'"))
minu = toint(systemfunc("awk '{print $2}' "+infile+" | sed -e '1,3d' | awk -F':' '{print $2}'"))
sec  = toint(systemfunc("awk '{print $2}' "+infile+" | sed -e '1,3d' | awk -F':' '{print $3}'"))
lat  = tofloat(systemfunc("awk '{print $3}' "+infile+" | sed -e '1,3d'"))
lon  = tofloat(systemfunc("awk '{print $5}' "+infile+" | sed -e '1,3d'"))*-1.

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

;Create arrays shifted by 1 and 2 to quickly compute differences without looping
julp1 = outtimes(1:)
latp1 = lat_interp(1:)
lonp1 = lon_interp(1:)
julp2 = outtimes(2:)
latp2 = lat_interp(2:)
lonp2 = lon_interp(2:)

;-------------------------------;
;Compute storm motion components;
;-------------------------------;
;Compute lat,lon and time displacements valid at center point
dlat = gc_latlon(latp2,lonp1(:dimsizes(lonp1)-2),lat_interp(:dimsizes(lat_interp)-3),lonp1(:dimsizes(lonp1)-2),2,-3)
dlon = gc_latlon(latp1(:dimsizes(latp1)-2),lonp2,latp1(:dimsizes(latp1)-2),lon_interp(:dimsizes(lon_interp)-3),2,-3)
djul = julp2 - outtimes(:dimsizes(outtimes)-3)
;Make the displacement negative if the storm is moving south or west
dlat = where(latp2.lt.lat_interp(:dimsizes(lat_interp)-3),dlat*-1.,dlat)
dlon = where(lonp2.lt.lon_interp(:dimsizes(lon_interp)-3),dlon*-1.,dlon)

;Divide by julian time differences valid at center point to get storm motion
ustorm = dlon/(djul*60)
vstorm = dlat/(djul*60)
ustorm@_FillValue = -9999.
vstorm@_FillValue = -9999.

;Apply smoother
ustorm = runave_Wrap(ustorm,smth,0)
vstorm = runave_Wrap(vstorm,smth,0)

;Convert back to Gregorian for output
jultime_days = outtimes 
gregout = cd_calendar(outtimes,0)

;Create formatted output strings
YYYY = sprintf("%2.0f",gregout(1:dimsizes(outtimes)-2,0))
MM   = sprintf("%2.0f",gregout(1:dimsizes(outtimes)-2,1))
DD   = sprintf("%2.0f",gregout(1:dimsizes(outtimes)-2,2))
hh   = sprintf("%2.0f",gregout(1:dimsizes(outtimes)-2,3))
mm   = sprintf("%2.0f",gregout(1:dimsizes(outtimes)-2,4))
YYYY_split = str_split_by_length(YYYY,2)
YY = YYYY_split(:,1)
MM = where(toint(MM).lt.10,"0"+sprintf("%1.0f",gregout(1:dimsizes(outtimes)-2,1)),MM)
DD = where(toint(DD).lt.10,"0"+sprintf("%1.0f",gregout(1:dimsizes(outtimes)-2,2)),DD)
hh = where(toint(hh).lt.10,"0"+sprintf("%1.0f",gregout(1:dimsizes(outtimes)-2,3)),hh)
mm = where(toint(mm).lt.10,"0"+sprintf("%1.0f",gregout(1:dimsizes(outtimes)-2,4)),mm)

;Write to output file
printVarSummary( ustorm)
printVarSummary( latp1)
writelist = [/hh+mm,MM+DD+YY,latp1(1:),lonp1(1:),ustorm,vstorm/]
write_table(outfile,"w",writelist,"%s%s%6.3f%8.3f%5.3f%5.3f")
