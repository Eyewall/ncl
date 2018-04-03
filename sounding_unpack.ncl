load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------;
;sounding_unpack.ncl
;Patrick Duran
;10/23/2013
;
;Loops through all subdirectories and contained files; 
;in "dir," decodes each BUFR file, interpolates the  ;
;radiosonde data to 100-m levels, and zips the files ;
;back up when finished.                              ;
;----------------------------------------------------;

;NOTE: THIS IS NOT OPERATIONAL FOR ACTUALLY UNPACKING SOUNDINGS...
;THERE IS A CSH SCRIPT TO DO THAT IN THE UNIX SCRIPTS DIRECTORY...
;HOLDING ONTO THIS FOR FUTURE USE IN CREATING EDIT FILES & PLOTTING

dir = "/jm13/pduran/soundings/"
decode_dir = "/jm13/pduran/unix_scripts_and_c++/SPARCradiosonde_decoding/"
year_dirs = systemfunc("ls "+dir)
num_year_dirs = dimsizes(year_dirs)

i = 0
do while(i.lt.num_year_dirs)
   stn_dirs  = systemfunc("ls "+dir+year_dirs(i))
   num_stn_dirs = dimsizes(stn_dirs)
   j = 0
   do while(j.lt.num_stn_dirs)
      raobfiles = systemfunc("ls "+dir+year_dirs(i)+"/"+stn_dirs(j))
      num_raobfiles = dimsizes(raobfiles)
      k = 0
      do while(k.lt.num_raobfiles) 
         ;Unzip BUFR file
         system("gunzip "+raobfiles(k))
         unzippedfile = systemfunc("echo "+raobfiles(k)+" colrm | 17 19")
         ;Convert BUFR file from DOS format to Unix format
         system(decode_dir+"unixbufr.exe "+unzippedfile+" "+unzippedfile+"_unix")
         k = numraobfiles
      end do
      j = num_stn_dirs
   end do
   delete(stn_dirs)
   delete(raobfiles)
   i = i + num_year_dirs
end do
   
