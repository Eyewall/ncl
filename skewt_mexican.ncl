load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"

;-------------------------------------------------------------
;Patrick Duran
;25 October 2016
;skewt_wyoming.ncl
;
;Plots SkewT diagrams for all soundings in an input directory
;using University of Wyoming ascii format.
;-------------------------------------------------------------


dir = "/nfs/jm13/pduran/rawinsondes/wyoming/76654-Manzanillo-October2015/"
;dir = "/nfs/jm13/pduran/rawinsondes/wyoming/76805-Acapulco-October2015/"
outdir = "/jm13/pduran/web/mexicansondes/"

files = systemfunc("ls "+dir)
nfiles = dimsizes(files)
do i=0,nfiles-1
   unixi = i + 1
   print("Plotting SkewT "+unixi+" of "+nfiles+"    Outdir: "+outdir)
   filename = dir+files(i)
   DropData := readwyoming(filename)
   p   := DropData(:,0)
   tc  := DropData(:,2)
   tdc := DropData(:,3)
   z   := DropData(:,1)
   wdir := DropData(:,6)
   wspd := DropData(:,7)
   dattim  = systemfunc("sed -n '/Observation time/p' "+filename+" | awk '{print $3}'")
   stnname = systemfunc("head -1 "+filename+" | awk '{print $2}' | sed 's/,//'")

   ;-----------;
   ;Create plot;
   ;-----------;
   wks = gsn_open_wks("png",outdir+files(i))
   skewtOpts                 = True
   skewtOpts@DrawColAreaFill = False    ; default is False
   skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      "+stnname
   skewtOpts@DrawFahrenheit  = False   ; default is True

   dataOpts           = True     ; options describing data and ploting
   dataOpts@Wthin     = 2        ; plot every n-th wind barb
   dataOpts@WspdWdir  = True     ; use speed and direction for wind barbs
   skewt_bkgd = skewT_BackGround (wks, skewtOpts)
   skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,wspd,wdir,dataOpts)
   draw (skewt_bkgd)
   draw (skewt_data)
   frame(wks)
end do
