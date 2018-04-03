load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/home/djv/NCL/djv_lib/dv_pltlibs.ncl"

; pltmcidas_wcenter-1tim.ncl
; date: 5/17
; Will plot a GOES McIDAS file using djv-ir colortable and put storm center on 
; if desired. Plot can be centered on storm and extend out a user-def area or 
; use set bounds.
; Uses AreaToNetCDF.jar to convert MCIDAS area to netcdf provided by P. Duran
; 
; Updates
;  5/17: Will apply a constant correction to each lat/lon point in the 
;        netcdf image in order to reduce parallax error.(since GOES subsatellite
;        location is on EQ will SUBTRACT corrections from lat/lon arrays.
; 12/16: To read/plot a raw GVAR GOES file(ie not remapped to MERC) where lat/lon
;        are 2D curvlinear arrays can  assign atts to ir(ie ir@lat2d = latitude)
; 11/16: Can read McIDAS files in either AREA or NetCDF fmt.
;       -To read/plot a raw GVAR GOES file(ie not remapped to MERC)
;        need to  set Grid Type = "TriangularMesh"(slow) or "Map"(faster)
;        Then define plotting bounds(trYMinF;trYMaxF;trXMinF;trXMaxF)
;        Then assign locations to datapoints using sfXArray := longitude
;        and sfYArray := latitude(:= reassigns sfYarray)
;       -Can use getind_latlon2d to find nearest coord in 2D lat/lons
; 10/16: User can process McIDAS AREA files or NetCDF files gotten from NOAA
;        Can plot out lat/lons to tenths of deg for blowup plts
; ***NOTE: Use NetCDF or MERC AREA for GOES15 data!!!
; Areafile name fmt = goes##.YYYY.JJJ.HHMM.BAND_0# where #=number and JJJ=julday
; ie  goes12.2004.250.1945.BAND_04
;
; Script is called with the following parameter 
;     ncl areatime=YYYY.MMDD.HHMM band=## xx.ncl
; ie  ncl areatime='"2015.1023.2000"' band='"04"' ncflag='"True"' out_type='"X11"' plt_drplocs_mcidas-1tim.ncl

; --------------------------------------------------------------
; --------------------------------------------------------------
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
;Set the center track and intensity files and McIdas area file path
 trkfile = "/jm13/djv/GIV_outflow/tracks/2004/gdtrk04aI01-1min-000.dat"
 drpfile = "/jm13/djv/DROPSONDES/ONR-drops/2015/QC/droplist-loc-1023-long.dat"
 satpath   = "/jm13/djv/DROPSONDES/ONR-drops/mcidas/2015/testpat/"
 satpath_nc = "/jm13/djv/DROPSONDES/ONR-drops/mcidas/2015/testpat/new/nc/"
;/jm13/djv/DROPSONDES/ONR-drops/mcidas/2015/n/"
; satpath  = "/jm13/djv/ivan04/mcidas/raw/"
; satpath_nc  = "/molinarilab_rit/McIDAS/"


 if (ncflag.eq."True") then
  satpath = satpath_nc
 end if
 
 res = True
 resMark = True
 parm = True
 parm@plax_corr = True    ;apply parallax correction to map latlons
 plax_lonoff = 0.1079     ;lat/lon offsets to correctt for parallax
 plax_latoff = 0.0548

 color_table = "djv_sat_ir15a"
; ******************** User def color table section ****************
 rescolor = False       ;If False then will use default IR coltbl
 T0 = -30              ;Grayscale Temp value(warmer temps use grayscale)
 numtemps = 3          ;Number of color temp values
 temps = (/-40.,-50.,-80./) ;User deff temp values to color
 colors0 = (/(/1,0,0/),(/0,1,0/),(/0,0,1/)/)      ;r,g,b 0-1
 if (rescolor) then
  colfile = make_coltbl_custom("tstcol",T0,temps,numtemps,colors0,rescolor)
  color_table = "tstcol"
 end if
; ******************************************************************

; #################### USER PARAMETERS  ###########################
  res@lbLabelBarOn   = True	;Turn on/off color label bar
  lb_txtthk = 3.0              ;labtxt thickness
  lb_txtsiz = .02             ;labtxt size
  lbtit_siz = .026             ;lab title size
  lbtit_thk = 4.0              ;lab title thickness
  vp_hgt = 0.7                 ;viewprt hgt
  vp_wdth = 0.7                ;viewprt width
  vp_xoff = 0.12               ;viewprt offset from left axis
  vp_yoff = 0.85               ;viewprt offset from bottom axis
  dx = 1                       ;+/- map xrange from center (deg)
  dy = 1                       ;+/- map yrange from center (deg)
  trk_1min     = True          ;6h or 1min trackfile
  parm@plttit = True           ;plot titles
  parm@pltcen = False           ;plot center
  parm@pltdrp = True           ;plot center
  min_drptim = "1956"          ;
  max_drptim = "2011"          ;

  parm@convert = True         ;Convert McIDAS area to netcdf
  parm@FixedMap = True        ;Use stationary user-def map or center on storm
  minlat = 17.5                  ;minlat stationary map
  maxlat = 20.0                  ;maxlat stationary map
  minlon = -106.5                 ;wlon stationary map
  maxlon = -104.                 ;elon stationary map
  ticinc = 10                    ;tic labinc  5= every 0.5deg
  stmcen_col = "Black"         ;color of stormcen symbol
  drp_col_fill = "Black"         ;color of stormcen symbol
  drp_col = "white"         ;color of stormcen symbol
  storm = "Patricia-plaxmap"               ;storm name
  out_fil_base = storm         ;outfile name
; #################################################################

 marker = new((/1000/),graphic)
 marker1 = new((/1000/),graphic)
 plot = new((/1/),graphic)
 areamin = new(1,"double")
 areatimejul = new(1,"double")

; Find desired areafile by converting greg day to julday
; --------------------------------------------------------------
 areayr = str_get_cols(areatime, 0,3)
 areahhmm = str_get_cols(areatime, 10,13)
 areasplit             = str_split(areatime, ".") 
 areayear       = stringtoint(areasplit(0))
 areatmpsplit         = str_split_by_length(areasplit(1),2)
 areamon        = stringtoint(areatmpsplit(0))
 areaday        = stringtoint(areatmpsplit(1))
 delete(areatmpsplit)
 areatmpsplit         = str_split_by_length(areasplit(2),2)
 areahr        = stringtoint(areatmpsplit(0))
 areamin        = stringtoint(areatmpsplit(1))
 areajulday = day_of_year(areayear,areamon,areaday)  ;gives julian value of 
 print(areayear+" "+areamon+" "+areaday+" "+" "+areajulday)

; Find desired file in area directory
 system("ls "+satpath+" |grep "+areayr+" |grep "+areajulday+" |grep "+areahhmm+" |grep BAND_"+band+" > areafilelist.tmp")
 afile = asciiread("areafilelist.tmp",1,"string")
 print(afile)
; --------------------------------------------------------------


;Read the trackfile into an array  7cols(hhhh,mmddyy,lat,lon,pres,wspd,stren)
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
; --------------------------------------------------------------


; Convert dates/times to Julian and
; Find trkfile index that matches area time 
; --------------------------------------------------------------
 hurtimejul = new(nrows,double)
 areatimejul = greg2jul(areayear,areamon,areaday,areahr) 
 hurtimejul = greg2jul(huryr,hurmon,hurday,hurhr) 
 if (trk_1min.eq."True") then
  areatimejul = greg2jul(areayear,areamon,areaday,areahr) + areamin/1400
  hurtimejul = greg2jul(huryr,hurmon,hurday,hurhr) + int2dble(hurmin)/1400
 end if
 center_ind = ind_nearest_coord (areatimejul, hurtimejul,0)
 print(center_ind+" "+areatimejul+" "+hurtimejul(center_ind))
; --------------------------------------------------------------

;Get drop info; ;20151023 1959 8664 -105.09   18.44
;                20151023 2005 0369 -105.472585   18.937880
; ---------------------------------------------------
 drpdata   = asciiread(drpfile,-1,"string")
 drpdate = str_get_cols(drpdata, 4,7)
 drphhmm = str_get_cols(drpdata, 9,12)
 drpyr  = stringtoint(str_get_cols(drpdata, 0,3)) 
 drphr  = stringtoint(str_get_cols(drpdata, 9,10)) 
 drpmin = stringtoint(str_get_cols(drpdata, 11,12))
 drpmon = stringtoint(str_get_cols(drpdata, 4,5))
 drpday = stringtoint(str_get_cols(drpdata, 6,7))
 drpid = str_get_cols(drpdata, 14,17)
; drplon = stringtodouble(str_get_cols(drpdata, 18,29)) + plax_latoff
; drplat = stringtodouble(str_get_cols(drpdata, 32,41)) + plax_lonoff
 drplon = stringtodouble(str_get_cols(drpdata, 18,29)) 
 drplat = stringtodouble(str_get_cols(drpdata, 32,41)) 
 drpind_min = min(ind(drphhmm.eq.min_drptim))
 drpind_max = max(ind(drphhmm.eq.max_drptim))
 print(drpind_min+" "+drpind_max)


; ######### Read IR data and plot satellite image #################
  if (ncflag.eq.True) then
   print("PROCESSING NOAA/CLASS NetCDF")
   print(satpath)
   ncfile = satpath+afile
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
   Gnum = stringtoint(str_get_cols(afile,4,5))  ;get goes number from filename
   print(Gnum)
   ir = GVAR2brit(Gnum-8,stringtoint(band),ir0,resIR)  ;convert GVAR to brit

  else

   print(" Convert AREA to NetCDF")
   areafile = satpath+afile
   if (parm@convert.eq. "True" ) then
    system("cp "+areafile+" /jm13/djv/area_tmp")
    system("java -cp /jm13/djv/java/AreaToNetCDF.jar AreaToNetCDF /jm13/djv/area_tmp* /jm13/djv/netcdf_tmp.nc -CBRIT")
   end if
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
  irdims = dimsizes(ir)
  nline = irdims(0)
  nelem = irdims(1)
  print(irdims)

  if (parm@plax_corr.eq."True") then
   print("Apply parallax correction to latlons")
   latitude  = latitude -  plax_latoff
   longitude = longitude - plax_lonoff
  end if

;Create Named dimensions and coord vars for IR
; ie res@sfXArray = longitude(minlat_ind:maxlat_ind,minlon_ind:maxlon_ind)
; --------------------------------------------------------------
 latitude@units="degrees_north"
 latitude@_FillValue = 2.143289e+09
 longitude@units="degrees_east"
 longitude@_FillValue = 2.143289e+09

; Assign 2D curvlinear arrays to ir for plotting
  ir@lat2d = latitude
  ir@lon2d = longitude

;  Define plot map area +/- dxdy from cenloc if FixedMap flag false
; --------------------------------------------------------------
 print(dx)
 print(hurlat(center_ind))
 if(parm@FixedMap.ne."True" ) then
  minlat = hurlat(center_ind) - int2flt(dy)
  maxlat = hurlat(center_ind) + int2flt(dy)
  minlon = hurlon(center_ind) - int2flt(dx)
  maxlon = hurlon(center_ind) + int2flt(dx)
 end if

 out_fil = out_fil_base+"-"+hurdate(center_ind)+hurhhmm(center_ind)+"_IR"

;  Open workstation and define IR colormap +viewport
; --------------------------------------------------------------
 wks = create_wks(out_fil, color_table, out_type)
 setvalues wks                          ;Set worksheet background color
  "wkBackgroundColor" : "white"
  "wkForegroundColor" : "black"
 end setvalues
 setvalues NhlGetWorkspaceObjectId()    ;Set workspace maximum size
  "wsMaximumSize" : 1000000000
 end setvalues
 res@gsnAddCyclic = False
 res@vpHeightF = vp_hgt          ;set up viewport 
 res@vpWidthF = vp_wdth
 res@vpXF = vp_xoff
 res@vpYF = vp_yoff

;  Set up IR contour parameters
; --------------------------------------------------------------
 res@cnFillOn = True             ;Color fill
 res@cnFillMode = "RasterFill"   ;Raster mode best for IR maps
 res@cnLinesOn = False           ;Turn off contours
 res@cnLineLabelsOn = False	   ;Turn off contour labels
 res@cnLevelSelectionMode = "ManualLevels"
 res@cnMinLevelValF      = 0.
 res@cnMaxLevelValF      = 240.
 res@cnLevelSpacingF = 1.0       ;Contour interval
 res@gsnSpreadColorStart = 2
 res@gsnSpreadColorEnd = 240
 res@gsnSpreadColors = True


;  Mapproj info
; --------------------------------------------------------------
 res = grab_base_res(res)  ;map/grid cols=gray20 
 res@mpMinLatF           = minlat  ;set up map area
 res@mpMaxLatF           = maxlat
 res@mpMinLonF           = minlon
 res@mpMaxLonF           = maxlon

 res@gsnDraw             = False   ;So we can add poly stuff
 res@gsnFrame            = False
 res@mpFillOn            = False
 res@mpGridAndLimbOn     = True    ; turn on lat/lon lines
 res@gsnMinorLatSpacing  = 2
 res@gsnMinorLonSpacing  = 2
 res@mpGridLineColor             = "gray"
 res@mpGridLatSpacingF   = dy       ;lat label spacing def=15
 res@mpGridLonSpacingF   = dx       ;lon label spacing def=15
 if (dx.lt.4.or.dy.lt.4) then
  res@gsnMinorLatSpacing = 1
  res@gsnMinorLonSpacing = 1
  res@mpGridLatSpacingF  = 1
  res@mpGridLonSpacingF  = 1
 end if
 res@gsnMajorLatSpacing  = dy
 res@gsnMajorLonSpacing  = dx
 res@mpGeophysicalLineThicknessF = 3
 res@mpGridLineThicknessF        = 2
 res@mpGridMaskMode     = "MaskNone" ;Gridmask opt(None;Land;Ocean;FillArea)
 res@mpGeophysicalLineColor     = 0
 res@mpGridAndLimbDrawOrder  = "postDraw"  ;
; ######### Function to plot lalo labs to tenths of degree #########
  res =  add_map_tic_tenths(wks,plot,minlon,maxlon,minlat,maxlat,ticinc,res)

; res@sfMissingValueV = maxir

 print("IR STATS min/max="+min(ir)+" "+max(ir)+" latrng="+min(latitude)+" "+max(latitude)+" lonrng="+min(longitude)+" "+max(longitude)+" XYres="+xres+" "+yres)

;   Title and label info 
; --------------------------------------------------------------
  if (parm@plttit.eq."True") then
   res@gsnLeftString = hurtyp(center_ind)+" "+storm
   res@gsnRightString = hurspd(center_ind)+"kt "+hurpres(center_ind)+"hPa"
   if (trk_1min.eq."True") then
    res@gsnRightString = hurspd(center_ind)+"kt "
   end if
   res@gsnStringFontHeightF = 0.01
   res@tiMainFontHeightF = 0.025
   res@tiMainString = storm+" sat "+areatime
  else
   res@gsnLeftString = " "
   res@gsnRightString = " "
  end if

; Puts IR labelbar onto plot  
; --------------------------------------------------------------
 res = create_ir_labbar(lbtit_siz,lbtit_thk,lb_txtsiz,lb_txtthk,res)

; Plot the image
; --------------------------------------------------------------
; plot = gsn_csm_contour_map( wks, ir({minlat:maxlat},{minlon:maxlon}), res)
 plot = gsn_csm_contour_map( wks, ir, res)


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
  print("hsym size="+hsym_siz)
  resMark@gsMarkerColor         = stmcen_col
  resMark@gsMarkerIndex         = NhlNewMarker(wks,"8",19,0,0,1,1,0)
  resMark@gsMarkerSizeF         = hsym_siz
  resMark@tfPolyDrawOrder = "PostDraw"  ;for polylines,polymarkers,or polygon
  resMark@gsMarkerThicknessF    = 4
  marker(0) = gsn_add_polymarker(wks,plot,hurlon(center_ind),hurlat(center_ind),resMark)
  overlay(plot,marker(0))        ;overlay 2nd parm onto 1st
 end if
 print("ceninfo "+center_ind+" "+hurlon(center_ind)+" "+hurlat(center_ind)+" "+hurdate(center_ind)+" "+hurhhmm(center_ind))
;finds nearest coord from 2d arrays(output=2d array
  nm = getind_latlon2d (latitude,longitude, hurlat(center_ind), hurlon(center_ind))
  print(nm)
  print("IR Center brit= "+ir(nm(0,0),nm(0,1)))

;  Plot drploc
; --------------------------------------------------------------
 if (parm@pltdrp .eq. "True" ) then
  drp_siz = 10                ;dx<4=12 ; dx >11=8 else=10
  if (dx.lt.4) then
   drp_siz = 12
  else if (dx.gt.11) then
   drp_siz = 8
  end if
  end if
  print("drpsym size="+drp_siz)
  resMark@gsMarkerIndex         = 9
  resMark@gsMarkerIndex         = NhlNewMarker(wks,"q",135,0,0,1,1,0)
  resMark@gsMarkerSizeF         = drp_siz
  resMark@gsMarkerColor         = drp_col
  resMark@tfPolyDrawOrder = "PostDraw"  ;for polylines,polymarkers,or polygon
  resMark@gsMarkerThicknessF    = 4
  resMark1 = True
  resMark1=resMark
  resMark1@tfPolyDrawOrder = "PostDraw"  ;for polylines,polymarkers,or polygon
  resMark1@gsMarkerIndex         = NhlNewMarker(wks,"q",35,0,0,1,1,0)
  resMark1@gsMarkerColor         = drp_col_fill
  resMark1@gsMarkerSizeF         = drp_siz-1
  drpcnt=0
  if (parm@pltcen .eq. "True" ) then
   drpcnt=1
  end if
  do dd = drpind_min,drpind_max
  marker(drpcnt) = gsn_add_polymarker(wks,plot,drplon(dd),drplat(dd),resMark)
  overlay(plot,marker(drpcnt))        ;overlay 2nd parm onto 1st
  marker1(drpcnt) = gsn_add_polymarker(wks,plot,drplon(dd),drplat(dd),resMark1)
  overlay(plot,marker1(drpcnt))        ;overlay 2nd parm onto 1st
  drpcnt=drpcnt+1


  end do
 end if
 draw(plot)
 frame(wks)

;   system("\rm -f area_tmp /jm13/djv/netcdf_tmp.nc")
 system("\rm -f /jm13/djv/area_tmp ")
 system("\rm -f *tmp*") ;Remove temporary files
end
