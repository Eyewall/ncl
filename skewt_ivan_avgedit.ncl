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
;dropdir = "/jm13/pduran/6sec_newest/"
;ndrops  = stringtoint(systemfunc("ls "+dropdir+" | wc | awk '{print $1}'"))
;system("ls "+dropdir+" > droplist.tmp")
;droplist = asciiread("droplist.tmp",(/ndrops/),"string")
;
;sleep(5)
;drop = 0
;do while(drop.lt.ndrops)
;   unixdrop = drop + 1
;   print("Plotting image "+unixdrop+" of "+ndrops)
   filename = "allsondes_12z_0-200km.ncnt.134.avgedit"
   dropfile = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/12z/avg/200kmbins/"+filename
   if(.not.ismissing(systemfunc("ls "+dropfile)))then
      ndroplevels = stringtoint(systemfunc("wc "+dropfile+" | awk '{print $1}'"))
      dropid = systemfunc("sed -n 4p "+dropfile+" | awk '{print $6}'")
      dattimslash = systemfunc("sed -n 4p "+dropfile+" | awk '{print $9}'")
      dattimsplit = str_split(dattimslash, "/")
      dattim = dattimsplit(0)+"_"+dattimsplit(1)
      DropData  = readAsciiTable(dropfile,28,"float",7)
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
      wks = gsn_open_wks("png",filename)
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
   
      ;--------------------;
      ;Delete old variables;
      ;--------------------;
      delete(DropData)
      delete(p)
      delete(tc)
      delete(tdc)
      delete(z)
      delete(u)
      delete(v)
   end if
;   drop = drop + 1
;end do
