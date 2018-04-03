load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-----------------------------------------------------------------------------------------------
; get_ir_brightness_temp.ncl
; Patrick Duran
; 2015
; 
; NOTE: This script finds the closest satellite image in time in the satpath directory
; to the dropsonde deployments in the dropdir directory. Since I have both GOES-13
; and GOES-15 files in the sat directory, it might pull a GOES-15 image for an
; Atlantic basin storm! I haven't fixed this yet except for Patricia 10/21/2015, so be aware...
;
; 16 AUGUST 2016
; WARNING: IT APPEARS THAT THIS SCRIPT MIGHT NOT ACCURATELY DETERMINE THE CLOSEST
;          SATELLITE IMAGE IN TIME TO THE OBSERVATIONS. NEED TO CHECK THAT BEFORE
;          PROCEEDING WITH HS3 CALCULATIONS, ALTHOUGH IT SHOULD NOT CHANGE THE
;          RESULTS IN A HUGE WAY.
;-----------------------------------------------------------------------------------------------

;Set the dropsonde and center track files and McIdas area file path
storm     = "patricia"
date      = "20151023"
transect  = "transect1"
dropdir   = "/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"
droplist  = "/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"+transect
satpath   = "/jm13/pduran/sat/"
outdir    = "/jm13/pduran/onr/ir/tb/"
outfile   = outdir+"ir-Tb-drops-"+storm+"-"+date+"-"+transect
tablefile = "/jm13/pduran/sat/tables/coeff.txt"
type      = "tci"   ;Options: "hs3" or "tci"
coordtyp  = "1"  ;Set to 0 to get coords from sonde files, 1 to get coords from coordfile
dateshort = systemfunc("echo "+date+" | colrm 1 4")
coordfile = "/jm13/pduran/dropsondes/onr/finalqc/droplocs_parallax_corrected/droplist-loc-"+dateshort+"-plax15-lincorr.dat"

;Create output files
;   timediffs.txt contains time differences between satellite time and dropsonde deployment time
;   outfile contains the output IR brightness temperatures
system("\rm "+outfile+" "+outdir+"timediffs.txt")
system("touch "+outfile)
system("touch "+outdir+"timediffs.txt")

;Read the satellite coefficient table file
table = readAsciiTable(tablefile,8,"float",(/2,13/))

;Read the list of dropsondes and satellite ncdf files into an array
system("echo Getting file lists. Please wait...     `date`")
if(type.eq."hs3")then
   dropfiles = systemfunc("awk '{print($2)}' "+droplist)
else if(type.eq."tci")then
   dropfiles = dropdir+systemfunc("cat "+droplist)
end if
end if
satfiles  = systemfunc("ls "+satpath+"*.nc")

;Get dates and times for drops and satellite images;
if(type.eq."hs3")then
   dropyear_str = systemfunc("awk '{print($2)}' "+droplist+" | awk -F'/' '{print $NF}' | cut -c 2-5")
   dropyear     = stringtoint(dropyear_str)
   dropmon_str  = systemfunc("awk '{print($2)}' "+droplist+" | awk -F'/' '{print $NF}' | cut -c 6-7")
   dropmon      = stringtoint(dropmon_str)
   dropday_str  = systemfunc("awk '{print($2)}' "+droplist+" | awk -F'/' '{print $NF}' | cut -c 8-9")
   dropday      = stringtoint(dropday_str)
   drophour_str = systemfunc("awk '{print($2)}' "+droplist+" | awk -F'/' '{print $NF}' | awk -F'_' '{print $2}' | cut -c 1-2")
   drophour     = stringtoint(drophour_str)
   dropminu_str = systemfunc("awk '{print($2)}' "+droplist+" | awk -F'/' '{print $NF}' | awk -F'_' '{print $2}' | cut -c 3-4")
   dropminu = stringtofloat(dropminu_str)
else if(type.eq."tci")then
   dropyear = stringtoint(systemfunc("echo "+date+" | cut -c 1-4"))
   dropmon  = stringtoint(systemfunc("echo "+date+" | cut -c 5-6"))
   dropday  = stringtoint(systemfunc("echo "+date+" | cut -c 7-8"))
   drophour = stringtoint(systemfunc("awk -F '_' '{print $2}' "+droplist+" | cut -c 1-2"))
   dropminu = stringtoint(systemfunc("awk -F '_' '{print $2}' "+droplist+" | cut -c 3-4"))
   dropyear := conform(drophour,dropyear,-1)
   dropmon  := conform(drophour,dropmon,-1)
   dropday  := conform(drophour,dropday,-1)
end if
end if
satyr   = systemfunc("ls "+satpath+"*.nc | awk -F'/' '{print $NF}' | awk -F'.' '{print $2}'")
satdy   = systemfunc("ls "+satpath+"*.nc | awk -F'/' '{print $NF}' | awk -F'.' '{print $3}'")
sathour = stringtoint(systemfunc("ls "+satpath+"*.nc | awk -F'/' '{print $NF}' | awk -F'.' '{print $4}' | cut -c 1-2"))
satminu = stringtofloat(systemfunc("ls "+satpath+"*.nc | awk -F'/' '{print $NF}' | awk -F'.' '{print $4}' | cut -c 3-4"))

;Convert dates and times into Julian date arrays
julian_drop = greg2jul(dropyear,dropmon,dropday,drophour) + dropminu/1440
satdate = yyyyddd_to_yyyymmdd(stringtoint(satyr+satdy))
asciiwrite("satdate.tmp",satdate)
satyear = stringtoint(satyr)
satmon = stringtoint(systemfunc("cat satdate.tmp | cut -c 5-6"))
satday = stringtoint(systemfunc("cat satdate.tmp | cut -c 7-8"))
julian_sat = greg2jul(satyear,satmon,satday,sathour) + satminu/1440

;Loop through all drops, find the closest time for each, and get brightness temperature
ndrops = dimsizes(dropfiles)
brightness_temperatures = new(ndrops,float)
do i=0,ndrops-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+ndrops+"    `date`")

   ;Get drop location
   if(coordtyp.eq.0)then   ;Use drop coordinates from individual sounding files
      if(type.eq."hs3")then
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
      else if(type.eq."tci")then
         if(storm.eq."patricia".and.date.eq."20151021")then
            droplat = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print $3}'"))
            droplon = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print $6}'"))
         else
            droplat = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print $3}'"))
            droplon = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print $5}' | colrm 1 1"))
         end if
      end if
      end if
   else    ;Use parallax-corrected drop coordinates from list file
      droplat = stringtofloat(systemfunc("sed -n "+unixi+"p "+coordfile+" | awk '{print $5}'"))
      droplon = stringtofloat(systemfunc("sed -n "+unixi+"p "+coordfile+" | awk '{print $4}'")) 
   end if
 
   ;Find the satellite image time closest to drop time
   satind = minind(abs(julian_sat - julian_drop(i)))
   timediff = min(abs(julian_sat - julian_drop(i)))*24*60 ;Units minutes
   satfile = satfiles(satind)













;FOR PATRICIA, WE ARE USING ONLY 1 IR IMAGE FOR PLOTTING, SO TO BE CONSISTENT
;WE WANT TO USE ONLY 1 IR IMAGE FOR NUMERICAL TB CALCULATIONS. SO WE SET THEM
;MANUALLY HERE
   if(date.eq."20151021")then  ;We need to use GOES-13 rather than GOES-15
      satfile = "/jm13/pduran/sat/goes13.2015.294.201520.BAND_04.nc"
   else if(date.eq."20151022")then
      satfile = "/jm13/pduran/sat/goes15.2015.295.183017.BAND_04.nc"
   else if(date.eq."20151023")then
      satfile = "/jm13/pduran/sat/goes15.2015.296.200018.BAND_04.nc"
   end if
   end if
   end if













;   if(date.eq."20151023")then
;      satfile = "
print(satfile)
   if(timediff.gt.16)then
      system("echo WARNING: TIME DIFFERENCE BETWEEN DROP TIME AND SATELLITE IMAGE TIME > 16 MINUTES")
      system("echo Dropfile: "+dropfiles(i)+"   Satfile: "+satfile)
      system("echo NO BRIGHTNESS TEMPERATURE FOUND FOR THIS DROPFILE.")
   else  
      ;---------------------------------------;
      ;    Now get brightness temperatures    ;
      ;---------------------------------------;
      ;Load netCDF file
      f = addfile(satfile,"r")
   
      ;Get data from netCDF file
      ir = f->data(0,:,:)    ;float
      latitude = f->lat      ;float
      longitude = f->lon     ;float
      sat = f->sensorID      ;char
      band = f->bands        ;int
   
      ;-------------------------------------------------------------------------------------------------;
      ;CALCULATE BRIGHTNESS TEMPERATURE FROM RAW GVAR SATELLITE COUNTS                                  ;
      ;Helpful documentation:                                                                           ;
      ;http://www.ncdc.noaa.gov/sites/default/files/attachments/Satellite-Frequently-Asked-Questions.pdf;
      ;https://www.ssec.wisc.edu/mcidas/doc/users_guide/2010.2/app_c-1.html                             ;
      ;http://www.ospo.noaa.gov/Operations/GOES/calibration/gvar-conversion.html                        ; 
      ;-------------------------------------------------------------------------------------------------;
      ir = ir/32    ;Convert 16-bit to 10-bit
   
      ;Constants for calibration equations
      c1 = .00001191066  ;Units [mW/(m^2-sr-cm^-4)]
      c2 = 1.438833      ;Units [K/cm^-1]
      
      ;Now get the sensor-dependent calibration coefficients
      ;See table file at top of script for variable names
      index = ind((table(:,0).eq.sat).and.(table(:,2).eq.band))
      if(ismissing(index))then
         print("ERROR: Coefficients for this satellite not in table file "+tablefile)
         print("       McIdas Satellite Number: "+sat+"  Channel: "+band)  
         exit
      end if
      coeffs = table(index,:)
      b = coeffs(3)
      m = coeffs(4)
      n = coeffs(5)
      A = coeffs(6)
      B = coeffs(7)
   
      ;Calculate radiance
      r = (ir-b)/m
   
      ;Calculate effective temperature
      ;(First determining whether argument of log is negative; if so, set to missing)
      arg_before = new(dimsizes(ir),"float")
      arg_before = 1+(c1*n^3)/r
      arg = where((arg_before.eq.0).or.(arg_before.eq.162965.4),arg_before@_FillValue,arg_before)
      Teff = (c2*n)/log(arg)
   
      ;Calculate brightness temperature
      Tb = A+B*Teff
      TbC = Tb-273.15

      ;----------------------;
      ;Give lat and lon units;
      ;----------------------;
      latitude@units="degrees_north"
      longitude@units="degrees_east"

      ;-------------------------------------------;
      ;Get brightness temperature at drop location;
      ;-------------------------------------------;
      distances = gc_latlon(droplat,droplon,latitude,longitude,2,4)
print(min(distances))
      distances_1d = ndtooned(distances)
      indices = ind_resolve(minind(distances_1d),dimsizes(distances))
      brightness_temperature = TbC(indices(0,0),indices(0,1))
      system("echo "+brightness_temperature+"'     '"+dropfiles(i)+" >> "+outfile)
      delete([/ir,latitude,longitude,r,arg_before,arg,Teff,Tb,TbC,distances,\
               distances_1d,indices/])
   end if
   system("echo "+timediff+" minutes'     '"+dropfiles(i)+" >> "+outdir+"timediffs.txt")
   if(type.eq."hs3")
      delete([/dropdata,lats,lons/])
   end if
end do
print("Output written to "+outfile)
