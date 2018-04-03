load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------------;
;mkdirs_and_move_files.ncl
;Patrick Duran
;12/16/2012
;
;Will read in a list of rawinsonde station directories from dir1 and   
;create new directories of the same name and moves the appropriate
;files in dir2 to their respective subdirectories. NOTE: THIS SCRIPT
;MUST BE RUN IN DIR2 (THE DIRECTORY WHERE THE NEW SUBDIRS WILL BE MADE
;----------------------------------------------------------------------;

;dir1 = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/processed/sondes/"
dir2 = "/jm13/pduran/2005-2010_1sec_sondes_subdirs/"   ;MAKE SURE YOU HAVE THE FINAL SLASH!!

;stn_dirs = systemfunc("ls -d "+dir1+"*/")
stn_dirs = (/
num_stn_dirs = dimsizes(stn_dirs)
do i=0, num_stn_dirs-1
   stn_dirs_split = str_split(stn_dirs(i),"/")
   subdir = stn_dirs_split(7)
   system("mkdir "+dir2+subdir)
   system("mv "+subdir+"-* "+subdir)
end do
