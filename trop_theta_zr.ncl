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
   prefix = "/jm13/pduran/ncl/trop_avgs_CPT_"  ;Prefix of input filename
   suffix = "_theta.txt"                       ;Suffix of input filename

   data = new((/3,10/),float)
;   data@_FillValue = -9999

   data(0,:) = stringtofloat(systemfunc("cat "+prefix+"major"+suffix+" | awk '{print($11)}'"))
   data(1,:) = stringtofloat(systemfunc("cat "+prefix+"nonmajor"+suffix+" | awk '{print($11)}'"))
   data(2,:) = stringtofloat(systemfunc("cat "+prefix+"ts+td"+suffix+" | awk '{print($11)}'"))

   data@_FillValue = data(0,0)  ;0-100 km radius is missing
   data(0,1) = data(0,0)   ;100-200 km radius is also missing

;   data(0,:) = (/-9999,-9999,-79.4,-79.2,-77.3,-78.0,-77.1,-76.6,-75.4,-74.5/) ;Major Hurricanes
;   data(1,:) = (/-77.3,-77.5,-77.4,-76.6,-76.1,-75.4,-74.8,-73.9,-72.6,-72.1/) ;Category 1&2 Hurricanes
;   data(2,:) = (/-72.9,-73.3,-72.9,-72.8,-72.9,-72.5,-72.4,-72.0,-72.1,-71.7/) ;Tropical depressions and storms
;   data(0,:) = (/-9999,-9999,16000,15900,15736,15292,15381,15520,14853,15036/) ;Major Hurricanes
;   data(1,:) = (/-9999,15281,15216,15384,14861,14932,14473,14226,13250,13192/) ;Category 1&2 Hurricanes
;   data(2,:) = (/14436,14677,14747,14694,14550,14352,14180,13815,13997,13506/) ;Tropical depressions and storms
;   data(0,:) = (/-9999,-9999,16182,15995,15802,15771,15769,15638,15501,15418/) ;Major Hurricanes
;   data(1,:) = (/-9999,15859,15780,15712,15613,15539,15429,15326,14797,14867/) ;Category 1&2 Hurricanes
;   data(2,:) = (/15097,15153,15207,15205,15137,15046,15002,14955,14899,14839/) ;Tropical depressions and storms

   radii     = (/50,150,250,350,450,550,650,750,850,950/)

   ;Add number of sondes in first bin to plot
   text  = (/"N=530","N=1504","N=6584"/)
   textx = (/215,75,75/)
   texty = (/16.2,15.4,14.85/)
   textcolors = (/"red","orange","blue"/)

   ;----------------------;
   ;Set plotting resources;
   ;----------------------;
   wks = gsn_open_wks("png","tropopause_theta")
   res  = True
   res@gsnMaximize = True
   ;res@tiMainString  = "Tropopause Heights"
   res@tiXAxisString = "Radius (km)"
   res@tiYAxisString = "Potential Temperature (C)"
   res@xyLineColors = (/"red","orange","blue"/)
   res@xyLineThicknesses = (/5,5,5/)
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
   res@trYMinF = 95.
   res@trYMaxF = 116.

   ;------------;
   ;Add a legend;
   ;------------;
   res@pmLegendDisplayMode = "Always"
   res@pmLegendSide = "Right"
   res@pmLegendOrthogonalPosF = -0.54 ;Move legend left
   res@pmLegendParallelPosF   = 0.1 ;Move legend down
   res@pmLegendWidthF = 0.20
   res@pmLegendHeightF = 0.10
   res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
   res@lgPerimOn = False             ;Turn on/off box around legend
   res@lgLabelFontHeightF = 0.02
   res@xyExplicitLegendLabels = (/"Major Hurricanes","Cat 1-2 Hurricanes","TS & TD"/)
   res@tmYROn = False
   res@tmXTOn = False
   res@gsnDraw = False
   res@gsnFrame = False
   plot = gsn_csm_xy (wks,radii,data,res)

   ;Add number of sondes in first radius to plot
   dum = new(dimsizes(text),graphic)
   do i=0,dimsizes(text)-1
      txres = True
      txres@txFontHeightF = 0.02
      txres@txFontColor = textcolors(i)
      dum(i) = gsn_add_text(wks,plot,text(i),textx(i),texty(i),txres)
   end do

draw(plot)
frame(wks)

system("rm *.tmp")
