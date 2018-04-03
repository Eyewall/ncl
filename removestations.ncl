load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;Will remove all subdirectories within directory dir
;that are not included in the stalist_keep file.

dir = "/jm13/pduran/soundings_6sec/2009/"
stalist_keep = systemfunc("cat /jm13/pduran/soundings_6sec/stalist_keep")
stalist = systemfunc("ls "+dir)
nstations = dimsizes(stalist)
do i=0,nstations-1
   station = stalist(i)
   if(ismissing(ind(stalist_keep.eq.station)))then
      system("\rm -r "+dir+"/"+station)
   end if
end do

;Will descend into remaining subdirectories, delete all unwanted
;files (as specified below), and unzip the remaining files.
system("csh /jm13/pduran/unix_scripts_and_c++/removefiles.sc "+dir)
