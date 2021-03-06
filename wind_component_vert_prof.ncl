load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

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
;Get data from files and plot it;
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
   data(0,:) = datatable(:upperbound-1,3) ;U values
   data(1,:) = datatable(:upperbound-1,4) ;V values
   hght      = datatable(:upperbound-1,5)
   pres      = datatable(:upperbound-1,0)
   data@_FillValue = -9999. 
   hght@_FillValue = -9999.
   pres@_FillValue = -9999.

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
      x_coord(i)    = 28.8
      i=i+1
      j=j+5
   end do
   hght_label_string = flt2string(hght_label)

   ;----------------------;
   ;Set plotting resources;
   ;----------------------;
   wks = gsn_open_wks("png",dattim)
   res  = True
   res@tiMainString  = "DATE/TIME: "+dattim+"      DROP ID: "+dropid
   res@tiXAxisString = "Wind Speed [m/s]"
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
   res@trXMinF = -30.
   res@trXMaxF = 30.
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
   res@xyExplicitLegendLabels = (/"U Comp","V Comp"/)

   res@gsnDraw  = False
   res@gsnFrame = False
   plot = gsn_csm_xy (wks,data,pres,res)

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
   delete(hght_label)
   delete(pres_coord)
   delete(x_coord)
   delete(hght_label_string)
   delete(text)

   index = index+1

end do
