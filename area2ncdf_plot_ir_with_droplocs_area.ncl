load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;Set the dropsonde and center track files and McIdas area file path
dropdir  = "/jm13/pduran/dropsondes/hs3/"
trakfile = "/jm13/pduran/hs3/hs3_stormtracks"
satpath  = "/jm13/djv/ivan04/mcidas/merc/*BAND_04"

;Read the list of dropsondes into an array
dropfiles = systemfunc("ls "+dropdir+"*.eol")
print(dropfiles)

;Read the list of area files into an array
system("ls "+satpath+" > areafilelist.tmp")
nrows = stringtoint(systemfunc("cat areafilelist.tmp | wc | awk '{print $1}'"))
areafiles = asciiread("areafilelist.tmp",(/nrows/),"string")

;Read the trackfile into an array
nrows = stringtoint(systemfunc("cat "+trakfile+" | wc | awk '{print $1}'"))
ncols = stringtoint(systemfunc("awk -F' ' '{print NF ; exit}' "+trakfile+""))
trackarray = asciiread(trakfile,(/nrows,ncols/),"float")
trackcol1  = trackarray(:,0)  ;Times
trackcol2  = trackarray(:,1)  ;Dates
trackcol3  = trackarray(:,2)  ;Latitudes
trackcol4  = trackarray(:,3)  ;Longitudes
trackcol7  = trackarray(:,6)  ;Maximum wind speed

;Get the number of drops and satellite area files
ndrops = dimsizes(droparray)
nareas = dimsizes(areafiles)

;---------------------------------------------------------;
;Convert drop date and time to Julian and stuff into array;
;---------------------------------------------------------;
julian_minutes = new(ndrops,double)  ;Allocate memory
dattim         = new(ndrops,string)
dropid         = new(ndrops,string)
latf           = new(ndrops,float)
lonf           = new(ndrops,float)
tracklat       = new(ndrops,float)
tracklon       = new(ndrops,float)
maxwinds       = new(ndrops,float)
drop = 0                             ;Initialize drop count
do while(drop.lt.ndrops)             ;Loop through drops
   ;Get drop info
   dropsplit = str_split(droparray(drop), "	")
   dropidsplit = dropsplit(2)
   dropid(drop) = dropidsplit
   dattimslash = dropsplit(3)
   dattimsplit = str_split(dattimslash, "/")
   dattim(drop) = dattimsplit(0)+"_"+dattimsplit(1)
   date   = dattimsplit(0)
   time   = dattimsplit(1)
   lat    = dropsplit(4)
   lon    = dropsplit(5)
   latf(drop)   = stringtofloat(lat)
   lonf(drop)   = stringtofloat(lon)

   ;Get year, month, and day of sonde drop from date string
   datesplit = str_split_by_length(date,2)
   yearsplit = (/"20",datesplit(0)/)
   timesplit = str_split_by_length(time,2)
   year  = str_concat(yearsplit(0:1))
   month = datesplit(1)
   day   = datesplit(2)
   hour  = timesplit(0)
   minu   = timesplit(1)

   ;Convert strings to integers (minutes to doubles)
   yeari  = stringtoint(year)
   monthi = stringtoint(month)
   dayi   = stringtoint(day)   
   houri  = stringtoint(hour)
   minui  = stringtodouble(minu)

   ;Calculate Julian date of sonde drop and shove into array
   julian = greg2jul(yeari,monthi,dayi,houri)
   julian_minutes(drop) = julian + minui/1440      ;Julian date of sonde drop

   ;-----------------------------------------------------;
   ;While we're here, let's get track data from trackfile;
   ;-----------------------------------------------------;
   trackdate1 = month+day+yearsplit(1)
   trackdate2 = str_concat(trackdate1)
   trackdate  = stringtofloat(trackdate2)      ;Convert to float so can be used in dateind below
   tracktime1 = hour+minu
   tracktime  = stringtofloat(tracktime1)      ;Convert to float so can be used in timeind below
   trakline   = ind((trackcol1 .eq. tracktime).and.(trackcol2 .eq. trackdate))
   dattim(drop)   = year+month+day+(/"_"/)+hour+minu
   tracklat(drop) = trackcol3(trakline)
   tracklon(drop) = trackcol4(trakline)
   maxwinds(drop) = trackcol7(trakline)

   drop = drop + 1   ;Iterate loop counter
end do

;--------------------------------------------------------------;
;Convert area file date and time to Julian and stuff into array;
;--------------------------------------------------------------;
areajulian_minutes = new(nareas,double)   ;Create the array
;tracklat           = new(ndrops,double)
;tracklon           = new(ndrops,double)
areanum = 0                               ;Initialize loop counter
do while(areanum .lt. nareas)             ;Loop through area files
   ;Get area file date and time
   areapathsplit = str_split(areafiles(areanum), "/")
   areafilesplit = str_split(areafiles(areanum), ".")
   areaday  = areafilesplit(2)
   areatim  = str_split_by_length(areafilesplit(3),2)
   areahour = areatim(0)
   areaminu = areatim(1)

   ;Convert day and hour to integers and minutes to doubles
   areadayi  = stringtoint(areaday)
   areahouri = stringtoint(areahour)
   areaminui = stringtodouble(areaminu)

   ;Convert yyyyddd to yyyymmdd format
   yyyydddsplit = (/yeari(0),areadayi(0)/)
   yyyyddd = str_concat(yyyydddsplit(0:1))
   yyyydddint = stringtoint(yyyyddd)
   areadate = yyyyddd_to_yyyymmdd(yyyydddint)

   ;Convert to Julian day as above and write to array
   areadatesplit = str_split_by_length(areadate,2)
   areayear  = areafilesplit(1)
   areayear2digit1 = str_split_by_length(areayear,2)
   areayear2digit  = areayear2digit1(1)
   areamonth = areadatesplit(2)
   areaday   = areadatesplit(3)
   areayeari  = stringtoint(areayear)
   areamonthi = stringtoint(areamonth)
   areadayi   = stringtoint(areaday)    
   areajulian = greg2jul(areayeari,areamonthi,areadayi,areahouri)
   areajulian_minutes(areanum) = areajulian + areaminui/1440  ;Julian date of area file

   areanum = areanum + 1   ;Iterate loop counter
end do

;----------------------------------------------------------;
;Find the area file which most closely matches time of drop;
;----------------------------------------------------------;
;Set up an array containing indices of areajulian_minutes
;which correspond to the area file time which is closest
;to the drop time.
mindifference_indices = new(ndrops,integer)
drop = 0                        
do while(drop .lt. ndrops)      
   differences = abs(areajulian_minutes - julian_minutes(drop))
   mindifference_indices(drop) = minind(differences)
   drop = drop + 1
end do

;-------------------------------------------;
;    Now proceed to plot satellite image    ;
;-------------------------------------------;
drop = 0
do while(drop .lt. ndrops)
   ;Copy area file to pwd and convert to netCDF
   areafile = areafiles(mindifference_indices(drop))
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
   minlat = tracklat(drop) - 15. 
   maxlat = tracklat(drop) + 15.
   minlon = tracklon(drop) - 15. 
   maxlon = tracklon(drop) + 15.

   wks = gsn_open_wks("PNG", dattim(drop))

   ;Set workspace maximum size
   setvalues NhlGetWorkspaceObjectId()
      "wsMaximumSize" : 100000000
   end setvalues

   ;Set some plotting resources
   res = True
   res@gsnAddCyclic = False
   res@sfXArray = longitude
   res@sfYArray = latitude
   res@gsnLeftString = "Hurricane Ivan "+dattim(drop)
   res@gsnRightString = "Drop ID: "+dropid(drop)
   res@gsnStringFontHeightF = 0.015

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

print(lonf(drop))
print(latf(drop))

   ;Plot the image
   polyres               = True
   polyres@gsMarkerIndex = 5	;Polymarker style
   polyres@gsMarkerSizeF = 20.	;Polymarker size
   polyres@gsMarkerColor   = "magenta"
   polyres@gsMarkerThicknessF = 5.
   plot = gsn_csm_contour_map(wks,ir(:,:),res)
   dum1 = gsn_add_polymarker(wks,plot,lonf(drop),latf(drop),polyres)
   draw(plot)
   frame(wks)

   drop   = drop + 1 ;Iterate loop counter
end do

system("\rm -f *tmp*") ;Remove temporary files
