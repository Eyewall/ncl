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
editpath  = "/jm13/pduran/6sec_newest/"    ;Where output files will be written
progpath  = "/jm13/pduran/unix_scripts_and_c++/" ;Directory where C++ program is located
nclpath   = systemfunc("pwd")+"/"                ;Directory in which this script is being run

;Set parameters
dz = 100           ;Level spacing to interpolate to in meters
ncolsthermo = 20   ;Number of columns in thermodynamic sounding file
fillvalue_hght   = -9999. ;Fill value to use for height in edit file output
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit" ;Suffix for output edit file name

;Remove all lines from the input files that contain missing data. Missing data
;is marked by "99999" in the RRS files...Also, replace every series of 5 asterisks
;with -99.9 so that the file may be read in without problems. We will also remove
;the 21 header rows from the input files so that we can use asciiRead instead of
;readAsciiTable, which can be very slow for large files
system("sed '/999\.0/d' xxxxx > thermofile_init.tmp")
system("sed 's/\*\*\*\*\*/-99.9/g' thermofile_init.tmp > thermofile.tmp1")
system("sed '1,21d' thermofile.tmp1 | colrm 1 28 > thermofile.tmp")
soundingfile = "xxxxx"

;Read in the data tables to arrays
nrowsthermo = stringtoint(systemfunc("wc thermofile.tmp" ))
thermodata = asciiread("thermofile.tmp",(/nrowsthermo,ncolsthermo/),"float")
thermodata@_FillValue = fillvalue_hght
ndims_thermo = dimsizes(thermodata) ;2-D
   
;Get the relevant data from the arrays
pres = thermodata(:,0)
presflag = thermodata(:,14)
tmpc = thermodata(:,1)
tmpcflag = thermodata(:,15)
dwpc = thermodata(:,2)
thermohght = thermodata(:,13)
thermohghtflag = thermodata(:,19)
uwnd = thermodata(:,4)
uwndflag = thermodata(:,17)
vwnd = thermodata(:,5)
vwndflag = thermodata(:,18)
windhght = thermohght 
windhghtflag = thermohghtflag
relh = thermodata(:,3)
relhflag = thermodata(:,16)
lat  = thermodata(:,10)
lon  = thermodata(:,9)

;Check QC flags. If there is a QC problem, replace those values with missing values.
if(any(.not.ismissing(ind((presflag.eq.2).or.(presflag.eq.3))))) then pres(ind(presflag.lt.99)) = fillvalue_hght end if
if(any(.not.ismissing(ind((tmpcflag.eq.2).or.(tmpcflag.eq.3))))) then tmpc(ind(tmpcflag.lt.99)) = fillvalue_hght end if
if(any(.not.ismissing(ind((thermohghtflag.eq.2).or.(thermohghtflag.eq.3))))) then thermohght(ind(thermohghtflag.lt.99)) = fillvalue_hght end if
if(any(.not.ismissing(ind((uwndflag.eq.2).or.(uwndflag.eq.3))))) then uwnd(ind(uwndflag.lt.99)) = fillvalue_hght end if
if(any(.not.ismissing(ind((vwndflag.eq.2).or.(vwndflag.eq.3))))) then vwnd(ind(vwndflag.lt.99)) = fillvalue_hght end if
if(any(.not.ismissing(ind((windhghtflag.eq.2).or.(windhghtflag.eq.3))))) then windhght(ind(windhghtflag.lt.99)) = fillvalue_hght end if
if(any(.not.ismissing(ind((relhflag.eq.2).or.(relhflag.eq.3))))) then relh(ind(relhflag.lt.99)) = fillvalue_hght end if


;Find maximum heights of thermo and wind data
maxhght_total = max(thermohght)

maxhght_string = flt2string(maxhght_total)
maxhght_string_split = str_split_by_length(maxhght_string,1)
maxhght_string_short = str_concat(maxhght_string_split(0:(dimsizes(maxhght_string_split)-3)))
maxhght_rounded = stringtoint(maxhght_string_short)*100
;Get filename and header information
year = stringtofloat(systemfunc("sed -n 6p "+soundingfile+" | sed 's/,//g' | awk '{print($6)}' | cut -c3-4"))
month = stringtofloat(systemfunc("sed -n 6p "+soundingfile+" | sed 's/,//g' | awk '{print($7)}'"))
day =   stringtofloat(systemfunc("sed -n 6p "+soundingfile+" | sed 's/,//g' | awk '{print($8)}'"))
hour =  stringtofloat(systemfunc("sed -n 6p "+soundingfile+" | sed 's/:/ /g' | awk '{print($9)}'"))
minu =  stringtofloat(systemfunc("sed -n 6p "+soundingfile+" | sed 's/:/ /g' | awk '{print($10)}'"))
stid = systemfunc("sed -n 1p "+soundingfile+" | cut -c1-5")
stnm = systemfunc("sed -n 4p "+soundingfile+" | cut -c1-5")
slat = systemfunc("sed -n 5p "+soundingfile+" | sed 's/,//g' | awk '{print($10)}'")
slon = systemfunc("sed -n 5p "+soundingfile+" | sed 's/,//g' | awk '{print($9)}'")
selv = systemfunc("sed -n 5p "+soundingfile+" | sed 's/,//g' | awk '{print($11)}'")
stim = systemfunc("echo "+soundingfile+" | cut -c54-55")+"00"
time = systemfunc("echo "+soundingfile+" | cut -c48-53")+"/"+stim
datetime = systemfunc("echo "+soundingfile+" | cut -c48-53")+stim
ptop = thermodata((ndims_thermo(0)-1),0) / 100 ;Convert Pa to hPa
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
hght_interp@_FillValue = fillvalue_hght
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
do while(edithght.lt.(maxhght_total-dz))
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
         if((.not.ismissing(lower_hght)).and.(.not.ismissing(upper_hght)))then
         if((lower_hght.ne.upper_hght).and.(upper_hght.ne.lower_hght))then     ;Avoid divide by zero errors
            pres_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                 (upper_pres-lower_pres)+lower_pres
         else
            pres_interp(level) = upper_pres
         end if
         end if
         if((.not.ismissing(lower_tmpc)).and.(.not.ismissing(upper_tmpc)))then
         if((upper_tmpc.ne.lower_tmpc).and.(upper_hght.ne.lower_hght))then
            tmpc_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                 (upper_tmpc-lower_tmpc)+lower_tmpc
         else
            tmpc_interp(level) = upper_tmpc
         end if
         end if
         if((.not.ismissing(lower_dwpc)).and.(.not.ismissing(upper_dwpc)))then
         if((upper_dwpc.ne.lower_dwpc).and.(upper_hght.ne.lower_hght))then
            dwpc_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                 (upper_dwpc-lower_dwpc)+lower_dwpc
         else
            dwpc_interp(level) = upper_dwpc
         end if
         end if
         if((.not.ismissing(lower_relh)).and.(.not.ismissing(upper_relh)))then
         if((upper_relh.ne.lower_relh).and.(upper_hght.ne.lower_hght))then
            relh_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                 (upper_relh-lower_relh)+lower_relh
         else
            relh_interp(level) = upper_relh
         end if
         end if
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
delete(pres)
delete(presflag)
delete(tmpcflag)
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
   dattim_interp(level) = datetime(0)
   edithght = edithght + dz
   level = level + 1
end if
do while(edithght.lt.(maxhght_total-dz))
   ;Need this if statement to avoid subscript out of range errors
   ;if(minind(abs(thermohght-edithght)).lt.min((/dimsizes(windhght),dimsizes(uwnd),dimsizes(vwind),dimsizes(lat),dimsizes(lon)/))then
   if(maxind(ind((windhght-edithght))).lt.dimsizes(uwnd))then
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
         if((.not.ismissing(lower_uwnd)).and.(.not.ismissing(upper_uwnd)))then
         if((upper_uwnd.ne.lower_uwnd).and.(upper_hght.ne.lower_hght))then     ;Avoid divide by zero error
            uwnd_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                 (upper_uwnd-lower_uwnd)+lower_uwnd
         else
            uwnd_interp(level) = upper_uwnd   ;If upper and lower values are the same,
         end if                               ;interpolated value will be the same
         end if
         if((.not.ismissing(lower_vwnd)).and.(.not.ismissing(upper_vwnd)))then
         if ((upper_vwnd.ne.lower_vwnd).and.(upper_hght.ne.lower_hght))then
            vwnd_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                 (upper_vwnd-lower_vwnd)+lower_vwnd
         else
            vwnd_interp(level) = upper_vwnd
         end if
         end if
         if((.not.ismissing(lower_lats)).and.(.not.ismissing(upper_lats)))then
         if ((upper_lats.ne.lower_lats).and.(upper_hght.ne.lower_hght))then
            lats_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                 (upper_lats-lower_lats)+lower_lats
         else
            lats_interp(level) = upper_lats
         end if
         end if
         if((.not.ismissing(lower_lons)).and.(.not.ismissing(upper_lons)))then
         if((upper_lons.ne.lower_lons).and.(upper_hght.ne.lower_hght))then
            lons_interp(level) = (edithght-lower_hght)/(upper_hght-lower_hght)*\
                                 (upper_lons-lower_lons)+lower_lons
         else
            lons_interp(level) = upper_lons
         end if
         end if
;         year_interp(level)  = year(maxind(ind((windhght-edithght)<0)))
;         month_interp(level) = month(maxind(ind((windhght-edithght)<0)))
;         day_interp(level)   = day(maxind(ind((windhght-edithght)<0)))
;         hour_interp(level)  = hour(maxind(ind((windhght-edithght)<0)))
;         minu_interp(level)  = minu(maxind(ind((windhght-edithght)<0)))
;         hght_interp(level)  = edithght
   ;end if
         ;Create dattim_interp array
;         yr = floattoint(year_interp(level))-2000
;         mo = floattoint(month_interp(level))
;         d = floattoint(day_interp(level))
;         h = floattoint(hour_interp(level))
;         m = floattoint(minu_interp(level))
;         idate = new((/1/),"long")
;         idate = yr*100000000+mo*1000000+d*10000+h*100+m 
         dattim_interp(level) = datetime(0) 
;         ;Create dattim_interp array
;          yrstringsplit = str_split_by_length(flt2string(year_interp(level)),2)
;          yr = yrstringsplit(1)
;          mo = flt2string(month_interp(level))
;          if(month_interp(level).lt.10)then
;             mo = "0"+flt2string(month_interp(level))
;          end if
;          d = flt2string(day_interp(level))
;          if(day_interp(level).lt.10)then
;             d = "0"+flt2string(day_interp(level))
;          end if
;          h = flt2string(hour_interp(level))
;          if(hour_interp(level).lt.10)then
;            h = "0"+flt2string(hour_interp(level))
;          end if
;          m = flt2string(minu_interp(level))
;          if(minu_interp(level).lt.10)then
;             m = "0"+flt2string(minu_interp(level))
;          end if
;          dattim_interp(level) = yr+mo+d+h+m 
      end if
      if(any(windhght-edithght).eq.0)then    ;If we're right on a 100-m level, take those values instead 
         uwnd_interp(level) = uwnd(ind(thermohght-edithght.eq.0))
         vwnd_interp(level) = vwnd(ind(thermohght-edithght.eq.0))
         lats_interp(level) = lats(ind(thermohght-edithght.eq.0))
         lons_interp(level) = lons(ind(thermohght-edithght.eq.0))
;         year_interp(level) = year(ind(thermohght-edithght.eq.0))
         month_interp(level) = month(ind(thermohght-edithght.eq.0))
         day_interp(level) = day(ind(thermohght-edithght.eq.0))
         hour_interp(level) = hour(ind(thermohght-edithght.eq.0))
         minu_interp(level) = minu(ind(thermohght-edithght.eq.0))
         hght_interp(level) = edithght
         ;Create dattim_interp array
;         yr = floattoint(year_interp(level))-2000
;         mo = floattoint(month_interp(level))
;         d = floattoint(day_interp(level))
;         h = floattoint(hour_interp(level))
;         m = floattoint(minu_interp(level))
;         idate = new((/1/),"long")
;         idate = yr*100000000+mo*1000000+d*10000+h*100+m
         dattim_interp(level) = datetime(0) 
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
delete(lon)
delete(year_interp)
delete(month_interp)
delete(day_interp)
delete(hour_interp)
delete(minu_interp)

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
yymmddhhmm = systemfunc("echo "+soundingfile+" | cut -c 48-55")+"00"
editfilename = stid+"-"+yymmddhhmm+suffix
print(editfilename)
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
