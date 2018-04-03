;**************************************************
; skewt_frd.ncl
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_hs3_50mb.ncl"
;**************************************************

datestr = "20151023"
transect = "transect1_inverted"
dir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/"+datestr+"/"
outdir = "/jm13/pduran/web/tci/skewt/patricia/"+datestr+"/"+transect
junkdir = "/jm13/pduran/dropsondes/onr/useless/"
opt = 1   ;Set to 0 to plot all files in directory; 1 to plot only files in listfile
listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/"+datestr+"/"+transect
outfilenameopt = 1  ;Set to 0 to use date/time in file name; 1 to use sequential numbers

if(opt.eq.0)then
   dropfiles = systemfunc("ls "+dir+"*.eol")
else if(opt.eq.1)
   dropfiles = dir+systemfunc("cat "+listfile)
end if
end if
ndropfiles = dimsizes(dropfiles)
droplats = new(ndropfiles,"float")
droplons = new(ndropfiles,"float")

do i=0,ndropfiles-1
   unixi = i + 1
   system("echo Plotting sonde "+unixi+" of "+ndropfiles+"   "+dropfiles(i))
   dropfile = dropfiles(i)

   system("sed -i -e 's/nan/-999.00/g' "+dropfile)

   ;----------------------;
   ;Get header information;
   ;----------------------;
   year = systemfunc("sed -n 6p "+dropfile+" | awk '{print($5)}' | sed 's/,//g'")
   mon  = systemfunc("sed -n 6p "+dropfile+" | awk '{print($6)}' | sed 's/,//g'")
   day  = systemfunc("sed -n 6p "+dropfile+" | awk '{print($7)}' | sed 's/,//g'")
   time  = systemfunc("sed -n 6p "+dropfile+" | awk '{print($8)}' | sed 's/,//g'")
   time_nocolons = systemfunc("echo "+time+" | sed 's/://g'")
   date = mon+"/"+day+"/"+year+"   "+time

   ;------------------------;
   ;Get sounding information;
   ;------------------------;
   DropData = readAsciiTable(dropfile,17,"float",14)
   p    = DropData (:,4)    ; pressure     [mb] 
   tc   = DropData (:,5)    ; temperature  [C]    
   tdc  = DropData (:,6)    ; relative humidity [%]
   z    = DropData (:,13)    ; geopotential [m] 
   wspd = DropData (:,10)    ; wind speed   [m/s]    
   wdir = DropData (:,11)    ; meteorological wind dir   
   lats = DropData (:,15)   ; latitudes [deg N]
   lons = DropData (:,14)   ; longitudes [deg E]
   p@_FillValue  = -999
   tc@_FillValue = -999
   tdc@_FillValue = -999
   z@_FillValue  = -999
   wspd@_FillValue = -999
   wdir@_FillValue = -999
   lats@_FillValue = -999
   lons@_FillValue = -999

   droplats(i) = lats(0)
   droplons(i) = lons(0)

   if(max(p).lt.100)then
      system("mv "+dropfile+" "+junkdir)
   else
   
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

      ;SkewT function also needs at least two of three variables (P,T,Td) data to be
      ;present simultaneously at every level. Thus, where all of these variables are
      ;missing, we will set them all to ridiculous values.
   ;   missingp  = ind(ismissing(p))
   ;   missingtc = ind(ismissing(tc))
   ;   missingtd = ind(ismissing(tdc))
   ;print(missingp)
   ;print(missingtc)
   ;print(missindtd)
   
         ;-------------------;
         ;Calculate variables;
         ;-------------------;
         ;Convert wind speed to kt
         wspd = wspd * 1.944
      
         ;Maximum wind speed and height of max wind
         vmax = -999.
         vmax_hght = -999.
         if(.not.all(ismissing(wspd)))then
            vmax = max(wspd)
            vmax_hght = z(maxind(wspd))
            if(ismissing(vmax_hght))then
               vmax_hght = z(maxind(wspd)-1)
            end if
         end if
      
         ;10 meter wind speed
         surface_wind = -999.
         if(.not.all(ismissing(z)))then
            z_diff = abs(z - 10)
            if(min(z_diff).lt.10)then
               surface_wind = wspd(minind(z_diff))
            end if
         else
            z_diff = -999.
         end if
      
         ;Sea level pressure
         slp = -999.
         if(.not.all(ismissing(z)).and..not.all(ismissing(p)))then
            if(min(z).lt.20.and.max(p).gt.800)then
               slp = max(p)
            end if
         end if
      
         ;----------;
         ;Plot SkewT;
         ;----------;
         if(outfilenameopt.eq.0)then
            filename = year+mon+day+"_"+time_nocolons+"_skewt"
         else if(outfilenameopt.eq.1)then
            filename = tostring(unixi)
         end if
         end if
         wks  = gsn_open_wks ("png",filename)
         skewtOpts                 = True
         skewtOpts@DrawColAreaFill = False
         skewtOpts@tiMainString    = "DATE/TIME: "+date+"   "+time+" UTC" 
         skewtOpts@DrawFahrenheit  = False   
         dataOpts           = True
         dataOpts@Wthin     = 15        ; plot every n-th wind barb
         skewt_bkgd = skewT_BackGround (wks,skewtOpts)
         skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,wspd,wdir,dataOpts)
         skewtOpts@gsnDraw = False
         skewtOpts@gsnFrame = False
      
         ;-----------------------------;
         ;Add text information to SkewT;
         ;-----------------------------;
         txOpts = True
         txOpts@txFont = 21
         txOpts@txFontColor = "black"
         txOpts@txFontHeightF = 0.01
         gsn_text_ndc(wks,"LAT/LON = "+sprintf("%5.2f",droplats(i))+","+sprintf("%6.2f",droplons(i)),.66,.9,txOpts)
         gsn_text_ndc(wks,"Vmax ="+sprintf("%5.1f",vmax)+" kt at "+sprintf("%5.0f",vmax_hght)+"m",.66,.88,txOpts)
         gsn_text_ndc(wks,"10m wind ="+sprintf("%5.1f",surface_wind)+" kt",.66,.86,txOpts)
         gsn_text_ndc(wks,"SLP = "+slp+" mb",.66,.84,txOpts)
   
      ;   gsn_text_ndc(wks,comment,.66,.82,txOpts)
      
         draw (skewt_bkgd)
         draw (skewt_data)
         frame(wks)
      
         delete([/wks,surface_wind,slp,z_diff/])
         system("mv "+filename+".png "+outdir)
      end if
   end if
   delete([/DropData,p,tc,z,wspd,wdir,tdc,lats,lons/])
end do

   ;--------------------;
   ;Plot sonde locations;
   ;--------------------;
   wks = gsn_open_wks("png","locations")
   res = True
   res@gsnMaximize = True
   res@gsnMajorLatSpacing = 5
   res@gsnMajorLonSpacing = 5
   res@gsnMinorLatSpacing = 1
   res@gsnMinorLonSpacing = 1
   res@mpOutlineBoundarySets = "AllBoundaries"
   res@mpMinLatF = min(droplats)-5
   res@mpMaxLatF = max(droplats)+5
   res@mpMinLonF = min(droplons)-5
   res@mpMaxLonF = max(droplons)+5
   res@mpFillOn = True
   res@mpGeophysicalLineThicknessF = 2.
   res@mpGridAndLimbOn = True
   res@mpGridLineDashPattern = 0
   res@mpGridLineThicknessF = 1.
   res@tmXMajorGrid = True
   res@tmYMajorGrid = True
   res@tmXMajorGridLineColor = "black"
   res@tmYMajorGridLineColor = "black"
   res@gsnMaximize = True
   res@tmXTOn = False
   res@tmYROn = False
   res@gsnDraw = False
   res@gsnFrame = False
   plot = gsn_csm_map_ce(wks,res)

   ;-------------------;
   ;Overlay sonde trace;
   ;-------------------;
;   color_table = "MPL_rainbow"
;   polyres = True
;   polyres@gsLineThicknessF = 10.
;   polyres@gsLineColor = color_table
;   dum1 = gsn_add_polyline(wks,plot,lons,lats,polyres)
;   nlines = max(z) / 1000
;   dum = new(nlines,"graphic")
;   do j=0,nlines-1
;      polyres = True
;      polyres@gsLineThicknessF = 10.
;      polyres@gsLineColor = colorlist(linenum)
;   draw(plot)
;   frame(wks)
;   delete([/lats,lons/])

;lineres = True
;lineres@gsLineColor = "black"
;lineres@gsLineThicknessF = 4.
;dum1 = gsn_add_polyline(wks,plot,stringtofloat(droplons),stringtofloat(droplats),lineres)
;
;texti = ispan(1,unixi,1)
;text = tostring(texti)
;polyres = True
;polyres@txFontHeightF = .03 
;polyres@txFontColor = "red"
;dum = gsn_add_text(wks,plot,text,stringtofloat(droplons),stringtofloat(droplats),polyres)

draw(plot)
frame(wks)
