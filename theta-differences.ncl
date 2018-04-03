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
transect1 = "transect1"  ;The transect to be used for the first date
transect2 = "transect1"  ;The transect to be used for the second date
date1     = "20151022"  ;Difference will be date2-date1
date2     = "20151023"
sondedir1 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date1+"/"
sondedir2 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date2+"/"
listfile1 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date1+"/"+transect1
listfile2 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date2+"/"+transect2
prefix   = "A"
suffix   = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
outdir   = "/jm13/pduran/web/tci/cross_sections/"+storm+"/differences/"
maxhght  = 20000
dz       = 100
nlevels  = maxhght/dz+1
type     = 1   ;Plot as total distance from start of flight let (0) or
               ;distance from storm center (1)?
interp   = 1   ;Interpolate across missing values? Set to 0 for no, 1 for yes.
axisorient = 1 ;X-Axis orientation (0=Leftmost side represents the first sonde in the
               ;                      transect, 1=Leftmost side is West
gridmax  = 55
gridmin  = -100
gridint  = 1
rd       = 287
cp       = 1004

yyyy = "2015"
mm   = "10"
dd1  = systemfunc("echo "+date1+" | colrm 1 6")
dd2  = systemfunc("echo "+date2+" | colrm 1 6")
mmddyyyy1 = mm+"/"+dd1+"/"+yyyy
mmddyyyy2 = mm+"/"+dd2+"/"+yyyy

;----------------------;
;STORM CENTER POSITIONS;
;----------------------;
if(date1.eq."20151021")then
   if(transect1.eq."transect1")
      centerlat1 = 13.38   ;Transect 1 did not have a center crossing!!
      centerlon1 = -99.26
      centersonde1 = 7
      if(axisorient.eq.1)then
         centersonde1 = 16
      end if
;      centerlat = 13.41    
;      centerlon = -99.34   
;      centersonde = 6      
   else    ;Transect 2
      centerlat1 = 12.99   ;Sonde location nearest the 19:50 UTC NOAA-43
      centerlon1 = -99.27  ;vortex message center location (12.98,-99.20)
      centersonde1 = 7     ;Also zero wind center in sondes...
      if(axisorient.eq.1)then
         centersonde1 = 21
      end if
   end if
else if(date1.eq."20151022")then
;   centerlat1 = 15.13      ;Sonde nearest the zero wind center.   
;   centerlon1 = -104.18
;   centersonde1 = 13
;   centerlat = 15.17     ;Upper-tropospheric pressure minimum
;   centerlon = -104.24
;   centersonde = 12
   centerlat1 = 15.09      ;Sonde nearest the interpolated center location for VORTEX msgs   
   centerlon1 = -104.12
   centersonde1 = 14

else if(date1.eq."20151023")then
;   centerlat = 18.58     ;Upper-tropospheric pressure minimum
;   centerlon = -105.20
;   centersonde = 13
   centerlat1 = 18.61      ;Sonde nearest the zero wind center   
   centerlon1 = -105.22
   centersonde1 = 14
   if(axisorient.eq.1)then
      centersonde1 = 32
   end if
else if(date1.eq."20151002")then
   centerlat1 = 23.83    ;Determined by combination of QC notes and meridional velocity
   centerlon1 = -74.65
   centersonde1 = 9
else if(date1.eq."20151003")then
   centerlat1 = 26.18    ;Determined by combination of QC notes and meridional velocity
   centerlon1 = -71.28
   centersonde1 = 7
else if(date1.eq."20151004")then
   centerlat1 = 31.81    ;Determine by IR imagery
   centerlon1 = -66.48
   centersonde1 = 10     ;Note that I chopped off some sondes from the high-density transect
end if
end if
end if
end if
end if
end if

if(date2.eq."20151021")then
   if(transect2.eq."transect1")
      centerlat2 = 13.38   ;Transect 1 did not have a center crossing!!
      centerlon2 = -99.26
      centersonde2 = 7
      if(axisorient.eq.1)then
         centersonde2 = 16
      end if
;      centerlat = 13.41    
;      centerlon = -99.34   
;      centersonde = 6      
   else    ;Transect 2
      centerlat2 = 12.99   ;Sonde location nearest the 19:50 UTC NOAA-43
      centerlon2 = -99.27  ;vortex message center location (12.98,-99.20)
      centersonde2 = 7     ;Also zero wind center in sondes...
      if(axisorient.eq.1)then
         centersonde2 = 21
      end if
   end if
else if(date2.eq."20151022")then
;   centerlat2 = 15.13      ;Sonde nearest the zero wind center.   
;   centerlon2 = -104.18
;   centersonde2 = 13
;   centerlat = 15.17     ;Upper-tropospheric pressure minimum
;   centerlon = -104.24
;   centersonde = 12
   centerlat2 = 15.09      ;Sonde nearest the interpolated center location for VORTEX msgs   
   centerlon2 = -104.12
   centersonde2 = 14
else if(date2.eq."20151023")then
;   centerlat = 18.58     ;Upper-tropospheric pressure minimum
;   centerlon = -105.20
;   centersonde = 13
   centerlat2 = 18.61      ;Sonde nearest the zero wind center   
   centerlon2 = -105.22
   centersonde2 = 14
   if(axisorient.eq.1)then
      centersonde2 = 32
   end if
else if(date2.eq."20151002")then
   centerlat2 = 23.83    ;Determined by combination of QC notes and meridional velocity
   centerlon2 = -74.65
   centersonde2 = 9
else if(date2.eq."20151003")then
   centerlat2 = 26.18    ;Determined by combination of QC notes and meridional velocity
   centerlon2 = -71.28
   centersonde2 = 7
else if(date2.eq."20151004")then
   centerlat2 = 31.81    ;Determine by IR imagery
   centerlon2 = -66.48
   centersonde2 = 10     ;Note that I chopped off some sondes from the high-density transect
end if
end if
end if
end if
end if
end if

;Set dt for this difference
if(date1.eq."20151021".and.date2.eq."20151022".and.transect1.eq."transect2".and.transect2.eq."transect1")then
   dt = 22.45
else if(date1.eq."20151021".and.date2.eq."20151022".and.transect1.eq."transect2".and.transect2.eq."transect2")then
   dt = 23.15
else if(date1.eq."20151022".and.date2.eq."20151023".and.transect1.eq."transect1".and.transect2.eq."transect1")then
   dt = 25.63
else if(date1.eq."20151022".and.date2.eq."20151023".and.transect1.eq."transect2".and.transect2.eq."transect1")then
   dt = 24.93
else
   print("Invalid date/transect combination...Exiting.")
   exit
end if
end if
end if
end if

system("mkdir "+outdir)

infiles1 = sondedir1+systemfunc("cat "+listfile1)
nfiles1  = dimsizes(infiles1)
infiles2 = sondedir2+systemfunc("cat "+listfile2)
nfiles2  = dimsizes(infiles2)

;If axisorient=1, we need to invert the X axis on 10/21 and 10/23
if(axisorient.eq.1)
   if(date1.eq."20151021".or.date1.eq."20151023")then
      infiles1 = infiles1(::-1)
   end if
end if
if(axisorient.eq.1)
   if(date2.eq."20151021".or.date2.eq."20151023")then
      infiles2 = infiles2(::-1)
   end if
end if


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
pres2     = new((/nfiles2,nlevels/),"float")
temp2     = new((/nfiles2,nlevels/),"float")
theta2    = new((/nfiles2,nlevels/),"float")
dropdist2 = new(nfiles2,"float")
droplat2  = new(nfiles2,"float")
droplon2  = new(nfiles2,"float")
cp_pres2  = new(nfiles2,"float")
cp_temp2  = new(nfiles2,"float")
cp_theta2 = new(nfiles2,"float")
trop_z2   = new(nfiles2,"float")
trop_z2@_FillValue   = -9999.0
cp_pres2@_FillValue  = -9999.0
cp_temp2@_FillValue  = -9999.0
cp_theta2@_FillValue  = -9999.0
pres2@_FillValue     = -9999.0
temp2@_FillValue     = -9999.0
theta2@_FillValue    = -9999.0

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

;-----------------------------;
;PROCESS SECOND LIST OF SONDES;
;-----------------------------;
dropdist2 = 0.
do i=0,nfiles2-1
   unixi = i+1
   print("Processing sonde "+unixi+" of "+nfiles2)
   ;Read input file and assign variables
   data = readAsciiTable(infiles2(i),10,"float",7)
   data@_FillValue = -9999.0
   p    = data(:,0)
   tc   = data(:,1)
   hght = data(:,5)

   ;Get drop latitude and longitude from header
   droplat2(i) = stringtofloat(systemfunc("sed -n 5p "+infiles2(i)+" | awk '{print $3}'"))
   nfields = stringtoint(systemfunc("sed -n 5p "+infiles2(i)+" | awk '{print NF}'"))
   if(nfields.eq.9)then
      droplon2(i) = stringtofloat(systemfunc("sed -n 5p "+infiles2(i)+" | awk '{print $5}' | sed 's/=//'"))
   else
      droplon2(i) = stringtofloat(systemfunc("sed -n 5p "+infiles2(i)+" | awk '{print $6}'"))
   end if

   nhghts = dimsizes(hght)

   ;Set or compute all of the variables
   pres2 (i,0:nhghts-1) = p
   temp2 (i,0:nhghts-1) = tc
   theta2(i,0:nhghts-1) = (tc+273.15)*(1000/p)^0.286
   cp_pres2(i) = pres2(i,minind(temp2(i,:)))
   cp_temp2(i) = min(temp2(i,:))
   cp_theta2(i) = theta2(i,minind(temp2(i,:)))

   ;Get the tropopause height from tropopause pressure by linear interpolation
   if(min(p).lt.200.and..not.ismissing(cp_pres2(i)))then
      diffs = abs(p-cp_pres2(i))
      diffs_sort = diffs(ind(.not.ismissing(diffs)))
      qsort(diffs_sort)
      p1 = p(ind(diffs.eq.diffs_sort(0)))
      p2 = cp_pres2(i)
      p3 = min(p(ind(diffs.eq.diffs_sort(1))))
      z1 = min(hght(ind(diffs.eq.diffs_sort(0))))
      z3 = min(hght(ind(diffs.eq.diffs_sort(1))))
      z2 = (p2-p1)*(z3-z1)/(p3-p1)+z1
      trop_z2(i) = z2/1000
      delete([/diffs,diffs_sort/])
   else
      trop_z2(i) = trop_z2@_FillValue
   end if

   ;Interpolate across missing values in radius, if desired
   if(interp.eq.1)then
      pres2  = linmsg_n(pres2,0,0)
      temp2  = linmsg_n(temp2,0,0)
      theta2 = linmsg_n(theta2,0,0)
   end if

   ;Compute cumulative distance from the first sonde drop
   if(i.gt.0.and.type.eq.0)then
      dropdist2(i) = dropdist(i-1) + gc_latlon(droplat2(i-1),droplon2(i-1),droplat2(i),droplon2(i),2,4)
   end if

   ;Clean up
   delete([/data,p,tc,hght/])
end do

;Compute distance from storm center
;gc_latlon doesn't check for missing values, so we'll just perform a
;quick fix by setting all distances greater than 2000 km to missing
if(type.eq.1)
   dropdist2 = gc_latlon(centerlat2,centerlon2,droplat2,droplon2,2,4)
   dropdist2@_FillValue = -9999.
   dropdist2 = where(dropdist2.gt.2000,dropdist2@_FillValue,dropdist2)
   dropdist2(0:(centersonde2-1)) = dropdist2(0:(centersonde2-1))*-1.
   totaldist2 = round(dropdist2(dimsizes(dropdist2)-1) - dropdist2(0),0) ;Total distance along transect
end if

;--------------------------------------------------------------;
;Interpolate to uniform horizontal grid and perform differences;
;--------------------------------------------------------------;
npts        = toint((gridmax-gridmin)/gridint)+1
uniformgrid = fspan(gridmin,gridmax,npts)
;Pressure
pres1_transpose = transpose(pres1)
pres2_transpose = transpose(pres2)
pres_int1  = linint1(dropdist1,pres1_transpose,False,uniformgrid,0)
pres_int2  = linint1(dropdist2,pres2_transpose,False,uniformgrid,0)
pres_diff  = pres_int2 - pres_int1
;Temperature
temp1_transpose = transpose(temp1)
temp2_transpose = transpose(temp2)
temp_int1  = linint1(dropdist1,temp1_transpose,False,uniformgrid,0)
temp_int2  = linint1(dropdist2,temp2_transpose,False,uniformgrid,0)
temp_diff  = temp_int2 - temp_int1
;Potential temperature
theta1_transpose = transpose(theta1)
theta2_transpose = transpose(theta2)
theta_int1  = linint1(dropdist1,theta1_transpose,False,uniformgrid,0)
theta_int2  = linint1(dropdist2,theta2_transpose,False,uniformgrid,0)
theta_diff  = theta_int2 - theta_int1
;Tropopause quantities
cp_pres_int1 = linint1(dropdist1,cp_pres1,False,uniformgrid,0)
cp_pres_int2 = linint1(dropdist2,cp_pres2,False,uniformgrid,0)
cp_temp_int1 = linint1(dropdist1,cp_temp1,False,uniformgrid,0)
cp_temp_int2 = linint1(dropdist2,cp_temp2,False,uniformgrid,0)
cp_theta_int1 = linint1(dropdist1,cp_theta1,False,uniformgrid,0)
cp_theta_int2 = linint1(dropdist2,cp_theta2,False,uniformgrid,0)
cp_theta_diff = cp_theta_int2 - cp_theta_int1
cp_temp_diff  = cp_temp_int2 - cp_temp_int1
cp_pres_diff  = cp_pres_int2 - cp_pres_int1

;-------------------------------------------------------;
;Create arrays for plotting and set coordinate variables;
;-------------------------------------------------------;
theta_diff!0 = "height"
theta_diff!1 = "radius"
theta_diff&height = fspan(0,maxhght,nlevels)/1000.
theta_diff&radius = uniformgrid
copy_VarMeta(theta_diff,pres_diff)
copy_VarMeta(theta_diff,temp_diff)

;-------------------;
;Compute d(theta)/dt;
;-------------------;
thetabar = (theta_int1+theta_int2)/2
tempbar  = (temp_int1+temp_int2)/2
presbar  = (pres_int1+pres_int2)/2
term1 = thetabar*(1/(tempbar+273.15)*temp_diff)*(24./dt)
term2 = -thetabar*(1/presbar*rd/cp*pres_diff)*(24./dt)
dtheta_dt = term1+term2
copy_VarMeta(theta_diff,dtheta_dt)
copy_VarMeta(theta_diff,term1)
copy_VarMeta(theta_diff,term2)

;-------------------------------------;
;Compute d(theta)/dt at the tropopause;
;-------------------------------------;
cp_thetabar = (cp_theta_int1+cp_theta_int2)/2
cp_tempbar  = (cp_temp_int1+cp_temp_int2)/2
cp_presbar  = (cp_pres_int1+cp_pres_int2)/2
cp_term1 = cp_thetabar*(1/(cp_tempbar+273.15)*cp_temp_diff)*(24./dt)
cp_term2 = -cp_thetabar*(1/cp_presbar*rd/cp*cp_pres_diff)*(24./dt)
cp_dtheta_dt = cp_term1+cp_term2

;----------------------------------------;
;Convert everything to 24-hour tendencies;
;----------------------------------------;
theta_diff   = theta_diff*(24./dt)
cp_theta_diff= cp_theta_diff*(24./dt)

if(date1.eq."20151022".or.date2.eq."20151022")then
   cp_term1(11) = cp_term1@_FillValue
   cp_term2(11) = cp_term2@_FillValue
   cp_dtheta_dt(11) = cp_dtheta_dt@_FillValue
   cp_theta_diff(11) = cp_theta_diff@_FillValue
end if
print(cp_term1)
print(cp_term2)
print(cp_dtheta_dt)
print(cp_theta_diff)
printMinMax(theta_diff-dtheta_dt,0)

;--------------;
;Draw the plots;
;--------------;
;POTENTIAL TEMPERATURE
filename = outdir+"theta-"+date2+"_"+transect2+"-"+date1+"_"+transect1
print( filename)
wks_theta = gsn_open_wks("png",filename)
res = True
;res@tiMainString = "Potential Temperature Difference Field (K)   "+str_capital(storm)+"  "+date2+" minus "+date1
thetachar = "~F33~q~F21~"
deltachar = "~F33~D~F21~"
res@tiMainString = deltachar+thetachar+"     "+mmddyyyy1+" to "+mmddyyyy2
res@tiMainOn = False
if(date1.eq."20151021")then
   res@gsnLeftString = "a) "+res@tiMainString
else if(date1.eq."20151022")then
   res@gsnLeftString = "b) "+res@tiMainString
end if
end if
res@gsnStringFontHeightF = 0.018
if(type.eq.0)then
   res@tiXAxisString = "Distance along flight track (km)"
else if(type.eq.1)then
   res@tiXAxisString = "W                   Distance from storm center (km)                   E"
end if
end if
res@tiYAxisString = "Height (km)"
if(date1.eq."20151022")then
   res@tiYAxisOn = False
end if
res@tiMainFontHeightF = 0.013
res@tiXAxisFontHeightF = 0.017
res@tiYAxisFontHeightF = 0.017
res@trXMinF = -100
res@trXMaxF = 55
res@trYMinF = 16.
res@trYMaxF = 18.5
res@cnLevelSpacingF = 2.0
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = -20
res@cnMaxLevelValF = 20
res@cnFillOn = True
res@cnInfoLabelOn = False
res@cnLinesOn = False
res@cnLineLabelsOn = True
res@lbLabelBarOn = False
res@lbOrientation = "Vertical"
res@lbAutoManage = False
res@lbLabelFontHeightF = 0.020
res@tmYLMode = "Explicit"
res@tmYLValues = (/16.0,16.5,17.0,17.5,18.0,18.5/)
res@tmYLLabels = (/"16.0","16.5","17.0","17.5","18.0","18.5"/)
res@tmYLMinorValues = fspan(16,18.5,26)
res@tmYROn = False
res@tmXTOn = False
res@tmXBLabelFontHeightF = 0.016
res@tmYLLabelFontHeightF = 0.016
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False
theta_img = gsn_csm_contour(wks_theta,theta_diff,res)
res@tiYAxisOn = False

;TEMPERATURE
;wks_temp = gsn_open_wks("png",outdir+"temp_"+date2+"-"+date1)
;tempres = res
;if(date2.eq."20151022")then
;   tempres@gsnLeftString = "b) "+res@tiMainString
;else
;   tempres@gsnLeftString = "e) "+res@tiMainString
;end if
;tempres@tiMainString = "Temperature Difference Field (K)   "+str_capital(storm)+" "+date2+" minus "+date1
;;tempres@cnMinLevelValF = -13
;;tempres@cnMaxLevelValF = 13
;temp_img = gsn_csm_contour(wks_temp,temp_diff,tempres)
;
;;PRESSURE
;wks_pres = gsn_open_wks("png",outdir+"pres_"+date2+"-"+date1)
;pres = res
;if(date2.eq."20151022")then
;   pres@gsnLeftString = "c) "+res@tiMainString
;else
;   pres@gsnLeftString = "f) "+res@tiMainString
;end if
;pres@tiMainString = "Pressure Difference Field (hPa)   "+str_capital(storm)+" "+date2+" minus "+date1
;;pres@cnLevelSpacingF = 1.0
;;pres@cnMinLevelValF = -20
;;pres@cnMaxLevelValF = 20
;pres_img = gsn_csm_contour(wks_pres,pres_diff,pres)

;TERMS 1 AND 2 of d(THETA)/dt
wks_term1 = gsn_open_wks("png",outdir+"term1_"+date2+"-"+date1)
wks_term2 = gsn_open_wks("png",outdir+"term2_"+date2+"-"+date1)
termres = res
termres@tiMainOn = False
termres@tiMainString = "Term 1     "+mmddyyyy1+" to "+mmddyyyy2;+date2+"-"+date1
if(date1.eq."20151021")then
   termres@gsnLeftString = "b) "+termres@tiMainString
else if(date1.eq."20151022")then
   termres@gsnLeftString = "e) "+termres@tiMainString
end if
end if
termres@tiYAxisOn = False
termres@lbLabelBarOn = False
;termres@cnMinLevelValF = -20
;termres@cnMaxLevelValF = 20
term1_img = gsn_csm_contour(wks_term1,term1,termres)
termres@tiMainString = "Term 2     "+mmddyyyy1+" to "+mmddyyyy2
if(date1.eq."20151021")then
   termres@gsnLeftString = "c) "+termres@tiMainString
else if(date1.eq."20151022")then
   termres@gsnLeftString = "f) "+termres@tiMainString
end if
end if
term2_img = gsn_csm_contour(wks_term2,term2,termres)

;TROPOPAUSE d(THETA)/dt
data = new((/3,npts/),"float")
data(0,:) = cp_dtheta_dt
data(1,:) = cp_term1
data(2,:) = cp_term2
wks_tropdtheta = gsn_open_wks("png",outdir+"tropdtheta_"+date2+"-"+date1)
tropdthetares = True
if(date1.eq."20151021")then
   tropdthetares@tiMainString = "Change From 10/21 to 10/22"
else if (date1.eq."20151022")then
   tropdthetares@tiMainString = "Change from 10/22 to 10/23"
end if
end if
tropdthetares@tiYAxisString = "Potential Temperature Change (K)"
tropdthetares@xyLineColor = "black"
tropdthetares@xyLineThicknesses = (/6,6,6/)
tropdthetares@xyDashPatterns = (/0,16,2/)
tropdthetares@trYMinF = -8
tropdthetares@trYMaxF = 36
tropdthetares@tmYROn = False
tropdthetares@tmXTOn = False
tropdthetares@gsnDraw = False
tropdthetares@gsnFrame = False
tropdthetares@gsnMaximize = True
tropdthetares@pmLegendDisplayMode = "Always"
tropdthetares@pmLegendSide = "Right"
tropdthetares@pmLegendOrthogonalPosF = -0.36 ;Move legend left
if(date2.eq."20151023")then
   tropdthetares@pmLegendOrthogonalPosF = -0.9
end if
tropdthetares@pmLegendParallelPosF   = 0.1 ;Move legend down
tropdthetares@pmLegendWidthF = 0.25
tropdthetares@pmLegendHeightF = 0.10
tropdthetares@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
tropdthetares@lgPerimOn = False             ;Turn on/off box around legend
tropdthetares@lgLabelFontHeightF = 0.02
tropdthetares@xyExplicitLegendLabels = (/"dtheta/dt","Term 1","Term 2"/)
tropdtheta_img = gsn_csm_xy(wks_tropdtheta,uniformgrid,data,tropdthetares)

;Add vertical lines at x=0
zerolineres = True
zerolineres@gsLineDashPattern = 16
zerolineres@gsLineThicknessF = 6.
zeroline_theta = gsn_add_polyline(wks_theta,theta_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
;zeroline_temp  = gsn_add_polyline(wks_temp,temp_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
;zeroline_pres  = gsn_add_polyline(wks_pres,pres_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
zeroline_term1 = gsn_add_polyline(wks_term1,term1_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
zeroline_term2 = gsn_add_polyline(wks_term2,term2_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
zerolineres@gsLineThicknessF = 2.
zeroline_tropdtheta = gsn_add_polyline(wks_tropdtheta,tropdtheta_img,(/0,0/),(/tropdthetares@trYMinF,tropdthetares@trYMaxF/),zerolineres)
zeroline_tropdtheta2 = gsn_add_polyline(wks_tropdtheta,tropdtheta_img,(/-40,40/),(/0,0/),zerolineres)

draw(theta_img)
;draw(temp_img)
;draw(pres_img)
draw(tropdtheta_img)
draw(term1_img)
draw(term2_img)
frame(wks_theta)
;frame(wks_temp)
;frame(wks_pres)
frame(wks_tropdtheta)
frame(wks_term1)
frame(wks_term2)

;PLOT PRESSURE FIELD JUST FOR THE HELL OF IT
copy_VarMeta(theta_diff,pres_int2)
copy_VarMeta(theta_diff,pres_int1)
wks = gsn_open_wks("png",outdir+"pres_"+date2+"_"+transect2)
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
printMinMax(theta_diff,0)
printMinMax(term1,0)
printMinMax(term2,0)
