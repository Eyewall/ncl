load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

yeardir = "/jm13/pduran/soundings/2011/"
stn_dirs = systemfunc("ls "+yeardir)
num_stn_dirs = dimsizes(stn_dirs)

stn_dir = 24
do while(stn_dir.lt.num_stn_dirs)
   thermofiles = systemfunc("ls "+yeardir+stn_dirs(stn_dir)+"/ascii/*5pPTU.txt | colrm 57 | colrm 1 46")
   windfiles = systemfunc("ls "+yeardir+stn_dirs(stn_dir)+"/ascii/*6pGPS.txt | colrm 57 | colrm 1 46")
   numthermofiles = dimsizes(thermofiles)
   numwindfiles = dimsizes(windfiles)

   if(numthermofiles.ne.numwindfiles)then
      i = 0
      do while(i.lt.min((/numthermofiles,numwindfiles/)))
         if(thermofiles(i).ne.windfiles(i))then
            print("File number "+((i+1)*2)+" in "+yeardir+stn_dirs(stn_dir)+" is missing. STNDIR "+stn_dir)
            exit
         end if
         i = i + 1
      end do
      print("Check the last file in "+yeardir+stn_dirs(stn_dir)+"/ascii   STNDIR "+stn_dir)
   else if(numthermofiles.eq.numwindfiles)then
      print("No missing files in "+yeardir+stn_dirs(stn_dir)+"/ascii/   STNDIR "+stn_dir)
   end if
   end if
   delete(thermofiles)
   delete(windfiles)
   stn_dir = stn_dir + 1
end do
