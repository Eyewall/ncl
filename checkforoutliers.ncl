load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"

;iddir = "/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/200kmbins/overlap/"
;suffix = ".idlist"
;dropdir = "/nfs/jm13/pduran/rawinsondes/allsondes_brch"
;
;idfiles = systemfunc("ls "+iddir+"*"+suffix)
;print(idfiles)
;exit

idfile = "/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/allhurricanes_100-200.idlist"
dropdir = "/nfs/jm13/pduran/rawinsondes/allsondes_brch_nomaxbrch/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"
heighttotest = 12800

sondeids = systemfunc("awk '{print($2)}' "+idfile)
dattims  = systemfunc("awk '{print($4)}' "+idfile)
nsondes = dimsizes(sondeids)
level = heighttotest/100 + 8

stabvals = new(nsondes,"float",-9999.)
shearvals = new(nsondes,"float",-9999.)
do i=0,nsondes-1
   unixi = i + 1
   print("Processing sonde "+unixi+" of "+nsondes)
   dropfile = dropdir+sondeids(i)+"-"+dattims(i)+suffix
   height = stringtofloat(systemfunc("awk '{print($6)}' "+dropfile+" | sed -n "+level+"p"))
   stabvals(i) = stringtofloat(systemfunc("awk '{print($10)}' "+dropfile+" | sed -n "+level+"p"))
   shearvals(i) = stringtofloat(systemfunc("awk '{print($12)}' "+dropfile+" | sed -n "+level+"p"))
end do
print(height)
;print(stabvals)
print(shearvals)
