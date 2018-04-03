load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------------;
;avg_relhum.ncl
;Patrick Duran
;12/6/2012
;
;Will calculate the average relative humidity for each of a series of
;soundings and write the filenames and average RH to output files in
;bins of 0-60%, 60-80%, and 80-100%. Only soundings that reached
;100 mb are included to avoid low biases inherently introduced by
;using soundings that climb very high in atmospehere (i.e. more obs
;higher up will drag down the average RELH relative to those soundings
;that do not have observations as high up, even if the troposphere is
;equally saturated for the two soundings.)
;----------------------------------------------------------------------;

;dirs = systemfunc("ls -d /jm13/pduran/6sec_sondes_1dir/*/")
;numdirs = dimsizes(dirs)


bin1 = new(100000,"string")
bin2 = new(100000,"string")
bin3 = new(100000,"string")
bin1i = 0
bin2i = 0
bin3i = 0
;i = 0
;do while(i.lt.numdirs)
;   i = i + 1
;   print("Processing station "+i+" of "+numdirs)
;   i = i - 1
   ;soundings = systemfunc("ls "+dirs(i)+"*.edit")
   dir = "/jm13/pduran/1+6sec_sondes_1dir/"
   soundings = systemfunc("ls "+dir)
   numsoundings = dimsizes(soundings)

   j = 0
   do while(j.lt.numsoundings)
      print("Processing sounding "+j+" of "+numsoundings)
      f = readAsciiTable(dir+soundings(j),10,"float",7)
      filenamesplit = str_split(soundings(j),"-")
      stn = filenamesplit(0)
      dattim = filenamesplit(1)
      type = filenamesplit(2)    ;Note that even the 1 sec soundings use "RAWIN_6S"
      pres = f(:,0)
      pres@_FillValue = -9999.
      if(.not.ismissing(min(pres)))then
         if(min(pres).lt.100)          ;Use only soundings that reach 100 mb
            top = max(ind(pres.ge.100))   ;Only get RELH values for pres < 100 to avoid
            relh = f(0:top,6)             ;repeated 
            relh@_FillValue = -9999.
            if(.not.(all(ismissing(relh))))then
               avg_relh = avg(relh)
               if(avg_relh.le.50)then
                  ;bin1(bin1i) = soundings(j)+"  "+avg_relh
                  bin1(bin1i) = stn+" "+type+" "+dattim
                  bin1i = bin1i + 1
               else if((avg_relh.gt.50).and.(avg_relh.le.70))then
                  ;bin2(bin2i) = soundings(j)+"  "+avg_relh
                  bin2(bin2i) = stn+" "+type+" "+dattim
                  bin2i = bin2i + 1
               else if(avg_relh.gt.70)then
                  ;bin3(bin3i) = soundings(j)+"  "+avg_relh
                  bin3(bin3i) = stn+" "+type+" "+dattim
                  bin3i = bin3i + 1
               end if
               end if
               end if
            end if
            delete(relh)
         end if
      end if
      delete(f)
      delete(pres)
      j = j + 1
   end do
;   delete(soundings)
;   i = i + 1
;end do

asciiwrite("0-50percent_relh_long.txt",bin1)
asciiwrite("50-70percent_relh_long.txt",bin2)
asciiwrite("70-100percent_relh_long.txt",bin3)

;system("sed '/missing/d' 0-50percent_relh_long.txt > 0-50percent_relh_1sec.txt")
;system("sed '/missing/d' 50-70percent_relh_long.txt > 50-70percent_relh_1sec.txt")
;system("sed '/missing/d' 70-100percent_relh_long.txt > 70-100percent_relh_1sec.txt")

system("sed '/missing/d' 0-50percent_relh_long.txt > 0-50percent_relh_1+6sec.idlist")
system("sed '/missing/d' 50-70percent_relh_long.txt > 50-70percent_relh_1+6sec.idlist")
system("sed '/missing/d' 70-100percent_relh_long.txt > 70-100percent_relh_1+6sec.idlist")

system("\rm *percent_relh_long.txt")
