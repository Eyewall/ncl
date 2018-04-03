load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; pull_brch_stab_shear.ncl                                    
; Patrick Duran                                           
; 6/15/2015
; This script pulls the BRCH, STAB, and SHEAR values from
; editfiles given an idlist directory and rawinsonde directory.
;----------------------------------------------------------------;

nlevels = 201  ;Number of vertical levels to pull from the files
listdir  = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/"
;listfile = "/jm13/pduran/unix_scripts_and_c++/allsondes_fixed_0-400km"
sondedir = "/jm13/pduran/rawinsondes/allsondes_brch_nomaxbrch/"
suffix   = "-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"

;listfiles = systemfunc("ls "+listdir+"*km")
listfiles = systemfunc("ls "+listdir+"*400-1000.idlist")
nlistfiles = dimsizes(listfiles)

i = 0
do i=0,nlistfiles-1
   unixi = i + 1
   listfile = listfiles(i)
;   stations = systemfunc("awk '{print($1)}' "+listfile+" | colrm 1 2")
;   types    = systemfunc("awk '{print($2)}' "+listfile)
;   dattims  = systemfunc("awk '{print($3)}' "+listfile)
   stations = systemfunc("awk '{print($2)}' "+listfile)
   types    = systemfunc("awk '{print($3)}' "+listfile)
   dattims  = systemfunc("awk '{print($4)}' "+listfile)
   brch_vals = new((/dimsizes(stations),nlevels/),"float")
   brch_vals@_FillValue = -9999.
   stab_vals  = brch_vals
   shear_vals = brch_vals
   do j=0,dimsizes(stations)-1
      unixj = j + 1
      system("echo Processing file "+unixj+" of "+dimsizes(stations)+" in listfile "\
             +unixi+" of "+nlistfiles+"'    '`date`")
;      system("echo Processing file "+unixj+" of "+dimsizes(stations))
      dropfile = sondedir+stations(j)+"-"+dattims(j)+"-"+types(j)+suffix
      if(.not.ismissing(systemfunc("ls "+dropfile)))
         nlines = stringtoint(systemfunc("wc "+dropfile))
         if(nlines.le.7)then
            brch_vals(j,:) = brch_vals@_FillValue
            stab_vals(j,:) = brch_vals@_FillValue
            shear_vals(j,:) = shear_vals@_FillValue
         else
            DropData = readAsciiTable(dropfile,13,"float",7)
            DropData@_FillValue = -9999.
            if(dimsizes(DropData(:,10)).lt.nlevels)then
               do k=0,dimsizes(DropData(:,10))-1
                  brch_vals(j,k)  = DropData(k,10)
                  stab_vals(j,k)  = DropData(k,9)
                  shear_vals(j,k) = DropData(k,11)
               end do
            else
               do k=0,nlevels-1
                  brch_vals(j,k)  = DropData(k,10)
                  stab_vals(j,k)  = DropData(k,9)
                  shear_vals(j,k) = DropData(k,11)
               end do
            end if
            delete(DropData)
         end if
      end if
   end do

   ;Print to output files for this radial bin
   outfile_brch  = listfile+"_brch_radbin"+i+".txt"
   outfile_stab  = listfile+"_stab_radbin"+i+".txt"
   outfile_shear = listfile+"_shear_radbin"+i+".txt"

   header = new(5,"string")
   header(0) = "OUTPUT FROM PULL_BRCH_STAB_SHEAR.NCL. LISTED ARE THE BRCH,STAB, OR"
   header(1) = "SHEAR VALUES FOR THE RADIAL BIN INDICATED BY THE FILENAME. EACH"
   header(2) = "COLUMN REPRESENTS AN ALTITUDE, IN INCREMENTS OF 100 METERS."
   header(3) = "COL 1 IS 0 METERS, COL2 IS 100 METERS, COL3 IS 200 METERS, ETC."
   header(4) = "EACH ROW REPRESENTS AN INDIVIDUAL SOUNDING FILE."
   asciiwrite("header.txt",header)

   opt = True
   opt@fout = "brchvals.txt"
   write_matrix(brch_vals,nlevels+"f9.2",opt)
   opt@fout = "stabvals.txt"
   write_matrix(stab_vals,nlevels+"f9.2",opt)
   opt@fout = "shearvals.txt"
   write_matrix(shear_vals,nlevels+"f9.2",opt)

   system("cat header.txt brchvals.txt > "+outfile_brch)
   system("cat header.txt stabvals.txt > "+outfile_stab)
   system("cat header.txt shearvals.txt > "+outfile_shear)

   system("\rm header.txt brchvals.txt stabvals.txt shearvals.txt")
   delete([/stations,types,dattims,brch_vals,stab_vals,shear_vals/])
end do
