load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; This procedure adds markers to a plot, making sure that each
; set is returned to a unique variable name, and that this
; variable is retained even outside this procedure call.
;
procedure add_markers(wks,plot,x,y,color,type)
local pmres, str
begin
;  print(color)
  pmres = True
  pmres@gsMarkerColor = color
  pmres@gsMarkerIndex = type
  pmres@gsMarkerSizeF = 10.       ;Polymarker size
  pmres@gsMarkerThicknessF = 5.


  str = unique_string("polymarker")  ; "unique_string" will return a unique
                                     ; string every time it is called from
                                     ;  within a single NCL session.
;
; You can then use this unique string as an attribute variable name
; that gets attached to the plot variable. This ensures that this
; value will live for the duration of the script.
;
  plot@$str$ = gsn_add_polymarker(wks, plot, x, y, pmres)
end

;Set the dropsonde satcenter track files and McIdas area file path
dropdir   = "/nfs/jm13/pduran/dropsondes/onr/edit/patricia/20151022/"
satpath   = "/nfs/jm13/pduran/sat/"
outputdir = "/nfs/jm13/pduran/web/"
tablefile = "/nfs/jm13/pduran/sat/tables/coeff.txt"
listfile  = "/nfs/jm13/pduran/dropsondes/onr/edit/patricia/20151022/fullflight"

;Read the satellite coefficient table file
table = readAsciiTable(tablefile,8,"float",(/2,13/))

;Get dropsonde and satellite files
satfiles   = new(2,"string")
satfiles(0)  = satpath+"goes13.2012.258.224519.BAND_04.nc"
satfiles(1) = satpath+"goes13.2015.295.184519.BAND_04.nc"

dropfiles = dropdir+systemfunc("cat "+listfile)

;Get drop latitudes and longitudes
locfiles = dropdir+systemfunc("cat "+listfile)
droplats = new(dimsizes(locfiles),"float")
droplons = new(dimsizes(locfiles),"float")
do i=0,dimsizes(locfiles)-1
   droplats(i) = stringtofloat(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print $3}'")) 
   nfields = stringtoint(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print NF}'"))
   if(nfields.eq.9)then
      droplons(i) = stringtofloat(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print $5}' | sed 's/=//'"))
   else
      droplons(i) = stringtofloat(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print $6}'"))
   end if
end do
;Loop through all drops, find the closest time for each, and plot IR image
ndrops = dimsizes(dropfiles)
;do i=1,ndrops-1
do i=1,dimsizes(satfiles)-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+ndrops+"    `date`")

   ;-------------------------------------------;
   ;            Plot satellite image           ;
   ;-------------------------------------------;
   ;Load netCDF file
   f = addfile(satfiles(i),"r")

   ;Get data from netCDF file
   satdate = f->crDate
   sattime = f->crTime
   ir = f->data(0,:,:)    ;float
   latitude = f->lat      ;float
   longitude = f->lon     ;float
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

   ;Get date and time of drop
   dropyear = "2015"
   dropmon  = "10"
   dropday  = "22"
   droptime = "1946"
   dropdate = dropmon+"/"+dropday+"/"+dropyear

;   drophour = systemfunc("echo "+droptime+" | cut -c 1-2")
   drophour = "00"
;   dropmin  = systemfunc("echo "+droptime+" | cut -c 4-5")
   dropmin =  systemfunc("echo "+droptime+" | cut -c 1-2") 

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
   r = (ir-b)/m
   r:= where(r.le.0,r@_FillValue,r)  ;Where radiance is negative or zero, set to missing

   ;Calculate effective temperature
   ;(First determining whether argument of log is negative; if so, set to missing)
   system("echo Computing effective temperature   `date`")
   arg_before = new(dimsizes(ir),"float")
   arg_before = 1+(c1*n^3)/r
   arg = where((arg_before.eq.0).or.(arg_before.eq.162965.4),arg_before@_FillValue,arg_before)
   Teff = (c2*n)/log(arg)

   ;Calculate brightness temperature
   system("echo Computing brightness temperature   `date`")
   Tb = A+B*Teff
   TbC = Tb-273.15

   ;----------------------;
   ;Give lat and lon units;
   ;----------------------;
   latitude@units="degrees_north"
   longitude@units="degrees_east"

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
   minlat = 10
   maxlat = 20
   minlon = -109.0
   maxlon = -99.0
 
   filename = outputdir+satyear+satmon+satday+"_"+hhmmss+"_ir_fullflight"
   wks = gsn_open_wks("PNG",filename)
 
   ;Get AVN satellite colormap and reverse it for plotting.
   gsn_define_colormap(wks,"avn_extended")
   gsn_reverse_colormap(wks)

   ;Set some plotting resources
   system("echo Plotting image   `date`")
   res = True
   res@gsnAddCyclic = False
   res@sfXArray = longitude
   res@sfYArray = latitude
   res@gsnLeftString = satdate+"  "+sattime
   res@gsnRightString = "Brightness Temperature (~S~o~N~C)"
   res@gsnStringFontHeightF = 0.015
   res@gsnLeftStringOrthogonalPosF = .01
   res@gsnRightStringOrthogonalPosF = .01
 
   res@cnFillOn = True             ;Color fill
   res@cnFillMode = "RasterFill"   ;Raster mode
   res@cnLinesOn = False           ;Turn off contours
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF = -90.
   res@cnMaxLevelValF = 38.
   res@cnLevelSpacingF = 2.
   res@cnLineLabelsOn = False	;Turn off contour labels

   res@gsnSpreadColors = True
   res@gsnSpreadColorStart = 2
   res@gsnSpreadColorEnd = 60

   res@mpMinLatF = minlat
   res@mpMaxLatF = maxlat
   res@mpMinLonF = minlon
   res@mpMaxLonF = maxlon
   res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
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
end do

;Add dropsonde locations
   dum = new(dimsizes(droplats),"graphic")
   do j=0,dimsizes(droplats)-1
      ;Overlay dropsonde location markers
      polyres               = True
      polyres@gsMarkerIndex = 3 ;Polymarker style
      add_markers(wks,plot,droplons(j),droplats(j),"black",polyres@gsMarkerIndex)
   end do

;Add dropsonde location labels
;text = tostring(ispan(1,dimsizes(droplats),1))
;txres = True
;txres@txFont = 30
;txres@txFontHeightF = 0.01
;txres@txFontColor = "black"
;dum = gsn_add_text(wks,plot,text,droplons,droplats,txres)

draw(plot)
frame(wks)
