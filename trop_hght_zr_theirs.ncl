load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;---------------------------------------------------------;
; stabshear_legend.ncl                                    
; Patrick Duran                                           
; 7/26/2013						  
; This script will plot vertical profiles of the stability
; and shear terms of the bulk Richardson number. Vertical 
; axis is log(p) with height labels and horizontal axis is
; nondimensional shear and stability terms. Magenta lines
; are drawn to indicate layers where BRCH < 0.25
;---------------------------------------------------------;

;-------------------;
;Modify these values;
;-------------------;
;dir = "/home/pduran/irdrops/BRCH/ivan/scripts/stabshear/datv/no_ecmwf/"
;dir = "/home/pduran/irdrops/BRCH/ivan/scripts/stabshear/datv/ecmwf_top/"
;ncols = 11      ;Number of columns in each data file
;nhead = 6       ;Number of header rows to chop off

;----------------------------------------;
;Create list of files and read into array;
;----------------------------------------;
;system("ls "+dir+"*datv > filelist.tmp")
;numfiles  = stringtoint(systemfunc("ls "+dir+"*datv | wc | awk '{print $1}'"))
;files     = asciiread("filelist.tmp", (/numfiles/), "string")

;-------------------------------;
;Loop through all files and plot;
;-------------------------------;
;index = 0
;do while(index.lt.numfiles)
;   print("Plotting image "+index+" of "+numfiles)
;   input = files(index)
;
;   ;-----------------------------;
;   ;Get info from dropfile header;
;   ;-----------------------------;
;   dropid = systemfunc("sed -n 4p "+input+" | awk '{print $6}'")
;   dattimslash = systemfunc("sed -n 4p "+input+" | awk '{print $9}'")
;   nlines = stringtoint(systemfunc("cat "+input+" | wc | awk '{print $1}'"))
;   datatable  = readAsciiTable(input,ncols,"float",nhead)
;   upperbound = nlines - nhead
;   dattimsplit = str_split(dattimslash, "/")
;   dattim = dattimsplit(0)+"_"+dattimsplit(1)
   
   ;-------------------------------------------------------------;
   ;To plot multiple curves, put data into multidimensional array;
   ;-------------------------------------------------------------;
;   data = new((/4,10/),float)
;   data(0,:) = (/-9999,15880,16035,15726,15702,15759,15793,15560,15450,15452/)  ;Major TCs
;   data(1,:) = (/15365,15184,15325,15292,15182,15164,15173,15121,15037,-9999/) ;Non-major TCs
;   data(2,:) = (/15667,15781,15964,15693,15622,15582,15507,15410,15233,15179/) ;Hurricanes
;   data(3,:) = (/15264,15086,15211,15157,15076,15056,15093,15060,15019,14944/) ;Non-hurricane TCs

   ;WMO DEFINITION (NCL FUNCTION)
   data = new((/3,10/),float)
   data(0,:) = (/-9999,-9999,16182,15996,15802,15771,15769,15638,15501,15418/) ;Major hurricanes
   data(1,:) = (/-9999,15859,15780,15712,15613,15539,15429,15326,14797,14867/) ;Non-major hurricanes
   data(2,:) = (/15097,15153,15207,15204,15137,15046,15002,14955,14899,14839/) ;TD+TS
   radii     = (/50,150,250,350,450,550,650,750,850,950/)
   data@_FillValue = -9999. 
   radii@_FillValue = -9999

   ;COLD POINT TROPOPAUSE HEIGHT
;   data = new((/3,10/),float)
;   data(0,:) = (/-9999,-9999,16320,16518,16537,16631,16569,16644,16546,16386/) ;Major hurricanes
;   data(1,:) = (/-9999,16420,16516,16560,16606,16559,16613,16599,16634,16603/) ;Non-major hurricanes
;   data(2,:) = (/16397,16315,16327,16445,16394,16447,16470,16478,16465,16416/) ;TD+TS
;   radii     = (/50,150,250,350,450,550,650,750,850,950/)
;   data@_FillValue = -9999.  
;   radii@_FillValue = -9999

   ;----------------------;
   ;Set plotting resources;
   ;----------------------;
   wks = gsn_open_wks("png","tropopause_heights_theirs")
   res  = True
   res@tiMainString  = "Tropopause Heights (WMO Lapse Rate)"
   res@tiXAxisString = "Radius [km]"
   res@tiYAxisString = "Height [m]"
   res@xyLineColors = (/"red","orange","blue"/)
   res@xyLineThicknesses = (/2,2/)
   res@xyDashPattern = 0
;   res@tmYLMode = "Explicit"	;Explicitly set the tick marks and labels below
   res@tfPolyDrawOrder = "Draw"
;   res@tmYLValues = (/100,150,200,250,300,350,400,450,500,600,700,800,900,1000/)
;   res@tmYLLabels = (/100,150,200,250,300,350,400,450,500,600,700,800,900,1000/)
;    res@tmYLValues = (/150,200,300,400,500,600,700,800,900,1000/)
;    res@tmYLLabels = (/150,200,300,400,500,600,700,800,900,1000/)

   ;----------------------------;
   ;Set x and y axis min and max;
   ;----------------------------;
   res@trXMinF = 0.
   res@trXMaxF = 1000.
   res@trYMinF = 14000.
   res@trYMaxF = 17000.

   ;------------;
   ;Add a legend;
   ;------------;
   res@pmLegendDisplayMode = "Always"
   res@pmLegendSide = "Right"
   res@pmLegendOrthogonalPosF = -0.5 ;Move legend left
   res@pmLegendParallelPosF   = 0.1 ;Move legend down
   res@pmLegendWidthF = 0.20
   res@pmLegendHeightF = 0.10
   res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
   res@lgPerimOn = False             ;Turn on/off box around legend
   res@lgLabelFontHeightF = 0.02
   res@xyExplicitLegendLabels = (/"Major Hurricanes","Cat 1+2 Hurricanes","TS & TD"/)

   plot = gsn_csm_xy (wks,radii,data,res)

system("rm *.tmp")
