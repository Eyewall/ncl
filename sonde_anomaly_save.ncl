load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"

;---------------------------------------------
; sonde_anomaly.ncl
; Patrick Duran
; 08 February 2016
; 
; Computes the temperature anomalies from the
; Dunion (2011) Moist Tropical Sounding for
; a list of dropsondes. Will plot a vertical
; cross-section of the anomalies, if desired.
;---------------------------------------------
storm    = "patricia"
flight   = "20151022"
transect = "transect1"
maxhght  = 20000  ;Maximum height to pull (m)
dz       = 100
nlevels  = maxhght/dz+1
sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+flight+"/"
listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+flight+"/"+transect
outfile  = "/jm13/pduran/web/tci/cross_sections/anomalies/"+storm+"/"+flight+"/"+transect
avg_file = "/jm13/pduran/dropsondes/dunion_moisttropical_sounding"
interp   = 1   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate
type     = 1   ;Plot as total distance from start of flight let (0) or
               ;distance from storm center (1)?

if(flight.eq."20151021")then
   centerlat = 13.41    ;Determined by looking at meridional velocity from dropsondes
   centerlon = -99.34
   centersonde = 6      ;The line number in the listfile where the center sonde is
else if(flight.eq."20151022")then
   centerlat = 15.09    ;Determined by IR imagery
   centerlon = -104.12
   centersonde = 13
else if(flight.eq."20151023")then
   centerlat = 18.61    ;Determined by IR imagery
   centerlon = -105.22
   centersonde = 14
end if
end if
end if

;------------------------------;
;SET UP THE BASE STATE SOUNDING;
;------------------------------;
;Get data from average file that we'll use to compute anomalies
average = readAsciiTable(avg_file,3,"float",2)
hght_avg  = average(:,0)
   t_avg  = average(:,1)
theta_avg = average(:,2)

;Interpolate the values to vertical levels defined by dz
hghts = fspan(0,maxhght,maxhght/dz+1)
avg_t = linint1(hght_avg,t_avg,False,hghts,0)
avg_theta = linint1(hght_avg,theta_avg,False,hghts,0)

;----------------------------;
;GET DATA FROM EACH DROPSONDE;
;----------------------------;
infiles    = sondedir+systemfunc("cat "+listfile)
nfiles     = dimsizes(infiles)
tempc      = new((/nfiles,nlevels/),"float") 
theta      = new((/nfiles,nlevels/),"float")
temp_anom  = new((/nfiles,nlevels/),"float")
theta_anom = new((/nfiles,nlevels/),"float")
lats       = new((/nfiles,nlevels/),"float")
lons       = new((/nfiles,nlevels/),"float")
droplat    = new(nfiles,"float")
droplon    = new(nfiles,"float")
dropdist   = new(nfiles,"float")
tempc@_FillValue      = -9999.0
theta@_FillValue      = -9999.0
lats@_FillValue       = -9999.0
lons@_FillValue       = -9999.0
temp_anom@_FillValue  = -9999.0
theta_anom@_FillValue = -9999.0

dropdist = 0.
do i=0,nfiles-1
   unixi = i+1
   print("Processing sonde "+unixi+" of "+nfiles)
   ;Read input file and assign variables
   data = readAsciiTable(infiles(i),10,"float",7)
   data@_FillValue = -9999.0
   p    = data(:,0)
   tc   = data(:,1)
   td   = data(:,2)
   u    = data(:,3)
   v    = data(:,4)
   hght = data(:,5)
   rh   = data(:,6)
   lat  = data(:,7)
   lon  = data(:,8)

   ;Get drop latitude and longitude from header
   droplat(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $3}'"))
   nfields = stringtoint(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print NF}'"))
   if(nfields.eq.9)then
      droplon(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $5}' | sed 's/=//'"))
   else
      droplon(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $6}'"))
   end if

   ;Compute some variables
   nhghts = dimsizes(hght)
   tempc(i,0:nhghts-1) = tc
   theta(i,0:nhghts-1) = (tc+273.15)*(1000/p)^0.286

   ;Compute anomalies
   temp_anom(i,:)  = tempc(i,:) - avg_t
   theta_anom(i,:) = theta(i,:) - avg_theta

   ;Assign latitudes and longitudes
   lats(i,0:nhghts-1) = lat
   lons(i,0:nhghts-1) = lon

   ;Compute distance along flight track
   if(i.gt.0.and.type.eq.0)then
      dropdist(i) = dropdist(i-1) + gc_latlon(droplat(i-1),droplon(i-1),droplat(i),droplon(i),2,4)
   end if

   ;Compute distance from storm center
   ;gc_latlon doesn't check for missing values, so we'll just perform a
   ;quick fix by setting all distances greater than 2000 km to missing
   if(type.eq.1)
   ;   dist = dist + gc_latlon(centerlat,centerlon,lats,lons,2,4)
      dropdist = gc_latlon(centerlat,centerlon,droplat,droplon,2,4)
   ;   dist@_FillValue = -9999.
      dropdist@_FillValue = -9999.
   ;   dist = where(dist.gt.2000,dist@_FillValue,dist)
      dropdist = where(dropdist.gt.2000,dropdist@_FillValue,dropdist)
      dropdist(0:(centersonde-1)) = dropdist(0:(centersonde-1))*-1.
   end if

   ;Clean up
   delete([/data,p,tc,td,u,v,hght,rh,lat,lon/])
end do

;-------------------------------------------------------;
;CREATE ARRAYS FOR PLOTTING AND SET COORDINATE VARIABLES;
;-------------------------------------------------------;
;TEMPERATURE ANOMALY
plot_temp_anom = transpose(temp_anom)
plot_temp_anom!0 = "height"
plot_temp_anom!1 = "radius"
plot_temp_anom&height = fspan(0,maxhght,nlevels)/1000.
plot_temp_anom&radius = dropdist

;POTENTIAL TEMPERATURE ANOMALY
plot_theta_anom = transpose(theta_anom)
copy_VarMeta(plot_temp_anom,plot_theta_anom)

;------------------------------------------------------------------;
;Interpolate across missing values in radius, if option is selected;
;------------------------------------------------------------------;
if(interp.eq.1)then
   plot_temp_anom  = linmsg(plot_temp_anom,0)
   plot_theta_anom = linmsg(plot_theta_anom,0)
   out_suffix = "interp"
else
   out_suffix = "nointerp"
end if

;--------------;
;Draw the plots;
;--------------;
;TEMPERATURE ANOMALIES
wks       = gsn_open_wks("png",outfile+"_temp"+out_suffix)
wks_theta = gsn_open_wks("png",outfile+"_theta"+out_suffix)
gsn_define_colormap(wks,"BlWhRe")
res = True
res@tiMainOn = False
res@tiMainString = "Temperature Anomalies From Dunion (2011) Moist Tropical Sounding (K)  "+flight+"  "+transect
res@gsnStringFontHeightF = 0.018
if(flight.eq."20151002".or.flight.eq."20151021")then
   res@tiYAxisOn = True
   res@tiYAxisString = "Height (km)"
   res@gsnLeftString = "d)"
else
   res@tiYAxisOn = False
;   res@tmYLLabelsOn = False
   if(flight.eq."20151003".or.flight.eq."20151022")then
      res@gsnLeftString = "e)"
   else if (flight.eq."20151004".or.flight.eq."20151023")then
      res@gsnLeftString = "f)"
   end if
   end if
end if
res@tiYAxisString = "Height (km)"
res@tiXAxisString = "Distance from storm center (km)"
res@tiMainFontHeightF = 0.01
res@tiXAxisFontHeightF = 0.017
res@tiYAxisFontHeightF = 0.017
res@trYMinF = 16.
res@trYMaxF = 18.5
res@trXMaxF = max(dropdist)
res@cnInfoLabelOn = False
res@cnLevelSpacingF = 2.
res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = -30
res@cnMaxLevelValF = 30
res@cnFillOn = True
res@cnLinesOn = False
res@lbLabelBarOn = False
res@lbOrientation = "Vertical"
res@tmYROn = False
res@tmXTOn = False
res@tmXBLabelFontHeightF = 0.016
res@tmYLLabelFontHeightF = 0.016
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False
res@cnMissingValPerimOn = True
res@cnMissingValPerimColor = "Dark Green"
res@cnMissingValFillPattern = 3
res@cnMissingValFillColor = "Dark Green"
if(flight.eq."20151022".or.flight.eq."20151023")then
   res@tiYAxisOn = False
;   res@tmYLLabelsOn = False
end if
temp_anom_img = gsn_csm_contour(wks,plot_temp_anom,res)
theta_anom_img = gsn_csm_contour(wks_theta,plot_theta_anom,res)

;Overlay lines that represent drop locations
liney = new((/dimsizes(dropdist),2/),"float")
linex = liney
locs  = new(dimsizes(dropdist),"graphic")
   do i=0,dimsizes(locs)-1
      linex(i,:) = dropdist(i)
      liney(i,0) = res@trYMinF
      liney(i,1) = res@trYMaxF
;      lineres = False
;      locs(i) = gsn_add_polyline(wks,temp_anom_img,linex(i,:),liney(i,:),lineres)
   end do

;Overlay digits that represent drop locations
text = tostring(ispan(1,nfiles,1))
txres = True
txres@txFont = 30
txres@txFontHeightF = 0.01
txres@txFontColor = "black"
dum  = gsn_add_text(wks,temp_anom_img,text,linex(:,0),liney(:,0)+0.25,txres)
dum1 = gsn_add_text(wks,theta_anom_img,text,linex(:,0),liney(:,0)+0.25,txres)

draw(temp_anom_img)
frame(wks)

;POTENTIAL TEMPERATURE ANOMALIES
;wks = gsn_open_wks("png",outfile+"_theta"+out_suffix)
;res@tiMainString = "Potential Temperature Anomalies from Dunion (2011) Moist Tropical Sounding (K)   "+flight+"  "+transect
;theta_anom_img = gsn_csm_contour(wks,plot_theta_anom,res)
draw(theta_anom_img)
frame(wks)
