load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;--------------------------------------------;
;THIS SECTION IS FOR FULL SOUNDING EDIT FILES;
;--------------------------------------------;
;sondedir = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/processed/sondes"
;subdirlist = systemfunc("ls -d "+sondedir+"/*/")
;nsubdirs = dimsizes(subdirlist)
;
;i = 0
;do while (i.lt.nsubdirs)
;   j = i + 1
;   station_num = systemfunc("echo "+subdirlist(i)+" | colrm 67 | colrm 1 61")
;   year = stringtoint("20"+systemfunc("ls "+subdirlist(i)+" | colrm 9 | colrm 1 6"))
;   mon  = stringtoint(systemfunc("ls "+subdirlist(i)+" | colrm 11 | colrm 1 8")) 
;   day  = stringtoint(systemfunc("ls "+subdirlist(i)+" | colrm 13 | colrm 1 10"))
;   hour = stringtoint(systemfunc("ls "+subdirlist(i)+" | colrm 15 | colrm 1 12"))
;   juldates = greg2jul(year,mon,day,hour)
;   asciiwrite(station_num+".dat",juldates)
;   delete(year)
;   delete(mon)
;   delete(day)
;   delete(hour)
;   delete(juldates)
;   i = i + 1
;end do


;----------------------------------------------------;
;THIS SECTION IS FOR EDIT FILES WITH BRCH CALCULATION;
;----------------------------------------------------;
sondedir = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/calcs/brch/"
stn_ID_namelist = systemfunc("ls -d /jm13/djv/soundings/NOAM_6sec/pduran_sondes/processed/sondes/*/")
nstns = dimsizes(stn_ID_namelist)

stn_ID_list = new(nstns,"string")
j = 0
do while (j.lt.nstns)
   stn_ID_namelist_split = str_split(stn_ID_namelist(j),"/")
   stn_ID_list(j) = stn_ID_namelist_split(7)

   files = systemfunc("ls "+sondedir+stn_ID_list(j)+"*datv")
   nfiles = dimsizes(files)
   
   juldates = new(nfiles,"double")
   i = 0
   do while (i.lt.nfiles)
      filename_split = str_split(files(i),"-")
      stn_ID = filename_split(0)
      date_split = str_split_by_length(filename_split(1),2)
      year = stringtoint("20"+date_split(0))
      month = stringtoint(date_split(1))
      day = stringtoint(date_split(2))
      hour = stringtoint(date_split(3))
      juldates(i) = greg2jul(year,month,day,hour)
      i = i + 1
   end do
   asciiwrite(stn_ID_list(j)+".dat",juldates)
   delete(files)
   delete(juldates)
   j = j + 1
end do
