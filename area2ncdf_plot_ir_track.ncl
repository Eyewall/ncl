load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;NOTE THAT I HAVE ADDED A LEADING ZERO IN LINE 51 BECAUSE WE ASSUME A 1-DIGIT MONTH. IF IN A 2-DIGIT MONTH, REMOVE LEADING ZERO.
;Set the center track and intensity files and McIdas area file path
trakfile  = "/jm13/pduran/sandy/sandy1min_besttrack.txt"
satpath   = "/jm13/pduran/sandy/mcidas/BAND_04/"
intensity = "/jm13/pduran/sandy/sandy_intensity.txt"
;trakfile   = "/jm13/pduran/ivan/ivan1min_besttrack.txt"
;satpath    = "/jm13/pduran/ivan/area/BAND_04/"
;intensity  = "/jm13/pduran/ivan/ivan_intensity.txt"

;Read the list of area files into an array
system("ls "+satpath+" > areafilelist.tmp")
nrows = stringtoint(systemfunc("cat areafilelist.tmp | wc | awk '{print $1}'"))
areafiles = asciiread("areafilelist.tmp",(/nrows/),"string")

;Read the trackfile into an array
nrowstrak = stringtoint(systemfunc("cat "+trakfile+" | wc | awk '{print $1}'"))
ncols = stringtoint(systemfunc("awk -F' ' '{print NF ; exit}' "+trakfile+""))
trakarray = asciiread(trakfile,(/nrowstrak/),"string")

;Read the intensity data into an array
system("cat "+intensity+" | sed 's/,//g' | colrm 15 15 > intensity.tmp")
nrowsint = stringtoint(systemfunc("cat intensity.tmp | wc | awk '{print $1}'"))
intensity_array = asciiread("intensity.tmp",(/nrowsint/),"string")

;Get the number of satellite area files
nareas = dimsizes(areafiles)

;------------------------;
;Get satellite image info;
;------------------------;
areayear       = new(nrows,integer)
areahour       = new(nrows,integer)
areamin        = new(nrows,double)
areatimestring = new(nrows,string)
areamonth      = new(nrows,integer)
areaday        = new(nrows,integer)
dattim         = new(nrows,string)
area = 0                             ;Initialize area count
do while(area.lt.nareas)             ;Loop through areas
   areasplit            = str_split(areafiles(area), ".")
   areayear(area)       = stringtoint(areasplit(1))
   areaday1             = stringtoint(areasplit(2))
   areatimestring(area) = areasplit(3)
   areatimsplit         = str_split_by_length(areasplit(3),2)
   areahour(area)       = stringtoint(areatimsplit(0))
   areamin(area)        = stringtoint(areatimsplit(1))
   ;monday               = str_split_by_length("0"+monthday(areayear(area),areaday1),2)
   monday               = str_split_by_length(monthday(areayear(area),areaday1),2)
   areamonth(area)      = stringtoint(monday(0))
   areaday(area)        = stringtoint(monday(1))
   dattim(area)         = areayear(area)+monday(0)+monday(1)+"_"+areatimestring(area)
   area = area + 1
end do

;--------------;
;Get track info;
;--------------;
trakmonth      = new(nrowstrak,integer)
trakday        = new(nrowstrak,integer)
trakyear       = new(nrowstrak,integer)
trakhour       = new(nrowstrak,integer)
trakmin        = new(nrowstrak,double)
traktimestring = new(nrowstrak,string)
traklat        = new(nrowstrak,float)
traklon        = new(nrowstrak,float)
trakrow = 0
do while(trakrow.lt.nrowstrak)
   traksplit = str_split(trakarray(trakrow), " ")
   datesplit = str_split(traksplit(0), "/")
   trakmonth(trakrow) = stringtoint(datesplit(0))
   trakday(trakrow)   = stringtoint(datesplit(1))
   trakyear(trakrow)  = stringtoint(datesplit(2)) + 2000
   trakhour(trakrow)  = stringtoint(traksplit(1))
   trakmin(trakrow)   = stringtoint(traksplit(2))
   traklat(trakrow)   = stringtofloat(traksplit(3))
   traklon(trakrow)   = stringtofloat(traksplit(4))
   trakrow = trakrow + 1
end do

;------------------;
;Get intensity info;
;------------------;
intensityyear  = new(nrowsint,integer)
intensitymonth = new(nrowsint,integer) 
intensityday   = new(nrowsint,integer)
intensityhour  = new(nrowsint,integer)
intensityclass = new(nrowsint,string)
vmax           = new(nrowsint,string)
pmin           = new(nrowsint,string)
introw = 0
do while(introw.lt.nrowsint)
   intsplit               = str_split(intensity_array(introw), " ")
   datesplitint           = str_split_by_length(intsplit(0),2)
   intensityyear(introw)  = stringtoint(str_concat(datesplitint(0:1)))
   intensitymonth(introw) = stringtoint(datesplitint(2))
   intensityday(introw)   = stringtoint(datesplitint(3))
   intensitytimesplit     = str_split_by_length(intsplit(1),2)
   intensityhour(introw)  = stringtoint(intensitytimesplit(0))
   intensityclass(introw) = intsplit(2)
   vmax(introw)           = intsplit(5)
   pmin(introw)           = intsplit(6)
   introw = introw + 1
end do

;-----------------------------;
;Convert dates/times to Julian;
;-----------------------------;
areatimejul = greg2jul(areayear,areamonth,areaday,areahour) + areamin/1400
traktimejul = greg2jul(trakyear,trakmonth,trakday,trakhour) + trakmin/1400
inttimejul  = greg2jul(intensityyear,intensitymonth,intensityday,intensityhour)

;-------------------------------------------------------------------------------;
;Find the indices of the intensity array which correspond to the area file times;
;-------------------------------------------------------------------------------;
areatime                  = new(nrowsint,double)
difference                = new(nrowsint,double)
mindifference_indices_int = new(area,integer)
mindifference_indices_int@_FillValue = 0
area = 0
do while(area.lt.nareas)
   areatime   = areatimejul(area)
   difference = areatime - inttimejul
   mindifference_indices_int(area) = min(ind((difference.gt.0).and.(difference.lt.0.25)))
   area = area + 1
end do

;--------------------------------------------------------------------;
;Find the indices of the trakfile array and the corresponding Julian ;
;times which correspond to the time of each area file.               ;
;--------------------------------------------------------------------;
differences           = new(nrowstrak,double)
mindifference_indices = new(nareas,integer)
traktimejul_reduced   = new(nareas,double)
area = 0
do while(area.lt.nareas)
   trak = 0
      do while(trak.lt.nrowstrak)
         differences(trak) = abs(areatimejul(area) - traktimejul(trak))
	 trak = trak + 1
      end do
   mindifference_indices(area) = minind(differences)
   traktimejul_reduced(area) = traktimejul(mindifference_indices(area))
   area = area + 1
end do

;-------------------------------------;
;Now proceed to plot satellite imagery;
;-------------------------------------;
area = 0
do while(area.lt.nareas)
   ;Get maximum wind speed, minimum pressure, and storm category from intensity file
   maxwind  = vmax(mindifference_indices_int(area))
   minpres  = pmin(mindifference_indices_int(area))
   category = intensityclass(mindifference_indices_int(area))
   if (category.eq."HU") then
      cat = "Hurricane Sandy"
   else if (category.eq."TS") then
      cat = "TS Sandy"
   else if (category.eq."TD") then
      cat = "TD 18"
   else if (category.eq."LO") then
      cat = "Pre-Sandy Low"
   else if (category.eq."EX") then
      cat = "EX Sandy"
   end if
   end if
   end if
   end if
   end if

   ;Copy area file to pwd and convert to netCDF
   area = area + 1
   print("Plotting image "+area+" of "+nareas)
   area = area - 1
   areafile = satpath+areafiles(area)
   system("cp "+areafile+" ./area_tmp")
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

   ;Define domain of plot
   minlat = traklat(mindifference_indices(area)) - 10. 
   maxlat = traklat(mindifference_indices(area)) + 10.
   minlon = traklon(mindifference_indices(area)) - 10. 
   maxlon = traklon(mindifference_indices(area)) + 10.

   wks = gsn_open_wks("PNG", dattim(area))

   ;Set worksheet background color
   setvalues wks
      "wkBackgroundColor" : "white"
      "wkForegroundColor" : "black"
   end setvalues

   ;Set workspace maximum size
   setvalues NhlGetWorkspaceObjectId()
      "wsMaximumSize" : 100000000
   end setvalues

   ;Set some plotting resources
   res = True
   res@gsnAddCyclic = False
   res@sfXArray = longitude
   res@sfYArray = latitude
   res@gsnLeftString = cat+"     Date_Time: "+dattim(area)
   res@gsnRightString = "Vmax (kt): "+maxwind+"     Pmin (mb): "+minpres
   res@gsnStringFontHeightF = 0.01

   res@cnFillOn = True             ;Color fill
   res@cnFillMode = "RasterFill"   ;Raster mode
   res@cnLinesOn = False           ;Turn off contours
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF      = 0.
   res@cnMaxLevelValF      = 220.
   res@cnLevelSpacingF = 2.0       ;Contour interval

   res@mpMinLatF = minlat
   res@mpMaxLatF = maxlat
   res@mpMinLonF = minlon
   res@mpMaxLonF = maxlon

   res@lbLabelBarOn   = False	;Turn off color label bar
   res@cnLineLabelsOn = False	;Turn off contour labels

   res@gsnDraw  = False		;So we can add poly stuff
   res@gsnFrame = False

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
   gsn_define_colormap(wks, colors)

   ;Plot the image
   plot = gsn_csm_contour_map(wks,ir(:,:),res)
   draw(plot)
   frame(wks)

   area = area + 1 ;Iterate loop counter
   system("\rm -f area_tmp netcdf_tmp.nc")
   delete(ir)
   delete(latitude)
   delete(longitude)
   delete(res@sfXArray)
   delete(res@sfYArray)

end do

system("\rm -f *tmp*") ;Remove temporary files
