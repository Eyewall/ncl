load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"

;Set the dropsonde satcenter track files and McIdas area file path
dropdir   = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/20151022/"
satpath   = "/nfs/jm13/pduran/sat/"
outputdir = "/nfs/jm13/pduran/web/"
tablefile = "/nfs/jm13/pduran/sat/tables/coeff.txt"
listfile  = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/20151022/transect1"
type = 1    ;Type of input file. Set to 0 to use a list of .edit files and pull
            ;the drop lats and lons from them. Set to 1 and use the coordfile
            ;variable to read the drop lats and lons from an input file.
labtyp = 1  ;Sonde location label type. Set to 0 for digits; 1 for asterisks.
coordfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/droplocs_parallax_corrected/droplist-loc-1022-plax15-lincorr.dat"
opt = 0     ;Set to 0 to plot a string of dropsonde locations; 1 to plot manual coordinates

;Read the satellite coefficient table file
table = readAsciiTable(tablefile,8,"float",(/2,13/))

;Get dropsonde and satellite files
satfiles   = new(2,"string")
satfiles(0)  = satpath+"goes13.2012.258.224519.BAND_04.nc"
satfiles(1) = satpath+"goes15.2015.295.183017.BAND_04.nc"
dropfiles = dropdir+systemfunc("cat "+listfile)

;Get drop latitudes and longitudes
if(type.eq.0)then
   locfiles = dropdir+systemfunc("cat "+listfile)
   droplats = new(dimsizes(locfiles),"float")
   droplons = new(dimsizes(locfiles),"float")
   do i=0,dimsizes(locfiles)-1
     droplats(i) = stringtofloat(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print $3}'")) 
     droplons(i) = stringtofloat(systemfunc("sed -n 5p "+locfiles(i)+" | awk '{print $5}' | colrm 1 1")) 
   end do
else if(type.eq.1)then
   droplats = stringtofloat(systemfunc("awk '{print $5}' "+coordfile))
   droplons = stringtofloat(systemfunc("awk '{print $4}' "+coordfile))
end if
end if
print(droplats)
print(droplons)
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
   minlat = 13.5;19 - 8.5 
   maxlat = 17.0;19 + 8.5
   minlon = -106.0;-105.3 - 8.5 
   maxlon = -102.5;-105.3 + 8.5
 
   filename = outputdir+satyear+satmon+satday+"_"+hhmmss+"_ir_new"
   if(opt.eq.0)then
      wks = gsn_open_wks("PNG",filename)
   else
      wks = gsn_open_wks("png",outputdir+"20151022_centerlocs")
   end if
 
   ;Get AVN satellite colormap and reverse it for plotting.
   gsn_define_colormap(wks,"avn_extended")
   gsn_reverse_colormap(wks)

   ;Set some plotting resources
   system("echo Plotting image   `date`")
   res = True
   res@gsnAddCyclic = False
   res@sfXArray = longitude
   res@sfYArray = latitude
;   res@tiXAxisString = "Degrees Longitude"
;   res@gsnLeftString = satdate+"  "+sattime
   res@gsnLeftString = "b) GOES-15   22 October   1830 UTC"
;   res@gsnRightString = "Brightness Temperature (~S~o~N~C)"
   res@tiMainFontHeightF = 0.015
   res@tiXAxisFontHeightF = 0.014
   res@tiYAxisFontHeightF = 0.014
   res@tiYAxisOffsetXF    = -0.08
   res@tiXAxisOffsetYF    = -0.06
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
;   res@tmXBLabelAngleF = 90.
   print("!!!!!IGNORE ANY TickMarkSetValues WARNING MESSAGES!!!!!")

   res@gsnMaximize = True 
   res@gsnDraw  = False		;So we can add poly stuff
   res@gsnFrame = False
   plot = gsn_csm_contour_map(wks,TbC(:,:),res)

   cnres = res
   cnres@cnFillOn = False
   cnres@cnLinesOn = True
   cnres@cnInfoLabelOn = False
   cnres@gsnLeftString = " "
   cnres@cnLevelSelectionMode = "ExplicitLevels"
   cnres@cnLevels = (/-82,-84,-86,-88/)
   cnres@cnLineThicknessF = 3.
;   cnres@cnLineLabelsOn = True
;   cnres@cnLineLabelPlacementMode = "constant"
;   cnres@cnLineLabelInterval = 2.
;   cnres@cnLineLabelDensityF = 2.
   cnplot = gsn_csm_contour(wks,TbC,cnres)
end do

;Add dropsonde location labels
if(opt.eq.0)then
   if(labtyp.eq.0)then
      text = tostring(ispan(1,dimsizes(droplats),1))
      txres = True
      txres@txFont = 30
      txres@txFontHeightF = 0.01
      txres@txFontColor = "black"
      dum = gsn_add_text(wks,plot,text,droplons,droplats,txres)
   else if(labtyp.eq.1)then
      dum = new(dimsizes(droplats),"graphic")
      do j=0,dimsizes(droplats)-1
         ;Overlay dropsonde location markers
         polyres               = True
         polyres@gsMarkerIndex = 3 ;Polymarker style
         if(j.eq.13)then
            add_markers(wks,plot,droplons(j),droplats(j),"cyan",10,5,polyres@gsMarkerIndex)
         else
            add_markers(wks,plot,droplons(j),droplats(j),"black",10,5,polyres@gsMarkerIndex)
         end if
      end do
   end if
   end if
else        ;Reset locations from sonde locs to manual coords
   droplats := (/15.18,15.14/)
   droplons := (/-104.09,-104.03/)
   polyres = True
   polyres@gsMarkerIndex = 3
   ;The first sonde location will be green, the second will be black
   add_markers(wks,plot,droplons(0),droplats(0),"green",20,10,polyres@gsMarkerIndex)
   add_markers(wks,plot,droplons(1),droplats(1),"black",20,10,polyres@gsMarkerIndex)
end if

overlay(plot,cnplot)
draw(plot)
frame(wks)
