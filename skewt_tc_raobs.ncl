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

 --- Read Data ----------------------------------------;
dropdir = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/processed/sondes/"
subdir  = systemfunc("ls -d "+dropdir+"*/") ;List only directories within dropdir
nsubdirs = dimsizes(subdir)
stn_name = (/"KLCH","KDTX","KAAA","TSJU","KTPA","KEYW","KGSO","KJAX","KBNA",\
             "KTOP","KCAR","KGRB","KFFC","KMIA","KIAD","KMHX","KTLH","KHWV"/)
i = 0
do while (i.lt.nsubdirs) ;Loop through all subdirectories of dropdir
   ndrops  = stringtoint(systemfunc("ls "+subdir(i)+" | wc | awk '{print $1}'"))
   system("ls "+subdir(i)+" > droplist.tmp")
   droplist = asciiread("droplist.tmp",(/ndrops/),"string")

   drop = 0
   do while(drop.lt.ndrops) ;Loop through all drops in each subdirectory
      drop = drop + 1
      print("Plotting image "+drop+" of "+ndrops+" in directory "+i+" of "+nsubdirs)
      drop = drop - 1
      ;--------;
      ;Get data;
      ;--------;
      dropfile    = subdir(i)+droplist(drop)
      system("cp "+dropfile+" dropfile.tmp")
      ;Replace all -9999 values with -999. This is necessary because the script
      ;uses floats, for which the missing value flag is -999.
      system("`sed -i 's/-9999/-999/g' dropfile.tmp`")
      ndroplevels = stringtoint(systemfunc("cat dropfile.tmp | wc | awk '{print $1}'"))
      dropid = systemfunc("sed -n 4p dropfile.tmp | awk '{print $6}'")
      dattimslash = systemfunc("sed -n 4p dropfile.tmp | awk '{print $9}'")
      dattimsplit = str_split(dattimslash, "/")
      dattim = dattimsplit(0)+"_"+dattimsplit(1)
      DropData  = readAsciiTable("dropfile.tmp",10,"float",7)
      p   = DropData(:,0)
      tc  = DropData(:,1)
      tdc = DropData(:,2)
      z   = DropData(:,5)
      u   = DropData(:,3) * 1.94384449 ;Convert to kt
      v   = DropData(:,4) * 1.94384449
      p@_FillValue = -999.
      tc@_FillValue = -999.
      tdc@_FillValue = -999.
      z@_FillValue = -999.
      u@_FillValue = (-999. * 1.94384449)
      v@_FillValue = (-999. * 1.94384449)
      
      ;-----------;
      ;Create plot;
      ;-----------;
      wks = gsn_open_wks("png",stn_name(i)+dattim)
      skewtOpts                 = True
      skewtOpts@DrawColAreaFill = False    ; default is False
      skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      "+stn_name(i)
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
   
      drop = drop + 1
   end do
delete(droplist)
i = i + 1
end do
