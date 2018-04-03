load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; theta-differences.ncl                                    
; Patrick Duran                                           
; 17 May 2016
; Used for TCI high-density sonde transects...
; Pulls data from two lists of .edit files, interpolates them to a
; uniform horizontal grid, and plots difference fields of
; potential temperature for the two .edit file lists.
;
; 5/17/16: Code currently uses drop lat and lon to compute distance
;          from flight center at all levels (i.e. does not account
;          for sonde drift.
;----------------------------------------------------------------;

storm     = "patricia"
transect  = "transect1"
date1     = "20151021"  ;Difference will be date2-date1
date2     = "20151021"
sondedir1 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date1+"/"
sondedir2 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date2+"/"
listfile1 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date1+"/"+transect
listfile2 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date2+"/"+transect
prefix   = "A"
suffix   = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
outdir   = "/jm13/pduran/web/tci/cross_sections/"+storm+"/differences/"+transect+"/"
maxhght  = 20000
dz       = 100
nlevels  = maxhght/dz+1
type     = 1   ;Plot as total distance from start of flight let (0) or
               ;distance from storm center (1)?
interp   = 1   ;Interpolate across missing values? Set to 0 for no, 1 for yes.
gridmax  = 40
gridmin  = -40
gridint  = 5
rd       = 287
cp       = 1004

;----------------------;
;STORM CENTER POSITIONS;
;----------------------;
if(date1.eq."20151021")then
   if(transect.eq."transect1")
      centerlat1 = 13.41
      centerlon1 = -99.34
      centersonde1 = 6
   else
      centerlat1 = 13.03
      centerlon1 = -99.62
      centersonde1 = 12
   end if
;   centerlat1 = 13.42    ;Determined by looking at meridional velocity from dropsondes
;   centerlon1 = -99.38   ;Note that this lat/lon is not actually at a drop location
;   centersonde1 = 5      ;The line number in the listfile where the center sonde is
else if(date1.eq."20151022")then
   centerlat1 = 15.13    ;Determined by meridional velocity
   centerlon1 = -104.18
   centersonde1 = 13 
else if(date1.eq."20151023")then
   centerlat1 = 18.61	;Determined by IR imagery
   centerlon1 = -105.22
   centersonde1 = 14
else if(date1.eq."20151002")then
   centerlat1 = 23.83	;Determined by combination of QC notes and meridional velocity
   centerlon1 = -74.65
   centersonde1 = 9
else if(date1.eq."20151003")then
   centerlat1 = 26.18	;Determined by combination of QC notes and meridional velocity
   centerlon1 = -71.28
   centersonde1 = 7
else if(date1.eq."20151004")then
   centerlat1 = 31.81	;Determine by IR imagery
   centerlon1 = -66.48
   centersonde1 = 10	;Note that I chopped off some sondes from the high-density transect
end if
end if
end if
end if
end if
end if

infiles1 = sondedir1+systemfunc("cat "+listfile1)
nfiles1  = dimsizes(infiles1)

pres1     = new((/nfiles1,nlevels/),"float")
temp1     = new((/nfiles1,nlevels/),"float")
theta1    = new((/nfiles1,nlevels/),"float")
dropdist1 = new(nfiles1,"float")
droplat1  = new(nfiles1,"float")
droplon1  = new(nfiles1,"float")
cp_pres1  = new(nfiles1,"float")
cp_temp1  = new(nfiles1,"float")
cp_theta1 = new(nfiles1,"float")
trop_z1    = new(nfiles1,"float")
pres1@_FillValue    = -9999.0
theta1@_FillValue    = -9999.0
trop_z1@_FillValue   = -9999.0
cp_pres1@_FillValue  = -9999.0
cp_temp1@_FillValue  = -9999.0
cp_theta1@_FillValue  = -9999.0

;----------------------------;
;PROCESS FIRST LIST OF SONDES;
;----------------------------;
dropdist1 = 0.
do i=0,nfiles1-1
   unixi = i+1
   print("Processing sonde "+unixi+" of "+nfiles1)
   ;Read input file and assign variables
   data = readAsciiTable(infiles1(i),10,"float",7)
   data@_FillValue = -9999.0
   p    = data(:,0)
   tc   = data(:,1)
   hght = data(:,5)

   ;Get drop latitude and longitude from header
   droplat1(i) = stringtofloat(systemfunc("sed -n 5p "+infiles1(i)+" | awk '{print $3}'"))
   nfields = stringtoint(systemfunc("sed -n 5p "+infiles1(i)+" | awk '{print NF}'"))
   if(nfields.eq.9)then
      droplon1(i) = stringtofloat(systemfunc("sed -n 5p "+infiles1(i)+" | awk '{print $5}' | sed 's/=//'"))
   else
      droplon1(i) = stringtofloat(systemfunc("sed -n 5p "+infiles1(i)+" | awk '{print $6}'"))
   end if

   nhghts = dimsizes(hght)

   ;Set or compute all of the variables
   pres1 (i,0:nhghts-1) = p
   temp1 (i,0:nhghts-1) = tc
   theta1(i,0:nhghts-1) = (tc+273.15)*(1000/p)^0.286
   cp_pres1(i) = pres1(i,minind(temp1(i,:)))
   cp_temp1(i) = min(temp1(i,:))
   cp_theta1(i) = theta1(i,minind(temp1(i,:)))

   ;Get the tropopause height from tropopause pressure by linear interpolation
   if(min(p).lt.200.and..not.ismissing(cp_pres1(i)))then
      diffs = abs(p-cp_pres1(i))
      diffs_sort = diffs(ind(.not.ismissing(diffs)))
      qsort(diffs_sort)
      p1 = p(ind(diffs.eq.diffs_sort(0)))
      p2 = cp_pres1(i)
      p3 = min(p(ind(diffs.eq.diffs_sort(1))))
      z1 = min(hght(ind(diffs.eq.diffs_sort(0))))
      z3 = min(hght(ind(diffs.eq.diffs_sort(1))))
      z2 := (p2-p1)*(z3-z1)/(p3-p1)+z1
      trop_z1(i) = z2/1000
      delete([/diffs,diffs_sort/])
   else
      trop_z1(i) = trop_z1@_FillValue
   end if

   ;Interpolate across missing values in radius, if desired
   if(interp.eq.1)then
      pres1  = linmsg_n(pres1,0,0)
      temp1  = linmsg_n(temp1,0,0)
      theta1 = linmsg_n(theta1,0,0)
   end if

   ;Compute cumulative distance from the first sonde drop
   if(i.gt.0.and.type.eq.0)then
      dropdist1(i) = dropdist(i-1) + gc_latlon(droplat1(i-1),droplon1(i-1),droplat1(i),droplon1(i),2,4)
   end if

   ;Clean up
   delete([/data,p,tc,hght/])
end do

;Compute distance from storm center
;gc_latlon doesn't check for missing values, so we'll just perform a
;quick fix by setting all distances greater than 2000 km to missing
if(type.eq.1)
   dropdist1 = gc_latlon(centerlat1,centerlon1,droplat1,droplon1,2,4)
   dropdist1@_FillValue = -9999.
   dropdist1 = where(dropdist1.gt.2000,dropdist1@_FillValue,dropdist1)
   dropdist1(0:(centersonde1-1)) = dropdist1(0:(centersonde1-1))*-1.
   totaldist1 = round(dropdist1(dimsizes(dropdist1)-1) - dropdist1(0),0) ;Total distance along transect
end if

;--------------------------------------------------------------;
;Interpolate to uniform horizontal grid and perform differences;
;--------------------------------------------------------------;
npts        = toint((gridmax-gridmin)/gridint)+1
uniformgrid = fspan(gridmin,gridmax,npts)

;Pressure
pres1_transpose = transpose(pres1)
pres_int1  = linint1(dropdist1,pres1_transpose,False,uniformgrid,0)

;-------------------------------------------------------;
;Create arrays for plotting and set coordinate variables;
;-------------------------------------------------------;
pres_int1!0 = "height"
pres_int1!1 = "radius"
pres_int1&height = fspan(0,maxhght,nlevels)/1000.
pres_int1&radius = uniformgrid

res = True
res@tiXAxisString = "Distance from storm center (km)"
res@tiYAxisString = "Height (km)"
res@tiMainFontHeightF = 0.013
res@tiXAxisFontHeightF = 0.017
res@tiYAxisFontHeightF = 0.017
res@trXMinF = -40
res@trXMaxF = 40
res@trYMinF = 9.
res@trYMaxF = 18.5
res@cnLevelSpacingF = 2.0
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = -30
res@cnMaxLevelValF = 30
res@cnFillOn = True
res@cnInfoLabelOn = False
res@cnLinesOn = False
res@cnLineLabelsOn = True
res@lbLabelBarOn = False
res@lbOrientation = "Vertical"
res@tmYROn = False
res@tmXTOn = False
res@tmXBLabelFontHeightF = 0.016
res@tmYLLabelFontHeightF = 0.016
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False

;PLOT PRESSURE FIELD JUST FOR THE HELL OF IT
wks = gsn_open_wks("png",outdir+"pres_"+date2+"_"+transect)
pres = res
pres@trYMinF = 10.
pres@trYMaxF = 11.
pres@tiYAxisOn = True
pres@cnMinLevelValF = 200
pres@cnMaxLevelValF = 300
pres@cnLevelSpacingF = 2
pres@lbLabelBarOn = True
pres_img1 = gsn_csm_contour(wks,pres_int1,pres)
draw(pres_img1)
frame(wks)
