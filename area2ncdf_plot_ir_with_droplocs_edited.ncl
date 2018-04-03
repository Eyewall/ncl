load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;Set the dropsonde and center track files and McIdas area file path
dropdir   = "/jm13/pduran/dropsondes/onr/Gonzalo/eol/"
trakfile  = "/jm13/pduran/onr/gonzalo_stormtrack"
satpath   = "/jm13/pduran/onr/ir/ncdf/"
outputdir = "/jm13/pduran/onr/ir/png/"

;Read the list of dropsondes and satellite ncdf files into an array
dropfiles = systemfunc("ls "+dropdir+"*.eol")
satfiles  = systemfunc("ls "+satpath+"*BAND_04")

;Get dates and times for drops and satellite images;
;COMMENTED LINES ARE FOR HS3 SONDES; UNCOMMENTED ARE FOR ONR/TCI SONDES
;dropyear_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 2-5")
dropyear_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 1-4")
dropyear     = stringtoint(dropyear_str)
;dropmon_str  = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 6-7")
dropmon_str  = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 5-6")
dropmon      = stringtoint(dropmon_str)
;dropday_str  = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 8-9")
dropday_str  = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 7-8")
dropday      = stringtoint(dropday_str)
;drophour_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | awk -F'_' '{print $2}' | cut -c 1-2")
drophour_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | awk -F'-' '{print $2}' | cut -c 1-2")
drophour     = stringtoint(drophour_str)
;dropminu_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | awk -F'_' '{print $2}' | cut -c 3-4")
dropminu_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | awk -F'-' '{print $2}' | cut -c 3-4")
dropminu = stringtofloat(dropminu_str)
satyr   = systemfunc("ls "+satpath+"*BAND_04 | awk -F'/' '{print $NF}' | awk -F'.' '{print $2}'")
satdy   = systemfunc("ls "+satpath+"*BAND_04 | awk -F'/' '{print $NF}' | awk -F'.' '{print $3}'")
sathour = stringtoint(systemfunc("ls "+satpath+"*BAND_04 | awk -F'/' '{print $NF}' | awk -F'.' '{print $4}' | cut -c 1-2"))
satminu = stringtofloat(systemfunc("ls "+satpath+"*BAND_04 | awk -F'/' '{print $NF}' | awk -F'.' '{print $4}' | cut -c 3-4"))

;Convert dates and times into Julian date arrays
julian_drop = greg2jul(dropyear,dropmon,dropday,drophour) + dropminu/1440
satdate = yyyyddd_to_yyyymmdd(stringtoint(satyr+satdy))
asciiwrite("satdate.tmp",satdate)
satyear = stringtoint(satyr)
satmon = stringtoint(systemfunc("cat satdate.tmp | cut -c 5-6"))
satday = stringtoint(systemfunc("cat satdate.tmp | cut -c 7-8"))
julian_sat = greg2jul(satyear,satmon,satday,sathour) + satminu/1440

;Read the trackfile into an array
nrows = stringtoint(systemfunc("wc "+trakfile+" | awk '{print $1}'"))
ncols = 6
trackarray = asciiread(trakfile,(/nrows,ncols/),"float")
trackdate = trackarray(:,0)  ;Times
tracktime = trackarray(:,1)  ;Dates
tracklat  = trackarray(:,2)  ;Latitudes
tracklon  = trackarray(:,3)  ;Longitudes
trackmaxV = trackarray(:,4)  ;Maximum wind speed
trackminP = trackarray(:,5)  ;Minimum sea level pressure 

;Loop through all drops, find the closest time for each, and plot IR image
ndrops = dimsizes(dropfiles)
do i=0,ndrops-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+ndrops)

   ;Get drop location
   dropdata = readAsciiTable(dropfiles(i),17,"float",14)
   lats = dropdata(:,15)
   lons = dropdata(:,14)
   lats@_FillValue = -999.
   lons@_FillValue = -999.
   droplat = lats(min(ind(.not.ismissing(lats).and.lats.ne.0)))
   droplon = lons(min(ind(.not.ismissing(lons).and.lons.ne.0)))
 
   ;Find the satellite image time closest to drop time
   satind = minind(abs(julian_sat - julian_drop(i)))
   satfile = satfiles(satind)

   ;Copy area file to pwd and convert to netCDF
   system("cp "+satfile+" ./area_tmp")
   system("java -cp /jm13/pduran/java/AreaToNetCDF.jar AreaToNetCDF ./area_tmp* netcdf_tmp.nc -CBRIT")
 
   ;-------------------------------------------;
   ;    Now proceed to plot satellite image    ;
   ;-------------------------------------------;
   ;Load netCDF file
;   f = addfile(satfile,"r")
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
   minlat = droplat - 7. 
   maxlat = droplat + 7.
   minlon = droplon - 7. 
   maxlon = droplon + 7.
   filename = dropyear_str(i)+dropmon_str(i)+dropday_str(i)+"_"+drophour_str(i)+dropminu_str(i)+"_ir"
   wks = gsn_open_wks("PNG",filename)
 
   ;Set workspace maximum size
   setvalues NhlGetWorkspaceObjectId()
      "wsMaximumSize" : 100000000
   end setvalues
 
   ;Set some plotting resources
   res = True
   res@gsnAddCyclic = False
   res@sfXArray = longitude
   res@sfYArray = latitude
   res@gsnLeftString = dropyear_str(i)+dropmon_str(i)+dropday_str(i)+"_"+drophour_str(i)+dropminu_str(i)+" UTC"
;   res@gsnRightString = sprinti("%0.2i",drophour(i))+sprinti("%0.2i",dropminu(i))+" UTC"
   res@gsnStringFontHeightF = 0.015
 
   res@cnFillOn = True             ;Color fill
   res@cnFillMode = "RasterFill"   ;Raster mode
   res@cnLinesOn = False           ;Turn off contours
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF      = -128.
   res@cnMaxLevelValF      = 128.
   res@cnLevelSpacingF = 2.0       ;Contour interval
 
   res@mpMinLatF = minlat
   res@mpMaxLatF = maxlat
   res@mpMinLonF = minlon
   res@mpMaxLonF = maxlon
   res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
   res@mpGeophysicalLineThicknessF = 2.5
   res@mpGeophysicalLineColor = "Orange"
   res@mpUSStateLineColor = "Orange"
 
   res@lbLabelBarOn   = False	;Turn off color label bar
   res@cnLineLabelsOn = False	;Turn off contour labels
   res@tmXTOn = False
   res@tmYROn = False

   res@gsnMaximize = True 
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
   colors = colors(::-1,:) ;Invert color array...Necessary for these data
   gsn_define_colormap(wks, colors)

   ;Plot the image
   polyres               = True
   polyres@gsMarkerIndex = 5	;Polymarker style
   polyres@gsMarkerSizeF = 20.	;Polymarker size
   polyres@gsMarkerColor   = "magenta"
   polyres@gsMarkerThicknessF = 5.
   plot = gsn_csm_contour_map(wks,ir(:,:),res)
   dum1 = gsn_add_polymarker(wks,plot,droplon,droplat,polyres)
   draw(plot)
   frame(wks)
   delete([/dropdata,lats,lons,ir,latitude,longitude,res/])
   system("mv "+filename+".png "+outputdir)
end do
