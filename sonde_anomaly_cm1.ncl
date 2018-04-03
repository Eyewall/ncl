load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"

;---------------------------------------------
; sonde_anomaly_cm1.ncl
; Patrick Duran
; 17 February 2016
; 
; Computes the temperature anomalies from the
; Rotunno and Emanuel (1987) hurricane sounding
; for a CM1 simulation. Plots cross-section of
; the anomalies, if desired.
;---------------------------------------------
minhght  = 9000   ;Minimum height to plot (m)
maxhght  = 18500  ;Maximum height to pull (m)
maxrad   = 100    ;Maximum radius to pull (km)
dz       = 250    ;Vertical grid spacing (m)
dx       = 1      ;Radial grid spacing (km)
nlevels  = maxhght/dz+1
lon      = 310    ;Longitude of storm center (needed for local time calculation)
modeldir = "/nfs/jm13/pduran/cm1/cm1r18/run/run02/output/"
outfile  = "/jm13/pduran/web/tci/cross_sections/anomalies/cm1/run02/"+maxrad+"km/"
avg_file = "/jm13/pduran/dropsondes/rotunno_emanuel_hurricane_sounding"
interp   = 0   ;Interpolate across missing values in the radial direction?
                ;0=Do not interpolate, 1=Interpolate
cp = 1004
rd = 287

system("mkdir "+outfile)

;------------------------------;
;SET UP THE BASE STATE SOUNDING;
;------------------------------;
;Get data from average file that we'll use to compute anomalies
average = readAsciiTable(avg_file,5,"float",2)
hght_avg  = average(:,0) / 1000.
theta_avg = average(:,1)

;Get the list of input files and the height coordinate
infiles    = systemfunc("ls "+modeldir+"*_00*nc")
nfiles     = dimsizes(infiles)
ncfile    = addfile(infiles(0),"r")
hght       = ncfile->z

;Interpolate the values to vertical levels defined by dz
;avg_theta = linint1(hght_avg,theta_avg,False,hght,0)
avg_theta_in = ncfile->th
avg_theta    = avg_theta_in(:,:(maxhght/dz)-1,:,:(maxrad/dx)-1)

;------------------------------;
;GET DATA FROM EACH INPUT FILE;
;------------------------------;
do i=0,nfiles-1
   unixi = i+1
   print("Processing file "+unixi+" of "+nfiles)
   ;Read input file and assign variables
   ncfile = addfile(infiles(i),"r")
   time      = ncfile->time
   p         = ncfile->prs     ;Pressure (Pa)
   theta_in  = ncfile->th	    ;Potential temperature (K)
   theta     = theta_in(:,:(maxhght/dz)-1,:,:(maxrad/dx)-1)

   ;Get local time
   time_units = time@units
   date_string = systemfunc("echo "+time_units+" | awk '{print($3)}'")
   time_string = systemfunc("echo "+time_units+" | awk '{print($4)}'")
   init_year   = stringtoint(systemfunc("echo "+date_string+" | awk -F'-' '{print($1)}'"))
   init_mon    = stringtoint(systemfunc("echo "+date_string+" | awk -F'-' '{print($2)}'"))
   init_day    = stringtoint(systemfunc("echo "+date_string+" | awk -F'-' '{print($3)}'"))
   init_hour   = stringtoint(systemfunc("echo "+time_string+" | awk -F':' '{print($1)}'"))
   t_init_jul  = greg2jul(init_year,init_mon,init_day,init_hour)

   time_jul  = t_init_jul + time/86400
   time_greg = jul2greg(time_jul)
   time_hour = time_greg(3)
   arg = tofloat(lon)*24/360
   hour_local_dec = mod((time_hour+arg),24)
   minu_local_dec = hour_local_dec-floor(hour_local_dec)
   hour_local = hour_local_dec - minu_local_dec
   minu_local = ceil(minu_local_dec*60)

   ;Compute some variables
   nhghts = dimsizes(hght)
   hour   = toint(time/3600.)

   ;Compute anomalies
;   avg_theta_conform = conform(theta,avg_theta,1)
;   theta_anom = theta - avg_theta_conform
   theta_anom = theta - avg_theta

   ;-------------------------------------------------------;
   ;CREATE ARRAYS FOR PLOTTING AND SET COORDINATE VARIABLES;
   ;-------------------------------------------------------;
   ;POTENTIAL TEMPERATURE ANOMALY
   theta_anom!1 = "height"
   theta_anom!3 = "radius"
   theta_anom&height = fspan(dz,maxhght,nlevels-1)/1000.
   theta_anom&radius = fspan(1,maxrad,dx*maxrad)

   ;------------------------------------------------------------------;
   ;Interpolate across missing values in radius, if option is selected;
   ;------------------------------------------------------------------;
   if(interp.eq.1)then
      plot_theta_anom = linmsg(plot_theta_anom,0)
      out_suffix = "interp"
   else
      out_suffix = "nointerp"
   end if

   ;---------------------------;
   ;Get the locations of maxima;
   ;---------------------------;
   max_theta_anom = max(theta_anom)
   max_theta_anom_inds = ind_resolve(maxind(ndtooned(theta_anom)),dimsizes(theta_anom))
   max_theta_anom_x = (max_theta_anom_inds(0,1)+1)*dx
   max_theta_anom_z = (max_theta_anom_inds(0,3)+1)*dz

   ;--------------;
   ;Draw the plots;
   ;--------------;
   ;TEMPERATURE ANOMALIES
;   wks = gsn_open_wks("png",outfile+unixi)
   wks = gsn_open_wks("png",outfile+unixi)
   gsn_define_colormap(wks,"BlWhRe")
   res = True
   res@tiMainString = "Potential temperature anomalies from initial state (K)   "+hour_local+":"+minu_local+" LST"
   res@tiYAxisString = "Height (km)"
   res@tiXAxisString = "Radius (km)"
   res@tiMainFontHeightF = 0.015
   res@tiXAxisFontHeightF = 0.02
   res@tiYAxisFontHeightF = 0.02
   res@trYMinF = minhght/1000.
   res@trYMaxF = maxhght/1000.
   res@trXMinF = 0.
   res@trXMaxF = maxrad
   res@cnLevelSpacingF = 2.
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF = -20
   res@cnMaxLevelValF = 20
   res@cnFillOn = True
   res@cnLinesOn = False
   res@lbOrientation = "Vertical"
   res@tmYROn = False
   res@tmXTOn = False
   res@gsnMaximize = True
   res@cnMissingValPerimOn = True
   res@cnMissingValPerimColor = "Dark Green"
   res@cnMissingValFillPattern = 3
   res@cnMissingValFillColor = "Dark Green"
   theta_anom_img = gsn_csm_contour(wks,theta_anom(0,:,0,:),res)
   wmlabs(wks,max_theta_anom_x,max_theta_anom_z,"HI")
end do
