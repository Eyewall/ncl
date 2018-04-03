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
idfile   = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/12z/2015/allsondes_12z_300-400km"
dropdir = "/jm13/pduran/rawinsondes/allsondes_brch_nomaxbrch/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"

idsuff  = systemfunc("echo "+idfile+" | rev | cut -c1-2 | rev")
if(idsuff.eq."st")then ;The suffix is .idlist, so...
   stids   = systemfunc("awk '{print($2)}' "+idfile)
   dattims = systemfunc("awk '{print($4)}' "+idfile)
else ;The suffix is km, so...
   stids   = systemfunc("awk '{print($1)}' "+idfile+" | cut -c3-7")
   dattims = systemfunc("awk '{print($3)}' "+idfile)
end if

ndrops = stringtoint(systemfunc("wc "+idfile+" | awk '{print($1)}'"))
do i=111,ndrops-1
   unixi = i + 1
   print("Plotting image "+unixi+" of "+ndrops)
   dropfilename = stids(i)+"-"+dattims(i)+suffix
   dropfile = dropdir+dropfilename
print(dropfile)
   nlines = stringtoint(systemfunc("wc "+dropfile+" | awk '{print($1)}'"))
   if(.not.ismissing(systemfunc("ls "+dropfile)).and.nlines.gt.7)then
      dropid = systemfunc("echo "+dropfile+" | awk -F'/' '{print $6}' | awk -F'-' '{print $1}'")
      dattim = systemfunc("echo "+dropfile+" | awk -F'/' '{print $6}' | awk -F'-' '{print $2}'") 
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
      if(.not.all(ismissing(p)).and.(.not.all(ismissing(tc))).and.(.not.all(ismissing(tdc)))\
         .and.(.not.all(ismissing(u))).and.(.not.all(ismissing(v))))then
         wks = gsn_open_wks("png",dropid+"_"+dattim)
         skewtOpts                 = True
         skewtOpts@DrawColAreaFill = False    ; default is False
         skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      DROP ID: "+dropid
         skewtOpts@DrawFahrenheit  = False   ; default is True
   
         dataOpts           = True     ; options describing data and ploting
         dataOpts@Wthin     = 1        ; plot every n-th wind barb
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
      delete([/DropData,p,tc,tdc,z,u,v,brch,stab,shear/])
   end if
end do
