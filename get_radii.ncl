;**************************************************
; skewt_frd.ncl
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_hs3.ncl"
;**************************************************

;dropdir = "/jm13/pduran/dropsondes/hs3/forskewt/"
;trakfile = "/jm13/pduran/hs3/hs3_stormtracks"
;outfile = "/jm13/pduran/hs3/distances.txt"

dropdir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151023/"
trakfile = "/nfs/jm13/pduran/recon-positions/patricia_hrd_interp_1sec.txt"
outfile = "/jm13/pduran/web/distances.txt"
traktype = 1  ;0=Best Track, 1=HRD Zero Wind Center Track

system("\rm "+outfile)

;Get storm track dates, times, and positions
if(traktype.eq.0)then
   trakyear = stringtoint(systemfunc("awk '{print ($1)}' "+trakfile+" | cut -c 1-4"))
   trakmon  = stringtoint(systemfunc("awk '{print ($1)}' "+trakfile+" | cut -c 5-6"))
   trakday  = stringtoint(systemfunc("awk '{print ($1)}' "+trakfile+" | cut -c 7-8"))
   trakhour = stringtoint(systemfunc("awk '{print ($2)}' "+trakfile))
   traklats = stringtofloat(systemfunc("awk '{print ($4)}' "+trakfile))
   traklons = stringtofloat(systemfunc("awk '{print ($5)}' "+trakfile))
else
   trackdata= readAsciiTable(trakfile,8,"float",1)
   trakyear = stringtoint(trackdata(:,2))
   trakmon  = stringtoint(trackdata(:,3))
   trakday  = stringtoint(trackdata(:,4))
   trakhour = stringtoint(trackdata(:,5))
   trakmin  = stringtoint(trackdata(:,6))
   trakss   = stringtoint(trackdata(:,7))
   traklats = trackdata(:,0)
   traklons = trackdata(:,1)
end if

;Get drop dates and times
dropyear = stringtoint(systemfunc("grep 'UTC Launch Time' "+dropdir+"*.eol | awk -F'       ' '{print $2}'"))
dropmon  = stringtoint(systemfunc("grep 'UTC Launch Time' "+dropdir+"*.eol | awk -F',' '{print $7}'"))
dropday  = stringtoint(systemfunc("grep 'UTC Launch Time' "+dropdir+"*.eol | awk -F',' '{print $8}'")) 
drophour = stringtoint(systemfunc("grep 'UTC Launch Time' "+dropdir+"*.eol | awk -F',' '{print $9}'"))
dropminu = stringtoint(systemfunc("grep 'UTC Launch Time' "+dropdir+"*.eol | awk -F':' '{print $4}'"))
dropsec  = stringtoint(systemfunc("grep 'UTC Launch Time' "+dropdir+"*.eol | awk -F':' '{print $5}'"))

;Convert dates and times into seconds since 1/1/1970
julian_trak = cd_inv_calendar(trakyear,trakmon,trakday,trakhour,trakmin,trakss,"seconds since 1970-1-1 00:00:0.0",0)
julian_drop = cd_inv_calendar(dropyear,dropmon,dropday,drophour,dropminu,dropsec,"seconds since 1970-1-1 00:00:0.0,0",0)

;Loop through all drops, find radii from storm center(s)
dropfiles = systemfunc("ls "+dropdir+"*eol")
ndropfiles = dimsizes(dropfiles)
;distance_array = new(ndropfiles,"float")
do i=0,ndropfiles-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+ndropfiles+"    `date`")

   ;Get drop location
   dropdata = readAsciiTable(dropfiles(i),17,"float",14)
   dropdata@_FillValue = -999
   lats = dropdata(:,15)
   lons = dropdata(:,14)
   droplat = lats(0)
   droplon = lons(0)
   if(ismissing(droplat))then
      droplat = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print($9)}' | sed 's/,//g'"))
      droplon = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print($6)}' | sed 's/,//g'"))
   end if
   ;Find distance(s) between drop location and storm center location(s)
   timediffs = julian_trak - julian_drop(i)  ;Units seconds
   if(any(abs(timediffs).le.180))then
      closest_times_ind = minind(abs(timediffs))
      distances = gc_latlon(droplat,droplon,traklats,traklons,2,4)
      dist = distances(closest_times_ind)
      system("echo "+dist+"'     '"+dropfiles(i)+" >> "+outfile)
      delete([/dropdata,lats,lons,closest_times_ind/])
   else
      system("echo WARNING: NO HURDAT TIME WITHIN 3 HOURS OF DROP TIME   DROPFILE: "+dropfiles(i))
      delete([/dropdata,lats,lons/])
   end if 
end do
