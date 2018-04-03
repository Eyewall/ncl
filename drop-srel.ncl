  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
  external SREL "/nfs/jm13/pduran/unix_scripts_and_c++/drop-srel.so"
; ===========================================
; drop-srel.ncl
; last Update: djv 1/2016
; ===========================================
; This script will read in ascii 100m dropsonde data in GEMPAK fmt and calc
; the storm relative U/V components.  Will then output in a similar format.

; Sample input: allstm-32815034-GIV-BOGFIX-T8C_KM-100m-loc.edit_400m_datv
;===========================================
;                  
; SNPARM = PRES;TMPC;DWPC;UWND;VWND;HGHT;RELH                                      
;
; STID = A05           STNM = F45F      TIME = 151023/1958                         
; SLAT = 18.31        SLON = -104.99  T SELV =      0.0                            
; STIM = 1958     PTOP =   78.     ZTOP =18185.                                    
;      PRES     TMPC     DWPC     UWND     VWND     HGHT     RELH     SLAT     SLON
;    981.54    26.11 -9999.00 -9999.00 -9999.00     0.00 -9999.00 -9999.000 -9999.000 1510232009



;;#############################################################################
;;                         MAIN PROGRAM 
;///////////////;#############################################################################
begin
   trkfile = "/nfs/jm13/pduran/recon-positions/patricia_storm-motion.txt"
   file_suff = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
   datpth_100m = "/jm13/pduran/dropsondes/onr/finalqc/edit/20151023/"


   sys_cmd = "ls -1 "+datpth_100m+"*"+file_suff+" >tmpfil"
   system(sys_cmd)
   files = systemfunc ("cat tmpfil")
   nfile = dimsizes(files)   ; number of variables on the file    
   print("Number of files to process "+nfile)

   sys_cmd = "wc "+trkfile+" >tmpfil"
   system(sys_cmd)
   sys_cmd = "awk '{print $1}' tmpfil>ntrk.dat"
   system(sys_cmd)
   nobs_trk = asciiread("ntrk.dat",(/1/),"integer")
   print("number of track obs "+nobs_trk)

;;********************** build xsec data arrays *********************
  do ifile = 0,nfile-1
   ofile = files(ifile)+"-srel"
   ncol = 10
   header = 7
   rows = systemfunc("wc " +files(ifile)+ "| awk '{print $1}'")

   nrows = stringtoint(rows)
   print("file "+ifile+"  "+files(ifile)+" has "+nrows+"obs")
   Drpdat = readAsciiTable(files(ifile),(/ncol/),"float",header)
   Drpdat@_FillValue = -9999.00
   dims = dimsizes(Drpdat)
   nobs = dims(0)
   nvar=7
   SREL::drop_srel(files(ifile),trkfile,ofile,nobs,nvar,nobs_trk,ifile)
   delete(Drpdat)
  end do
   sys_cmd = "rm ntrk.dat tmpfil "
   system(sys_cmd)
  print("finished processing "+nfile+" files")
end


