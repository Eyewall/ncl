load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"

;Set paths to data
pirepfile = "/jm13/pduran/pireps/severe_pirep_fit_constraints_unique.out"
raobpath = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/processed/sondes/"
brchpath = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/calcs/brch/"
satpath  = "ftp://disc2.nascom.nasa.gov/data/s4pa/TRMM_ANCILLARY/MERG/"
raobtimedir = "ls /jm13/pduran/soundings/raob_index_lists_6sec/skewt/"
brchtimedir = "ls /jm13/pduran/soundings/raob_index_lists_6sec/brch/"
stnfile = "/jm13/pduran/soundings/raob_index_lists_6sec/skewt/ListOfStations.txt"

;Read the list of PIREPS into an array
nrows = stringtoint(systemfunc("cat "+pirepfile+" | wc | awk '{print $1}'"))
pireparray = asciiread(pirepfile,(/nrows,9/),"double")

;Read in the RAOB times and locations for each station
nlines = stringtoint(systemfunc("wc "+stnfile+" | awk '{print $1}'"))
ListOfStations = asciiread(stnfile,(/nlines,3/),"float")
stn_IDs  = flt2string(ListOfStations(:,0))
stn_lats = ListOfStations(:,1)
stn_lons = ListOfStations(:,2)

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
pminustring = flt2string(doubletofloat(pireparray(:,8)))
ptime_jul = greg2jul(pyear,pmonth,pday,phour) + pminu/1440

dayofyear = day_of_year(year,month,day)
npireps = dimsizes(year)

palt = doubletoint(palt / 3.28084)  ;Convert feet to meters

i = 0
do while(i.lt.npireps) ;Loop through all PIREPS
   ;--------------------------------------------------------------------;
   ;Determine the RAOB stations that are within 500 km of PIREP location;
   ;--------------------------------------------------------------------;
   latf_array = new(nlines,"double",latf(i))    ;Two arrays needed for the great circle
   lonf_array = new(nlines,"double",lonf(i))    ;distance calculation called below
   distances = gc_latlon(latf(i),lonf(i),stn_lats,stn_lons,2,4)
   closest_stn_flt = stringtofloat(stn_IDs(minind(distances)))  
   if (closest_stn_flt.lt.10000) then
      closest_stn = "0"+flt2string(closest_stn_flt)
   else
      closest_stn = flt2string(closest_stn_flt)
   end if
   closest_stn_lat = stn_lats(minind(distances))
   closest_stn_lon = stn_lons(minind(distances))
   raobtimes = stringtodouble(systemfunc("cat "+raobtimedir+closest_stn+".dat"))
   raobindex = minind(abs(raobtimes-ptime_jul(i))) + 1 ;Add 1 because Unix indexes from 1
   raobfile = raobpath+closest_stn+"/"+systemfunc("ls "+raobpath+closest_stn+" | sed -n "+raobindex+"p")
   raobindex = raobindex - 1 ;Subtract 1 back out because we now need raobindex for NCL array indices

   ;ONLY CONTINUE IF THE RAOB IS WITHIN 500 KM AND 24 HOURS OF PIREP
   distance = min(distances) ;Spatial distance between PIREP and raob
   timediff = abs(raobtimes(raobindex)-ptime_jul(i)) ;Time between PIREP and raob (Julian)
   if ((min(distances).lt.500).and.(abs(raobtimes(raobindex)-ptime_jul(i)).le.1))

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
   
      i = i + 1
      print("Creating montage "+i+" of "+npireps)
      print("-----------------------------")
      print("Reading and processing satellite data...")   
      i = i - 1
      
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
      print("Plotting satellite image with PIREP and RAOB locations overlaid...")
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
   
      wks = gsn_open_wks("PNG","sat.png")
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
   
      ;Create arrays for plotting below
      markerlons = (/lonf(i),closest_stn_lon/)
      markerlats = (/latf(i),closest_stn_lat/)   
   
      ;Plot the image
      pirepres               = True
      pirepres@gsMarkerIndex = 5	;Polymarker style
      pirepres@gsMarkerSizeF = 20.	;Polymarker size
      pirepres@gsMarkerColor = "magenta"
      pirepres@gsMarkerThicknessF = 5.
   
      raobres               = True
      raobres@gsMarkerIndex = 12
      raobres@gsMarkerSizeF = 20.
      raobres@gsMarkerColor = "black"
      raobres@gsMarkerThicknessF = 7.
   
      raobres2               = True
      raobres2@gsMarkerIndex = 12
      raobres2@gsMarkerSizeF = 20.
      raobres2@gsMarkerColor = "red"
      raobres2@gsMarkerThicknessF = 3.
   
   
      plot = gsn_csm_contour_map_ce(wks,ir(0,:,:),res)
   
      dum1 = gsn_add_polymarker(wks,plot,closest_stn_lon,closest_stn_lat,raobres)
      dum2 = gsn_add_polymarker(wks,plot,closest_stn_lon,closest_stn_lat,raobres2)
      dum3 = gsn_add_polymarker(wks,plot,lonf(i),latf(i),pirepres)
      draw(plot)
      frame(wks)
   
      ;-----------------------------------------------------------------------;
      ;Set up station name arrays for SkewT and BRCH vertical profile plotting;
      ;-----------------------------------------------------------------------;
      stn_names = (/"KLCH","KDTX","KAAA","TSJU","KTPA","KEYW","KGSO","KJAX","KBNA",\
                   "KTOP","KCAR","KGRB","KFFC","KMIA","KIAD","KMHX","KTLH","KHWV"/)
      stn_nmbrs = (/"03937","04830","04833","11641","12842","12850","13723","13889",\
                   "13897","13996","14607","14898","53819","92803","93734","93768",\
                   "93805","94703"/)
      stn_name = stn_names(ind(stn_nmbrs.eq.closest_stn))
      ;--------------;
      ;Plot the SkewT;
      ;--------------;
         print("Plotting SkewT...")

         ;Get date and time from SkewT filename string for use in BRCH section below
         raobtimesplit = str_split(raobfile,"-")
         raobdattim = raobtimesplit(1)
         system("cp "+raobfile+" raobfile.tmp")

         ;Replace all -9999 values with -999. This is necessary because the script
         ;uses floats, for which the missing value flag is -999.
         system("`sed -i 's/-9999/-999/g' raobfile.tmp`")
         ndroplevels = stringtoint(systemfunc("cat raobfile.tmp | wc | awk '{print $1}'"))
         dattimslash = systemfunc("sed -n 4p raobfile.tmp | awk '{print $9}'")
         dattimsplit = str_split(dattimslash, "/")
         dattim = dattimsplit(0)+"_"+dattimsplit(1)
         DropData  = readAsciiTable("raobfile.tmp",10,"float",7)
         p   = DropData(:,0)
         tc  = DropData(:,1)
         tdc = DropData(:,2)
         z   = DropData(:,5)
         u   = DropData(:,3) * 1.94384449 ;Convert to kt
         v   = DropData(:,4) * 1.94384449
         p@_FillValue = -999.
         tc@_FillValue = -999.
         tdc@_FillValue = -999. 
         z@_FillValue = -999.
         u@_FillValue = (-999. * 1.94384449)
         v@_FillValue = (-999. * 1.94384449)
   
         wks = gsn_open_wks("png","skewt.png")
         skewtOpts                 = True
         skewtOpts@DrawColAreaFill = False    ; default is False
         skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      "+stn_name
         skewtOpts@DrawFahrenheit  = False   ; default is True
   
         dataOpts           = True     ; options describing data and ploting
         dataOpts@Wthin     = 2        ; plot every n-th wind barb
         skewt_bkgd = skewT_BackGround (wks, skewtOpts)
         skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,u,v,dataOpts)
         draw (skewt_bkgd)
         draw (skewt_data)
         frame(wks)
   
         delete(DropData)
         delete(p)
         delete(tc)
         delete(tdc)
         delete(z)
         delete(u)
         delete(v)
   
      ;--------------------------;
      ;Plot BRCH vertical profile;
      ;--------------------------;
         print("Plotting BRCH vertical profile...")
         ;yearsplitbrch = str_split_by_length(y,2)
         ;brchtimes = stringtoint(systemfunc("cat "+brchtimedir+closest_stn+".dat"))
         ;brchindex = minind(abs(brchtimes-ptime_jul(i)))
         ;brchfiles = systemfunc("ls "+brchpath+closest_stn+"*datv")
         brchfile = systemfunc("ls "+brchpath+closest_stn+"-"+raobdattim+"*datv")
         ncols = 11
         nhead = 7
   
         ;Get info from sounding file header 
         stn_nmbr = systemfunc("sed -n 4p "+brchfile+" | awk '{print $6}'")
         dattimslash = systemfunc("sed -n 4p "+brchfile+" | awk '{print $9}'")
         nlines = stringtoint(systemfunc("cat "+brchfile+" | wc | awk '{print $1}'"))
         datatable  = readAsciiTable((brchfile),ncols,"float",nhead)
         dattimsplit = str_split(dattimslash, "/")
         dattim = dattimsplit(0)+"_"+dattimsplit(1)
         stn_name = stn_names(ind(stn_nmbr.eq.stn_nmbrs))
   
         ;---------;
         ;Read data;
         ;---------;
         data = readAsciiTable(brchfile,ncols,"float",nhead)
         pres = data(:,0)  ;Pressure (mb)
         hght = data(:,5)  ;Height (m)
         brch = data(:,9)  ;Bulk Richardson Number
         pres@_FillValue = -9999.
         hght@_FillValue = -9999.
         brch@_FillValue = -9999.
   
         ;--------------------------;
         ;Get data for height labels;
         ;--------------------------;
         hght_label_size = dimsizes(hght)/5
         g = 0
         n = 0
         hght_label = new(hght_label_size,"float")
         pres_coord = new(hght_label_size,"float")
         x_coord    = new(hght_label_size,"float")
         do while(g .lt. hght_label_size)
            hght_label(g) = hght(n)
            pres_coord(g) = pres(n)
            x_coord(g)    = 4.8
            g=g+1
            n=n+5
         end do
         hght_label_string = flt2string(hght_label)
      
         ;--------------------------------------;
         ;Get data for BRCH<0.25 indicator lines;
         ;--------------------------------------;
         brch25ind = ind(brch.lt.0.25)
         brch25ind_size = dimsizes(brch25ind)
         brch25ind@_FillValue = -999
      
         ;----------------------;
         ;Set plotting resources;
         ;----------------------;
         wks = gsn_open_wks("png","brch.png")
         brchres = True
         ;brchres@tiMainString  = "DATE/TIME: "+dattim+"      "+stn_name
         brchres@tiXAxisString = "Bulk Richardson Number"
         brchres@tiYAxisString = "Pressure [mb]"
         brchres@xyLineColors = (/"blue"/)
         brchres@xyLineThicknesses = (/3/)
         brchres@xyDashPattern = 0
         brchres@trYReverse = True        ;Invert the pressure axis
         brchres@xyYStyle = "Log"         ;Make the pressure axis logarithmic
         brchres@tmYLMode = "Explicit"    ;Explicitly set the tick marks and labels below
         ;brchres@tfPolyDrawOrder = "Draw"
         brchres@tmYLValues = (/150,200,300,400,500,600,700,800,900,1000/) ;Tick mark values
         brchres@tmYLLabels = (/150,200,300,400,500,600,700,800,900,1000/) ;Tick mark labels
         brchres@trXMinF = 0.     ;X axis min
         brchres@trXMaxF = 5.     ;X axis max
         brchres@trYMinF = 150.   ;Y axis min
         brchres@trYMaxF = 1020.  ;Y axis max
         brchres@gsnDraw = False  ;Don't draw plot until we overlay height labels
         brchres@gsnFrame = False ;and BRCH<0.25 indicator lines
      
         plot = gsn_csm_xy(wks,brch,pres,brchres)
      
         ;-----------------------------;
         ;Add BRCH<0.25 indicator lines;
         ;-----------------------------;
         lineres = True
         lineres@gsLineColor   = "magenta"
         lineres@gsLineThicknessF = 7.0
         lines = new(brch25ind_size,graphic)
         x_coord_line = new(2,float)
         y_coord_line = new(2,float)
         x_coord_line = (/0.,5./)
         k=0
         if(.not.all(ismissing(brch25ind)))
            do while (k.lt.brch25ind_size)
               y_coord_line = (/pres(brch25ind(k)),pres(brch25ind(k))/)
               lines(k) = gsn_add_polyline(wks,plot,x_coord_line,y_coord_line,lineres)
               delete(y_coord_line)
               k=k+1
            end do
         end if
      
         ;-----------------;
         ;Add height labels;
         ;-----------------;
         txres = True
         txres@txFontHeightF = 0.01
         text = gsn_add_text(wks,plot,hght_label_string,x_coord,pres_coord,txres)
      
         ;---------------------------;
         ;Draw plot and delete arrays;
         ;---------------------------;
         draw(plot)
         frame(wks)
         delete(pres)
      ;---------------------------------------------------;
      ;Plot the stability and shear terms vertical profile;
      ;---------------------------------------------------;
         print("Plotting stability/shear vertical profile...")
         ;Create multidimensional array to plot more than 1 line
         upperbound = nlines-nhead-1
         stabsheardata = new((/2,upperbound/),float)
         stabsheardata(0,:) = data(:upperbound-1,8)  ;STAB values
         stabsheardata(1,:) = data(:upperbound-1,10) ;VSHR values
         pres = datatable(:upperbound-1,0)
         stabsheardata@_FillValue = -9999.
         hght@_FillValue = -9999.
         pres@_FillValue = -9999.
         brch@_FillValue = -9999.
     
         ;Set plotting resources 
         wks = gsn_open_wks("png","stabshear.png")
         stabshearres  = True
         ;stabshearres@tiMainString  = "DATE/TIME: "+dattim+"      DROP ID: "+stn_name
         stabshearres@tiXAxisString = "Shear and Stability Terms"
         stabshearres@tiYAxisString = "Pressure [mb]"
         stabshearres@xyLineColors = (/"red","blue"/)
         stabshearres@xyLineThicknesses = (/2,2/)
         stabshearres@xyDashPattern = 0
         stabshearres@trYReverse = True        ;Invert the pressure axis
         stabshearres@xyYStyle = "Log"         ;Make the pressure axis logarithmic
         stabshearres@tmYLMode = "Explicit"    ;Explicitly set the tick marks and labels below
         stabshearres@tfPolyDrawOrder = "Draw"
         stabshearres@tmYLValues = (/150,200,300,400,500,600,700,800,900,1000/)
         stabshearres@tmYLLabels = (/150,200,300,400,500,600,700,800,900,1000/)
   
         ;Sex x and y axis max and min
         stabshearres@trXMinF = 0.
         stabshearres@trXMaxF = 4.
         stabshearres@trYMinF = 150.
         stabshearres@trYMaxF = 1020.

         ;Add a legend
         stabshearres@pmLegendDisplayMode = "Always"
         stabshearres@pmLegendSide = "Right"
         stabshearres@pmLegendOrthogonalPosF = -0.5 ;Move legend left
         stabshearres@pmLegendParallelPosF   = 0.1 ;Move legend down
         stabshearres@pmLegendWidthF = 0.20
         stabshearres@pmLegendHeightF = 0.10
         stabshearres@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
         stabshearres@lgPerimOn = False             ;Turn on/off box around legend
         stabshearres@lgLabelFontHeightF = 0.02
         stabshearres@xyExplicitLegendLabels = (/"Stability","Shear"/)
      
         stabshearres@gsnDraw  = False
         stabshearres@gsnFrame = False
         plot = gsn_csm_xy (wks,stabsheardata,pres,stabshearres)

         ;Add BRCH<0.25 indicator lines
         stabshearlineres = True
         stabshearlineres@gsLineColor   = "magenta"
         stabshearlineres@gsLineThicknessF = 7.0
         lines = new(brch25ind_size,graphic)
         x_coord_line = new(2,float)
         y_coord_line = new(2,float)
         x_coord_line = (/0.,4./)
         p=0
         if(.not.all(ismissing(brch25ind)))
            do while (p.lt.brch25ind_size)
               y_coord_line = (/pres(brch25ind(p)),pres(brch25ind(p))/)
               lines(p) = gsn_add_polyline(wks,plot,x_coord_line,y_coord_line,stabshearlineres)
               delete(y_coord_line)
               p=p+1
            end do
         end if
         delete(p)        

         ;Add height labels
         stabsheartxres = True
         stabsheartxres@txFontHeightF = 0.01
         text = gsn_add_text(wks,plot,hght_label_string,x_coord,pres_coord,stabsheartxres)

         ;Draw plot, delete arrays, and iterate loop index
         draw(plot)
         frame(wks)

         delete(datatable)
         delete(data)
         delete(hght)
         delete(pres)
         delete(brch)
         delete(hght_label)
         delete(pres_coord)
         delete(x_coord)
         delete(hght_label_string)
         delete(text)
         delete(brch25ind)
         delete(lines)
         delete(stabsheardata)     
 
      ;Finished plotting. Delete more arrays and move on to montaging

      system("\rm "+satfile) 
   
      delete(latf_array)
      delete(lonf_array)
      delete(ir)
      delete(ir_unflipped)
      delete(plot)
      delete(dum1)
      delete(dum2)
   
      ;------------------------------------------------;
      ;Montage the four plots and iterate loop counter;
      ;------------------------------------------------;
      if (i.lt.10) then
         filename = "000"+i
      else if ((i.ge.10).and.(i.lt.100)) then
         filename = "00"+i
      else if ((i.ge.100).and.(i.lt.1000)) then
         filename = "0"+i
      else
         filename = i
      end if
      end if
      end if

      print("Montaging IR+SkewT+BRCH+StabShear...")
      system("montage -geometry 800x800 -trim sat.png skewt.png brch.png stabshear.png "+filename+"_montage.png")
      system("\rm sat.png skewt.png brch.png stabshear.png")

      print(" ")
      print(" ")

      delete(m)
      delete(d)
      delete(h)

   end if

   delete(raobtimes)

   i = i + 1
   ;i = npireps

end do
