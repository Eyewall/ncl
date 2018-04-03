load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

listdir  = "/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/"
idsuffix = "idlist"
sondedir = "/jm13/pduran/rawinsondes/allsondes_brch_nomaxbrch/"
suffix   = "-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"


listfiles = systemfunc("ls "+listdir+"*"+idsuffix)
nlistfiles = dimsizes(listfiles)

do i=0,nlistfiles-1
   unixi = i + 1
   listfile = listfiles(i)
   if(idsuffix.eq."km")then
      stations = systemfunc("awk '{print($1)}' "+listfile+" | colrm 1 2")
      types    = systemfunc("awk '{print($2)}' "+listfile)
      dattims  = systemfunc("awk '{print($3)}' "+listfile)
   else
      stations = systemfunc("awk '{print($2)}' "+listfile)
      types    = systemfunc("awk '{print($3)}' "+listfile)
      dattims  = systemfunc("awk '{print($4)}' "+listfile)
   end if
   do j=0,dimsizes(stations)-1
      unixj = j + 1
      print("Working on dropfile "+unixj+" of "+dimsizes(stations)+" in listfile "+unixi+" of "+nlistfiles)
      dropfile = sondedir+stations(j)+"-"+dattims(j)+"-"+types(j)+suffix
      if(ismissing(systemfunc("ls "+dropfile)))then
         system("sed '/"+stations(j)+" "+types(j)+" "+dattims(j)+"/d' "+listfile+" > listfile.tmp")
         system("mv listfile.tmp "+listfile)
      end if
   end do
   delete([/stations,types,dattims/])
end do
