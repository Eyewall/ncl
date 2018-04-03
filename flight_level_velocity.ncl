load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-----------------------------------------------------------------; 
;flight_level_velocity.ncl
;Patrick Duran
;1/18/2014
;
;Will read in a netCDF file containing 1-Hz flight-level aircraft
;reconnaissance data and will plot a 4-panel figure of the flight
;track over an IR satellite image and the perturbation u, v, and
;w velocities. The perturbations are calculated about a running
;average over a time specified by the user. The flight track and
;u', v', and w' traces are color coded for easy comparison. The
;time step of the color change can be modified in the PARAMETERS
;section. Script will only create plots if a minimum altitude
;criterion (set by user in PARAMETERS) is met.
;-----------------------------------------------------------------;

;----------------;
;DATA DIRECTORIES;
;----------------;
datapath = "/jm13/pduran/ivan/flight_level/data/"
satpath  = "/jm13/djv/ivan04/mcidas/merc/"

;------------------------------------;
;Loop through all of the netCDF files;
;------------------------------------;
ncdf_files = systemfunc("ls "+datapath+"*.cdf")
numfiles   = dimsizes(ncdf_files)
do b=1,numfiles-1
  flightnum = sprinti("%0.2i",(b+1))   ;Each netCDF file corresponds to one recon flight
   datafile = ncdf_files(b)
  
   ;----------;
   ;PARAMETERS;
   ;----------;
   plotopt = 0             ;Set to "0" for 4-panel perturbation velocity plots, "1" for 2-panel vertical velocity variance plots
   minalt = 12000          ;The altitude the plane must be above for plotting to occur [meters]
;   averaging_time = a    ;The amount of time over which the running average is performed [seconds]
   timestep_plot = 2000    ;The amount of time to plot ovservations on each plot (seconds)
   timestep_color = 120.   ;The time (seconds) between each change in line color
   timestep_plot = 27000
   timestep_color = 1200.
   
   colorlist = (/"black","purple","red","blue","brown","green","black","purple","red","blue","brown","green",\
                 "black","purple","red","blue","brown","green","black","purple","red","blue","brown","green",\
                 "black","purple","red","blue","brown","green","black","purple","red","blue","brown","green",\
                 "black","purple","red","blue","brown","green","black","purple","red","blue","brown","green",\
                 "black","purple","red","blue","brown","green","black","purple","red","blue","brown","green",\
                 "black","purple","red","blue","brown","green","black","purple","red","blue","brown","green"/)
  
   ;---------------------;
   ;Get flight level data;
   ;---------------------;
   flightdata  = addfile(datafile,"r")
   vert_accel  = flightdata->ACINS_PITR   ;Aircraft vertical acceleration
;   vert_accel = (vert_accel_raw * vert_accel_raw)^0.5
   w           = flightdata->WI           ;Wind vector, vertical gust component
   u           = flightdata->UI           ;Wind vector, zonal component
   v           = flightdata->VI           ;Wind vector, meridional component
   tmpc        = flightdata->TT1          ;Temperature, Left Top (there are 3 other total temperautures in ncdf file)
   dwpc        = flightdata->DPL          ;Dew/Frost Point Temperature, Left (there is also one for Right in ncdf file)
   relh        = flightdata->RHUM         ;Relative humidity
   theta       = flightdata->THETA        ;Potential temperatures
   thetae      = flightdata->THETAE       ;Equivalent potential temperature
   lat         = flightdata->GPLAT        ;Latitude
   lon         = flightdata->GPLON        ;Longitude
   alt         = flightdata->GPALT        ;Altitude
   groundspeed = flightdata->GHGSF_SG1    ;Aircraft ground speed
   airspeed    = flightdata->TASX         ;Aircraft airspeed
   base_time   = flightdata->base_time    ;Base time (Seconds since Jan 1, 1970)
   flight_time = flightdata->time_offset  ;Time since base_time (seconds)
   time_sec = new(dimsizes(flight_time),"double")
   time_sec    = base_time + flight_time  ;Observation times (Seconds since Jan 1, 1970)
   flight_time_minu = flight_time/60      ;Convert flight time to minutes for use in plotting
   thetac = theta - 273.15                ;Convert theta to Celsius
print(max(flight_time(ind(alt.gt.minalt))))
print(min(groundspeed(min(ind(alt.gt.minalt)):max(ind(alt.gt.minalt)))))
print(max(groundspeed(min(ind(alt.gt.minalt)):max(ind(alt.gt.minalt)))))

   ;-----------------------------------------------------;
   ;Loop through all averaging times for running averages;
   ;-----------------------------------------------------;      
;   do a = 0,1000,100       
   do a = 0,10,1
      averaging_time = a    ;The amount of time over which the running average is performed [seconds]      
      ;-----------------------------------------;
      ;Smooth the velocities with a running mean;
      ;-----------------------------------------;
      u_smth = runave_Wrap(u,averaging_time,0)
      v_smth = runave_Wrap(v,averaging_time,0)
      w_smth = runave_Wrap(w,averaging_time,0)
      accel_smth = runave_Wrap(vert_accel,averaging_time,0)
      theta_smth = runave_Wrap(theta,averaging_time,0)
      relh_smth = runave_Wrap(relh,averaging_time,0)
 
      perturb_accel = vert_accel - accel_smth     
      ;------------------------------------------------------;
      ;Calculate perturbation velocities WRT the running mean;
      ;------------------------------------------------------;
      if(a.eq.0)then     ;Plot the total values (not perturbations;no average subtracted)
         perturb_u = u
         perturb_v = v
         perturb_w = w
         perturb_theta = theta
         perturb_u@long_name = "u velocity [m/s]"
         perturb_v@long_name = "v velocity [m/s]"
         perturb_w@long_name = "w velocity [m/s]"
         perturb_theta@long_name = "Potential temperature [K]"
         yaxismin = -30
         yaxismax = 30
         yaxismin_theta = 340
         yaxismax_theta = 355
         labelstring = (/"","U","V","W"/)
      else               ;Plot perturbation quantities
         perturb_u = u - u_smth
         perturb_v = v - v_smth
         perturb_w = w - w_smth
         perturb_theta = theta - theta_smth
         perturb_u@long_name = "Perturbation u velocity [m/s]"
         perturb_v@long_name = "Perturbation v velocity [m/s]"
         perturb_w@long_name = "Perturbation w velocity [m/s]"
         perturb_theta@long_name = "Perturbation potential temperature [K]"
         yaxismin = -6
         yaxismax = 6
         yaxismin_theta = -10
         yaxismax_theta = 10
         labelstring = (/"","U'","V'","W'"/)
      end if
      
      ;----------------------------------------------;
      ;Loop over the whole flight time to plot images;
      ;----------------------------------------------;
      starttime = floattoint(flight_time(min(ind(alt.gt.minalt))))
      endtime = floattoint(flight_time(max(ind(alt.gt.minalt))))
      timestep_plot = endtime - starttime
      altkm = alt/1000       ;Convert altitude to km
      ntimes = floor((endtime-starttime)/timestep_plot)
      mintime = starttime
      maxtime = starttime + timestep_plot
      do index=0,ntimes-1
         unixi = ntimes + 1
         print("Creating plot "+unixi+" of "+ntimes+"   "+systemfunc("date"))
;         if(index.ne.0)then
;            mintime = mintime + timestep_plot 
;;TODO: CHANGE THIS BACK
;;            maxtime = maxtime + timestep_plot
;            maxtime = maxtime + timestep_plot - mintime
;         end if

         ;-------------------------------------;
         ;Get base time in recongnizable format;
         ;-------------------------------------;
         base_time@units = "seconds since 1970-1-1 00:00:0.0"
         base_dattim = cd_calendar(base_time,0)      ;Base date/time 2-D array: [n_obs x 6]
         center_time = maxtime - (timestep_plot / 2) ;Temporal center of flight leg [seconds since base_time]
         total_center_time = base_time + center_time ;Temporal center of flight leg [seconds since 1/1/1970]
      
         ;----------------------------------------;
         ;Get base time array for all observations;
         ;----------------------------------------;
         time_sec@units = "seconds since 1970-1-1 00:00:0.0"
         actual_dattim = floattoint(cd_calendar(time_sec,0))  ;Date/time of each individual observation 2-D array: [n_obs x 6]
         time_min = time_sec / 60.                ;Convert seconds to minutes
      
         ;-----------------------------------------;
         ;Get center LAT,LON and center time of leg;
         ;-----------------------------------------;
         centerlat = lat(center_time)
         centerlon = lon(center_time)
         centerdattim = sprinti("%0.2i",actual_dattim(center_time,1))+"/"+sprinti("%0.2i",actual_dattim(center_time,2))+"/"+\
                        sprinti("%0.4i",actual_dattim(center_time,0))+" "+sprinti("%0.2i",actual_dattim(center_time,3))+":"+\
                        sprinti("%0.2i",actual_dattim(center_time,4))+":"+sprinti("%0.2i",actual_dattim(center_time,5))+" UTC"
      
         ;---------------------------------------------------;
         ;Get initial and final altitudes for this flight leg;
         ;---------------------------------------------------;
         init_alt = sprintf("%5.2f",altkm(mintime))+"km"
         final_alt = sprintf("%5.2f",altkm(maxtime))+"km"
         min_alt = sprintf("%5.2f",min(altkm(mintime:maxtime)))
         max_alt = sprintf("%5.2f",max(altkm(mintime:maxtime))) 
      
            basefilename = sprinti("%0.5i",mintime)+"-"+sprinti("%0.5i",maxtime)+"_"+averaging_time+"s_flight"+flightnum

         if(plotopt.eq.0)then   ;Plot perturbation velocities
         ;----------------------------;
         ;Make velocity vs. time plots;
         ;----------------------------; 
            filename = sprinti("%0.5i",mintime)+"-"+sprinti("%0.5i",maxtime)+"_"+averaging_time+"s_flight"+flightnum+"_vertaccel"
            filename2 = sprinti("%0.5i",mintime)+"-"+sprinti("%0.5i",maxtime)+"_"+averaging_time+"s_flight"+flightnum+"_vertaccel_avg"
            wks_type = "png"
            ;wks_type@wkPaperSize = "B"
            wks = gsn_open_wks(wks_type,filename)
            wks2 = gsn_open_wks(wks_type,filename2)
            ;Set some resources for xy plots 
            ytres = True   ;Resources for u and v plots
;            ytres@gsnMaximize = True
            ytres@tiXAxisString = "Flight time (minutes)"
            ytres@trXMinF = mintime/60.
            ytres@trXMaxF = maxtime/60.
      ;      ytres@trYMinF = floor(min((/perturb_u(starttime:endtime),perturb_v(starttime:endtime)/)))
      ;      ytres@trYMaxF = ceil(max((/perturb_u(starttime:endtime),perturb_v(starttime:endtime)/)))
            ytres@trYMinF = yaxismin
            ytres@trYMaxF = yaxismax
            ytres@xyLineThicknessF = 2.
            ytres@gsnMaximize = False
            ytres@gsnDraw = False      ;Set to False so we can plot multi-colored lines
            ytres@gsnFrame = False
            ytres@tiYAxisOn = True   
         
            ytresu = ytres
            ytresu@tiXAxisOn = False
            ytresu@tmXBLabelsOn = False
            ytresu@gsnStringFontHeightF = 0.015
            ytresu@gsnLeftString = "Flight time (center of leg): "+centerdattim+"  Averaging time: "+averaging_time+"s" 
      
            ytresw = ytres
            ytresw@trYMinF = -6
            ytresw@trYMaxF = 5
            ytresw@tiYAxisString = "w (ms~S~-1~N~)"
            ytresw@tmXTOn = False
            ytresw@tmYROn = False

            ytresa = ytres
            ytresa@trYMinF = -2
            ytresa@trYMaxF = 2
            ytresa@tiYAxisString = "Vertical acceleration (ms~S~-2~N~)"
            ytresa@tmXTOn = False
            ytresa@tmYROn = False
      
            thetares = ytres
            thetares@trYMinF = yaxismin_theta ;min(thetac(ind(alt.gt.minalt)))
            thetares@trYMaxF = yaxismax_theta ;max(thetac(ind(alt.gt.minalt)))
            thetares@tiYAxisString = "Perturbation Potential Temperature [C]"
            thetares@xyLineColor = "darkgreen" 
      
            relhres = thetares
            relhres@trYMinF = 50
            relhres@trYMaxF = 100
            relhres@tiYAxisString = "Relative Humidity [%] WRT Water"
      
            ;Create xy plots of perturbation velocities
            plotu = gsn_csm_xy(wks,flight_time_minu(mintime:maxtime),perturb_u(mintime:maxtime),ytresu)
            plotv = gsn_csm_xy(wks,flight_time_minu(mintime:maxtime),perturb_v(mintime:maxtime),ytres)
            plotw = gsn_csm_xy(wks,flight_time_minu(mintime:maxtime),perturb_w(mintime:maxtime),ytresw)
            plotaccel = gsn_csm_xy(wks,flight_time_minu(mintime:maxtime),vert_accel(mintime:maxtime),ytresa)
            plot_accel_smth = gsn_csm_xy(wks2,flight_time_minu(mintime:maxtime),perturb_accel(mintime:maxtime),ytresa)
            plotu = gsn_csm_xy2(wks,flight_time_minu(mintime:maxtime),perturb_u(mintime:maxtime),perturb_theta(mintime:maxtime),ytresu,thetares)
      ;      plotv = gsn_csm_xy2(wks,flight_time_minu(mintime:maxtime),perturb_v(mintime:maxtime),perturb_theta(mintime:maxtime),ytres,thetares)
      ;      plotw = gsn_csm_xy2(wks,flight_time_minu(mintime:maxtime),perturb_w(mintime:maxtime),perturb_theta(mintime:maxtime),ytresw,thetares)
;TODO: REINSTATE THESE BELOW
;            plotu = gsn_csm_xy2(wks,flight_time_minu(mintime:maxtime),perturb_u(mintime:maxtime),relh(mintime:maxtime),ytresu,relhres)
;            plotv = gsn_csm_xy2(wks,flight_time_minu(mintime:maxtime),perturb_v(mintime:maxtime),relh(mintime:maxtime),ytres,relhres)
;            plotw = gsn_csm_xy2(wks,flight_time_minu(mintime:maxtime),perturb_w(mintime:maxtime),relh(mintime:maxtime),ytresw,relhres)
           
            ;Overlay colored lines
            nlines     = floattointeger(ceil((maxtime-mintime)/timestep_color))
            plotcolors = new(nlines,"string")
            dum1       = new(nlines,"graphic")
            dum2       = new(nlines,"graphic")
            dum3       = new(nlines,"graphic")
            dum4       = new(nlines,"graphic")
            do linenum = 0,nlines-1
               plotcolors = colorlist(linenum)   
               mintimeplot = floattointeger(mintime+(timestep_color*linenum))
               maxtimeplot = floattointeger(mintime+(timestep_color*(linenum+1)))
               polyres = True
               polyres@gsLineThicknessF = 2.
               polyres@gsLineColor = plotcolors(linenum)
               if(any(.not.ismissing(perturb_u(mintimeplot:maxtimeplot))))then
                  dum1(linenum) = gsn_add_polyline(wks,plotu,flight_time_minu(mintimeplot:maxtimeplot),perturb_u(mintimeplot:maxtimeplot),polyres)
               if(any(.not.ismissing(perturb_v(mintimeplot:maxtimeplot))))then
                  dum2(linenum) = gsn_add_polyline(wks,plotv,flight_time_minu(mintimeplot:maxtimeplot),perturb_v(mintimeplot:maxtimeplot),polyres)
               if(any(.not.ismissing(perturb_w(mintimeplot:maxtimeplot))))then
                  dum3(linenum) = gsn_add_polyline(wks,plotw,flight_time_minu(mintimeplot:maxtimeplot),perturb_w(mintimeplot:maxtimeplot),polyres)
               if(any(.not.ismissing(vert_accel(mintimeplot:maxtimeplot))))then
                  dum3(linenum) = gsn_add_polyline(wks,plotaccel,flight_time_minu(mintimeplot:maxtimeplot),vert_accel(mintimeplot:maxtimeplot),polyres)
                  dum4(linenum) = gsn_add_polyline(wks,plot_accel_smth,flight_time_minu(mintimeplot:maxtimeplot),perturb_accel(mintimeplot:maxtimeplot),polyres)
               end if
               end if
               end if
               end if
            end do
            draw(plotaccel)
;            draw(plot_accel_smth)
;            frame(wks)
            frame(wks)
         end if
;TODO: Delete below

;--------------------------------------------------------------------------------------------------;

         if(plotopt.eq.1)then    ;Plot vertical velocity variance
            ;-------------;
            ;Calculate TKE;
            ;-------------;
            perturb_u_squared = perturb_u*perturb_u
            perturb_v_squared = perturb_v*perturb_v 
            perturb_w_squared = perturb_w*perturb_w

;BELOW IF TURBULENCE KINETIC ENERGY...WILL CALCULATE VARIANCE INSTEAD         
            avg_perturb_u_squared = runave_Wrap(perturb_u_squared,averaging_time,0)
            avg_perturb_v_squared = runave_Wrap(perturb_v_squared,averaging_time,0)
            avg_perturb_w_squared = runave_Wrap(perturb_w_squared,averaging_time,0)
         
            tke = 0.5*(avg_perturb_u_squared + avg_perturb_v_squared + avg_perturb_w_squared)
            w_variance = avg_perturb_w_squared
                    
            ;--------------;
            ;Make TKE plots;
            ;--------------;
            filename = sprinti("%0.5i",mintime)+"-"+sprinti("%0.5i",maxtime)+"_"+averaging_time+"s.png"
            wks = gsn_open_wks("png","variance.png")
      
            ;Set some resources for TKE plot
            ytres = True 
            ytres@tiXAxisString = "Flight time (minutes)"
            ytres@tiYAxisString = "w'~S~2~N~ (m~S~2~N~s~S~-2~N~)" 
            ytres@trXMinF = mintime/60.
            ytres@trXMaxF = maxtime/60.
            ytres@trYMinF = 0
            ytres@trYMaxF = 30
            ytres@xyLineThicknessF = 2.
            ytres@gsnMaximize = False
            ytres@gsnDraw = False      ;Set to False so we can plot multi-colored lines
            ytres@gsnFrame = False
            plottke = gsn_csm_xy(wks,flight_time_minu(mintime:maxtime),w_variance(mintime:maxtime),ytres)
         
            ;Overlay colored lines
            nlines     = floattointeger(ceil((maxtime-mintime)/timestep_color))
            plotcolors = new(nlines,"string")
            dum1       = new(nlines,"graphic")
            do linenum = 0,nlines-1
               plotcolors = colorlist(linenum)
               mintimeplot = floattointeger(mintime+(timestep_color*linenum))
               maxtimeplot = floattointeger(mintime+(timestep_color*(linenum+1)))
               polyres = True
               polyres@gsLineThicknessF = 2.
               polyres@gsLineColor = plotcolors(linenum)
               if(any(.not.ismissing(w_variance(mintimeplot:maxtimeplot))))then
                  dum1(linenum) = gsn_add_polyline(wks,plottke,flight_time_minu(mintimeplot:maxtimeplot),w_variance(mintimeplot:maxtimeplot),polyres)
               end if
            end do
            draw(plottke)
            frame(wks)
         end if
      
         ;-----------------------------------------------;
         ;Plot satellite image with flight track overlaid;
         ;-----------------------------------------------;
            ;----------------------------------------------------------;
            ;Get area file closest to leg time and convert it to NetCDF;
            ;----------------------------------------------------------;
            ;Get satellite image file that most closely matchest the flight time
            satfiles = systemfunc("ls "+satpath+"*BAND_04")
            satyear = stringtoint(systemfunc("ls "+satpath+"*BAND_04 | cut -d '.' -f2"))
            dayofyear = stringtoint(systemfunc("ls "+satpath+"*BAND_04 | cut -d '.' -f3"))
            sathour = stringtoint(systemfunc("ls "+satpath+"*BAND_04 | cut -d '.' -f4 | cut -c 1-2"))
            satminu = stringtoint(systemfunc("ls "+satpath+"*BAND_04 | cut -d '.' -f4 | cut -c 3-4"))
            satsecond = new(dimsizes(satminu),"integer")
            satsecond = 0
            monday = monthday(satyear,dayofyear)
            monday_string = sprinti("%0.4i",monday)
            asciiwrite("monday.tmp",monday_string)
            satmon = stringtoint(systemfunc("cat monday.tmp | cut -c 1-2"))
            satday = stringtoint(systemfunc("cat monday.tmp | cut -c 3-4"))
            units = "seconds since 1970-01-01 00:00:00"
            total_sattime = cd_inv_calendar(satyear,satmon,satday,sathour,satminu,satsecond,units,0)
            satfile = satfiles(minind(abs(total_center_time-total_sattime)))
            satdatetime = sprinti("%0.2i",satmon)+"/"+sprinti("%0.2i",satday)+"/"+sprinti("%0.4i",satyear)+" "+\
                          sprinti("%0.2i",sathour)+":"+sprinti("%0.2i",satminu)
            system("\rm monday.tmp")
         
            ;Copy satellite file to PWD and convert to netCDF
            system("cp "+satfile+" ./area_tmp")
            system("java -cp /jm13/pduran/java/AreaToNetCDF.jar AreaToNetCDF ./area_tmp* netcdf_tmp.nc -CBRIT")
         
            ;Load netCDF file
            f = addfile("netcdf_tmp.nc","r")
         
            ;Get data from netCDF file
            ir = f->image(0,:,:)    ;float
            latitude = f->lats      ;float
            longitude = f->lons     ;float
            yyddd = f->image_date   ;int
            hhmmss = f->image_time  ;int
            sat = f->sensor_ID      ;char   
      
            ;Give lat and lon units
            latitude@units="degrees_north"
            longitude@units="degrees_east"
         
            ;Define plot boundaries
;TODO: CHANGE THIS BACK
;            minlat = centerlat - 2.5
;            maxlat = centerlat + 2.5
;            minlon = centerlon - 3.5
;            maxlon = centerlon + 3.5
centerlat = 15.2
centerlon = -72.8
minlat = centerlat - 7
maxlat = centerlat + 12
minlon = centerlon - 9
maxlon = centerlon + 12
;            if(plotopt.eq.1)then      
               wks3 = gsn_open_wks("png",basefilename+"planview")
;            end if
            setvalues NhlGetWorkspaceObjectId()
               "wsMaximumSize": 500000000      ;Increase workspace size
            end setvalues                      ;to fit whole IR image
            planres = True
;            planres@gsnLeftString = "IR Image Time: "+satdatetime(minind(abs(total_center_time-total_sattime)))
;            planres@gsnRightString = "Min alt: "+min_alt+"km  Max alt: "+max_alt+"km"
planres@gsnRightString = " "
planres@gsnLeftString = " "
            planres@gsnStringFontHeightF = 0.015
            planres@gsnAddCyclic = False   ;File already has a cyclic point
            planres@sfXArray = longitude
            planres@sfYArray = latitude
            planres@cnFillOn = True             ;Color fill
            planres@cnFillMode = "RasterFill"   ;Raster mode
            planres@cnLinesOn = False           ;Turn off contours
            planres@cnLevelSelectionMode = "ManualLevels"
            planres@cnMinLevelValF      = 0.
            planres@cnMaxLevelValF      = 220.
            planres@cnLevelSpacingF = 2.0       ;Contour interval
         
            planres@mpMinLatF = minlat
            planres@mpMaxLatF = maxlat
            planres@mpMinLonF = minlon
            planres@mpMaxLonF = maxlon
            planres@mpFillOn = False                   ;Turn off gray fill for continents
            planres@mpOutlineBoundarySets = "GeophysicalAndUSStates" ;Plot nation & states
            planres@mpGeophysicalLineThicknessF = 1.5  ;Increase map outline thickness
            planres@mpGeophysicalLineColor = "Black"
            planres@mpUSStateLineThicknessF = 1.5
            planres@mpUSStateLineColor = "Black"
;TODO: SET GSNMAXIMIZE BACK TO FALSE FOR PANELING
;            planres@gsnMaximize = True
            planres@gsnPaperOrientation = "landscape"
            planres@lbLabelBarOn = False
            planres@cnLineLabelsOn = False
            planres@tfPolyDrawOrder = "Draw"
         
            planres@gsnDraw  = False              ;So we can overlay PIREPs later
            planres@gsnFrame = False
         
            ;Define color map
            colors = (/ (/255,255,255/), (/0,0,0/), (/0,0,0/), (/0,0,0/), (/0,0,0/), \
                        (/0,0,0/), (/0,0,0/), (/0,0,0/), (/0,0,0/), (/0,0,0/), \
                        (/8,8,8/), (/20,20,20/), (/28,28,28/), (/40,40,40/), \
                        (/52,52,52/), (/60,60,60/), (/72,72,72/), (/84,84,84/), \
                        (/92,92,92/), (/104,104,104/), (/112,112,112/), \
                        (/124,124,124/), (/136,136,136/), (/144,144,144/), \
                        (/156,156,156/), (/168,168,168/), (/176,176,176/), \
                        (/188,188,188/), (/196,196,196/), (/208,208,208/), \
         	       (/220,220,220/), (/228,228,228/), (/240,240,240/), \
                        (/252,252,252/), (/0,156,243/), (/0,152,236/), \
                        (/0,148,230/), (/0,140,212/), (/0,137,209/), \
                        (/0,132,199/), (/0,128,193/), (/0,124,184/), \
                        (/1,122,177/), (/160,160,0/), (/188,188,0/), \
                        (/220,220,0/), (/248,248,0/), (/252,179,0/), \
                        (/232,160,0/), (/216,141,0/), (/196,120,0/), \
                        (/255,0,0/), (/255,255,255/) /) * 1.0 ;Make them float
            colors = colors/255 ;Normalize so NCL won't freak out and plot black screen
            gsn_define_colormap(wks3, colors)
      
            sat_img = gsn_csm_contour_map_ce(wks3,ir(:,:),planres)
            delete(colors)
            ;----------------------------------------------------------------------------;
            ;Now we're going to add several lines, each a different color, to the plot.  ;
            ;The colors here will correspond to the colors in the perturbation plots so  ;
            ;that it may be easily seen where each section of the perturbation plot falls;
            ;along the airplane track.                                                   ;
            ;----------------------------------------------------------------------------;
         
            linenum  = 0
            ;linelats = new(2,"float")
            ;linelons = new(2,"float")
            dum      = new(nlines,"graphic")
            do while(linenum.lt.nlines)
               plotcolors(linenum)  = colorlist(linenum)
               ;minlat = lat(floattointeger(mintime+(timestep_color*linenum)))
               ;maxlat = lat(floattointeger(mintime+(timestep_color*(linenum+1))))
               ;minlon = lon(floattointeger(mintime+(timestep_color*linenum)))
               ;maxlon = lon(floattointeger(mintime+(timestep_color*(linenum+1))))
         
               linelats = lat((floattointeger(mintime+(timestep_color*linenum))):(floattointeger(mintime+(timestep_color*(linenum+1)))))
               linelons = lon((floattointeger(mintime+(timestep_color*linenum))):(floattointeger(mintime+(timestep_color*(linenum+1)))))
         
               polyres = True
               polyres@gsLineThicknessF = 10.
               polyres@gsLineColor = plotcolors(linenum)
               dum(linenum) = gsn_add_polyline(wks3,sat_img,linelons,linelats,polyres)
               linenum = linenum + 1 
               delete(linelats)
               delete(linelons)
            end do

            ;--------------------------------------------;
            ;Add asterisk to indicate start of flight leg;
            ;--------------------------------------------;
            texres = True
            texres@txFontColor = "black"
;            txarray = (/"*","(a)"/)
;            txlons = (/lon(mintime),
            text = gsn_add_text(wks3,sat_img,"*",lon(mintime),lat(mintime),texres)
            

;TODO: DELETE BELOW
;exit      
            if(plotopt.eq.1)then
               draw(sat_img)
               frame(wks3)
            end if
         
            ;---------------------------------------------------------;
            ;Tack on the altitudes at the beginning and end of the leg;
            ;---------------------------------------------------------;
            ;Put this in the w' frame instead...
            ;textres = True
            ;textres@txFontHeightF = .02
            ;dum4 = gsn_add_text(wks,sat_img,init_alt,lon(mintime),lat(mintime),textres)
            ;dun5 = gsn_add_text(wks,sat_img,final_alt,lon(maxtime),lat(maxtime),textres)   
      
;         if(plotopt.eq.0)then   
;            panel_res = True
;            panel_res@gsnMaximize = True
;            panel_res@gsnPanelFigureStrings = labelstring
;            panel_res@amJust = "TopLeft"
;            gsn_panel(wks,(/sat_img,plotu,plotv,plotw/),(/2,2/),panel_res)
;         else if(plotopt.eq.1)then
        ;    panel_res = True
        ;    panel_res@gsnMaximize = True
        ;    panel_res@gsnPanelFigureStrings = (/"","TKE"/)
        ;    panel_res@amJust = "TopLeft"
        ;    panel_res@gsnPanelScalePlotIndex = 1
        ;    gsn_panel(wks,(/sat_img,plottke/),(/1,2/),panel_res)
;         system("montage -geometry 800x800 -trim planview.png variance.png "+filename)
;         end if
;         end if
      
      delete(plotcolors)
      delete(dum1)
      delete(dum)
;      delete(sat_img)
;      delete(wks)
      end do
   end do

draw(plotaccel)
frame(wks)
draw(sat_img)
frame(wks3)

   delete([/flightdata,vert_accel,w,u,v,tmpc,dwpc,relh,theta,thetae,lat,lon,alt,groundspeed,airspeed,base_time,\
            flight_time,time_sec,flight_time_minu,thetac,u_smth,v_smth,w_smth,theta_smth,relh_smth,perturb_u,\
            perturb_v,perturb_w,perturb_theta,actual_dattim,time_min,altkm/])
   if(plotopt.eq.1)then
      delete([/perturb_u_squared,perturb_v_squared,perturb_w_squared,avg_perturb_u_squared,avg_perturb_v_squared,\
               avg_perturb_w_squared,tke/])
   end if
end do
