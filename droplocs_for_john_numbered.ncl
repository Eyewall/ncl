load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; This procedure adds markers to a plot, making sure that each
; set is returned to a unique variable name, and that this
; variable is retained even outside this procedure call.
;
procedure add_markers(wks,plot,x,y,color,type,size)
local pmres, str
begin
  print(color)
  pmres = True
  pmres@gsMarkerColor = color
  pmres@gsMarkerIndex = type
  pmres@gsMarkerSizeF = size       ;Polymarker size
  pmres@gsMarkerThicknessF = 10.


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
dropdir   = "/nfs/jm13/pduran/dropsondes/hs3/edit/onedir/"
trakfile  = "/jm13/pduran/hs3/ascii/hs3_stormtracks"
satpath   = "/jm13/pduran/sat/"
outputdir = "/jm13/pduran/web/"
tablefile = "/jm13/pduran/sat/tables/coeff.txt"
listfile  = "/nfs/jm13/pduran/dropsondes/hs3/edit/2012/nadine2/transect_abstract2"
outdir    = "/jm13/pduran/web/"

;Read the satellite coefficient table file
table = readAsciiTable(tablefile,8,"float",(/2,13/))

;Get dropsonde and satellite files
;dropfiles = new(2,"string")
satfiles   = new(2,"string")
;dropfiles(0) = dropdir+"A78-151022-1945-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
;dropfiles(1) = dropdir+"A79-151022-1946-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit"
satfiles(0)  = satpath+"goes13.2012.258.224519.BAND_04.nc"
;satfiles(1)  = satpath+"goes13.2012.259.001519.BAND_04.nc" 
satfiles(1)  = satpath+"goes13.2012.259.031519.BAND_04.nc"
dropfiles = dropdir+systemfunc("cat "+listfile)

;Read the trackfile into an array
;nrows = stringtoint(systemfunc("wc "+trakfile+" | awk '{print $1}'"))
;ncols = 6
;trackarray = asciiread(trakfile,(/nrows,ncols/),"float")
;trackdate = trackarray(:,0)  ;Times
;tracktime = trackarray(:,1)  ;Dates
;tracklat  = trackarray(:,2)  ;Latitudes
;tracklon  = trackarray(:,3)  ;Longitudes
;trackmaxV = trackarray(:,4)  ;Maximum wind speed
;trackminP = trackarray(:,5)  ;Minimum sea level pressure 

;Get drop latitudes and longitudes
locfiles = dropdir+systemfunc("cat "+listfile)
droplats = new(dimsizes(locfiles),"float")
droplons = new(dimsizes(locfiles),"float")
do i=0,dimsizes(locfiles)-1
  droplats(i) = stringtofloat(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print $3}'")) 
  droplons(i) = stringtofloat(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print $6}'")) 
;  droplons(i) = stringtofloat(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print $5}' | colrm 1 1")) 
end do

;Hard code drop locations
;droplats = (/31.72,31.72,31.72,31.72,31.72,31.57,30.00,30.03,29.85,28.05,28.01,28.01,28.01/)
;droplats = (/31.72,31.72,31.72,31.72,31.57,30.00,30.03,29.85,28.05,28.01,28.01,28.01/)
;droplons = (/-57.21,-55.844,-54.13,-52.28,-50.71,-49.59,-49.07,-47.47,-45.93,-46.10,-47.65,-49.09,-50.57/)
;droplons = (/-55.844,-54.13,-52.28,-50.71,-49.59,-49.07,-47.47,-45.93,-46.10,-47.65,-49.09,-52.21/)

;Loop through all drops, find the closest time for each, and plot IR image
ndrops = dimsizes(dropfiles)
nsatfiles = dimsizes(satfiles)
do i=1,nsatfiles-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+nsatfiles+"    `date`")

   ;-------------------------------------------;
   ;    Now proceed to plot satellite image    ;
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
   satmon = systemfunc("echo "+satdate+" | cut -c 1")
   satday := systemfunc("echo "+satdate+" | colrm 1 1")
   satdate := satmon+"/"+satday+"/"+satyear
   sathr  = systemfunc("echo "+sattime+" | cut -c 1-2")
   satmin = systemfunc("echo "+sattime+" | cut -c 3-4")
   sattime := sathr+":"+satmin+" UTC"

   ;NOTE: Using the netCDF time variable doesn't work well if the hour is 00 because
   ;      it reads as a float and chops off the hour. Instead, we'll get the sattime
   ;      from the sat filename, but note that this won't work if the satfile string
   ;      differs from that which is assumed here.
   sathour  := systemfunc("echo "+satfiles(i)+" | awk -F '/' '{print $NF}' | cut -c 17-18")
   satmin   := systemfunc("echo "+satfiles(i)+" | awk -F '/' '{print $NF}' | cut -c 19-20")
   sattime  := sathr+":"+satmin+" UTC"
   
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
   r = (ir-b)/m

   ;Calculate effective temperature
   ;(First determining whether argument of log is negative; if so, set to missing)
   arg_before = new(dimsizes(ir),"float")
   arg_before = 1+(c1*n^3)/r
   arg = where((arg_before.eq.0).or.(arg_before.eq.162965.4),arg_before@_FillValue,arg_before)
   Teff = (c2*n)/log(arg)

   ;Calculate brightness temperature
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
   minlat = 30 - 8.5 
   maxlat = 30 + 8.5
   minlon = -52 - 8.5
   maxlon = -52 + 8.5

   ;Define workstation 
   filename = outdir+satyear+satmon+satday+"_"+sathour+satmin+"_ir"
print(filename)
   wks = gsn_open_wks("PNG",filename)
   gsn_define_colormap(wks,"avn_extended")
   gsn_reverse_colormap(wks)
 
   ;Set workspace maximum size
   setvalues NhlGetWorkspaceObjectId()
      "wsMaximumSize" : 100000000
   end setvalues

   ;Set some plotting resources
   res = True
   res@gsnAddCyclic = False
   res@sfXArray = longitude
   res@sfYArray = latitude
   res@gsnLeftString = satdate+"  "+sathour+":"+satmin+" UTC"
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

   res@gsnSpreadColors = True
   res@gsnSpreadColorStart = 2
   res@gsnSpreadColorEnd = 60

   res@mpMinLatF = minlat
   res@mpMaxLatF = maxlat
   res@mpMinLonF = minlon
   res@mpMaxLonF = maxlon
   res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
   res@mpGeophysicalLineThicknessF = 2.5
   res@mpGeophysicalLineColor = "Orange"
   res@mpUSStateLineColor = "Orange"
 
   res@lbLabelStride = 5.
   res@lbTitleOn = False
   res@lbTitleString = "~S~o~N~C" ;Deg C
   res@lbTitleFontHeightF = 0.013
   res@lbLabelFontHeightF = 0.013
   res@lbOrientation = "Vertical"
   res@lbBoxMinorExtentF = 0.1
   res@pmLabelBarOrthogonalPosF = 0.005

   res@cnLineLabelsOn = False	;Turn off contour labels
   res@tmXTOn = False
   res@tmYROn = True
   res@tmXBLabelFontHeightF = 0.013
   res@tmYLLabelFontHeightF = 0.013

   res@gsnMaximize = True 
   res@gsnDraw  = False		;So we can add poly stuff
   res@gsnFrame = False
   plot = gsn_csm_contour_map(wks,TbC(:,:),res)
end do

;   markercolors = new(dimsizes(droplats),"string")
;   markercolors = "black"
;   markercolors(0) = "magenta"
;   markercolors(2) = "red"

;   dum = new(dimsizes(droplats),"graphic")
;   do j=0,dimsizes(droplats)-1
;      ;Overlay dropsonde location markers
;      polyres               = True
;      polyres@gsMarkerIndex = 3	;Polymarker style
;      polyres@gsMarkerSizeF = 30.	;Polymarker size
;      polyres@gsMarkerColor   = markercolors(j)
;      polyres@gsMarkerThicknessF = 10.
;      add_markers(wks,plot,droplons(j),droplats(j),markercolors(j),polyres@gsMarkerIndex,polyres@gsMarkerSizeF)
;   end do

   text = tostring(ispan(1,dimsizes(droplats),1))
   txres = True
   txres@txFont = 30
   txres@txFontHeightF = 0.025
   txres@txFontColor = "black"
   dum = gsn_add_text(wks,plot,text,droplons,droplats,txres)
   draw(plot)
   frame(wks)
   delete([/ir,latitude,longitude,r,arg_before,arg,Teff,Tb,TbC,res/])
;   delete([/dropdata,lats,lons/])
