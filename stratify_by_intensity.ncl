load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-------------------------------------------------;
;Patrick Duran                                    ;
;1/31/2014                                        ;
;stratify_by_intensity.ncl                        ;
;                                                 ;
;Will read in an idlist file and get the intensity;
;of each TC within a user-defined radius of each  ;
;sonde in the idlist file. Will then write out an ;
;idlist file for the user-specified intensity     ;
;stratifications.                                 ;
;-------------------------------------------------;

;----------;
;PARAMETERS;
;----------;
;hours = (/"00","06","12","18"/)
;do hournum=0,3
;   hour = hours(hournum)
;   do m=0,900,100
;      lower = m
;      upper = lower + 200
;      
lower = 0
upper = 400
      idlist_input = "/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/allsondes_"+lower+"-"+upper+".idlist"
;      idlist_input = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/"+hour+"z/200kmbins/allsondes_"+hour+"z_"+lower+"-"+upper+"km"
      filename_1 = "allhurricanes_"+lower+"-"+upper+".idlist"
      filename_3 = "ts+td_"+lower+"-"+upper+".idlist"
      
      maxrad = 400.   ;Maximum radius in kilometers
      hurdatfile = "/jm13/pduran/hurdat2-atlantic-1998-2012-013114.txt"
      stnlocfile = "/jm13/pduran/unix_scripts_and_c++/2014/sonde-hdist-clc-mlt.sc"
      
      trackfile = "/jm13/pduran/alltrk98_11-atl-6h.dat"
      ;--------------------;
      ;Create output arrays;
      ;--------------------;
      allhurricanes = new(10000,"string")
      tstd = new(10000,"string")
      allhurricanes_index = 0
      tstd_index = 0
      
      ;Get station locations from stnloc file
      stns = systemfunc("cat "+stnlocfile+" | tail -n+4 | awk '{print($2)}'")
      lats = systemfunc("cat "+stnlocfile+" | tail -n+4 | awk '{print($3)}'")
      lons = systemfunc("cat "+stnlocfile+" | tail -n+4 | awk '{print($4)}'")
      ;------------------------;
      ;Loop through idlist file;
      ;------------------------;
      nlines_idlist_input = stringtoint(systemfunc("wc "+idlist_input+" | awk '{print($1)}'"))
      do i=0,nlines_idlist_input-1
         unixi = i + 1
         print("Processing line: "+unixi+" of "+nlines_idlist_input+"  "+systemfunc("date"))
      
         system("cat "+idlist_input+" | colrm 1 2 > idlist.tmp")
      
         ;Get data from idlist file
         idline = systemfunc("sed -n "+unixi+"p idlist.tmp")
         idline_split = str_split(idline," ")

         nradii = dimsizes(idline_split) - 3 ;Number of radii for this idlist entry
         stn = idline_split(0)	;Station number
         dattim = idline_split(2)	;YYMMDDHHHH 
         ;Get all radii
         radii = new(nradii,"float")
         do j=0,nradii-1
            subscript = j + 3		;Subscript of idline_split
            radii(j) = stringtofloat(idline_split(subscript))
         end do
      
         ;Get components of dattim
         if(stringtoint(systemfunc("echo "+dattim+" | wc | awk '{print($3)}'")).eq.11)
            yy_int = stringtoint(systemfunc("echo "+dattim+" | cut -c1-2"))
            mm_int = stringtoint(systemfunc("echo "+dattim+" | cut -c3-4"))
            dd = systemfunc("echo "+dattim+" | cut -c5-6")
            hr_int = stringtoint(systemfunc("echo "+dattim+" | cut -c7-10"))
         else
            yy_int = stringtoint(systemfunc("echo "+dattim+" | cut -c1"))
            mm_int = stringtoint(systemfunc("echo "+dattim+" | cut -c2-3"))
            dd = systemfunc("echo "+dattim+" | cut -c4-5")
            hr_int = stringtoint(systemfunc("echo "+dattim+" | cut -c6-9")) 
         end if
      
         yy = sprinti("%0.2i",yy_int)
         mm = sprinti("%2.0i",mm_int)
         if(hr_int.eq.0)then
            hr = "   0"
         else
            hr = sprinti("%4.0i",hr_int)
         end if
      
         ;Get the relevant lines from HURDAT file
         if(nradii.eq.1)then	;We don't need to check distances because we only have 1 time
            hurdat_date_time = hr+" "+mm+dd+yy
print(hurdat_date_time)
            intensity = stringtoint(systemfunc("grep -i '"+hurdat_date_time+"' "+trackfile+" | awk '{print($16)}'"))
print(intensity)
            if(.not.ismissing(intensity))then
               if(intensity.ge.64)then
                  allhurricanes(allhurricanes_index) = ". "+stn+" RAWIN_6S "+dattim+" "+radii
                  allhurricanes_index = allhurricanes_index + 1
               end if
               if(intensity.lt.64)then
                  tstd(tstd_index) = ". "+stn+" RAWIN_6S "+dattim+" "+radii
                  tstd_index = tstd_index + 1
               end if
            end if
            delete(intensity)
         else		;We need to check each distance to determine which storm cooresponds to each radius
            hurdat_date_time = hr+" "+mm+dd+yy
            hurdatlines = systemfunc("grep -i '"+hurdat_date_time+"' "+trackfile)
            do k=0,dimsizes(hurdatlines)-1
               hurlat = stringtofloat(systemfunc("echo "+hurdatlines(k)+" | awk '{print($3)}'"))
               hurlon = stringtofloat(systemfunc("echo "+hurdatlines(k)+" | awk '{print($4)}'"))
               intensity = stringtoint(systemfunc("echo "+hurdatlines(k)+" | awk '{print($16)}'"))
               stnlat = stringtofloat(lats(ind(stn.eq.stns)))
               stnlon = stringtofloat(lons(ind(stn.eq.stns)))
               distance = gc_latlon(hurlat,hurlon,stnlat,stnlon,2,4)
               radius = sprintf("%8.2f",distance)
               if(.not.ismissing(intensity))
                  if(distance.lt.maxrad)then
                     if(intensity.ge.64)then
                        allhurricanes(allhurricanes_index) = ". "+stn+" RAWIN_6S "+dattim+" "+radius
                        allhurricanes_index = allhurricanes_index + 1
                     end if
                     if(intensity.lt.64)then
                        tstd(tstd_index) = ". "+stn+" RAWIN_6S "+dattim+" "+radius
                        tstd_index = tstd_index + 1
                     end if
                  end if
               end if
            end do
         delete(hurdatlines)
         delete(intensity)
         end if
         delete([/idline_split,radii/])
      print("Hurricanes: "+allhurricanes_index+"      TS+TD: "+tstd_index)
      end do
      
      asciiwrite(filename_1+"1",allhurricanes)
      asciiwrite(filename_3+"1",tstd)
      
      system("sed '/missing/d' "+filename_1+"1 > "+filename_1)
      system("sed '/missing/d' "+filename_3+"1 > "+filename_3)
      system("\rm "+filename_1+"1 "+filename_3+"1")
;   end do
;end do
