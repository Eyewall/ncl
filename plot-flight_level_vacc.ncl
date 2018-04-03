load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/home/djv/NCL/djv_lib/dv_pltlibs.ncl"

external GMT2LST "/home/djv/NCL/fortran/gmt2lst_clc.so"
;-----------------------------------------------------------------; 
;plot-flight_level_vacc.ncl
; djv 11/16
; This program is based on a NCL program written by Patrick Duran
; and is stripped down and modified to plot vertical acceleration
; and altitude from G-IV flightlevel data.

; Will read in a netCDF file created by   GIV-fltlev-distsubset-create.ncl 
; containing 1-Hz flight-level aircraft data(TIME,ALT,VACCEL,DIST).
; Will plot a 2-panel figure of the flight track over an IR satellite image 
; and a timeseries of  altitude and vertical acceleration. The flight track 
; and acceleration trace are color coded for easy comparison. The time step 
; of the color change can be modified in the PARAMETERS section. Script will
; only create plots if a minimum  altitude/distance criterion are met(see User 
; PARAMETERS)
;
; Updates
; 11/16: Can read McIDAS files in either AREA or NetCDF fmt.

; This program will generate individual plots for each NetCDF file in a dir.
; Can plot 2panel plots or individual plots
; Can plot out a storm center onto IR plan plot
; Can plot out track/accel for a user-def radial range
; Will calc local siderial time wrt hurrcen loc/imgtime and put on plot

; ncl rad1=0 rad2=500 ncflag='"False"' out_type='"png"' plot-flight_level_vacc.ncl
;-----------------------------------------------------------------;
; For converted AREA files:
; IR brightness values are in signed byte fmt(-128 to 127). Can neg brightness 
; values to positive by adding 256 to make continuous
; res1@cnMinLevelValF      = 191.
; res1@cnMaxLevelValF      = 240.        ; shade 241 brightness levs inc=1
; ir0 = byte2flt(ir) 
; ir0 = where(ir0.lt.0,ir0+256,ir0)
; sets all ir0 values to missing if not in contour range
; ir0 = where(ir0.lt.res1@cnMinLevelValF.or.ir0.gt.res1@cnMaxLevelValF,ir@_FillValue,ir0)
;
; For NOAA/CLASS NetCDF files:
; Use function  GVAR2brit(Gnum-8,stringtoint(band),ir0,resIR)
; Make sure that input file is in format: goes12.2004.250.1945.BAND_04 to get
; proper satellite number
; --------------------------------------------------------------    

begin
;----------------;
;DATA DIRECTORIES;
;----------------;
;Set the center track and intensity files and McIdas area file path
 trkfile = "/jm13/djv/GIV_outflow/tracks/2004/gdtrk04aI01-1min-000.dat"
 datapath = "/jm13/djv/flightlevel_data/GIV/2004/I/sub/"
 satpath  = "/jm13/djv/ivan04/mcidas/merc/"
 satpath_nc  = "/molinarilab_rit/McIDAS/"
 color_table = "djv_sat_ir15a"



  if (ncflag.eq."True") then
    satpath = satpath_nc
  end if

 res = True
 resplan = True
 resMark = True
 parm = True
;------------------ User PARAMETERS -----------------------------
  res@lbLabelBarOn   = True    ;Turn on/off color label bar
  lb_txtthk = 2.0              ;labtxt thickness
  lb_txtsiz = .015             ;labtxt size
  lbtit_siz = .02              ;lab title size
  lbtit_thk = 3.0              ;lab title thickness

  parm@pltcen = True           ;plot center
  trk_1min     = True          ;6h or 1min trackfile
  stmcen_col = "Black"         ;color of stormcen symbol
  marker = new((/1/),graphic)

;  out_type =  "X11"            ;X11,ps,png
  storm = "Ivan"               ;storm name

  pltvar = "VACCEL"       ;plot var chc(RH or VACCEL 
  panel = 1              ;Set to "1" for 2panel plot 0 for individual plots
  minalt = 12000          ;The min altitude to plot the data(m)
  altoff = 5000           ;offset from minalt(m) so as to not interfere w/freq plt
  timestep_color = 1200.  ;The time (s) between each change in line color


;------------------ End User PARAMETERS -------------------------   

  colorlist = (/"black","purple","red","blue","sienna","darkgreen","black","purple","red","blue","sienna","darkgreen",\
           "black","purple","red","blue","sienna","darkgreen","black","purple","red","blue","sienna","darkgreen",\
           "black","purple","red","blue","sienna","darkgreen","black","purple","red","blue","sienna","darkgreen",\
           "black","purple","red","blue","sienna","darkgreen","black","purple","red","blue","sienna","darkgreen",\
           "black","purple","red","blue","sienna","darkgreen","black","purple","red","blue","sienna","darkgreen",\
           "black","purple","red","blue","sienna","darkgreen","black","purple","red","blue","sienna","darkgreen"/)


;------------------------------------------------------------------------;
;Loop through all of the netCDF files
;------------------------------------------------------------------------;
 ncdf_files = systemfunc("ls "+datapath+"*.cdf")
 numfiles   = dimsizes(ncdf_files) 
 print(numfiles)
 do b=0,numfiles-1
  flightnum = sprinti("%0.2i",(b+1))   ;Each netCDF file = one recon flight
  datafile = ncdf_files(b)
  print(datafile) 
;     Get flight level data;
;-----------------------------------------------
  flightdata  = addfile(datafile,"r")
  vert_accel  = flightdata->ACINS_PITR   ;Aircraft vertical acceleration
  lat         = flightdata->GPLAT        ;Latitude
  lon         = flightdata->GPLON        ;Longitude
  alt         = flightdata->GPALT        ;Altitude
  dist        = flightdata->distance     ;Dist from center
  altkm = alt/1000                       ;Convert altitude to km

;  lon = where(dist.ge.rad1.and.dist.le.rad2, lon, lon@_FillValue)
  lat = where(dist.ge.rad1.and.dist.le.rad2, lat, lat@_FillValue)
  altkm = where(dist.ge.rad1.and.dist.le.rad2, altkm, altkm@_FillValue)
  vert_accel = where(dist.ge.rad1.and.dist.le.rad2, vert_accel, vert_accel@_FillValue)

; Time parameters
;-----------------------------------------------
  base_time   = flightdata->base_time    ;Base time (Seconds since Jan 1, 1970)
  flight_time = flightdata->time_offset  ;Time since base_time (s)
  time_sec = new(dimsizes(flight_time),"double")
  time_sec    = base_time + flight_time  ;Obs times (Seconds since Jan 1, 1970)
  flight_time_minu = flight_time/60      ;Convert flght tims to mins for pltting

  if (all(ismissing(ind(alt.gt.minalt)))) then
   print("All obs below "+minalt+" stop program")
   exit
  end if
  print(max(flight_time(ind(alt.gt.minalt))))

;-----------------------------------------------------;      
;  RUNNING AVERAGE LOOP
;Smooth the vars with a running mean 
;-----------------------------------------------------;      
  do a = 0,10,100            ; create 2 plots raw,10sec runavg
   averaging_time = a    ;The nsec over which the running average is performed
   accel_smth = runave_Wrap(vert_accel,averaging_time,0)

; find time range where plane exceeds user-def  min altitude
   alt_ind = ind(alt.gt.minalt)   ;array of indices where alt>minalt
   starttime = floattoint(flight_time(min(alt_ind)))
   endtime = floattoint(flight_time(max(alt_ind)))
   time_range = endtime - starttime

   ntimes = floor((endtime-starttime)/time_range) ;floor gets intval just below
   mintime = starttime
   maxtime = starttime + time_range

;Loop over the whole flight time to plot images;
;----------------------------------------------;
   do index=0,ntimes-1

;Get base time in recongnizable format using cd_calendar(YYYY,MM,DD,HH,MM,SS)
;-------------------------------------;
    base_time@units = "seconds since 1970-1-1 00:00:0.0"
    base_dattim = cd_calendar(base_time,0)   ;Base date/tim 2-D array:[nobs x 6] 
    center_time = maxtime - (time_range / 2) ;Temporal center of flight leg [s since base_time]
    total_center_time = base_time + center_time ;Temporal center of flight leg [seconds since 1/1/1970]

;Get base time array for all observations;
;----------------------------------------;
    time_sec@units = "seconds since 1970-1-1 00:00:0.0"
    actual_dattim = floattoint(cd_calendar(time_sec,0))  ;Date/time of each individual observation 2-D array: [nobs x 6]
    time_min = time_sec / 60.                ;Convert seconds to minutes


    alt_ind = ind(alt.gt.minalt)
;-----------------------------------------;
;LAT,LON ranges of flight above minalt
;-----------------------------------------;
     minlat0 =min(lat(min(alt_ind):max(alt_ind)))
     maxlat0 =max(lat(min(alt_ind):max(alt_ind)))
     minlon0 =min(lon(min(alt_ind):max(alt_ind)))
     maxlon0 =max(lon(min(alt_ind):max(alt_ind)))

     centerdattim = sprinti("%0.2i",actual_dattim(center_time,1))+"/"+sprinti("%0.2i",actual_dattim(center_time,2))+"/"+\
                   sprinti("%0.4i",actual_dattim(center_time,0))+" "+sprinti("%0.2i",actual_dattim(center_time,3))+":"+\
                   sprinti("%0.2i",actual_dattim(center_time,4))+":"+sprinti("%0.2i",actual_dattim(center_time,5))+" UTC"
      
   ;---------------------------------------------------;
   ;Get initial and final altitudes for this flight leg;
   ;---------------------------------------------------;
     init_alt = sprintf("%5.2f",altkm(mintime))+"km"
     final_alt = sprintf("%5.2f",altkm(maxtime))+"km"
     min_alt = sprintf("%5.2f",min(altkm(mintime:maxtime)))
     min_alt1 = sprintf("%5.2f",min(altkm(mintime:maxtime))-altoff/1000)
     max_alt = sprintf("%5.2f",ceil(max(altkm(mintime:maxtime))) )

     minute_range =sprinti("%0.2i",actual_dattim(min(alt_ind),3))+sprinti("%0.2i",actual_dattim(min(alt_ind),4))+\
                    "_"+sprinti("%0.2i",actual_dattim(max(alt_ind),3))+sprinti("%0.2i",actual_dattim(max(alt_ind),4))

;   Generate output file name
; ------------------------------------------------------
     basefilename = storm+sprinti("%0.4i",actual_dattim(min(alt_ind),0))+"-"+sprinti("%0.2i",actual_dattim(min(alt_ind),1))+sprinti("%0.2i",actual_dattim(min(alt_ind),2))+minute_range+"UTC_"+minalt/1000+"km"+"_flt"+flightnum


  ;----------------------------;
  ;Make var vs. time plots;
  ;----------------------------; 
     filename = basefilename+"_"+pltvar+"-R"+rad1+"_"+rad2+"km"
     if (a.gt.0) then
      filename = basefilename+"_"+pltvar+"_ravg"+a+"s"
     end if
     print(filename)

;Set some resources for xy plots 
     ytres = True              ;Resources for timeseries plots
     ytres@tiXAxisString = "Flight time (minutes)"
     ytres@trXMinF    = mintime/60.
     ytres@trXMaxF    = maxtime/60.
     ytres@xyLineThicknessF = 2.
     ytres@gsnMaximize = False
     ytres@gsnDraw     = False     ;Set to False so can plot multi-colored lines
     ytres@gsnFrame    = False
     ytres@tiYAxisOn   = True   
     if(panel.eq.1) then   ;Create panel plot
      ytres@vpXF       = 0.13  ;controls the size+loc of the plot in vwport
      ytres@vpWidthF   = 0.75	    
      ytres@vpYF       = 0.35  ;offset from bot
      ytres@vpHeightF  = 0.25   
      filename = filename+"_2pan"
     else
      ytres@gsnLeftString = "Flight time (center of leg): "+centerdattim+"  Ravg time: "+averaging_time+"s" 
      ytres@gsnLeftStringFontHeightF = .015
     end if
       
; Set plt resources for vert accel
     ytresa = ytres
     ytresa@trYMinF = -2
     ytresa@trYMaxF = 2
     ytresa@tiYAxisString = "Vertical acceleration (ms~S~-2~N~)"
     ytresa@tmXTOn  = False
     ytresa@tmYROn  = False
;     ytresa@xyCurveDrawOrder = "PreDraw"
     ytresa@xyLineColor = -1           ;Set=Transparent so polyline colors work

; Set plt resources for altitude
     altres = ytres
     altres@xyLineThicknesses = 3
     altres@trYMinF = min_alt1
     altres@trYMaxF = max_alt
     altres@tiYAxisString = "Altitude (km)"
     altres@gsnLeftString = " "
     print(min_alt1+" "+max_alt+" "+altkm(100))
     altres@tmXTOn  = False
     altres@tmYLOn  = False
     wks = gsn_open_wks(out_type,filename)
     if (pltvar.eq."VACCEL") then
;     plotaccel = gsn_csm_xy(wks,flight_time_minu(mintime:maxtime),accel_smth(mintime:maxtime),ytresa)
       plotaccel = gsn_csm_xy2(wks,flight_time_minu(mintime:maxtime),accel_smth(mintime:maxtime),altkm(mintime:maxtime),ytresa,altres)
     end if

;----------------------------------------------
;   Overlay colored lines
;----------------------------------------------
     nlines     = floattointeger(ceil((maxtime-mintime)/timestep_color))
     print(ntimes+" "+time_range+" "+starttime+" "+endtime)
     print(base_dattim)
     print(" "+center_time+" "+total_center_time+" "+dimsizes(flight_time))
     print(maxtime+" "+mintime)

     plotcolors = new(nlines,"string")

     dum2       = new(nlines,"graphic")
     polyres = True
     polyres@gsLineThicknessF = 2.

     do linenum = 0,nlines-1
      dumstr       = unique_string("line")
      plotcolors = colorlist(linenum)   
      seg_strt = floattointeger(mintime+(timestep_color*linenum))
      seg_end  = floattointeger(mintime+(timestep_color*(linenum+1)))
      if (linenum.eq.nlines-1) then
       seg_end  = maxtime
      end if

      polyres@gsLineColor = plotcolors(linenum)
      print(linenum+" "+seg_strt+" "+seg_end+" "+polyres@gsLineColor+" "+dumstr)
      if (pltvar.eq."VACCEL") then
       if(any(.not.ismissing(accel_smth(seg_strt:seg_end))))then
         plotaccel@$dumstr$ = gsn_add_polyline(wks,plotaccel,flight_time_minu(seg_strt:seg_end),accel_smth(seg_strt:seg_end),polyres)
       end if
      end if
     end do          ;end linenum loop color overlay 

     if (pltvar.eq."VACCEL") then
      draw(plotaccel)
     end if
 
     if(panel.eq.0) then   ;Create individual plot
      frame(wks)
     end if

;--------------------------------------------------------------------------
         ;Plot satellite image with flight track overlaid;
;--------------------------------------------------------------------------

;----------------------------------------------------------;
; Get area file closest to center leg time and convert it to NetCDF
; fimename fmt = goes12.2004.253.1745.BAND_04
; convert from julian day to gregorian to match flight times
;----------------------------------------------------------;
     satfiles = systemfunc("ls "+satpath+"*BAND_04*")
     satyear = stringtoint(systemfunc("ls "+satpath+"*BAND_04* | cut -d '.' -f2"))
     dayofyear = stringtoint(systemfunc("ls "+satpath+"*BAND_04* | cut -d '.' -f3"))
     sathour = stringtoint(systemfunc("ls "+satpath+"*BAND_04* | cut -d '.' -f4 | cut -c 1-2"))
     satminu = stringtoint(systemfunc("ls "+satpath+"*BAND_04* | cut -d '.' -f4 | cut -c 3-4"))
     satsecond = new(dimsizes(satminu),"integer")
     satsecond = 0
     monday = monthday(satyear,dayofyear)
     monday_string = sprinti("%0.4i",monday)
     asciiwrite("monday.tmp",monday_string)
     satmon = stringtoint(systemfunc("cat monday.tmp | cut -c 1-2"))
     satday = stringtoint(systemfunc("cat monday.tmp | cut -c 3-4"))

     units = "seconds since 1970-01-01 00:00:00"
     total_sattime = cd_inv_calendar(satyear,satmon,satday,sathour,satminu,satsecond,units,0)
     sat_index = minind(abs(total_center_time-total_sattime))
     satfile = satfiles(sat_index)
     satdatetime = sprinti("%0.2i",satmon)+"/"+sprinti("%0.2i",satday)+"/"+sprinti("%0.4i",satyear)+" "+\
     sprinti("%0.2i",sathour)+":"+sprinti("%0.2i",satminu)
     system("\rm monday.tmp")
     print(satfile)

;------------------------------------------------------------------------
; Satellite image must be witthin flight max/min times to plot out
;------------------------------------------------------------------------
     satmmddhh = sprinti("%0.2i",satmon)+sprinti("%0.2i",satday)+sprinti("%0.2i",sathour)
     xday0 = sprinti("%0.2i",actual_dattim(min(alt_ind),1))+sprinti("%0.2i",actual_dattim(min(alt_ind),2))+sprinti("%0.2i",actual_dattim(min(alt_ind),3))
     xday1 = sprinti("%0.2i",actual_dattim(max(alt_ind),1))+sprinti("%0.2i",actual_dattim(max(alt_ind),2))+sprinti("%0.2i",actual_dattim(max(alt_ind),3))

     if ((satmmddhh(sat_index).ge.xday0).and.(satmmddhh(sat_index).le.xday1)) then

; ######### Read IR data and plot satellite image #################
;Copy satellite file to PWD and convert to netCDF if 1st time thru
      if (a.eq.0) then
       if (ncflag.eq.True) then
        print("PROCESSING NOAA/CLASS NetCDF")
        pathlen = strlen(satpath)
        ncfile = satfile
;  Get data from netCDF file
; --------------------------------------------------------------
        f = addfile(ncfile,"r")
        ir0 = f->data(0,:,:)          ;float
        latitude = f->lat             ;float
        longitude = f->lon            ;float
        yyddd = f->imageDate          ;int
        hhmmss = f->imageTime         ;int
        sat = f->sensorID             ;int
        band = f->bands               ;int
        xres = f->elemRes             ;int
        yres = f->lineRes             ;int
        maxir = max(ir0)
        minir = min(ir0)
        resIR  = True
        print(band)
        Gnum = stringtoint(str_get_cols(satfile,strlen(satpath)+4,strlen(satpath)+5))  ;get goes number from filenam
        print(Gnum)
        ir = GVAR2brit(Gnum-8,stringtoint(band),ir0,resIR)  ;convert GVAR to brit

  else

        print(" Convert AREA to NetCDF")
        system("cp "+satfile+" /jm13/djv/area_tmp")
        system("java -cp /jm13/djv/java/AreaToNetCDF.jar AreaToNetCDF /jm13/djv/area_tmp* /jm13/djv/netcdf_tmp.nc -CBRIT")

        ncfile = "/jm13/djv/netcdf_tmp.nc"
;  Get data from netCDF file
; --------------------------------------------------------------
        f = addfile(ncfile,"r")
        ir = f->image(0,:,:)           ;float
        latitude = f->lats             ;float
        longitude = f->lons            ;float
        yyddd = f->image_date          ;int
        hhmmss = f->image_time         ;int
        sat = f->sensor_ID             ;char
        xres = f->elem_resolution      ;int
        yres = f->line_resolution      ;int
        ir0 = ir
        maxir = max(ir0)
        minir = min(ir0)
       end if

      end if         ;end 1st time 
      print("here")
      irdims = dimsizes(ir)
      nline = irdims(0)
      nelem = irdims(1)
      print(irdims)
;Create Named dimensions and coord vars for IR
; Do not need to create sfXArrays/sfYArrays
; ie res@sfXArray = longitude(minlat_ind:maxlat_ind,minlon_ind:maxlon_ind)
; --------------------------------------------------------------
      latitude@units="degrees_north"
      latitude@_FillValue = 2.143289e+09
      longitude@units="degrees_east"
      longitude@_FillValue = 2.143289e+09
      ir!0 = "latitude"
      ir!1 = "longitude"
      ir&latitude = latitude(:,nelem/2)
      ir&longitude = longitude(nline/2,:)

      j1 = ind_nearest_coord(11.24,latitude(:,0),0)
      i1 = ind_nearest_coord(-55.32,longitude(j1,:),0)
      ir&latitude = latitude(:,i1)
      ir&longitude = longitude(j1,:)


      ir0!0 = "latitude"
      ir0!1 = "longitude"
      ir0&latitude = latitude(:,nelem/2)
      ir0&longitude = longitude(nline/2,:)
;      print(ir&longitude)
      print("IR STATS min/max="+min(ir)+" "+max(ir)+" latrng="+min(latitude)+" "+max(latitude)+" lonrng="+min(longitude)+" "+max(longitude)+" XYres="+xres+" "+yres)
      print("CCC "+ir0({11.24},{-55.32})+" "+ir({11.24},{-55.32}))


   
         
;      Define plot boundaries by edges of flighttimes
;----------------------------------------------------------;
      minlat = floor(minlat0) - 1.
      maxlat = ceil(maxlat0) + 1.
      minlon = floor(minlon0) -1.
      maxlon = ceil(maxlon0) +1.
      dy = floattointeger(floor(abs(maxlat-minlat)))
      dx = floattointeger(floor(abs(minlon-maxlon)))
      cenlon = (maxlon+minlon)/2
      cenlat = (maxlat+minlat)/2
;&&
      j1 = ind_nearest_coord(cenlat,latitude(:,0),0)
      i1 = ind_nearest_coord(cenlon,longitude(j1,:),0)
      ir&latitude = latitude(:,i1)
      ir&longitude = longitude(j1,:)
      print("mapcen="+maxir+" "+minir+" "+i1+" "+j1+" "+cenlon+" "+cenlat)
      print("lat0 range="+minlat0+" "+maxlat0+" "+dy)
      print("lon0 range="+minlon0+" "+maxlon0+" "+dx)
      print("lat range="+minlat+" "+maxlat)
      print("lon range="+minlon+" "+maxlon)

      filename_plan = basefilename+"_"+pltvar+"_track"
      if (panel.eq.0) then
       wks = gsn_open_wks(out_type,filename_plan) 
       resplan@vpXF       = 0.12   ;controls the size/loc of plot in vwport
       resplan@vpWidthF   = 0.7	    
       resplan@vpYF       = 0.85
       resplan@vpHeightF  = 0.7
      else
       resplan@vpXF       = 0.1   ;controls the size/loc of plot in vwport
       resplan@vpWidthF   = 0.75	    
       resplan@vpYF       = 0.9
       resplan@vpHeightF  = 0.48
      end if
      setvalues NhlGetWorkspaceObjectId()
       "wsMaximumSize": 500000000      ;Increase workspace size
      end setvalues                      ;to fit whole IR image
      resplan@trGridType = "TriangularMesh"
      resplan@tfDoNDCOverlay = True
      resplan@mpProjection = "Satellite"
;  Set up IR contour parameters
; --------------------------------------------------------------
      resplan@cnFillOn   = True             ;Color fill
      resplan@cnFillMode = "RasterFill"   ;Raster mode best for IR maps
      resplan@cnLinesOn  = False           ;Turn off contours
      resplan@cnLineLabelsOn       = False	   ;Turn off contour labels
       resplan@cnFillDrawOrder           = "Draw"   
      resplan@cnLevelSelectionMode = "ManualLevels"
      resplan@cnMinLevelValF       = 0.
      resplan@cnMaxLevelValF       = 241.
      resplan@cnLevelSpacingF      = 1.0       ;Contour interval
      resplan@gsnSpreadColorStart  = 2
      resplan@gsnSpreadColorEnd    = 240
      resplan@gsnSpreadColors      = True

;  Mapproj info
; --------------------------------------------------------------
     resplan = grab_base_res(resplan)  ;map/grid cols=gray20 
     resplan@mpMinLatF           = minlat  ;set up map area
     resplan@mpMaxLatF           = maxlat
     resplan@mpMinLonF           = minlon
     resplan@mpMaxLonF           = maxlon
     resplan@gsnDraw             = False   ;So we can add poly stuff
     resplan@gsnFrame            = False
     resplan@mpFillOn            = False
     resplan@mpGridAndLimbOn     = True    ; turn on lat/lon lines 
     resplan@gsnMinorLatSpacing  = 2 
     resplan@gsnMinorLonSpacing  = 2
     resplan@mpGridLatSpacingF   = 4       ;lat label spacing def=15 
     resplan@mpGridLonSpacingF   = 4       ;lon label spacing def=15
     if (dx.lt.4.or.dy.lt.4) then
      resplan@gsnMinorLatSpacing = 1
      resplan@gsnMinorLonSpacing = 1
      resplan@mpGridLatSpacingF  = 1
      resplan@mpGridLonSpacingF  = 1
     end if
     resplan@gsnMajorLatSpacing  = dx/2
     resplan@gsnMajorLonSpacing  = dx/2
     resplan@mpGeophysicalLineThicknessF = 3
     resplan@mpGridLineThicknessF        = 2
     resplan@mpGridMaskMode     = "MaskNone" ;Gridmask opt(None;Land;Ocean;FillArea)
     resplan@mpGeophysicalLineColor     = 1
;    resplan@mpOutlineBoundarySets = "GeophysicalAndUSStates" ;Plot nation & states
     resplan@gsnAddCyclic = False

; --------------------------------------------------------------
;Read the trackfile into an array  7cols(hhhh,mmddyy,lat,lon,pres,wspd,stren)
; --------------------------------------------------------------
     if (trk_1min.eq."True") then
      system(" csh /home/djv/NCL/djv_lib/gdtrkrd-1min.sc "+trkfile+"|sed 1,1d >trktmp")
     else
      system(" csh /home/djv/NCL/djv_lib/gdtrkrd.sc "+trkfile+"|sed 1,1d >trktmp")
     end if

;Get track info; ;0600 090605    25.80   -78.60 1009 025 TD
; --------------------------------------------------------------
     hurdata   = asciiread("./trktmp",-1,"string")
     hurdate = str_get_cols(hurdata, 5,10)
     hurhhmm = str_get_cols(hurdata, 0,3)
     hurhr  = stringtoint(str_get_cols(hurdata, 0,1)) 
     hurmin  = stringtoint(str_get_cols(hurdata, 2,3))
     hurmon = stringtoint(str_get_cols(hurdata, 5,6))
     hurday = stringtoint(str_get_cols(hurdata, 7,8))
     huryr  = stringtoint(str_get_cols(hurdata, 9,10))
     hurlat = stringtofloat(str_get_cols(hurdata, 12,19))
     hurlon = stringtofloat(str_get_cols(hurdata, 20,28))
     hurpres = stringtoint(str_get_cols(hurdata, 30,33))
     hurspd = stringtoint(str_get_cols(hurdata, 35,37))
     hurtyp = str_get_cols(hurdata, 39,40)
     nrows  = numAsciiRow("./trktmp")
     print(nrows)
     if (huryr(0).lt.30) then
      huryr = huryr+2000 
     else
      huryr = huryr+1900
     end if
     hurtime =  hurdate+hurhhmm
     satyear =  where (satyear.gt.1999,satyear-2000,satyear-1900)
     sattime = sprinti("%0.2i",satmon)+sprinti("%0.2i",satday)+sprinti("%0.2i",satyear)+sprinti("%0.2i",sathour)+sprinti("%0.2i",satminu)
     hurcen_ind = (ind(stringtoint(hurtime).eq.stringtoint(sattime(sat_index))))
     print(hurcen_ind+" "+hurtime(hurcen_ind)+" "+sattime(sat_index))
; --------------------------------------------------------------

;  Calc local siderial time here(wrt sat_time, not center time
; --------------------------------------------------------------
   lst = new((/1/),"float")
   print(sathour(sat_index))
   xlon = lon(center_time)
 ;  xlon = hurlon(hurcen_ind)
   tmpchar = sprinti("%0.2i",satminu(sat_index))
   GMT2LST::sun_time(int2flt(sathour(sat_index)),stringtoint(tmpchar),xlon,lst) 
   print("GMT "+sathour(sat_index)+" "+stringtoint(tmpchar)+" "+xlon+" "+sat_index+" "+center_time)
   print("LST="+lst+" cntertime="+centerdattim)
   
;   Title and label info 
; --------------------------------------------------------------
     resplan@gsnLeftString = "IR Image Time: "+satdatetime(sat_index)
     resplan@gsnRightString = "Min alt: "+min_alt+"km  Max alt: "+max_alt+"km"
     resplan@gsnStringFontHeightF = 0.01
     resplan@tiMainFontHeightF = 0.025
     resplan@tiMainString = storm+" "+hurdate(hurcen_ind)+"/"+hurhhmm(hurcen_ind)+"UTC "+hurspd(hurcen_ind)+"kt  R="+rad1+"-"+rad2+"km"+" "+floattoint(lst)+"LST"

; Puts IR labelbar onto plot  
; --------------------------------------------------------------
     resplan = create_ir_labbar(lbtit_siz,lbtit_thk,lb_txtsiz,lb_txtthk,resplan)
     resplan@tfPolyDrawOrder = "PostDraw"
     resplan@gsnDraw  = False              ;So we can overlay PIREPs later
     resplan@gsnFrame = False

; Plots the IR image    
     gsn_define_colormap(wks, color_table) 
     
     sat_img = gsn_csm_contour_map_ce(wks,ir(:,:),resplan)
     sat_img@tfPolyDrawOrder = "PreDraw"
;----------------------------------------------------------------------------;
;Now we're going to add several lines, each a different color, to the plot.  ;
;The colors here will correspond to the colors in the perturbation plots so  ;
;that it may be easily seen where each section of the perturbation plot falls;
;along the airplane track.                                                   ;
;----------------------------------------------------------------------------;
     linenum  = 0
     print(maxtime)
     polyres = True
     polyres@gsLineThicknessF = 10.
     dum      = new(nlines,"graphic")
     do while(linenum.lt.nlines)
      dumstr       = unique_string("track")
      seg_strt = floattointeger(mintime+(timestep_color*linenum))
      seg_end  = floattointeger(mintime+(timestep_color*(linenum+1)))
      if (linenum.eq.nlines-1) then
       seg_end  = maxtime
      end if
      plotcolors(linenum)  = colorlist(linenum)
      linelats = lat(seg_strt:seg_end)
      linelons = lon(seg_strt:seg_end)
      polyres@gsLineColor = plotcolors(linenum)
      if (.not.all(ismissing(linelats))) then
       sat_img@$dumstr$ = gsn_add_polyline(wks,sat_img,linelons,linelats,polyres)
       if (linenum.eq.12) then
;     print("dist="+dist(seg_strt:seg_end)+" "+vert_accel(seg_strt:seg_end)+" "+seg_strt+" "+seg_end)

       end if
      end if
       linenum = linenum + 1 
       delete(linelats)
       delete(linelons)
     end do      ;end while loop coloring tracks
;--------------------------------------------;
;Add asterisk to indicate start of flight leg;
;--------------------------------------------;
     texres = True
     texres@txFontColor = "black"
     text = gsn_add_text(wks,sat_img,"*",lon(mintime),lat(mintime),texres)
;  Plot stormloc
; --------------------------------------------------------------
     if (parm@pltcen .eq. "True" ) then
      hsym_siz = 10                ;dx<4=12 ; dx >11=8 else=10
      if (dx.lt.4) then
       hsym_siz = 12
      else if (dx.gt.11) then
       hsym_siz = 8
      end if
      end if
      print("hsym size="+hsym_siz+" "+hurlon(hurcen_ind)+" "+hurlat(hurcen_ind))
      resMark@gsMarkerColor         = stmcen_col
      resMark@gsMarkerIndex         = NhlNewMarker(wks,"8",19,0,0,1,1,0)
      resMark@gsMarkerSizeF         = hsym_siz
      resMark@tfPolyDrawOrder = "PostDraw"  ;for polyline,polymarker,or polygon
      resMark@gsMarkerThicknessF    = 4
      marker = gsn_add_polymarker(wks,sat_img,hurlon(hurcen_ind),hurlat(hurcen_ind),resMark)
     end if
     draw(sat_img)
     delete([/sat_img,dum,ir/])
    else
     resblnk = True
     filename_plan = basefilename+"_"+pltvar+"_track"
     if (panel.eq.0) then 
      wks = gsn_open_wks(out_type,filename_plan) 
      resblnk@vpXF       = 0.12   ;controls the size/loc of plot in vwport
      resblnk@vpWidthF   = 0.7	    
      resblnk@vpYF       = 0.85
      resblnk@vpHeightF  = 0.7
     else
      resblnk@vpXF       = 0.13   ;controls the size/loc of plot in vwport
      resblnk@vpWidthF   = 0.75	    
      resblnk@vpYF       = 0.9
      resblnk@vpHeightF  = 0.28
     end if
     texres = True
     texres@txFontColor = "black"
     resblnk@tmXBMode                = "Explicit"
     resblnk@tmXBLabelFontHeightF    = 0.01    ; Make these labels smaller.
     resblnk@tmXBMajorOutwardLengthF = 0.0     ; Don't draw tickmarks b/c they
     resblnk@tmXBMajorLengthF        = 0.0     ; were drawn on previous plot.
     resblnk@tmXBLabelDeltaF         = 0.6     ; Move label away from tickmarks.
     resblnk@tmYROn = False            ; Turn off right tickmarks.
     resblnk@tmXBOn = False            ; Turn off right tickmarks.
     resblnk@tmXTOn = False            ; Turn off top tickmarks.
     resblnk@tmYLOn = False            ; Turn off left tickmarks.
     resblnk@tiMainString = storm+" flight range "+xday0+"-"+xday1
     sat_img = gsn_blank_plot(wks,resblnk)    ; Create a blank plot.
     text = gsn_add_text(wks,sat_img,"No Matching Image",0.5,0.55,texres)
     draw(sat_img)
    end if         ;endif satellite img time OK 
    frame(wks)
     

    delete([/plotcolors,wks/])
   end do            ; end index loop
  end do            ;end "a" loop (running averages) 
  print("delete")
  delete([/flightdata,vert_accel,lat,lon,alt,alt_ind,\\
            flight_time,time_sec,flight_time_minu,accel_smth,\
            actual_dattim,time_min,altkm,base_time/])
 end do               ;end "b" loop( netcdf files)
;  system("montage -geometry 800x800 -trim planview.png variance.png "+filename)
end
