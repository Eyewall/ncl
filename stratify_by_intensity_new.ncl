load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-------------------------------------------------;
;Patrick Duran                                    ;
;8/6/2014                                         ;
;stratify_by_intensity_new.ncl                    ;
;-------------------------------------------------;

lower = 0
upper = 400
maxrad = 400

idlist_input = "/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/allsondes_"+lower+"-"+upper+".idlist"
stnlocfile = "/jm13/pduran/unix_scripts_and_c++/2014/sonde-hdist-clc-mlt.sc"
trackfile = "/jm13/pduran/alltrk98_11-atl-6h.dat"

outfile1 = "allhurricanes_"+lower+"-"+upper+".idlist"
outfile2 = "ts+td_"+lower+"-"+upper+".idlist"

;Get station locations from stnlocfile
stns     = systemfunc("cat "+stnlocfile+" | tail -n+4 | awk '{print($2)}'")
stn_lats = systemfunc("cat "+stnlocfile+" | tail -n+4 | awk '{print($3)}'")
stn_lons = systemfunc("cat "+stnlocfile+" | tail -n+4 | awk '{print($4)}'")

;Get stations, dates, and times from idlist file
stns_id  = systemfunc("awk '{print($2)}' "+idlist_input)
dates    = systemfunc("awk '{print($4)}' "+idlist_input+" | cut -c 1-6")
times    = systemfunc("awk '{print($4)}' "+idlist_input+" | cut -c 7-10")

;Loop through all sondes in idlist file
allhurricanes = new(10000,"string")
tstd = new(10000,"string")
nsondes = dimsizes(stns_id)
allhurricanes_index = 0
tstd_index = 0
do i=0,nsondes-1
   unixi = i + 1
   print("Processing idlist entry "+unixi+" of "+nsondes)

   ;Get station, date, and time for this idlist entry
   stn  = stns_id(i)
   date = dates(i)
   time = times(i)

   ;Get latitudes and longitudes and wind speeds of storms that correspond to this idlist entry
   system("grep -i '"+date+" "+time+"' "+trackfile+" > hurdatlines")
   lats  = stringtofloat(systemfunc("awk '{print($4)}' hurdatlines"))
   lons  = stringtofloat(systemfunc("awk '{print($5)}' hurdatlines"))
   wspds = stringtofloat(systemfunc("awk '{print($6)}' hurdatlines"))

   ;Get lats and lons of the station for this idlist entry
   stn_lat = new(dimsizes(lats),"float")
   stn_lon = stn_lat
   stn_lat = stringtofloat(stn_lats(ind(stns.eq.stn)))
   stn_lon = stringtofloat(stn_lons(ind(stns.eq.stn)))

   ;Calculate distances and get wind speed
   distances = gc_latlon(lats,lons,stn_lat,stn_lon,2,4)
   index = ind(distances.le.400)
   wspd = wspds(index)

   ;Determine intensity classification
   if(wspd.ge.64)then
      allhurricanes(allhurricanes_index) = ". "+stn+" RAWIN_6S "+date+time+" "+distances(index)
      allhurricanes_index = allhurricanes_index + 1
   end if
   if(wspd.lt.64)then
      tstd(tstd_index) = ". "+stn+" RAWIN_6S "+date+time+" "+distances(index)
      tstd_index = tstd_index + 1
   end if

   delete([/lats,lons,wspds,stn_lat,stn_lon,distances/])
end do
asciiwrite(outfile1+"1",allhurricanes)
asciiwrite(outfile2+"1",tstd)

system("sed '/missing/d' "+outfile1+"1 > "+outfile1)
system("sed '/missing/d' "+outfile2+"1 > "+outfile2)
system("\rm "+outfile1+"1 "+outfile2+"1")
system("\rm hurdatlines")
