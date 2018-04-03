load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; irbt.ncl                                    
; Patrick Duran                                           
; June 2016
; Pulls data from .edit files and plots various quantitues of the
; cold point tropopause (pressure, temperature, theta) along a
; recon flight track.
;
; 5/07/16: Code currently uses drop lat and lon to compute distance
;          from flight center at all levels (i.e. does not account
;          for sonde drift). Also, sondes that were dropped before
;          the aircraft passed the eye are manually set negative,
;          so be sure to change that for each flight leg.
;----------------------------------------------------------------;

storm    = "patricia"
;dates    = (/"20151021","20151022","20151023"/)
;dates    = (/"20151002","20151003","20151004"/)
dates = "20151021"
transect = "transect2"
prefix   = "A"
suffix   = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
interp   = 1   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate
type      = 1   ;Plot as total distance from start of flight leg (0) or
                ;distance from storm center (1)?

;----------------------;
;Loop through all dates;
;----------------------;
cp_temp  = new((/dimsizes(dates),100/),"float")
cp_theta = new((/dimsizes(dates),100/),"float")
cp_pres  = new((/dimsizes(dates),100/),"float")
irbt     = new((/dimsizes(dates),100/),"float")
dropdist = new((/dimsizes(dates),100/),"float")
cp_temp@_FillValue  = -9999
cp_theta@_FillValue = -9999
cp_pres@_FillValue  = -9999
dropdist@_FillValue = -9999
do i=0,dimsizes(dates)-1
   date = dates(i)
   sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"
   listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"+transect
   outdir   = "/jm13/pduran/web/tci/cross_sections/"+storm+"/"
   irbtfile = "/jm13/pduran/onr/ir/tb/ir-Tb-drops-"+storm+"-"+date+"-"+transect
   if(date.eq."20151021")then
      coordfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/droplocs_parallax_corrected/droplist-loc-1021-plax15-lincorr.dat"
   else if(date.eq."20151022")then
      coordfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/droplocs_parallax_corrected/droplist-loc-1022-plax15-lincorr.dat"
   else if(date.eq."20151023")then
      coordfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/droplocs_parallax_corrected/droplist-loc-1023-plax15-lincorr.dat"
   end if
   end if
   end if

   ;----------------------------------------------------;
   ;Set appropriate storm center locations for each date;
   ;----------------------------------------------------;  
   if(date.eq."20151021")then
      if(transect.eq."transect1")
         centerlat = 13.45
         centerlon = -99.45
         centersonde = 6
      else
         centerlat = 13.10
         centerlon = -99.63
         centersonde = 11
      end if
   else if(date.eq."20151022")then
      centerlat = 15.18
      centerlon = -104.09
      centersonde = 13
   else if(date.eq."20151023")then
      centerlat = 18.64
      centerlon = -105.10
      centersonde = 13
   else if(date.eq."20151002")then
      centerlat = 23.83    ;Determined by combination of QC notes and meridional velocity
      centerlon = -74.65
      centersonde = 9
   else if(date.eq."20151003")then
      centerlat = 26.18    ;Determined by combination of QC notes and meridional velocity
      centerlon = -71.28
      centersonde = 7
   else if(date.eq."20151004")then
      centerlat = 31.81    ;Determined by IR imagery
      centerlon = -66.48
      centersonde = 20
   end if
   end if
   end if
   end if
   end if
   end if
   minxpatricia = -102
   maxxpatricia = 145
   minxjoaquin  = -174
   maxxjoaquin  = 124

   ;------------------------------------------;
   ;Get parallax-corrected dropsonde locations;
   ;------------------------------------------;
   droplat := stringtofloat(systemfunc("awk '{print $5}' "+coordfile))
   droplon := stringtofloat(systemfunc("awk '{print $4}' "+coordfile))

   ;------------------------------------;
   ;Loop through all files for this date;
   ;------------------------------------;
   infiles := sondedir+systemfunc("cat "+listfile)
   nfiles  := dimsizes(infiles)
   irtb    := stringtofloat(systemfunc("awk '{print $1}' "+irbtfile))
print(irtb)
   do j=0,nfiles-1
      data := readAsciiTable(infiles(j),10,"float",7)
      data@_FillValue = -9999.0
      p    := data(:,0)
      tc   := data(:,1)
      td   := data(:,2)
      u    := data(:,3)
      v    := data(:,4)
      hght := data(:,5)
      rh   := data(:,6)
      lat  := data(:,7)
      lon  := data(:,8)

      ;Get drop latitude and longitude from header
;      droplat = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $3}'"))
;      nfields = stringtoint(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print NF}'"))
;      if(nfields.eq.9)then
;         droplon = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $5}' | sed 's/=//'"))
;      else
;         droplon = stringtofloat(systemfunc("sed -n 5p "+infiles(j)+" | awk '{print $6}'"))
;      end if

      theta := (tc+273.15)*(1000/p)^0.286

      ;Tropopause quantities
      cp_temp (i,j) = min(tc)
      cp_pres (i,j) = p(minind(tc))
      cp_theta(i,j) = theta(minind(tc))
      irbt    (i,j) = irtb(j) 

      ;-------------------------------------------------;
      ;Compute drop location distances from storm center;
      ;-------------------------------------------------;
      if(type.eq.1)
         dropdist(i,j) = gc_latlon(centerlat,centerlon,droplat(j),droplon(j),2,4)
      end if
   end do ;Files loop

   ;---------------------------------;
   ;Set unrealistic values to missing;
   ;---------------------------------;
   cp_temp = where(cp_temp.gt.-60,cp_temp@_FillValue,cp_temp)
   cp_pres = where(cp_temp.gt.-60,cp_pres@_FillValue,cp_pres)
   cp_theta= where(cp_temp.gt.-60,cp_theta@_FillValue,cp_theta)
   dropdist = where(dropdist.gt.2000,dropdist@_FillValue,dropdist)
   dropdist(i,0:(centersonde-1)) = dropdist(i,0:(centersonde-1))*-1.  ;Set drops before center to negative

   ;------------------------------------------------------------------;
   ;Interpolate across missing values in radius, if option is selected;
   ;------------------------------------------------------------------;
                                       ;When plotting the tropopause quantities, we
   cp_temp_interp := linmsg(cp_temp,0)  ;will first plot cp_temp_interp using
   cp_pres_interp := linmsg(cp_pres,0)  ;dashed lines, and then cp_temp using solid
   cp_theta_interp:= linmsg(cp_theta,0) ;so we have dashed lines where missing vals are.
end do ;Dates loop
print(dropdist)

;------------;
;CREATE PLOTS;
;------------;
;IR BRIGHTNESS TEMPERATURE VS. R
out_suffix = "_interp"
wks = gsn_open_wks("png",outdir+"irbt"+out_suffix)
xyres = True
xyres@gsnMaximize = True
xyres@gsnDraw = False
xyres@gsnFrame = False
if(type.eq.0)then
   xyres@tiXAxisString = "Distance along flight track (km)"
else if(type.eq.1)then
   xyres@tiXAxisString = "Distance from storm center (km)"
end if
end if
xyres@tiYAxisOffsetXF = 0.01
xyres@gsnStringFontHeightF = 0.018
xyres@gsnLeftString = "b)"
xyres@tiYAxisFontHeightF = 0.017
xyres@tiYAxisString = "IR Brightness Temperature (C)"
xyres@tiMainFontHeightF = 0.02
xyres@tiXAxisFontHeightF = 0.02
xyres@tiYAxisFontHeightF = 0.02
if(storm.eq."patricia")then
   xyres@trXMinF = minxpatricia 
   xyres@trXMaxF = maxxpatricia
else
   xyres@trXMinF = minxjoaquin 
   xyres@trXMaxF = maxxjoaquin
end if
if(storm.eq."patricia")then
   xyres@trYMinF = -84.
   xyres@trYMaxF = -45;-69.
else
   xyres@trYMinF = -81.
   xyres@trYMaxF = -72.
end if
xyres@xyLineColor = "blue"
xyres@xyLineThicknessF = 10
xyres@tmXTOn = False
xyres@tmYROn = False
xyres@tmYMajorGrid = True
xyres@tmYMajorGridLineColor = "gray"
xyres@tmYMajorGridLineDashPattern = 1
xyres@tmXMajorGrid = True
xyres@tmXMajorGridLineColor = xyres@tmYMajorGridLineColor
xyres@tmXMajorGridLineDashPattern = xyres@tmYMajorGridLineDashPattern
xyres_noint = xyres   ;Non-interpolated field will be plotted with solid line
xyres_noint@xyDashPattern = 0
plres = True
plres@gsLineColor = "orange"
plres@gsLineThicknessF = 10
btres = True
btres@gsLineColor = "blue"
btres@gsLineThicknessF = 10
cp_temp_plot_int = gsn_csm_xy(wks,dropdist(0,:),irbt(0,:),xyres)
dum1 = gsn_add_polyline(wks,cp_temp_plot_int,dropdist(1,:),irbt(1,:),plres)
btres@gsLineColor = "red"
dum3 = gsn_add_polyline(wks,cp_temp_plot_int,dropdist(2,:),irbt(2,:),btres)
zerolineres = True
zerolineres@gsLineDashPattern = 1
zerolineres@gsLineThicknessF = 6.
zeroline_theta = gsn_add_polyline(wks,cp_temp_plot_int,(/0,0/),(/xyres@trYMinF,xyres@trYMaxF/),zerolineres)
draw(cp_temp_plot_int)
frame(wks)
