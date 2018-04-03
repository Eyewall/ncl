load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;Set the dropsonde and center track files and McIdas area file path
dropdir   = "//nfs/jm13/pduran/dropsondes/onr/20150928/"
trakfile  = "/jm13/pduran/onr/gonzalo_stormtrack"
satpath   = "/jm13/pduran/onr/ir/ncdf/"
outputdir = "/jm13/pduran/onr/ir/png/"
baddir    = "/jm13/pduran/dropsondes/onr/useless/"
tablefile = "/jm13/pduran/sat/tables/coeff.txt"

;Read the satellite coefficient table file
table = readAsciiTable(tablefile,8,"float",(/2,13/))

;Read the list of dropsondes and satellite ncdf files into an array
dropfiles = systemfunc("ls "+dropdir+"*.eol")
satfiles  = systemfunc("ls "+satpath+"*.nc")

;Get dates and times for drops and satellite images;
;dropyear_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 1-4")
;dropyear     = stringtoint(dropyear_str)
;dropmon_str  = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 5-6")
;dropmon      = stringtoint(dropmon_str)
;dropday_str  = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | cut -c 7-8")
;dropday      = stringtoint(dropday_str)
;drophour_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | awk -F'-' '{print $2}' | cut -c 1-2")
;drophour     = stringtoint(drophour_str)
;dropminu_str = systemfunc("ls "+dropdir+"*.eol | awk -F'/' '{print $NF}' | awk -F'-' '{print $2}' | cut -c 3-4")
;dropminu = stringtofloat(dropminu_str)
satyr   = systemfunc("ls "+satpath+"*.nc | awk -F'/' '{print $NF}' | awk -F'.' '{print $2}'")
satdy   = systemfunc("ls "+satpath+"*.nc | awk -F'/' '{print $NF}' | awk -F'.' '{print $3}'")
sathour = stringtoint(systemfunc("ls "+satpath+"*.nc | awk -F'/' '{print $NF}' | awk -F'.' '{print $4}' | cut -c 1-2"))
satminu = stringtofloat(systemfunc("ls "+satpath+"*.nc | awk -F'/' '{print $NF}' | awk -F'.' '{print $4}' | cut -c 3-4"))

dropyear_str = systemfunc("ls "+dropdir+"*eol | awk -F'/' '{print $NF}' | cut -c 4-7")
dropmon_str  = systemfunc("ls "+dropdir+"*eol | awk -F'/' '{print $NF}' | cut -c 8-9")
dropday_str  = systemfunc("ls "+dropdir+"*eol | awk -F'/' '{print $NF}' | cut -c 10-11")
drophour_str = systemfunc("ls "+dropdir+"*eol | awk -F'/' '{print $NF}' | cut -c 13-14")
dropminu_str = systemfunc("ls "+dropdir+"*eol | awk -F'/' '{print $NF}' | cut -c 15-16")
dropyear = stringtoint(dropyear_str)
dropmon  = stringtoint(dropmon_str)
dropday  = stringtoint(dropday_str)
drophour = stringtoint(drophour_str)
dropminu = stringtoint(dropminu_str)

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
   if(all(ismissing(dropdata(1:,15))))then
      system("mv "+dropfiles(i)+" "+baddir)
   else
      droplat = lats(min(ind(.not.ismissing(lats).and.lats.ne.0)))
      droplon = lons(min(ind(.not.ismissing(lons).and.lons.ne.0)))

      ;Find the satellite image time closest to drop time
      satind = minind(abs(julian_sat - julian_drop(i)))
      satfile = satfiles(satind)
 
      ;-------------------------------------------;
      ;    Now proceed to plot satellite image    ;
      ;-------------------------------------------;
      ;Load netCDF file
      f = addfile(satfile,"r")
           
      ;Get data from netCDF file
      ir = f->data(0,:,:)    ;float
      latitude = f->lat      ;float
      longitude = f->lon     ;float
      yyddd = f->imageDate   ;int
      hhmmss = f->imageTime  ;int
      sat = f->sensorID      ;char
      band = f->bands        ;int

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

      ;---------------------------------------;
      ;Convert yyyyddd to yyyymmdd for sat img;
      ;---------------------------------------;
      yyyymmdd = yyyyddd_to_yyyymmdd(yyddd)
      imgyear  = systemfunc("echo "+yyyymmdd+" | cut -c 1-4")
      imgmon   = systemfunc("echo "+yyyymmdd+" | cut -c 5-6")
      imgday   = systemfunc("echo "+yyyymmdd+" | cut -c 7-8")

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

      ;Define domain of plot
      minlat = droplat - 5. 
      maxlat = droplat + 5.
      minlon = droplon - 5. 
      maxlon = droplon + 5.
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
      res@gsnLeftString = imgyear+imgmon+imgday+"_"+imgtime+" UTC"
      res@gsnRightString = "Brightness Temperature (~S~o~N~C)"
      res@gsnStringFontHeightF = 0.015
      res@gsnLeftStringOrthogonalPosF = -.0005
      res@gsnRightStringOrthogonalPosF = -.0005

      res@cnFillOn = True             ;Color fill
      res@cnFillMode = "RasterFill"   ;Raster mode
      res@cnLinesOn = False           ;Turn off contours
      res@cnLevelSelectionMode = "ManualLevels"
      res@cnMinLevelValF = -80.
      res@cnMaxLevelValF = 50.
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

      res@cnLineLabelsOn = False        ;Turn off contour labels
      res@tmXTOn = False
      res@tmYROn = True
      res@tmXBLabelFontHeightF = 0.013
      res@tmYLLabelFontHeightF = 0.013

      res@gsnMaximize = True
      res@gsnDraw  = False              ;So we can add poly stuff
      res@gsnFrame = False

      ;Get AVN satellite colormap, change foreground and background colors to
      ;white and black, respectively, and reverse it for plotting.
      gsn_define_colormap(wks,"avn")
      colors = gsn_retrieve_colormap(wks)
      colors(0,:) = 0
      colors(1,:) = 1
      gsn_define_colormap(wks,colors)
      gsn_reverse_colormap(wks)

      ;Plot the image
      polyres               = True
      polyres@gsMarkerIndex = 5 ;Polymarker style
      polyres@gsMarkerSizeF = 20.       ;Polymarker size
      polyres@gsMarkerColor   = "magenta"
      polyres@gsMarkerThicknessF = 5.
      plot = gsn_csm_contour_map(wks,TbC(:,:),res)
      dum1 = gsn_add_polymarker(wks,plot,droplon,droplat,polyres)
      draw(plot)
      frame(wks)
      delete([/ir,latitude,longitude,r,arg_before,arg,Teff,Tb,TbC,res/])
      system("mv "+filename+".png "+outputdir)
   end if
   delete([/dropdata,lats,lons/])
end do
