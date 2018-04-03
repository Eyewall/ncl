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
dir = "/home/pduran/irdrops/BRCH/ivan/scripts/stabshear/datv/no_ecmwf/"
;dir = "/home/pduran/irdrops/BRCH/ivan/scripts/stabshear/datv/ecmwf_top/"
ncols = 11      ;Number of columns in each data file
nhead = 6       ;Number of header rows to chop off

;----------------------------------------;
;Create list of files and read into array;
;----------------------------------------;
system("ls "+dir+"*datv > filelist.tmp")
numfiles  = stringtoint(systemfunc("ls "+dir+"*datv | wc | awk '{print $1}'"))
files     = asciiread("filelist.tmp", (/numfiles/), "string")

;-------------------------------;
;Loop through all files and plot;
;-------------------------------;
index = 0
do while(index.lt.numfiles)
   print("Plotting image "+index+" of "+numfiles)
   input = files(index)

   ;-----------------------------;
   ;Get info from dropfile header;
   ;-----------------------------;
   dropid = systemfunc("sed -n 4p "+input+" | awk '{print $6}'")
   dattimslash = systemfunc("sed -n 4p "+input+" | awk '{print $9}'")
   nlines = stringtoint(systemfunc("cat "+input+" | wc | awk '{print $1}'"))
   datatable  = readAsciiTable(input,ncols,"float",nhead)
   upperbound = nlines - nhead
   dattimsplit = str_split(dattimslash, "/")
   dattim = dattimsplit(0)+"_"+dattimsplit(1)
   
   ;-------------------------------------------------------------;
   ;To plot multiple curves, put data into multidimensional array;
   ;-------------------------------------------------------------;
   data = new((/2,upperbound/),float)
   data(0,:) = datatable(:upperbound-1,8)  ;STAB values
   data(1,:) = datatable(:upperbound-1,10) ;VSHR values
   hght      = datatable(:upperbound-1,5)
   pres      = datatable(:upperbound-1,0)
   brch      = datatable(:upperbound-1,9)
   data@_FillValue = -9999. 
   hght@_FillValue = -9999.
   pres@_FillValue = -9999.
   brch@_FillValue = -9999.

   ;--------------------------;
   ;Get data for height labels;
   ;--------------------------;
   hght_label_size = dimsizes(hght)/5
   i = 0
   j = 0
   hght_label = new(hght_label_size,"float")
   pres_coord = new(hght_label_size,"float")
   x_coord    = new(hght_label_size,"float")
   do while(i .lt. hght_label_size)
      hght_label(i) = hght(j)
      pres_coord(i) = pres(j)
      x_coord(i)    = 3.8
      i=i+1
      j=j+5
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
   wks = gsn_open_wks("png",dattim)
   res  = True
   res@tiMainString  = "DATE/TIME: "+dattim+"      DROP ID: "+dropid
   res@tiXAxisString = "Shear and Stability Terms"
   res@tiYAxisString = "Pressure [mb]"
   res@xyLineColors = (/"red","blue"/)
   res@xyLineThicknesses = (/2,2/)
   res@xyDashPattern = 0
   res@trYReverse = True	;Invert the pressure axis
   res@xyYStyle = "Log"		;Make the pressure axis logarithmic
   res@tmYLMode = "Explicit"	;Explicitly set the tick marks and labels below
   res@tfPolyDrawOrder = "Draw"
;   res@tmYLValues = (/100,150,200,250,300,350,400,450,500,600,700,800,900,1000/)
;   res@tmYLLabels = (/100,150,200,250,300,350,400,450,500,600,700,800,900,1000/)
    res@tmYLValues = (/150,200,300,400,500,600,700,800,900,1000/)
    res@tmYLLabels = (/150,200,300,400,500,600,700,800,900,1000/)

   ;----------------------------;
   ;Set x and y axis min and max;
   ;----------------------------;
   res@trXMinF = 0.
   res@trXMaxF = 4.
   res@trYMinF = 150.
   res@trYMaxF = 1020.

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
   res@xyExplicitLegendLabels = (/"Stability","Shear"/)

   res@gsnDraw  = False
   res@gsnFrame = False
   plot = gsn_csm_xy (wks,data,pres,res)

   ;-----------------------------;
   ;Add BRCH<0.25 indicator lines;
   ;-----------------------------;
   lineres = True
   lineres@gsLineColor   = "magenta"
   lineres@gsLineThicknessF = 7.0
   lines = new(brch25ind_size,graphic)
   x_coord_line = new(2,float)
   y_coord_line = new(2,float)
   x_coord_line = (/0.,4./)
   i=0
   if(.not.all(ismissing(brch25ind)))
      do while (i.lt.brch25ind_size)
         y_coord_line = (/pres(brch25ind(i)),pres(brch25ind(i))/)
	 print(y_coord_line)
         lines(i) = gsn_add_polyline(wks,plot,x_coord_line,y_coord_line,lineres)
         delete(y_coord_line)
         i=i+1
      end do
   end if

   ;-----------------;
   ;Add height labels;
   ;-----------------;
   txres = True
   txres@txFontHeightF = 0.01
   text = gsn_add_text(wks,plot,hght_label_string,x_coord,pres_coord,txres)

   ;------------------------------------------------;
   ;Draw plot, delete arrays, and iterate loop index;
   ;------------------------------------------------;
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
   delete(x_coord_line)
   delete(hght_label_string)
   delete(text)
   delete(brch25ind)
   delete(brch25ind_size)
   delete(lines)

   index = index+1

end do

system("rm *.tmp")
