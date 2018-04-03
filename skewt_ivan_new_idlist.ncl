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
class = "ts+td"
time  = "12z"
dropdir = "/jm13/pduran/1+6sec_sondes_SEP2014_brch/"
iddir   = "/jm13/pduran/unix_scripts_and_c++/2014/"+class+"/200kmbins/avg/"+time+"/"
suffix  = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"

idfiles = systemfunc("ls "+iddir+"*z")
nidfiles = dimsizes(idfiles)
;do i=0,nidfiles-1
do i=0,1
   ;class  = systemfunc("echo "+idfiles(i)+" | cut -d'/' -f8 | cut -d'_' -f1")
   ;radbin = systemfunc("echo "+idfiles(i)+" | cut -d'/' -f8 | cut -d'_' -f2 | cut -d'.' -f1")
   radbin = systemfunc("echo "+idfiles(i)+" | cut -d'/' -f10 | cut -d'_' -f2")
   system("mkdir "+class+"_"+radbin+"_"+time+"_skewt")
   idlist = systemfunc("cat "+idfiles(i))
   ndrops = dimsizes(idlist)
   drop = 0
   do drop=0,ndrops-1
      unixdrop = drop + 1
      print("Plotting image "+unixdrop+" of "+ndrops)
      stn = systemfunc("echo "+idlist(drop)+" | awk '{print($2)}'")
      dattim = systemfunc("echo "+idlist(drop)+" | awk '{print($4)}'")
      dropfile = stn+"-"+dattim+suffix 
      if(.not.ismissing(systemfunc("ls "+dropdir+dropfile)))then
         DropData  = readAsciiTable(dropdir+dropfile,13,"float",7)
         p   = DropData(:,0)
         tc  = DropData(:,1)
         tdc = DropData(:,2)
         z   = DropData(:,5)
         u   = DropData(:,3) * 1.94384449 ;Convert to kt
         v   = DropData(:,4) * 1.94384449
         p@_FillValue = -9999.
         tc@_FillValue = -9999.
         tdc@_FillValue = -9999.
         z@_FillValue = -9999.
         u@_FillValue = (-9999. * 1.94384449)
         v@_FillValue = (-9999. * 1.94384449)
         
         ;-----------;
         ;Create plot;
         ;-----------;
         if(.not.all(ismissing(p)))then
            outfilename = class+"_"+radbin+"_"+stn+"-"+dattim+"_skewt"
            wks = gsn_open_wks("png",outfilename)
            skewtOpts                 = True
            skewtOpts@DrawColAreaFill = False    ; default is False
            skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      STATION: "+stn
            skewtOpts@DrawFahrenheit  = False   ; default is True
      
            dataOpts           = True     ; options describing data and ploting
            dataOpts@Wthin     = 2        ; plot every n-th wind barb
            skewt_bkgd = skewT_BackGround (wks, skewtOpts)
            skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,u,v,dataOpts)
            draw (skewt_bkgd)
            draw (skewt_data)
            frame(wks)
         end if
         delete([/DropData,p,tc,tdc,z,u,v/])
      end if
   end do   ;dropsonde loop
   system("mv *"+class+"_"+radbin+"*skewt.png "+class+"_"+radbin+"_"+time+"_skewt")
   delete(idlist)
end do   ;idfile loop
