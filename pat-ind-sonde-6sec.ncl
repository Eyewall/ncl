load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-------------------------------------------------------------;
;RRS2editsonde_100m-interp_bogfix.ncl                         ;
;Patrick duran                                                ;
;11/7/2013                                                    ;
;                                                             ;
;Reads in two RRS files (one with thermo data, one with wind),;
;runs the temperature and dewpoint through a 1-2-1 smoother,  ;
;and interpolates all data to levels of set spacing. Output is; 
;then read into a C++ program which prints to output files in ;
;editsonde format.                                            ;
;-------------------------------------------------------------;
;Location of C++ program: /nfs/jm13/pduran/unix_scripts_and_c++/create_editfile.cpp
;Example RRS thermo file: http://www.atmos.albany.edu/student/pduran/file_formats/12924_2005100318_5pPTU.txt
;Example RRS wind file: http://www.atmos.albany.edu/student/pduran/file_formats/12924_2005100318_6pGPS.txt
;Example editsonde file: http://www.atmos.albany.edu/student/pduran/file_formats/12924-200510031800_smoothed.edit

;Set paths to data and programs
RRSpath   = "/jm13/pduran/soundings/"            ;Path to RRS thermo and wind files
editpath  = "/jm13/pduran/1sec_sondes_newer/"    ;Where output files will be written
progpath  = "/jm13/pduran/unix_scripts_and_c++/" ;Directory where C++ program is located
nclpath   = systemfunc("pwd")+"/"                ;Directory in which this script is being run

;Set parameters
dz = 100           ;Level spacing to interpolate to in meters
ncolsthermo = 46   ;Number of columns in thermodynamic sounding file
ncolswind   = 36   ;Number of columns in wind sounding file
nhead       = 3    ;Number of header lines to chop off in input files
fillvalue_hght   = -9999. ;Fill value to use for height in edit file output
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit" ;Suffix for output edit file name
;fillvalue_hght   = -99.9  ;Fill value to use for temps, winds, & other floating point variables < 100

;-------------------------------------------------------;
;Loop through all ascii sounding file directories in dir;
;-------------------------------------------------------;
year_dirs = systemfunc("ls "+RRSpath)
num_year_dirs = dimsizes(year_dirs)

   j = 0
   num_stn_dirs = 1
   sta_pth = "xxx"
   do while(j.lt.num_stn_dirs)    ;Loop through station directories
      ;Read lists of the input files into arrays
      thermofiles = systemfunc("ls "+RRSpath+sta_pth+"/ascii/*5pPTU.txt")
      windfiles = systemfunc("ls "+RRSpath+sta_pth+"/ascii/*6pGPS.txt")

      ;Make sure we have the same number of thermo and wind files
      if(dimsizes(thermofiles).ne.(dimsizes(windfiles))) then
         print("ERROR: MISSING WIND OR THERMO FILE IN "+RRSpath+sta_pth)
         exit
      end if

      n = 0   ;Loop through all sounding files
      do while(n.lt.dimsizes(thermofiles))
         time_step = systemfunc("date ")
         print("Processing "+thermofiles(n)+" "+time_step)

         ;Remove all lines from the input files that contain missing data. Missing data
         ;is marked by "99999" in the RRS files...Also, replace every series of 5 asterisks
         ;with -99.9 so that the file may be read in without problems. We will also remove
         ;the 3 header rows from the input files so that we can use asciiRead instead of
         ;readAsciiTable, which can be very slow for large files
         system("sed '/99999/d' "+thermofiles(n)+" > thermofile_init.tmp")
         system("sed '/99999/d' "+windfiles(n)+" > windfile_init.tmp") 
         system("sed 's/\*\*\*\*\*/-99.9/g' thermofile_init.tmp > thermofile.tmp1")
         system("sed 's/\*\*\*\*\*/-99.9/g' windfile_init.tmp > windfile.tmp1")
         system("sed '1,3d' thermofile.tmp1 > thermofile.tmp")
         system("sed '1,3d' windfile.tmp1 > windfile.tmp")

         ;Get number of rows in input files
         nrowsthermo = stringtoint(systemfunc("wc thermofile.tmp" ))
         nrowswind = stringtoint(systemfunc("wc windfile.tmp" ))

         ;Read in the data tables to arrays
         thermodata = asciiread("thermofile.tmp",(/nrowsthermo,ncolsthermo/),"float")
         winddata = asciiread("windfile.tmp",(/nrowswind,ncolswind/),"float")

         ndims_thermo = dimsizes(thermodata) ;2-D
         ndims_wind = dimsizes(winddata)     ;2-D
            
         ;Get the relevant data from the arrays
         pres = thermodata(:,26)
         presflag = thermodata(:,27)
         tmpc_unsmoothed = thermodata(:,37)
         tmpcflag = thermodata(:,38)
         dwpc_unsmoothed = thermodata(:,40)
         dwpcflag = thermodata(:,41)
         thermohght = thermodata(:,43)
         thermohghtflag = thermodata(:,44)
         uwnd = winddata(:,30)
         uwndflag = winddata(:,31)
         vwnd = winddata(:,33)
         vwndflag = winddata(:,34)
         windhght = winddata(:,27) 
         windhghtflag = winddata(:,28)   
         relh = thermodata(:,29)
         relhflag = thermodata(:,30)
         lat  = winddata(:,21)
         latflag = winddata(:,22)
         lon  = winddata(:,24)
         lonflag = winddata(:,25)
         year = thermodata(:,15)
         month = thermodata(:,16)
         day = thermodata(:,17)
         hour = thermodata(:,18)
         minu = thermodata(:,19)

         ;Check QC flags. If there is a QC problem, replace those values with missing values.
         if(any(.not.ismissing(ind(presflag.ge.3)))) then pres(ind(presflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(tmpcflag.ge.3)))) then tmpc_unsmoothed(ind(tmpcflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(dwpcflag.ge.3)))) then dwpc_unsmoothed(ind(dwpcflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(thermohghtflag.ge.3)))) then thermohght(ind(thermohghtflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(uwndflag.ge.3)))) then uwnd(ind(uwndflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(vwndflag.ge.3)))) then vwnd(ind(vwndflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(windhghtflag.ge.3)))) then windhght(ind(windhghtflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(relhflag.ge.3)))) then relh(ind(relhflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(latflag.ge.3)))) then lat(ind(latflag.ge.3)) = fillvalue_hght end if
         if(any(.not.ismissing(ind(lonflag.ge.3)))) then lon(ind(lonflag.ge.3)) = fillvalue_hght end if


         ;Smooth the temperature and dewpoint data with a 1-2-1 smoother
;         tmpc_smoothed = wgt_runave(tmpc_unsmoothed,(/0.25,0.5,0.25/),0)
;        dwpc_smoothed = wgt_runave(dwpc_unsmoothed,(/0.25,0.5,0.25/),0)

         ;The "0" smoothing option in wgt_runave places missing values flags in the first and
         ;last elements of the array, as they are not smoothed. To remove these, we will write
         ;the smoothed data to output files, remove the first and last lines of the files, and
         ;read them back in. I suspect this is faster than looping through the arrays - which is
         ;the only other way I know how to remove missing values - as NCL is very slow with looping....
;         asciiwrite("tmpc_smoothed.tmp",tmpc_smoothed)
;         asciiwrite("dwpc_smoothed.tmp",dwpc_smoothed)
;         system("sed -e '1d' -e '$d' tmpc_smoothed.tmp > tmpc_smoothed_trim.tmp")
;         system("sed -e '1d' -e '$d' dwpc_smoothed.tmp > dwpc_smoothed_trim.tmp")
;         tmpc = asciiread("tmpc_smoothed_trim.tmp",stringtoint(systemfunc("wc tmpc_smoothed_trim.tmp | awk '{print($1)}'")),"float")
;         dwpc = asciiread("dwpc_smoothed_trim.tmp",stringtoint(systemfunc("wc dwpc_smoothed_trim.tmp | awk '{print($1)}'")),"float")
;         HAVE REMOVED SMOOTHER, AS WE ARE USING THE PRE-SMOOTHED DATA FROM SPARC
          tmpc = tmpc_unsmoothed
          dwpc = dwpc_unsmoothed

         ;Find maximum heights of thermo and wind data
         maxhght_thermo = max(thermohght)
         maxhght_wind   = max(windhght)
         maxhght_total  = max((/maxhght_thermo,maxhght_wind/))

         maxhght_string = flt2string(maxhght_total)
         maxhght_string_split = str_split_by_length(maxhght_string,1)
         maxhght_string_short = str_concat(maxhght_string_split(0:(dimsizes(maxhght_string_split)-3)))
         maxhght_rounded = stringtoint(maxhght_string_short)*100

         ;Get header information
         stid = winddata(0,1)
         stnm = winddata(0,1)
         time = systemfunc("echo "+windfiles(n)+" | colrm 55 | colrm 1 48")+"/"+\
                systemfunc("echo "+windfiles(n)+" | colrm 57 | colrm 1 54")+"00"
         slat = winddata(0,10)
         slon = winddata(0,11)
         selv = winddata(0,12)
         stim = systemfunc("echo "+windfiles(n)+" | colrm 57 | colrm 1 54")+"00"
         ptop = thermodata((ndims_thermo(0)-1),26) / 100 ;Convert Pa to hPa
         ztop = maxhght_total

         ;Get number of levels that will be in the output edit file
         ;nlevels_edit = floattoint(max((/maxhght_thermo,maxhght_wind/))/dz - selv/dz) + 1
         nlevels_edit = maxhght_rounded / dz + 1

         ;Interpolate pressure, temperature, and dewpoint to 100m height levels
         edithght = (ceil(thermohght(0)/dz))*dz   ;The level to which we're interpolating
         level = floattoint(edithght/dz)	  ;For array indexing
         pres_interp = new(nlevels_edit,"float")
         tmpc_interp = new(nlevels_edit,"float")
         dwpc_interp = new(nlevels_edit,"float")
         relh_interp = new(nlevels_edit,"float")
         hght_interp = fspan(0,maxhght_rounded,nlevels_edit)
         pres_interp@_FillValue = fillvalue_hght
         tmpc_interp@_FillValue = fillvalue_hght
         dwpc_interp@_FillValue = fillvalue_hght
         relh_interp@_FillValue = fillvalue_hght
         ;If the first observation is from within 20 meters of the lower level, set edit
         ;height to the lower level and use the first observation as the lowest level obs.
         if((thermohght(0)-(edithght-dz)).le.20)then
            edithght = edithght-dz
            level = level - 1
            pres_interp(level) = pres(0)
            tmpc_interp(level) = tmpc(0)
            dwpc_interp(level) = dwpc(0)
            relh_interp(level) = relh(0)
            hght_interp(level) = edithght
            edithght = edithght + dz
            level = level + 1
         end if
         do while(edithght.lt.(maxhght_thermo-dz))
            ;Need this if statement to avoid subscript out of range errors
            if(minind(abs(thermohght-edithght)).lt.min((/dimsizes(thermohght),dimsizes(pres),dimsizes(tmpc),dimsizes(dwpc),dimsizes(relh)/)))then
            if(minind(abs(thermohght-edithght))+1.lt.dimsizes(tmpc))then
               lower_hght = thermohght(maxind(ind((thermohght-edithght)<0)))
               upper_hght = thermohght(minind(abs(thermohght-edithght)))
               lower_pres = pres(maxind(ind((thermohght-edithght)<0)))
               upper_pres = pres(minind(abs(thermohght-edithght)))
               lower_tmpc = tmpc(maxind(ind((thermohght-edithght)<0)))
               upper_tmpc = tmpc(minind(abs(thermohght-edithght)))
               lower_dwpc = dwpc(maxind(ind((thermohght-edithght)<0)))
               upper_dwpc = dwpc(minind(abs(thermohght-edithght)))
               lower_relh = relh(maxind(ind((thermohght-edithght)<0)))
               upper_relh = relh(minind(abs(thermohght-edithght)))
               if(maxind(ind((thermohght-edithght)<0)).eq.minind(abs(thermohght-edithght)))then
                  upper_hght = thermohght(minind(abs(thermohght-edithght))+1)
                  upper_pres = pres(minind(abs(thermohght-edithght))+1)
                  upper_tmpc = tmpc(minind(abs(thermohght-edithght))+1)
                  upper_dwpc = dwpc(minind(abs(thermohght-edithght))+1)
                  upper_relh = relh(minind(abs(thermohght-edithght))+1)
               end if
               if((lower_hght-upper_hght).le.400)then   ;Only interpolate if layer <= 400m thick
                  if((lower_hght.ne.upper_hght).and.(upper_hght.ne.lower_hght))then     ;Avoid divide by zero errors
                     pres_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                          (upper_pres-lower_pres)+lower_pres
                  else
                     pres_interp(level) = upper_pres
                  end if
                  if((upper_tmpc.ne.lower_tmpc).and.(upper_hght.ne.lower_hght))then
                     tmpc_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                          (upper_tmpc-lower_tmpc)+lower_tmpc
                  else
                     tmpc_interp(level) = upper_tmpc
                  end if
                  if((upper_dwpc.ne.lower_dwpc).and.(upper_hght.ne.lower_hght))then
                     dwpc_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                          (upper_dwpc-lower_dwpc)+lower_dwpc
                  else
                     dwpc_interp(level) = upper_dwpc
                  end if
                  if((upper_relh.ne.lower_relh).and.(upper_hght.ne.lower_hght))then
                     relh_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                          (upper_relh-lower_relh)+lower_relh
                  else
                     relh_interp(level) = upper_relh
                  end if
                  hght_interp(level) = edithght
               end if      
               if(any(thermohght-edithght).eq.0)then    ;If we're right on a 100-m level, take those values instead 
                  pres_interp(level) = pres(ind(thermohght-edithght.eq.0))
                  tmpc_interp(level) = tmpc(ind(thermohght-edithght.eq.0))
                  dwpc_interp(level) = dwpc(ind(thermohght-edithght.eq.0))
                  relh_interp(level) = relh(ind(thermohght-edithght.eq.0))
               end if              
               delete(lower_hght)
               delete(upper_hght)
               delete(lower_pres)
               delete(upper_pres)
               delete(lower_tmpc)
               delete(upper_tmpc)
               delete(lower_dwpc)
               delete(upper_dwpc)
               delete(lower_relh)
               delete(upper_relh) 
            end if
            end if
            edithght = edithght + dz
            level = level + 1
         end do

         ;Delete a bunch of arrays, as we're finished with them for this iteration
         delete(thermodata) 
         delete(winddata)
         delete(pres)
         delete(presflag)
         delete(tmpc_unsmoothed)
         delete(tmpcflag)
         delete(dwpc_unsmoothed)
         delete(dwpcflag)
;         delete(tmpc_smoothed)
;         delete(dwpc_smoothed)
         delete(tmpc)
         delete(dwpc)
         delete(thermohght)
         delete(thermohghtflag)
         delete(relh)
         delete(relhflag)
         ;Interpolate wind components to 100m height levels
         edithght = (ceil(windhght(0)/dz))*dz 
         level = floattoint(edithght/dz)
         uwnd_interp = new(nlevels_edit,"float")
         vwnd_interp = new(nlevels_edit,"float") 
         lats_interp = new(nlevels_edit,"float")
         lons_interp = new(nlevels_edit,"float")
         ;hght_interp = fspan(0,maxhght_rounded,nlevels_edit)
         ;hght_interp = new(nlevels_edit,"float")
         year_interp = new(nlevels_edit,"float")
         month_interp = new(nlevels_edit,"float")
         day_interp = new(nlevels_edit,"float")
         hour_interp = new(nlevels_edit,"float")
         minu_interp = new(nlevels_edit,"float")
         dattim_interp = new(nlevels_edit,"string")
         uwnd_interp@_FillValue = fillvalue_hght
         vwnd_interp@_FillValue = fillvalue_hght
         lats_interp@_FillValue = fillvalue_hght
         lons_interp@_FillValue = fillvalue_hght
         hght_interp@_FillValue = fillvalue_hght
         dattim_interp@_FillValue = fillvalue_hght
         ;If the first observation is from lower than 20 meters, set edit height to zero
         ;and use the first observation as the 0-meter obs.
         if((windhght(0)-(edithght-dz)).le.20)then
            edithght = edithght-dz
            level = level - 1
            uwnd_interp(level) = uwnd(0)
            vwnd_interp(level) = vwnd(0)
            lats_interp(level) = lat(0)
            lons_interp(level) = lon(0)
            year_interp(level) = year(0)
            month_interp(level) = month(0)
            day_interp(level) = day(0)
            hour_interp(level) = hour(0)
            minu_interp(level) = minu(0)
            hght_interp(level) = edithght
            ;Create first element of dattim interp array
            yr = floattoint(year_interp(level))-2000
            mo = floattoint(month_interp(level))
            d = floattoint(day_interp(level))
            h = floattoint(hour_interp(level))
            m = floattoint(minu_interp(level))
            idate = new((/1/),"long")
            idate = yr*100000000+mo*1000000+d*10000+h*100+m
            dattim_interp(level) = yr*100000000+mo*1000000+d*10000+h*100+m
            if((year_interp(level).ge.2000.).and.(year_interp(level).lt.2010.))then
               dattim_interp(level) = "0"+dattim_interp(level)
            end if
            edithght = edithght + dz
            level = level + 1
         end if
         do while(edithght.lt.(maxhght_wind-dz))
            ;Need this if statement to avoid subscript out of range errors
            ;if(minind(abs(thermohght-edithght)).lt.min((/dimsizes(windhght),dimsizes(uwnd),dimsizes(vwind),dimsizes(lat),dimsizes(lon)/))then
            if(maxind(ind((windhght-edithght))).lt.dimsizes(year))then
               lower_hght = windhght(maxind(ind((windhght-edithght)<0)))
               upper_hght = windhght(minind(abs(windhght-edithght)))
               lower_uwnd = uwnd(maxind(ind((windhght-edithght)<0)))
               upper_uwnd = uwnd(minind(abs(windhght-edithght)))
               lower_vwnd = vwnd(maxind(ind((windhght-edithght)<0)))
               upper_vwnd = vwnd(minind(abs(windhght-edithght)))
               lower_lats = lat(maxind(ind((windhght-edithght)<0)))
               upper_lats = lat(minind(abs(windhght-edithght)))
               lower_lons = lon(maxind(ind((windhght-edithght)<0)))
               upper_lons = lon(minind(abs(windhght-edithght)))
               if(maxind(ind((windhght-edithght)<0)).eq.minind(abs(windhght-edithght)))then
                  upper_hght = windhght(minind(abs(windhght-edithght))+1)
                  upper_uwnd = uwnd(minind(abs(windhght-edithght))+1)
                  upper_vwnd = vwnd(minind(abs(windhght-edithght))+1)
                  upper_lats = lat(minind(abs(windhght-edithght))+1)
                  upper_lons = lon(minind(abs(windhght-edithght))+1)
               end if
               if((upper_hght-lower_hght).le.400)then  ;Only interpolate if layer is <= 400m thick
                  if((upper_uwnd.ne.lower_uwnd).and.(upper_hght.ne.lower_hght))then     ;Avoid divide by zero error
                     uwnd_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                          (upper_uwnd-lower_uwnd)+lower_uwnd
                  else
                     uwnd_interp(level) = upper_uwnd   ;If upper and lower values are the same,
                  end if                               ;interpolated value will be the same
                  if ((upper_vwnd.ne.lower_vwnd).and.(upper_hght.ne.lower_hght))then
                     vwnd_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                          (upper_vwnd-lower_vwnd)+lower_vwnd
                  else
                     vwnd_interp(level) = upper_vwnd
                  end if
                  if ((upper_lats.ne.lower_lats).and.(upper_hght.ne.lower_hght))then
                     lats_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                          (upper_lats-lower_lats)+lower_lats
                  else
                     lats_interp(level) = upper_lats
                  end if
                  if((upper_lons.ne.lower_lons).and.(upper_hght.ne.lower_hght))then
                     lons_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                          (upper_lons-lower_lons)+lower_lons
                  else
                     lons_interp(level) = upper_lons
                  end if
                  year_interp(level)  = year(maxind(ind((windhght-edithght)<0)))
                  month_interp(level) = month(maxind(ind((windhght-edithght)<0)))
                  day_interp(level)   = day(maxind(ind((windhght-edithght)<0)))
                  hour_interp(level)  = hour(maxind(ind((windhght-edithght)<0)))
                  minu_interp(level)  = minu(maxind(ind((windhght-edithght)<0)))
                  hght_interp(level)  = edithght
            ;end if
                  ;Create dattim_interp array
                  yr = floattoint(year_interp(level))-2000
                  mo = floattoint(month_interp(level))
                  d = floattoint(day_interp(level))
                  h = floattoint(hour_interp(level))
                  m = floattoint(minu_interp(level))
                  idate = new((/1/),"long")
                  idate = yr*100000000+mo*1000000+d*10000+h*100+m 
                  dattim_interp(level) = yr*100000000+mo*1000000+d*10000+h*100+m 
                  if((year_interp(level).ge.2000.).and.(year_interp(level).lt.2010.))then
                   dattim_interp(level) = "0"+dattim_interp(level)
                  end if
                  ;Create dattim_interp array
;                  yrstringsplit = str_split_by_length(flt2string(year_interp(level)),2)
;                  yr = yrstringsplit(1)
;                  mo = flt2string(month_interp(level))
;                  if(month_interp(level).lt.10)then
;                     mo = "0"+flt2string(month_interp(level))
;                  end if
;                  d = flt2string(day_interp(level))
;                  if(day_interp(level).lt.10)then
;                     d = "0"+flt2string(day_interp(level))
;                  end if
;                  h = flt2string(hour_interp(level))
;                  if(hour_interp(level).lt.10)then
;                    h = "0"+flt2string(hour_interp(level))
;                  end if
;                  m = flt2string(minu_interp(level))
;                  if(minu_interp(level).lt.10)then
;                     m = "0"+flt2string(minu_interp(level))
;                  end if
;                  dattim_interp(level) = yr+mo+d+h+m 
               end if
               if(any(windhght-edithght).eq.0)then    ;If we're right on a 100-m level, take those values instead 
                  uwnd_interp(level) = uwnd(ind(thermohght-edithght.eq.0))
                  vwnd_interp(level) = vwnd(ind(thermohght-edithght.eq.0))
                  lats_interp(level) = lats(ind(thermohght-edithght.eq.0))
                  lons_interp(level) = lons(ind(thermohght-edithght.eq.0))
                  year_interp(level) = year(ind(thermohght-edithght.eq.0))
                  month_interp(level) = month(ind(thermohght-edithght.eq.0))
                  day_interp(level) = day(ind(thermohght-edithght.eq.0))
                  hour_interp(level) = hour(ind(thermohght-edithght.eq.0))
                  minu_interp(level) = minu(ind(thermohght-edithght.eq.0))
                  hght_interp(level) = edithght
                  ;Create dattim_interp array
                  yr = floattoint(year_interp(level))-2000
                  mo = floattoint(month_interp(level))
                  d = floattoint(day_interp(level))
                  h = floattoint(hour_interp(level))
                  m = floattoint(minu_interp(level))
                  idate = new((/1/),"long")
                  idate = yr*100000000+mo*1000000+d*10000+h*100+m
                  dattim_interp(level) = yr*100000000+mo*1000000+d*10000+h*100+m
                  if((year_interp(level).ge.2000.).and.(year_interp(level).lt.2010.))then
                   dattim_interp(level) = "0"+dattim_interp(level)
                  end if
               end if           
            end if
            edithght = edithght + dz
            level = level + 1
         end do

         ;Delete more arrays we're finished with
         delete(uwnd)
         delete(uwndflag)
         delete(vwnd)
         delete(vwndflag)
         delete(windhght)
         delete(windhghtflag)
         delete(lat)
         delete(latflag)
         delete(lon)
         delete(lonflag)
         delete(year_interp)
         delete(month_interp)
         delete(day_interp)
         delete(hour_interp)
         delete(minu_interp)

         ;Convert pressure from Pa to hPa
         pres_interp = pres_interp / 100.

         ;Apply Bogner (2000) correction to remove anomalous saturated 
         ;superadiabiatic layers due to wetbulbing.
         ;Actually, it appears that the QC'd RRS data provided by SUNY-Stony Brook
         ;has already been checked for superadiabatic layers, so will hold off on 
         ;applying the Bogner correction.
      
         ;----------------------------------------------;
         ;Write header and sounding data temporary files;
         ;----------------------------------------------;
         ;Create temporary file with header information to read into C++ program
         headerinfo = new(9,"string")
         headerinfo(0) = stid
         headerinfo(1) = stnm
         headerinfo(2) = time
         headerinfo(3) = slat
         headerinfo(4) = slon
         headerinfo(5) = selv
         headerinfo(6) = stim
         headerinfo(7) = ptop
         headerinfo(8) = ztop
         asciiwrite("header.tmp",headerinfo)
         ;Create temporary file with sounding data to read into C++ program
         nvalues = nlevels_edit
         soundingdata = new((/10,nvalues/),"string")
         soundingdata(0,:) = pres_interp
         soundingdata(1,:) = tmpc_interp
         soundingdata(2,:) = dwpc_interp
         soundingdata(3,:) = uwnd_interp
         soundingdata(4,:) = vwnd_interp
         soundingdata(5,:) = hght_interp
         soundingdata(6,:) = relh_interp
         soundingdata(7,:) = lats_interp
         soundingdata(8,:) = lons_interp
         soundingdata(9,:) = dattim_interp
         asciiwrite("sounding.tmp",soundingdata)

         delete(tmpc_interp)
         delete(dwpc_interp)
         delete(uwnd_interp)
         delete(vwnd_interp)
         delete(hght_interp)
         delete(relh_interp)
         delete(lats_interp)
         delete(lons_interp)
         delete(dattim_interp)
         delete(soundingdata)    
 
         ;Create editsonde filename and determine number of lines in
         ;sounding.tmp
         stid_string = flt2string(stid)
         if(stid.lt.10000)then
            stid_string = "0"+flt2string(stid)
         end if
         yearstringlong = flt2string(year(dimsizes(year)-1))
         yearstringsplit = str_split_by_length(yearstringlong,2)
         yearstring = yearstringsplit(1)
         monthstring = flt2string(month(dimsizes(month)-1))
         if(month(0).lt.10)then
            monthstring = "0"+flt2string(month(dimsizes(month)-1))
         end if
         daystring   = flt2string(day(dimsizes(day)-1))
         if(day(dimsizes(day)-1).lt.10)then
            daystring = "0"+flt2string(day(dimsizes(day)-1))
         end if
         editfilename = stid_string+"-"+yearstring+monthstring+daystring+stim+suffix
         nlinessoundingfile = systemfunc("wc sounding.tmp | awk '{print($1)}'")

         delete(year)
         delete(month)
         delete(day)
         delete(hour)
         delete(minu)
         delete(pres_interp)     
         delete(maxhght_string_split)
         delete(maxhght_string_short)
 
         ;CALL create_editfile.cpp TO CREATE THE EDIT FILE FROM THE DATA ABOVE
         system(progpath+"create_editfile "+nclpath+"header.tmp "+nclpath+"sounding.tmp "+\
               editpath+editfilename+" "+nlinessoundingfile) 
   ;Delete last line of edit file to remove some weird things at top of sounding
;   system("sed -i '$d' "+editpath+editfilename)

   ;Iterate loop counters
         n = n + 1        ;Sounding file counter
      end do
      delete(thermofiles)
      delete(windfiles)
      j = j + 1        ;Station directory counter
   end do
;system("\rm *.tmp")   ;Remove temporary files
