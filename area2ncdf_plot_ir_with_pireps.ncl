load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;Set the PIREP file and satellite binary file path
pirepfile = "/jm13/pduran/pireps/severe_pirep_fit_constraints_unique.out"
satpath  = "ftp://disc2.nascom.nasa.gov/data/s4pa/TRMM_ANCILLARY/MERG/"

;Read the list of PIREPS into an array
nrows = stringtoint(systemfunc("cat "+pirepfile+" | wc | awk '{print $1}'"))
pireparray = asciiread(pirepfile,(/nrows,9/),"double")

;--------------------------------------------------;
;Convert Julian time to Gregorian and split up data;
;--------------------------------------------------;
date  = jul2greg(pireparray(:,0)) ;Each row has elements (year,month,day,hour)
year  = date(:,0)
month = date(:,1)
day   = date(:,2)
hour  = date(:,3)
latf  = pireparray(:,1)
lonf  = pireparray(:,2)
palt  = pireparray(:,3)
pyear = doubletoint(pireparray(:,4))
pmonth= doubletoint(pireparray(:,5))
pday  = doubletoint(pireparray(:,6))
phour = doubletoint(pireparray(:,7))
pminu = doubletoint(pireparray(:,8))

dayofyear = day_of_year(year,month,day)
npireps = dimsizes(year)

palt = doubletoint(palt / 3.28084)  ;Convert feet to meters

i = 0
do while(i.lt.npireps) ;Loop through all PIREPS
   print(palt(i))
   ;-----------------------------;
   ;Get binary file from FTP site;
   ;-----------------------------;
   y = year(i)              ;<-Year string
   if(month(i).lt.10) then  ;-
      m = "0"+month(i)      ; |
   else                     ; |<-Month string
      m = month(i)          ; |
   end if                   ;-
   if(day(i).lt.10) then    ;-
      d = "0"+day(i)        ; |
   else                     ; |<-Day string
      d = day(i)            ; |
   end if                   ;-
   if(hour(i).lt.10) then   ;-
      h = "0"+hour(i)       ; |
   else                     ; |<-Hour string
      h = hour(i)           ; |
   end if                   ;-

   system("wget "+satpath+year(i)+"/"+dayofyear(i)+"/merg_"+y+m+d+h+"_4km-pixel.Z")
   system("gunzip -f *.Z")
   satfile = "merg_"+y+m+d+h+"_4km-pixel"

   ;------------------------------;
   ;Read the satellite binary file;
   ;------------------------------;
   setfileoption("bin","ReadByteOrder","LittleEndian")
   binary = fbindirread(satfile,0,(/2,3298,9896/),"byte")
   ;Create coordinate variables
   lats = fspan(60,-60,3298)
   lons = fspan(-180,180,9896)
   lats@units = "degrees_north"
   lons@units = "degrees_east"
   ;Convert binary to floats
   ir_unflipped = byte2flt(tounsigned(binary))
   ;Flip data around meridian
   ir = new((/2,3298,9896/),"float")
   ir(:,:,4948:9895) = ir_unflipped(:,:,0:4947)
   ir(:,:,0:4947) = ir_unflipped(:,:,4948:9895)
   ;Create and specify coordinate variables
   ir(:,:,:) = ir(:,:,:) + 75
   print(max(ir))
   print(min(ir))
   ir!1    = "lat"
   ir!2    = "lon"
   ir&lat  = lats
   ir&lon  = lons
   ir@long_name = "brightness temperature"
   ir@units     = "K"
   ir@_FillValue = -999.
   ;Convert to degrees Celsius
   ir = ir - 273.15
   ;Fill all values greater than or equal to 55 C
   ir = where(ir.ge.55,ir@_FillValue,ir)
   ;Interpolate to missing values
   poisson_grid_fill(ir,True,0,5,0.001,0.6,0)

   ;----------------------------------------;
   ;Plot satellite image with PIREP overlaid;
   ;----------------------------------------;
   i = i + 1
   print("Plotting image "+i+" of "+npireps)
   print("-----------------------------")   
   i = i - 1

   ;Define domain of plot
   minlat = latf(i) - 10. 
   maxlat = latf(i) + 10.
   minlon = lonf(i) - 10. 
   maxlon = lonf(i) + 10.

   ;Set date and time strings for writing to plot
   monthstring = sprinti("%0.2i",pmonth(i))
   daystring   = sprinti("%0.2i",pday(i))
   hourstring  = sprinti("%0.2i",phour(i))
   minustring  = sprinti("%0.2i",pminu(i))

   filename = year(i)+monthstring+daystring+hourstring+"_"+i 

   wks = gsn_open_wks("PNG",filename)
   setvalues NhlGetWorkspaceObjectId()
      "wsMaximumSize": 500000000      ;Increase workspace size
   end setvalues                      ;to fit whole IR image
   
   ;Set some plotting resources
   res = True
   res@gsnAddCyclic = False   ;Already has cyclic point
   res@sfXArray = lons
   res@sfYArray = lats
   res@gsnLeftString = "Severe Pirep Time: "+monthstring+"/"+daystring+"/"+year(i)+\
                       " "+hourstring+minustring+" UTC     Altitude: "+palt(i)+" m" 
   i = i + 1
   res@gsnRightString = " "
   i = i - 1
   res@gsnStringFontHeightF = 0.015

   res@cnFillOn = True             ;Color fill
   res@cnFillMode = "RasterFill"   ;Raster mode
   res@cnLinesOn = False           ;Turn off contours
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF      = -80.
   res@cnMaxLevelValF      = 50.
   res@cnLevelSpacingF = 2.0       ;Contour interval

   res@mpMinLatF = minlat
   res@mpMaxLatF = maxlat
   res@mpMinLonF = minlon
   res@mpMaxLonF = maxlon
   res@mpFillOn = False                   ;Turn off gray fill for continents
   res@mpOutlineBoundarySets = "GeophysicalAndUSStates" ;Plot nation & states
   res@mpGeophysicalLineThicknessF = 2.5  ;Increase map outline thickness
   res@mpGeophysicalLineColor = "Orange"
   res@mpUSStateLineColor = "Orange"

   ;res@lbLabelBarOn   = False	;Turn off color label bar
   ;res@cnLineLabelsOn = False	;Turn off contour labels

   res@gsnMaximize = True
   res@gsnPaperOrientation = "landscape"

   res@gsnDraw  = False		;So we can overlay PIREPs later
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
   gsn_reverse_colormap(wks)       ;Reverse colormap...Necessary for this data

   ;Plot the image
   polyres               = True
   polyres@gsMarkerIndex = 5	;Polymarker style
   polyres@gsMarkerSizeF = 20.	;Polymarker size
   polyres@gsMarkerColor   = "magenta"
   polyres@gsMarkerThicknessF = 5.
   plot = gsn_csm_contour_map_ce(wks,ir(0,:,:),res)
   dum1 = gsn_add_polymarker(wks,plot,lonf(i),latf(i),polyres)
   draw(plot)
   frame(wks)

   system("\rm "+satfile) 

   delete(ir)
   delete(ir_unflipped)
   delete(plot)
   delete(dum1)
   delete(m)
   delete(d)
   delete(h)

   print(" ")
   print(" ")

   i = i + 1

end do
