load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;dir = "/jm13/pduran/soundings/YEAR/STATION/ascii/"
;dir = "/jm13/pduran/soundings/2005/12924/ascii/"

;thermofiles = systemfunc("ls "+dir+"*PTU.txt")
;windfiles = systemfunc("ls "+dir+"*GPS.txt")
;nthermofiles = dimsizes(thermofiles)
;nwindfiles = dimsizes(windfiles)
;if(nthermofiles.ne.nwindfiles)then
;   print("ERROR: Number of thermo files is not equal to number of wind files in "+dir)
;   exit
;end if

;do i=0,nthermofiles-1
;   unixi = i + 1
;   write_table("/jm13/pduran/ncl/convert.log","a",[/"Processing file "+unixi+" of "+nthermofiles+" in "+dir+"    "+systemfunc("date")/],"%s")
;   thermofile = thermofiles(i)
;   windfile = windfiles(i)
    thermofile = "THERMOFILE.txt"
    windfile   = "WINDFILE.txt"
;   thermofile = dir+"12924_2005100412_5pPTU.txt"
;   windfile   = dir+"12924_2005100412_6pGPS.txt"
   
   thermo = readAsciiTable(thermofile,46,"float",3)
   wind   = readAsciiTable(windfile,36,"float",3)

;If the thermo and wind files are different sizes, this simply means that either the
;thermo or wind data was recorded longer...So we will simply chop off the bottom of
;the longer array so that the arrays are the same size, and the final times are the same
   if(dimsizes(thermo(:,0)).ne.dimsizes(wind(:,0)))then
      if(dimsizes(thermo(:,0)).lt.dimsizes(wind(:,0)))then
         new_wind = wind(0:dimsizes(thermo(:,0))-1,:)
         delete(wind)
         wind = new_wind
         delete(new_wind)
;         ryear  = thermo(:,15)
;         rmonth = thermo(:,16)
;         rday   = thermo(:,17)
;         rhour  = thermo(:,18)
;         rminu  = thermo(:,19)
;         rsec   = thermo(:,20)
      else
         new_thermo = thermo(0:dimsizes(wind(:,0))-1,:)
         delete(thermo)
         thermo = new_thermo
         delete(new_thermo)
;         ryear  = wind(:,15)
;         rmonth = wind(:,16)
;         rday   = wind(:,17)
;         rhour  = wind(:,18)
;         rminu  = wind(:,19)
;         rsec   = wind(:,20)
      end if
   end if
;   if(dimsizes(thermo(:,0)).eq.dimsizes(wind(:,0)))then
;      ryear  = wind(:,15)
;      rmonth = wind(:,16)
;      rday   = wind(:,17)
;      rhour  = wind(:,18)
;      rminu  = wind(:,19)
;      rsec   = wind(:,20)
;   end if
   
   ;Create output array
   nlines = min((/dimsizes(thermo(:,0)),dimsizes(wind(:,0))/))
   output = new((/nlines,23/),"string")
   
   ;Get various parameters necessary for output file
   stnid = systemfunc("echo "+thermofile+" | cut -c1-5")
   year  = systemfunc("echo "+thermofile+" | cut -c7-10")
   month = systemfunc("echo "+thermofile+" | cut -c11-12")
   day   = systemfunc("echo "+thermofile+" | cut -c13-14")
   hour  = systemfunc("echo "+thermofile+" | cut -c15-16")
;   minu  = flt2string(thermo(0,8))
;   sec   = flt2string(round(thermo(0,9),1))
   slat  = flt2string(decimalPlaces(thermo(0,10),1,True))
   slon  = flt2string(decimalPlaces(thermo(0,11),1,True))

   ;First column is the station ID and date+hour+"1"
      output(:,0) = stnid+year+month+day+hour+"1"
   
   ;Second column is line numbers
      output(:,1) = flt2string(ceil(fspan(16,nlines-1,nlines)))

   ;Third column is time since launch
;      launch_time_julian = cd_inv_calendar(stringtoint(year),stringtoint(month),\
;                                           stringtoint(day),stringtoint(hour),\
;                                           stringtoint(minu),stringtoint(sec),\
;                                           "seconds after 0049-09-01 00:00:00",0)
;      running_time_julian = cd_inv_calendar(floattoint(ryear),floattoint(rmonth),\
;                                            floattoint(rday),floattoint(rhour),\
;                                            floattoint(rminu),floattoint(rsec),\
;                                           "seconds after 0049-09-01 00:00:00",0)
;      if(.not.ismissing(launch_time_julian).and..not.ismissing(running_time_julian(0)))then
;         output(:,2) = decimalPlaces((running_time_julian - launch_time_julian),1,True)
;      else
         output(:,2) = fspan(0,nlines-1,nlines)
;      end if
   ;Pressure, temperature, dewpoint, relative humidity, uwind, vwind
      output(:,3) = thermo(:,22) / 100
      output(:,4) = thermo(:,33)
      output(:,5) = thermo(:,40)
      output(:,6) = thermo(:,29)
      output(:,7) = wind(:,30)
      output(:,8) = wind(:,33)
   
   ;We will keep total wind speed and direction and Wcmp as missing values;
      output(:,9) = 999.0
      output(:,10) = 999.0
      output(:,11) = 999.0
   
   ;Longitude and latitude
      output(:,12) = wind(:,24)
      output(:,13) = wind(:,21)
   
   ;Elevation and azimuth are also missing values
      output(:,14) = 999.0
      output(:,15) = 999.0
   
   ;Altitude
      output(:,16) = wind(:,27)
   
   ;QC codes for pressure, temperature, rel hum, uwnd, vwnd, dZ
      output(:,17) = thermo(:,27)
      output(:,18) = thermo(:,34)
      output(:,19) = thermo(:,30)
      output(:,20) = wind(:,31)
      output(:,21) = wind(:,34)
      output(:,22) = wind(:,28)
   
   ;PRINT OUTPUT FILES AND APPEND ALL THREE TO MAKE COMPLETE OUTFILE
   ;Header
   header = new(16,"string")
   header(0) = output(0,0)+"   0################################################################"+\
               "###################################################################"
   header(1) = output(0,0)+"   1Data Type:                         National Weather Service Sounding."
   header(2) = output(0,0)+"   2Project ID:                        0"
   header(3) = output(0,0)+"   3Launch Site Type/Site ID:          STATION"
   header(4) = output(0,0)+"   4Launch Location (lon,lat,alt):     90 06.00'W, 32 18.00'N,  "+\
               slon+",  "+slat+",  "+sprintf("%5.1f",stringtofloat(output(0,16)))
   header(5) = output(0,0)+"   5GMT Launch Time (y,m,d,h,m,s):     "+year+","+sprintf("%3.0f",thermo(0,5))+\
               ","+sprintf("%3.0f",thermo(0,6))+","+sprintf("%3.0f",thermo(0,7))+":"+\
               sprinti("%0.2i",floattoint(thermo(0,8)))+":"+sprinti("%0.2i",floattoint(round(thermo(0,9),1)))
   header(6) = output(0,0)+"   6Ascension No:                      9999"
   header(7) = output(0,0)+"   7Radiosonde Serial Number:          9999"
   header(8) = output(0,0)+"   8Radiosonde Manufacturer:           9999"
   header(9) = output(0,0)+"   9/"
   header(10) = output(0,0)+"   10/"
   header(11) = output(0,0)+"   11/"
   header(12) = output(0,0)+"   12Nominal Launch Time (y,m,d,h,m,s): 9999, 99, 99, 99:99:99"
   header(13) = output(0,0)+"  13 Time  Press  Temp  Dewpt  RH    Ucmp   Vcmp   spd   dir   Wcmp     Lon     Lat   Ele   Azi    Alt    Qp   Qt   Qrh  Qu   Qv   QdZ"
   header(14) = output(0,0)+"  14  sec    mb     C     C     %     m/s    m/s   m/s   deg   m/s      deg     deg   deg   deg     m    code code code code code code"
   header(15) = output(0,0)+"  15------ ------ ----- ----- ----- ------ ------ ----- ----- ----- -------- ------- ----- ----- ------- ---- ---- ---- ---- ---- ----"
   asciiwrite("header.txt",header)
   
   ;Data
   infilesplit = str_split(windfile,"_")
   outfile = infilesplit(0)+"-"+infilesplit(1)+".dat"
   alist = [/output(:,0),stringtofloat(output(:,1)),stringtofloat(output(:,2)),stringtofloat(output(:,3)),\
             stringtofloat(output(:,4)),stringtofloat(output(:,5)),stringtofloat(output(:,6)),\
             stringtofloat(output(:,7)),stringtofloat(output(:,8)),stringtofloat(output(:,9)),\
             stringtofloat(output(:,10)),stringtofloat(output(:,11)),stringtofloat(output(:,12)),\
             stringtofloat(output(:,13)),stringtofloat(output(:,14)),stringtofloat(output(:,15))/]
   write_table("temp_out.dat","w",alist,"%s%3.0f%-5.1f%6.1f%5.1f%5.1f%5.1f%6.1f%6.1f%5.1f%5.1f%5.1f%8.3f"+\
                                 "%7.3f%5.1f%5.1f")
   
   blist = [/stringtofloat(output(:,16)),stringtofloat(output(:,17)),stringtofloat(output(:,18)),\
             stringtofloat(output(:,19)),stringtofloat(output(:,20)),stringtofloat(output(:,21)),\
             stringtofloat(output(:,22))/]
   write_table("temp_out2.dat","w",blist,"%7.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f")
   
   system("paste -d' ' temp_out.dat temp_out2.dat > temp_out3.dat")
   system("cat header.txt temp_out3.dat > outfile.tmp")
   system("sed '5000,$d' outfile.tmp > outfile.tmp2")
   
   ;Remove columns if obs number is 1000 or greater
   system("awk '$2>=1000' outfile.tmp2 | colrm 17 17 | colrm 28 28 | sed '1,12d' > lower.tmp")
   system("sed '1003,$d' outfile.tmp2 > upper.tmp")
   system("cat upper.tmp lower.tmp > "+outfile)
   
   system("\rm header.txt temp_out.dat temp_out2.dat temp_out3.dat *.tmp*")
   ;hello = new(dimsizes(output(:,0)),"string")
   ;hello = "hello!"
   ;asciiwrite("hello.txt",hello)
   delete([/output,thermo,wind/])
;end do
