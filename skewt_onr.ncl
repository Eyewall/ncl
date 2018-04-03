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
load "/jm13/pduran/ncl/skewt_func_hs3.ncl"
;**************************************************

; --- Read Data ----------------------------------------;
dropdir = "/nfs/jm13/pduran/dropsondes/onr/20150928/"
droplist = systemfunc("ls "+dropdir+"*eol")
ndrops = dimsizes(droplist)

drop = 0
do while(drop.lt.ndrops)
   unixdrop = drop + 1
   print("Plotting image "+unixdrop+" of "+ndrops)
   dropfile = droplist(drop)

   if(.not.ismissing(systemfunc("ls "+dropfile)))then
;      dropid = systemfunc("echo "+dropfile+" | awk -F'/' '{print $NF}' | awk -F'-' '{print $1}'")
      dropid = systemfunc("sed -n 4p "+dropfile+" | awk '{print($3)}'")
      dattim = systemfunc("sed -n 4p "+dropfile+" | awk '{print($9)}'")
      time = systemfunc("echo "+dropfile+" | awk -F'/' '{print $NF}' | awk -F'-' '{print $2}'") 
      DropData  = readAsciiTable(dropfile,10,"float",7)
      p     = DropData(:,0)
      tc    = DropData(:,1)
      tdc   = DropData(:,2)
      z     = DropData(:,5)
      u     = DropData(:,3) * 1.94384449 ;Convert to kt
      v     = DropData(:,4) * 1.94384449
      p@_FillValue = -9999.
      tc@_FillValue = -9999.
      tdc@_FillValue = -9999.
      z@_FillValue = -9999.
      u@_FillValue = (-9999. * 1.94384449)
      v@_FillValue = (-9999. * 1.94384449)

      ;SkewT function will not plot without at least 2 points of P, T, and Td. To avoid
      ;this, if there are less than two values, we will set the array values to a
      ;ridiculous number that won't appear on the plot.
      if(dimsizes(ind(.not.ismissing(tc))).lt.3)then
         tc = -900
      end if
      if(dimsizes(ind(.not.ismissing(tdc))).lt.3)then
         tdc = -900
      end if
      if(dimsizes(ind(.not.ismissing(p))).lt.3)then
         system("echo All pressure data are missing...No skewT plotted.")
      else
   
         ;-----------;
         ;Create plot;
         ;-----------;
         wks = gsn_open_wks("png",dropid+"_"+time)
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
      end if
      delete([/DropData,p,tc,tdc,z,u,v/])
      drop = drop + 1
   end if
end do
