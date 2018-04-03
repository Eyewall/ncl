;**************************************************
; skewt_3.ncl
;
; Concepts illustrated:
;   - Drawing Skew-T plots
;   - Thinning the wind barbs in a Skew-T plot
;   - Customizing the background of a Skew-T plot
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
;**************************************************

; --- Read Data ----------------------------------------;
dropdir = "/jm13/pduran/rawinsondes/badsoundings/"
;ndrops  = stringtoint(systemfunc("ls "+dropdir+" | wc | awk '{print $1}'"))
;system("ls "+dropdir+" > droplist.tmp")
;droplist = asciiread("droplist.tmp",(/ndrops/),"string")
droplist = "/nfs/jm13/pduran/rawinsondes/badsoundings/list.txt"
ndrops = stringtoint(systemfunc("wc "+droplist+" | awk '{print($1)}'"))

drops = systemfunc("cat "+droplist)
;sleep(10)
drop = 0
do while(drop.lt.ndrops)
   unixdrop = drop + 1
   ;system("echo Plotting image "+unixdrop+" of "+ndrops+" >> debug.txt")
   print("Plotting image "+unixdrop+" of "+ndrops)
;   dropfile = dropdir+droplist(drop)
   dropfile = dropdir+drops(drop)
   if(.not.ismissing(systemfunc("ls "+dropfile)))then
      dropid = systemfunc("echo "+dropfile+" | awk -F'/' '{print $7}' | awk -F'-' '{print $1}'")
      dattim = systemfunc("echo "+dropfile+" | awk -F'/' '{print $7}' | awk -F'-' '{print $2}'") 
      DropData  = readAsciiTable(dropfile,13,"float",7)
      p     = DropData(:,0)
      tc    = DropData(:,1)
      tdc   = DropData(:,2)
      z     = DropData(:,5)
      u     = DropData(:,3) * 1.94384449 ;Convert to kt
      v     = DropData(:,4) * 1.94384449
      brch  = DropData(:,10)
      stab  = DropData(:,9)
      shear = DropData(:,11) 
      p@_FillValue = -9999.
      tc@_FillValue = -9999.
      tdc@_FillValue = -9999.
      z@_FillValue = -9999.
      u@_FillValue = (-9999. * 1.94384449)
      v@_FillValue = (-9999. * 1.94384449)
      brch@_FillValue = -9999.
      stab@_FillValue = -9999.
      shear@_FillValue = -9999.      

      ;-----------;
      ;Create plot;
      ;-----------;
;      if(.not.ismissing(brch(130)))then
         if(.not.all(ismissing(p)).and.(.not.all(ismissing(tc))).and.(.not.all(ismissing(tdc)))\
            .and.(.not.all(ismissing(u))).and.(.not.all(ismissing(v))))then
            wks = gsn_open_wks("png",dropid+"_"+dattim)
            skewtOpts                 = True
            skewtOpts@DrawColAreaFill = False    ; default is False
            skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      DROP ID: "+dropid
            skewtOpts@DrawFahrenheit  = False   ; default is True
      
            dataOpts           = True     ; options describing data and ploting
            dataOpts@Wthin     = 2        ; plot every n-th wind barb
            skewt_bkgd = skewT_BackGround (wks, skewtOpts)
            skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,u,v,dataOpts)
            draw (skewt_bkgd)
            draw (skewt_data)
            frame(wks)
         else
            if(all(ismissing(z)).or.all(ismissing(brch)).or.all(ismissing(stab)).or.all(ismissing(shear)))
               system("echo Moving file "+dropfile+" to bad soundings directory. >> debug.txt")
               system("mv "+dropfile+" /jm13/pduran/rawinsondes/badsoundings/")
            end if
         end if
;      end if
         delete([/DropData,p,tc,tdc,z,u,v,brch,stab,shear/])
   end if
   drop = drop + 1
end do
