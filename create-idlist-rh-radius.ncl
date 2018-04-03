load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------------;
;create-idlist-rh-radius.ncl
;Patrick Duran
;12/12/2012
;
;Will create an idlist file containing station IDs and dates for
;soundings that fit both a radius and relative humidity constraint.
;
;----------------------------------------------------------------------;

dir = "/jm13/pduran/unix_scripts_and_c++/"
radius = "0-1000km"
radfiles = systemfunc("ls "+dir+"*0-1000km")
rhfiles  = systemfunc("ls "+dir+"*percent*1+6sec.idlist")
nradfiles = dimsizes(radfiles)
nrhfiles  = dimsizes(rhfiles)

do i=0, nrhfiles-1
   n = 0
   output = new(30000,"string")
   rhfile = rhfiles(i)
   nlines_rhfile = stringtoint(systemfunc("cat "+rhfile+" | wc | awk '{print $1}'"))
   rhids = asciiread(rhfile,nlines_rhfile,"string")
   rhfilenamesplit = str_split(rhfile,"/")
   rhfilenamesplit2 = str_split(rhfilenamesplit(3),"_")
   outfilename = rhfilenamesplit2(0)+"+"+radius+".idlist"
   print(outfilename)
   rh_stn = new(nlines_rhfile,"string")
   rh_des = new(nlines_rhfile,"string")
   rh_date = new(nlines_rhfile,"string")
   do k=0, nlines_rhfile-1
      rh_linesplit = str_split(rhids(k)," ")
      rh_stn(k) = rh_linesplit(0)
      rh_des(k) = rh_linesplit(1)
      rh_date(k) = rh_linesplit(2)
   end do
   do j=0, nradfiles-1
      radfile = radfiles(j)
      nlines_radfile = stringtoint(systemfunc("cat "+radfile+" | wc | awk '{print $1}'"))
      if(nlines_radfile.ne.0)then
         radids = asciiread(radfile,nlines_radfile,"string")
         do k=0, nlines_radfile-1
            rad_linesplit = str_split(radids(k)," ")
            rad_stn = rad_linesplit(0)
            rad_des = rad_linesplit(1)
            rad_date = rad_linesplit(2)
            rad_rad = rad_linesplit(3)
            if(dimsizes(rad_linesplit).eq.5)then
               rad_rad2 = rad_linesplit(4)
            else if(dimsizes(rad_linesplit).eq.6)then
               rad_rad2 = rad_linesplit(4)
               rad_rad3 = rad_linesplit(5)
            else if(dimsizes(rad_linesplit).eq.7)then
               rad_rad2 = rad_linesplit(4)
               rad_rad3 = rad_linesplit(5)
               rad_rad4 = rad_linesplit(6)
            end if
            end if
            end if
print(rad_date)
print(rh_date)
print(rad_stn)
print(rh_stn) 
            if(.not.ismissing(ind((rad_date.eq.rh_date).and.(rad_stn.eq.rh_stn))))
               index = ind((rad_date.eq.rh_date).and.(rad_stn.eq.rh_stn))
               if(dimsizes(rad_linesplit).eq.4)then
                  output(n) = rh_stn(index)+" "+rh_des(index)+" "+rh_date(index)+" "+rad_rad
               else if(dimsizes(rad_linesplit).eq.5)then
                  output(n) = rh_stn(index)+" "+rh_des(index)+" "+rh_date(index)+" "+rad_rad+" "+rad_rad2
               else if(dimsizes(rad_linesplit).eq.6)then
                  output(n) = rh_stn(index)+" "+rh_des(index)+" "+rh_date(index)+" "+rad_rad+" "+rad_rad2+" "+rad_rad3
               else if(dimsizes(rad_linesplit).eq.7)then
                  output(n) = rh_stn(index)+" "+rh_des(index)+" "+rh_date(index)+" "+rad_rad+" "+rad_rad2+" "+rad_rad3+\
                              " "+rad_rad4
               end if
               end if
               end if
               end if
               n = n + 1
            end if
            delete(rad_linesplit)
         end do
         delete(radids)
      end if
   end do
   delete(rhids)
   delete(rh_stn)
   delete(rh_des)
   delete(rh_date)
   asciiwrite(outfilename+"_long",output)
   system("sed '/missing/d' "+outfilename+"_long > "+outfilename)
   system("\rm "+outfilename+"_long")
   delete(output)
end do


;      delete(pres)
;      j = j + 1
;   end do
;;   delete(soundings)
;;   i = i + 1
;;end do
;
;asciiwrite("0-50percent_relh_long.txt",bin1)
;asciiwrite("50-70percent_relh_long.txt",bin2)
;asciiwrite("70-100percent_relh_long.txt",bin3)
;
;system("sed '/missing/d' 0-50percent_relh_long.txt > 0-50percent_relh_1sec.txt")
;system("sed '/missing/d' 50-70percent_relh_long.txt > 50-70percent_relh_1sec.txt")
;system("sed '/missing/d' 70-100percent_relh_long.txt > 70-100percent_relh_1sec.txt")
;
;system("\rm *percent_relh_long.txt")
