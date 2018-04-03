load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/jm13/pduran/ncl/radar/scripts/functions/rangering.ncl"

;------------------------------------------------------------------------------------------
;AS OF 12 MAY 2017, WE'RE NOW SHIFTING THE IR PIXELS BY
;THE AVERAGE PARALLAX ADJUSTMENT FOR EACH SONDE IN THE
;TRANSECT. ADJUSTMENT FACTORS ARE FOUND IN /jm13/pduran/sat/patricia/lin-parallax.tabdat
;
;ALSO CHANGED ON 12 MAY 2017: DROPSONDE DEPLOYMENT LOCATIONS ARE NOW OBTAINED FROM EOL
;                             FILES RATHER THAN EDIT FILES. EOL FILES HAVE THE ACTUAL
;                             DEPLOYMENT LOCATION, WHEREAS EDIT FILES HAVE THE LOCATION
;                             OF THE FIRST NONMISSING DATA POINT *AFTER* DEPLOYMENT
;16 MAY 2017: Added option to plot dropsonde locations at a given vertical level.
;             If level is missing, no location will be plotted.
;18 SEP 2017: Added option to plot storm tracks over IR image (traj=2)
;------------------------------------------------------------------------------------------

;-----------------;
;SET THESE OPTIONS;
;-----------------;
storm = "patricia"
dates = (/"20151021","20151022","20151022","20151023"/)
transects = (/"transect2","transect1","transect2","transect1"/)
type = 2    ;How to handle sonde coordinates and parallax correction 
            ;    0=Use a list of .edit files and do not apply a parallax correction 
            ;    1=Use the coordfile variable to read parallax corrected drop lats and lons.
            ;    2=Use the actual drop lats,lon from list of .eol files and correct the IR
            ;      pixels themslves for parallax error.
            ;    3=Use the lat,lon at a given vertical level, defined below in meters
lev  = 17000
labtyp = 1  ;Type of dropsonde location labels to use. Set to 0 for digits; 1 for asterisks
traj   = 3  ;Set to 0 to plot sonde location, 1 to plot sonde trajectories, 2 to plot two
            ;markers for each sonde: one for the drop location and one for z=16 km
            ;Set to 3 to plot storm track from trakfiles defined below
               ;Sonde trajectory plotting options (only used if traj=1)
               minlev = 16000 ;Bottom of layer over which to plot trajectory
               maxlev = 20000 ;Top of layer over which to plot trajectory
               dz     = 100   ;Vertical grid spacing of input files
               nlevs  = (maxlev-minlev)/dz
               ;Storm track files (only used if traj=3)
               trakfile1 = "/nfs/jm13/pduran/recon-positions/patricia_vortex_interp-1sec.txt"
               trakfile2 = "/nfs/jm13/pduran/recon-positions/patricia_hrd_interp_1sec.txt"
presopt = 0  ;Set to 0 to plot figures for paper; 1 to plot figures for presentation
;--------------------------------;
;LOOP THROUGH ALL DATES/TRANSECTS;
;--------------------------------;
if(dimsizes(dates).ne.dimsizes(transects))then
   print("Error: Dimension sizes of dates must be same as dimension sizes of transects...exiting")
   exit
end if
do k=0,dimsizes(dates)-1
   date      = dates(k)
   transect  = transects(k)
   dropdir   = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/"
   eoldir    = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/"+date+"/"
   satpath   = "/nfs/jm13/pduran/sat/"
   outputdir = "/nfs/jm13/pduran/web/"
   tablefile = "/nfs/jm13/pduran/sat/tables/coeff.txt"
   listfile  = dropdir+transect
   monday    = systemfunc("echo "+date+" | colrm 1 4")
   plaxfile  = "/jm13/pduran/sat/patricia/lin-parallax.tabdat" ;Used only if type = 2
   coordfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/droplocs_parallax_corrected/droplist-loc-"\
               +monday+"-"+transect+"-plax15-lincorr.dat" ;Used only if type = 1
   
   ;Check date and transect and throw a warning if they're not recognized
   if((date.eq."20151021".and.transect.ne."transect2").or.(date.eq."20151023".and.transect.ne."transect1"))then
      print("ERROR: Date/Transect pair not recognized...Exiting.")
      exit
   else if(date.eq."20151022")
      if(transect.ne."transect1".and.transect.ne."transect2")then
         print("ERROR: Date/Transect pair not recognized...Exiting.")
         exit
      end if
   end if
   
   ;Get storm center lat,lon for this transect using centersonde
   if(date.eq."20151021")then
      centersonde = "BB9D"
      centersondefile = eoldir+"QC_20151021-195645-BB9D.eol"
   else if(date.eq."20151022")then
      if(transect.eq."transect1")then
         centersonde = "3872"
         centersondefile = eoldir+"QC_20151022-182301-3872.eol"
      else
         centersonde = "6530"
         centersondefile = eoldir+"QC_20151022-190545-6530.eol"
      end if
   else
      centersonde = "4E93"
      centersondefile = eoldir+"QC_20151023-200138-4E93.eol"
   end if
   end if
   centerlat = stringtofloat(systemfunc("grep Location "+centersondefile+" | awk '{print $9}' | sed 's/,//g'"))
   centerlon = stringtofloat(systemfunc("grep Location "+centersondefile+" | awk '{print $6}' | sed 's/,//g'"))

   ;Read dropfiles
   dropfiles := dropdir+systemfunc("cat "+listfile)
   ndrops = dimsizes(dropfiles)
   
   ;Initialize lat and lon coordinate arrays for trajectories if traj = 1
   if(traj.eq.1)then
      lats := new((/ndrops,nlevs/),float)
      lons := new((/ndrops,nlevs/),float)
      maxdrift := new(ndrops,float)
      lats@_FillValue = -9999.
      lons@_FillValue = -9999.
   end if

   ;Get drop latitudes and longitudes and if selected, lats and lons for trajectories
   if(type.eq.0.or.type.eq.2.or.type.eq.3)then
      droplats := new(dimsizes(dropfiles),"float")
      droplons := new(dimsizes(dropfiles),"float")
      do i=0,ndrops-1
         unixi = i+1
         print("Getting dropsonde lat,lon for sonde "+unixi+" of "+ndrops)
         if(type.eq.0)then
            nfields = stringtoint(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print NF}'"))
            droplats(i) = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print $3}'"))
            if(nfields.eq.9)then
               droplons(i) = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print $5}' | sed 's/=//'"))
            else
               droplons(i) = stringtofloat(systemfunc("sed -n 5p "+dropfiles(i)+" | awk '{print $6}'"))
            end if

         end if
         if(type.eq.2)then
            sondeid = systemfunc("sed -n 4p "+dropfiles(i)+" | awk -F'=' '{print $3}' | cut -c2-5")
            eolfile := systemfunc("ls "+eoldir+"*"+sondeid+".eol ")
            ;Two of the sondes on 10/22 have the same ID -_- so check for that...
            if(eolfile(0).eq.eoldir+"QC_20151022-184541-6530.eol")then
               eolfile := eoldir+"QC_20151022-190545-6530.eol"
            end if
            droplats(i) = stringtofloat(systemfunc("grep Location "+eolfile+" | awk '{print $9}' | sed 's/,//g'"))
            droplons(i) = stringtofloat(systemfunc("grep Location "+eolfile+" | awk '{print $6}' | sed 's/,//g'"))
         end if
         if(type.eq.3)then
            data := readAsciiTable(dropfiles(i),10,"float",7)
            hght := data(:,5)
            lats := data(:,7)
            lons := data(:,8)
            if(.not.ismissing(ind(hght.eq.lev)))then
               droplats(i) = lats(ind(hght.eq.lev))
               droplons(i) = lons(ind(hght.eq.lev))
            end if
         end if
         if(traj.eq.1)then
            data := readAsciiTable(dropfiles(i),10,"float",7)
            data@_FillValue = -9999.
            hght := data(:,5)
            topind = max(ind(hght.le.maxlev))
            botind = min(ind(hght.ge.minlev))
            nhghts = topind-botind
            if(.not.(max(hght).lt.minlev))then  ;Check if all data are missing above bottom level
               lats(i,:nhghts) = data(botind:topind,7)
               lons(i,:nhghts) = data(botind:topind,8)
               ;Need to reverse lats and lons because .edit file altitude is in ascending order
               ;and we need descending order...
               lats(i,:) = lats(i,::-1)
               lons(i,:) = lons(i,::-1)
               ;Set first latitude to actual drop latitude to get a correct maximum drift
               minnonmissingind = min(ind(.not.ismissing(lats(i,:))))
               lats(i,minnonmissingind) = droplats(i)
               lons(i,minnonmissingind) = droplons(i)
               ;Get maximum sonde drift in this layer
               ;Ignore drifts > 1000 km because gc_latlon doesn't search for missing values
               drifts = gc_latlon(droplats(i),droplons(i),lats(i,:),lons(i,:),2,4)
               maxdrift(i) = max(drifts(ind(drifts.lt.1000)))
            end if
         end if 
      end do
   else if(type.eq.1)then
      droplats := stringtofloat(systemfunc("awk '{print $5}' "+coordfile))
      droplons := stringtofloat(systemfunc("awk '{print $4}' "+coordfile))
   end if
   end if

   ;Adjust all lat,lons for parallax. Only done if traj=1, since that's where
   ;we're dealing with lats,lons at multiple levels
;   if(traj.eq.1)then
;      if(date.eq."20151021")then
;         lats = lats+0.0344
;         lons = lons-0.0751
;      else if(date.eq."20151022")then
;         lats = lats+0.0422
;         lons = lons+0.1086
;      else
;         lats = lats+0.0548
;         lons = lons+0.1079
;      end if
;      end if
;      end if
   end if
   
   ;Get satellite file
   if(date.eq."20151021")then
      satfile = satpath+"goes13.2015.294.201520.BAND_04.nc"
      letter  = "a)"
      satstr  = "GOES-13"
      dattimstr = "21 October   2015 UTC"
      centerind = 6
   else if(date.eq."20151022")then
      if(transect.eq."transect1")then
         letter  = "b)"
         satfile = satpath+"goes15.2015.295.183017.BAND_04.nc"
         dattimstr = "22 October   1830 UTC"
         centerind = 13
      else
         letter  = "c)"
         satfile = satpath+"goes15.2015.295.190019.BAND_04.nc"
         dattimstr = "22 October   1900 UTC"
         centerind = 15
      end if
      satstr  = "GOES-15"
   else if(date.eq."20151023")then
      letter  = "d)"
      satfile = satpath+"goes15.2015.296.200018.BAND_04.nc"
      satstr  = "GOES-15"
      dattimstr = "23 October   2000 UTC"
      centerind = 14
   end if
   end if
   end if
  
   ;----------------------------------------------;
   ;Get parallax offsets for IR pixels, if desired;
   ;----------------------------------------------;
   if(type.eq.2.or.type.eq.3)then
      latoffset = stringtofloat(systemfunc("grep "+date+" "+plaxfile+" | awk '{print $4}'")) 
      lonoffset = stringtofloat(systemfunc("grep "+date+" "+plaxfile+" | awk '{print $5}'"))
   end if
 
   ;--------------------;
   ;Plot satellite image;
   ;--------------------;
   table = readAsciiTable(tablefile,8,"float",(/2,13/)) ;Read satellite coefficient table file
   
   ;-------------------------------------------;
   ;            Plot satellite image           ;
   ;-------------------------------------------;
   f = addfile(satfile,"r")
   
   ;Get data from netCDF file
   satdate = f->crDate
   sattime = f->crTime
   ir := f->data(0,:,:)    ;float
   latitude := f->lat      ;float
   longitude := f->lon     ;float
   yyddd = f->imageDate   ;int
   hhmmss = f->imageTime  ;int
   sat = f->sensorID      ;char
   band = f->bands        ;int
   
   ;Get date and time of satellite imagery
   satyear := toint(systemfunc("echo "+satdate+" | cut -c 1-4"))
   satday  := toint(systemfunc("echo "+satdate+" | colrm 1 4"))
   satdate := monthday(satyear,satday)
   if(sizeof(satdate).eq.3)then
      satmon = systemfunc("echo "+satdate+" | cut -c 1")
      satday := systemfunc("echo "+satdate+" | colrm 1 1")
   else
      satmon = systemfunc("echo "+satdate+" | cut -c 1-2")
      satday := systemfunc("echo "+satdate+" | colrm 1 2")
   end if
   satdate := satmon+"/"+satday+"/"+satyear
   sathr  = systemfunc("echo "+sattime+" | cut -c 1-2")
   satmin = systemfunc("echo "+sattime+" | cut -c 3-4")
   sattime := sathr+":"+satmin+" UTC"
   
   ;-------------------------------------------------------------------------------------------------;
   ;CALCULATE BRIGHTNESS TEMPERATURE FROM RAW GVAR SATELLITE COUNTS                                  ;
   ;Helpful documentation:                                                                           ;
   ;http://www.ncdc.noaa.gov/sites/default/files/attachments/Satellite-Frequently-Asked-Questions.pdf;
   ;https://www.ssec.wisc.edu/mcidas/doc/users_guide/2010.2/app_c-1.html                             ;
   ;http://www.ospo.noaa.gov/Operations/GOES/calibration/gvar-conversion.html                        ; 
   ;-------------------------------------------------------------------------------------------------;
   ir = ir/32    ;Convert 16-bit to 10-bit
   
   ;Constants for calibration equations
   c1 = .00001191066  ;Units [mW/(m^2-sr-cm^-4)]
   c2 = 1.438833      ;Units [K/cm^-1]
   
   ;Now get the sensor-dependent calibration coefficients
   ;See table file at top of script for variable names
   index = ind((table(:,0).eq.sat).and.(table(:,2).eq.band))
   if(ismissing(index))then
      print("ERROR: Coefficients for this satellite not in table file "+tablefile)
      print("       McIdas Satellite Number: "+sat+"  Channel: "+band)  
      exit
   end if
   coeffs = table(index,:)
   b = coeffs(3)
   m = coeffs(4)
   n = coeffs(5)
   A = coeffs(6)
   B = coeffs(7)
   
   ;Calculate radiance
   system("echo Computing radiance   `date`")
   r := (ir-b)/m
   r:= where(r.le.0,r@_FillValue,r)  ;Where radiance is negative or zero, set to missing
   
   ;Calculate effective temperature
   ;(First determining whether argument of log is negative; if so, set to missing)
   system("echo Computing effective temperature   `date`")
   arg_before := new(dimsizes(ir),"float")
   arg_before := 1+(c1*n^3)/r
   arg := where((arg_before.eq.0).or.(arg_before.eq.162965.4),arg_before@_FillValue,arg_before)
   Teff := (c2*n)/log(arg)
   
   ;Calculate brightness temperature
   system("echo Computing brightness temperature   `date`")
   Tb := A+B*Teff
   TbC := Tb-273.15
   
   ;----------------------;
   ;Give lat and lon units;
   ;----------------------;
   latitude@units="degrees_north"
   longitude@units="degrees_east"

   ;-----------------------------------------------------------;
   ;Adjust IR pixel coordinates by parallax offset, if selected;
   ;-----------------------------------------------------------;
   if(type.eq.2.or.type.eq.3) 
      latitude  = latitude - latoffset
      longitude = longitude - lonoffset
   end if

   ;---------------------------------------------------;
   ;Convert hhmmss to string, cutting off seconds place;
   ;---------------------------------------------------;
   if(hhmmss.lt.10000)then
      imgtime = "00"+hhmmss
   else if(hhmmss.lt.100000)then
      imgtime = "0"+hhmmss
   else
      imgtime = tostring(hhmmss)
   end if
   end if
   imgtime_noseconds = systemfunc("echo "+imgtime+" | colrm 5 6")
   
   ;---------------------;
   ;Define domain of plot;
   ;---------------------;
   if(date.eq."20151021")then
      minlat = 11.3
      maxlat = 15.0
      minlon = -101.5
      maxlon = -98.0
      if(traj.eq.1)then
         minlat = 12.5
         maxlat = 13.5
         minlon = -100.8
         maxlon = -98.5
      end if
   else if(date.eq."20151022")then
      minlat = 13.5 
      maxlat = 17.0
      minlon = -106.0 
      maxlon = -102.5
      if(traj.eq.1)then
         minlat = 14.3
         maxlat = 16.1
         minlon = -105.0
         maxlon = -103.5
      end if
   else if(date.eq."20151023")then
      minlat = 17.0
      maxlat = 20.5
      minlon = -107.0
      maxlon = -103.5
      if(traj.eq.1)then
         minlat = 18.1
         maxlat = 19.65
         minlon = -106.0
         maxlon = -104.85
      end if
   end if
   end if
   end if
   
   ;Define filename
   if(traj.eq.0)then
      filename = outputdir+satyear+satmon+satday+"_"+hhmmss+"_ir_new"
   else if(traj.eq.1)then
      filename = outputdir+satyear+satmon+satday+"_"+hhmmss+"_ir+droptraj"
   else if(traj.eq.3)then
      filename = outputdir+satyear+satmon+satday+"_"+hhmmss+"_ir+stormtracks"
   end if
   end if
   end if
   
   ;Set workstation
   wks = gsn_open_wks("PNG",filename)
   gravwavewks = gsn_open_wks("PNG",outputdir+"gravity_wave_ir.png") 
   
   ;Get AVN satellite colormap and reverse it for plotting.
   gsn_define_colormap(wks,"avn_extended")
   gsn_reverse_colormap(wks)
   gsn_define_colormap(gravwavewks,"avn_extended")
   gsn_reverse_colormap(gravwavewks)
   
   ;Set some plotting resources
   system("echo Plotting image   `date`")
   res = True
   res@gsnAddCyclic = False
   res@sfXArray := longitude
   res@sfYArray := latitude
   res@tiXAxisString = "Degrees Longitude"
   res@tiYAxisString = "Degrees Latitude"
   res@tiYAxisOn = True
   res@tiXAxisOn = True
   res@tiXAxisFontHeightF = 0.014
   res@tiYAxisFontHeightF = 0.014
   res@gsnStringFontHeightF = 0.015
   res@gsnLeftStringOrthogonalPosF = .01
   res@gsnRightStringOrthogonalPosF = .01
   if(date.eq."20151021")then
      res@tiXAxisOn = False
      if(presopt.eq.1)then
         res@tiXAxisOn = True
      end if
   else if(date.eq."20151022")then
      if(transect.eq."transect1".or.presopt.eq.1)then
         res@tiYAxisOn = False
         res@tiXAxisOn = False
      end if
   else if(date.eq."20151023")then
      res@tiYAxisOn = False
   end if
   end if
   end if
   if(traj.eq.0)then
      res@gsnLeftString = letter+" "+satstr+"   "+dattimstr
   else if(traj.eq.1)then
      minstr = minlev/1000
      maxstr = maxlev/1000
      res@gsnLeftString = "Sonde trajectories "+minstr+"km-"+maxstr+"km  "+dattimstr 
      res@gsnStringFontHeightF = 0.012
      res@tiXAxisFontHeightF = 0.012
      res@tiYAxisFontHeightF = 0.012
      res@tiYAxisOn = False
      res@tiXAxisOn = False
   else if(traj.eq.3)then
      res@gsnLeftString = "Storm tracks   "+dattimstr
      res@gsnStringFontHeightF = 0.012
      res@tiXAxisFontHeightF = 0.012
      res@tiYAxisFontHeightF = 0.012
      res@tiYAxisOn = False
      res@tiXAxisOn = False
   end if
   end if
   end if
   res@tiMainFontHeightF = 0.015
   res@tiYAxisOffsetXF    = -0.08
   res@tiXAxisOffsetYF    = -0.06
   res@cnFillOn = True             ;Color fill
;   res@cnFillMode = "RasterFill"   ;Raster mode
   res@cnLinesOn = False           ;Turn off contours
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF = -90.
   res@cnMaxLevelValF = 38.
   res@cnLevelSpacingF = 2.
   res@cnLineLabelsOn = False	;Turn off contour labels
   if(traj.eq.1)then
      res@cnFillOpacityF = 0.8
   end if

   res@gsnSpreadColors = True
   res@gsnSpreadColorStart = 2
   res@gsnSpreadColorEnd = 60
   
   res@mpMinLatF = minlat
   res@mpMaxLatF = maxlat
   res@mpMinLonF = minlon
   res@mpMaxLonF = maxlon
   res@mpOutlineBoundarySets = "NoBoundaries";"GeophysicalAndUSStates"
   res@mpGeophysicalLineThicknessF = 10.0
   res@mpGeophysicalLineColor = "Green"
   res@mpUSStateLineColor = "Green"
   
   res@lbLabelBarOn = False
   res@lbLabelStride = 5.
   res@lbTitleOn = False
   res@lbTitleString = "~S~o~N~C" ;Deg C
   res@lbTitleFontHeightF = 0.013
   res@lbLabelFontHeightF = 0.013
   res@lbOrientation = "Vertical"
   res@lbBoxMinorExtentF = 0.1
   res@pmLabelBarOrthogonalPosF = 0.005
   
   res@tmXBLabelFontHeightF = 0.013
   res@tmYLLabelFontHeightF = 0.013
   
   res@tmYROn   = "False"
   res@tmXTOn   = "False"
   res@tmYLMode = "Manual"
   res@tmXBMode = "Manual"
   res@tmYLTickStartF = minlat
   res@tmYLTickEndF   = maxlat
   res@tmXBTickStartF = minlon
   res@tmXBTickEndF   = maxlon
   res@tmYLTickSpacingF = 1.
   res@tmXBTickSpacingF = 1.
   print("!!!!!IGNORE ANY TickMarkSetValues WARNING MESSAGES!!!!!")
   
   res@gsnMaximize = True 
   res@gsnDraw  = False		;So we can add poly stuff
   res@gsnFrame = False
   plot = gsn_csm_contour_map(wks,TbC(:,:),res)
   gravwaveres = res
   gravwaveres@gsnLeftString = " "
   gravwaveres@lbLabelBarOn = True
   gravwaveres@tiYAxisOn = True 
;   gravwaveplot = gsn_csm_contour_map(gravwavewks,TbC(:,:),gravwaveres)
   cnres = res
   cnres@cnFillOn = False
   cnres@cnLinesOn = True
   cnres@cnInfoLabelOn = False
   cnres@gsnLeftString = " "
   cnres@cnLevelSelectionMode = "ExplicitLevels"
   cnres@cnLevels = (/-82,-84,-86,-88/)
   cnres@cnLineThicknessF = 3.
   ;cnres@cnLineLabelsOn = True
   ;cnres@cnLineLabelPlacementMode = "constant"
   ;cnres@cnLineLabelInterval = 2.
   ;cnres@cnLineLabelDensityF = 2.
   cnplot = gsn_csm_contour(wks,TbC,cnres)
   ;cnplot2 = gsn_csm_contour(gravwavewks,TbC,cnres)
   
   if(traj.eq.0)then ;If traj=0, add dropsonde location labels
      if(labtyp.eq.0)then
         text = tostring(ispan(1,dimsizes(droplats),1))
         txres = True
         txres@txFont = 30
         txres@txFontHeightF = 0.01
         txres@txFontColor = "black"
         dum = gsn_add_text(wks,plot,text,droplons,droplats,txres)
      else
         dum := new(dimsizes(droplats),"graphic")
         do j=0,dimsizes(droplats)-1
            ;Overlay dropsonde location markers
            polyres               = True
            polyres@gsMarkerIndex = 3 ;Polymarker style
      ;      if(j.eq.0)then
      ;         add_markers(wks,plot,droplons(j),droplats(j),"black",15,10,polyres@gsMarkerIndex)
      ;      else
               if(j.eq.centerind)then
                  if(presopt.eq.0)then
                     add_markers(wks,plot,droplons(j),droplats(j),"cyan",10,5,polyres@gsMarkerIndex)
                  else
                     add_markers(wks,plot,droplons(j),droplats(j),"black",10,5,polyres@gsMarkerIndex)
                  end if
               else
                  add_markers(wks,plot,droplons(j),droplats(j),"black",10,5,polyres@gsMarkerIndex)
               end if
      ;         add_markers(gravwavewks,gravwaveplot,droplons(j),droplats(j),"black",10,5,polyres@gsMarkerIndex)
      ;      end if
         end do
      end if
   else if(traj.eq.1)then ;If traj=1, add dropsonde trajectories
      dum := new(dimsizes(droplats),graphic)
      dum1:= new(dimsizes(droplats),graphic)
      polyres = True
      polyres@gsLineColor = "cyan"
      polyres@gsLineThicknessF = 6.
;      polyres1 = True
;      polyres@gsMarkerColor  = "black"
;      polyres1@gsMarkerColor = "cyan"
;      polyres@gsMarkerIndex = 3
;      polyres1@gsMarkerIndex = 3
;      polyres@gsMarkerThicknessF = 3
;      polyres1@gsMarkerThicknessF = 3
      do j=0,dimsizes(droplats)-1
         ;Make sure that not all of the lats (except the first one, which we put in there manually) are missing
         if(.not.all(ismissing(lats(j,1:))).and..not.all(ismissing(lons(j,1:))))
            dum(j) = gsn_add_polyline(wks,plot,lons(j,:),lats(j,:),polyres)
         end if
;         dum(j)  = gsn_add_polymarker(wks,plot,droplons(j),droplats(j),polyres)
;         dum1(j) = gsn_add_polymarker(wks,plot,lons(j,dimsizes(droplats)-1),lats(j,dimsizes(droplats)-1),polyres1)
      end do
   else if(traj.eq.3)then ;If traj=3, add storm tracks
      traklats1 = stringtofloat(systemfunc("awk '{print $1}' "+trakfile1+" | sed '1d'"))
      traklons1 = stringtofloat(systemfunc("awk '{print $2}' "+trakfile1+" | sed '1d'"))
      traklats2 = stringtofloat(systemfunc("awk '{print $1}' "+trakfile2+" | sed '1d'"))
      traklons2 = stringtofloat(systemfunc("awk '{print $2}' "+trakfile2+" | sed '1d'"))
      polyres = True
      polyres@gsLineColor = "black"
      polyres@gsLineThicknessF = 6.
      polyres2 = polyres
      polyres2@gsLineColor = "cyan"
      trakline1 = gsn_add_polyline(wks,plot,traklons1,traklats1,polyres)
      trakline2 = gsn_add_polyline(wks,plot,traklons2,traklats2,polyres2)
   end if
   end if
   end if
   
   ;Add range rings
   radialextent = 300
   ringspacing  = 20
   nrings = radialextent/ringspacing
   txdum = new(nrings,"graphic")
   do l=1,nrings
      centerlatrad = stringtofloat(centerlat)*(2*3.141592/360.)
      range_lat = l*ringspacing/111.
      range_lon = (l*ringspacing)/(110.567*cos(centerlatrad))
      scale   = range_lon/range_lat
      ringres = True
      ringres@Scale = scale
      ringres@gsLineThicknessF = 2.
      circle_ll(wks,plot,centerlon,centerlat,range_lat,ringres)
      if(l%2.eq.0)then
         rrlabel = tostring(ringspacing*l)+" km"
         rrlabelres = True
         rrlabelres@txFontHeightF = .01
         rrlabelres@txJust = "centercenter"
         rrlabelres@txPerimOn = True
         rrlabelres@txBackgroundFillColor = "white"
         txdum(l) = gsn_add_text(wks,plot,rrlabel,centerlon,centerlat+range_lat,rrlabelres)
      end if
   end do
   
   overlay(plot,cnplot)
   ;overlay(gravwaveplot,cnplot2)
   draw(plot)
   ;draw(gravwaveplot)
   frame(wks)
   ;frame(gravwavewks)
   if(traj.eq.1)then
      print("Maximum sonde drifts for "+date+" "+transect)
      print(maxdrift)
      delete([/droplats,droplons/])
   end if
end do
