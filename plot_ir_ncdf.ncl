load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;Set the center track and intensity files and McIdas ncdf file path
trakfile  = "/jm13/pduran/sandy/sandy1min_besttrack.txt"
satpath   = "/jm13/pduran/20140326_case/"
intensity = "/jm13/pduran/sandy/sandy_intensity.txt"

;Read the list of NetCDF files into an array
system("ls "+satpath+"*BAND_04.nc > ncdffilelist.tmp")
nrows = stringtoint(systemfunc("cat ncdffilelist.tmp | wc | awk '{print $1}'"))
ncdffiles = asciiread("ncdffilelist.tmp",(/nrows/),"string")

;Read the trackfile into an array
nrowstrak = stringtoint(systemfunc("cat "+trakfile+" | wc | awk '{print $1}'"))
ncols = stringtoint(systemfunc("awk -F' ' '{print NF ; exit}' "+trakfile+""))
trakarray = asciiread(trakfile,(/nrowstrak/),"string")

;Read the intensity data into an array
system("cat "+intensity+" | sed 's/,//g' | colrm 15 15 > intensity.tmp")
nrowsint = stringtoint(systemfunc("cat intensity.tmp | wc | awk '{print $1}'"))
intensity_array = asciiread("intensity.tmp",(/nrowsint/),"string")

;Get the number of satellite ncdf files
nncdfs = dimsizes(ncdffiles)

;------------------------;
;Get satellite image info;
;------------------------;
ncdfyear       = new(nrows,integer)
ncdfhour       = new(nrows,integer)
ncdfmin        = new(nrows,double)
ncdftimestring = new(nrows,string)
ncdfmonth      = new(nrows,integer)
ncdfday        = new(nrows,integer)
dattim         = new(nrows,string)
ncdf = 0                             ;Initialize ncdf count
do while(ncdf.lt.nncdfs)             ;Loop through ncdfs
   ncdfsplit            = str_split(ncdffiles(ncdf), ".")
   ncdfyear(ncdf)       = stringtoint(ncdfsplit(1))
   ncdfday1             = stringtoint(ncdfsplit(2))
   ncdftimestring(ncdf) = ncdfsplit(3)
   ncdftimsplit         = str_split_by_length(ncdfsplit(3),2)
   ncdfhour(ncdf)       = stringtoint(ncdftimsplit(0))
   ncdfmin(ncdf)        = stringtoint(ncdftimsplit(1))
   monday               = str_split_by_length(monthday(ncdfyear(ncdf),ncdfday1),2)
   ncdfmonth(ncdf)      = stringtoint(monday(0))
   ncdfday(ncdf)        = stringtoint(monday(1))
   dattim(ncdf)         = ncdfyear(ncdf)+monday(0)+monday(1)+"_"+ncdftimestring(ncdf)
   ncdf = ncdf + 1
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
;intensityyear  = new(nrowsint,integer)
;intensitymonth = new(nrowsint,integer) 
;intensityday   = new(nrowsint,integer)
;intensityhour  = new(nrowsint,integer)
;intensityclass = new(nrowsint,string)
;vmax           = new(nrowsint,string)
;pmin           = new(nrowsint,string)
;introw = 0
;do while(introw.lt.nrowsint)
;   intsplit               = str_split(intensity_array(introw), " ")
;   datesplitint           = str_split_by_length(intsplit(0),2)
;   intensityyear(introw)  = stringtoint(str_concat(datesplitint(0:1)))
;   intensitymonth(introw) = stringtoint(datesplitint(2))
;   intensityday(introw)   = stringtoint(datesplitint(3))
;   intensitytimesplit     = str_split_by_length(intsplit(1),2)
;   intensityhour(introw)  = stringtoint(intensitytimesplit(0))
;   intensityclass(introw) = intsplit(2)
;   vmax(introw)           = intsplit(5)
;   pmin(introw)           = intsplit(6)
;   introw = introw + 1
;end do

;-----------------------------;
;Convert dates/times to Julian;
;-----------------------------;
;ncdftimejul = greg2jul(ncdfyear,ncdfmonth,ncdfday,ncdfhour) + ncdfmin/1400
;traktimejul = greg2jul(trakyear,trakmonth,trakday,trakhour) + trakmin/1400
;inttimejul  = greg2jul(intensityyear,intensitymonth,intensityday,intensityhour)

;-------------------------------------------------------------------------------;
;Find the indices of the intensity array which correspond to the ncdf file times;
;-------------------------------------------------------------------------------;
;ncdftime                  = new(nrowsint,double)
;difference                = new(nrowsint,double)
;mindifference_indices_int = new(ncdf,integer)
;mindifference_indices_int@_FillValue = 0
;ncdf = 0
;do while(ncdf.lt.nncdfs)
;   ncdftime   = ncdftimejul(ncdf)
;   difference = ncdftime - inttimejul
;   mindifference_indices_int(ncdf) = min(ind((difference.gt.0).and.(difference.lt.0.25)))
;   ncdf = ncdf + 1
;end do
;
;;--------------------------------------------------------------------;
;;Find the indices of the trakfile array and the corresponding Julian ;
;;times which correspond to the time of each ncdf file.               ;
;;--------------------------------------------------------------------;
;differences           = new(nrowstrak,double)
;mindifference_indices = new(nncdfs,integer)
;traktimejul_reduced   = new(nncdfs,double)
;ncdf = 0
;do while(ncdf.lt.nncdfs)
;   trak = 0
;      do while(trak.lt.nrowstrak)
;         differences(trak) = abs(ncdftimejul(ncdf) - traktimejul(trak))
;	 trak = trak + 1
;      end do
;   mindifference_indices(ncdf) = minind(differences)
;   traktimejul_reduced(ncdf) = traktimejul(mindifference_indices(ncdf))
;   ncdf = ncdf + 1
;end do

;-------------------------------------;
;Now proceed to plot satellite imagery;
;-------------------------------------;
ncdf = 0
do while(ncdf.lt.nncdfs)
   ;Get maximum wind speed, minimum pressure, and storm category from intensity file
;   maxwind  = vmax(mindifference_indices_int(ncdf))
;   minpres  = pmin(mindifference_indices_int(ncdf))
;   category = intensityclass(mindifference_indices_int(ncdf))
;   if (category.eq."HU") then
;      cat = "Hurricane Sandy"
;   else if (category.eq."TS") then
;      cat = "TS Sandy"
;   else if (category.eq."TD") then
;      cat = "TD 18"
;   else if (category.eq."LO") then
;      cat = "Pre-Sandy Low"
;   else if (category.eq."EX") then
;      cat = "EX Sandy"
;   end if
;   end if
;   end if
;   end if
;   end if

   ;Copy netCDF file to PWD
   system("cp "+ncdffiles(ncdf)+" ./netcdf_tmp.nc") 
   qqqq = satpath+ncdffiles(ncdf)

   ;Load netCDF file
   f = addfile("netcdf_tmp.nc","r")
        
   ;Get data from netCDF file
   ir = f->data(0,:,:)    ;float
   latitude = f->lat      ;float
   longitude = f->lon     ;float
   yyddd = f->imageDate   ;int
   hhmmss = f->imageTime  ;int
   sat = f->sensorID      ;char

   ;Give lat and lon units
   latitude@units="degrees_north"
   longitude@units="degrees_east"

   ;Define domain of plot
;   minlat = traklat(mindifference_indices(ncdf)) - 15. 
;   maxlat = traklat(mindifference_indices(ncdf)) + 15.
;   minlon = traklon(mindifference_indices(ncdf)) - 15. 
;   maxlon = traklon(mindifference_indices(ncdf)) + 15.

   minlat = 0
   maxlat = 20
   minlon = -95
   maxlon = -65

   wks = gsn_open_wks("PNG", dattim(ncdf))

   ;Set workspace maximum size
   setvalues NhlGetWorkspaceObjectId()
      "wsMaximumSize" : 100000000
   end setvalues

   ;Set some plotting resources
   res = True
   res@gsnAddCyclic = False
   res@sfXArray = longitude
   res@sfYArray = latitude
   res@gsnLeftString = "Date_Time: "+dattim(ncdf)
;   res@gsnRightString = "Vmax (kt): "+maxwind+"     Pmin (mb): "+minpres
   res@gsnStringFontHeightF = 0.01

maxrad = max(ir)
minrad = min(ir)
print(maxrad)
print(minrad)

   res@gsnMaximize = True
   res@cnFillOn = True             ;Color fill
   res@cnFillMode = "RasterFill"   ;Raster mode
   res@cnLinesOn = False           ;Turn off contours
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF      = 1500.
   res@cnMaxLevelValF      = 22000.
   res@cnLevelSpacingF = 200.0       ;Contour interval

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
               (/255,0,0/), (/255,255,255/), (/0,0,0/) /) * 1.0 ;Make them float
   colors = colors/255 ;Normalize so NCL won't freak out and plot black screen
   colors = colors(::-1,:) ;Invert color array
   gsn_define_colormap(wks, colors)

   ;Plot the image
   plot = gsn_csm_contour_map(wks,ir(:,:),res)
   draw(plot)
   frame(wks)

   delete(ir)
   delete(latitude)
   delete(longitude)

   ncdf = ncdf + 1 ;Iterate loop counter
   system("\rm -f ncdf_tmp netcdf_tmp.nc")	 
end do

system("\rm -f *tmp*") ;Remove temporary files
