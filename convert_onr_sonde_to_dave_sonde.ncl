load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

dir = "/jm13/pduran/dropsondes/onr/Gonzalo/"

files = systemfunc("ls "+dir+"*.eol")
nfiles = dimsizes(files)
do i=0,nfiles-1
   unixi = i + 1
   write_table("/jm13/pduran/ncl/convert.log","a",[/"Processing file "+unixi+" of "+nfiles+" in "+dir+"    "+systemfunc("date")/],"%s")
   dropfile = files(i)
   data = readAsciiTable(dropfile,17,"float",14)
   data = where(data.eq.-999,999,data)
   data@_FillValue = 999

   nlines = dimsizes(data(:,0))
   output = new((/nlines,23/),"string")
   
   ;Get various parameters necessary for output file
   stnid = "00000"
   year  = systemfunc("sed -n 6p "+dropfile+" | awk '{print($5)}' | cut -c 1-4")
   month = stringtofloat(systemfunc("sed -n 6p "+dropfile+" | awk '{print($6)}' | cut -c 1-2"))
   day   = stringtofloat(systemfunc("sed -n 6p "+dropfile+" | awk '{print($7)}' | cut -c 1-2"))
   hour  = stringtofloat(systemfunc("sed -n 6p "+dropfile+" | awk '{print($8)}' | cut -c 1-2"))
   minu  = stringtoint(systemfunc("sed -n 6p "+dropfile+" | awk '{print($8)}' | cut -c 4-5"))
   sec   = stringtoint(systemfunc("sed -n 6p "+dropfile+" | awk '{print($8)}' | cut -c 7-8"))
   slat  = systemfunc("sed -n 5p "+dropfile+" | awk '{print($9)}' | sed 's/,//g'")
   slon  = systemfunc("sed -n 5p "+dropfile+" | awk '{print($6)}' | sed 's/,//g'")

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
      output(:,3) = data(:,4)
      output(:,4) = data(:,5)
      output(:,5) = data(:,6)
      output(:,6) = data(:,7)
      output(:,7) = data(:,8)
      output(:,8) = data(:,9)
   
   ;We will keep total wind speed and direction and Wcmp as missing values;
      output(:,9) = 999.0
      output(:,10) = 999.0
      output(:,11) = 999.0
   
   ;Longitude and latitude
      output(:,12) = data(:,14)
      output(:,13) = data(:,15)
   
   ;Elevation and azimuth are also missing values
      output(:,14) = 999.0
      output(:,15) = 999.0
   
   ;Altitude
      output(:,16) = data(:,13)
   
   ;QC codes for pressure, temperature, rel hum, uwnd, vwnd, dZ
      output(:,17) = 0.
      output(:,18) = 0.
      output(:,19) = 0.
      output(:,20) = 0.
      output(:,21) = 0.
      output(:,22) = 0.

   output = output(::-1,:)
   
   ;PRINT OUTPUT FILES AND APPEND ALL THREE TO MAKE COMPLETE OUTFILE
   ;Header
   header = new(16,"string")
   header(0) = output(0,0)+"   0################################################################"+\
               "###################################################################"
   header(1) = output(0,0)+"   1Data Type:                         ONR TCI Outflow Layer Sounding."
   header(2) = output(0,0)+"   2Project ID:                        0"
   header(3) = output(0,0)+"   3Launch Site Type/Site ID:          STATION"
   header(4) = output(0,0)+"   4Launch Location (lon,lat,alt):     00 00.00'W, 00 00.00'N,  "+\
               slon+",  "+slat+",  "+sprintf("%5.1f",stringtofloat(output(0,16)))
   header(5) = output(0,0)+"   5GMT Launch Time (y,m,d,h,m,s):     "+year+","+sprintf("%3.0f",month)+\
               ","+sprintf("%3.0f",day)+","+sprintf("%3.0f",hour)+":"+\
               sprinti("%0.2i",minu)+":"+sprinti("%0.2i",floattoint(sec))
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
   outfile = dropfile+".dat"
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
   delete([/output,data/])
end do
