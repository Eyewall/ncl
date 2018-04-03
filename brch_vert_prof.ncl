load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;Path to directory which contains data
dir = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/calcs/brch/"

;Store list of files in array and get data
files = systemfunc("ls "+dir+"*datv") ;List of files in directory
nfiles = dimsizes(files) ;Number of files in directory
ncols = 11 ;Number of columns of data in each file
nhead = 7  ;Number of lines in the header to be chopped off

;Set up station names and numbers
stn_names = (/"KLCH","KDTX","KAAA","TSJU","KTPA","KEYW","KGSO","KJAX","KBNA",\
             "KTOP","KCAR","KGRB","KFFC","KMIA","KIAD","KMHX","KTLH","KHWV"/)
stn_nmbrs = (/"03937","04830","04833","11641","12842","12850","13723","13889",\
             "13897","13996","14607","14898","53819","92803","93734","93768",\
             "93805","94703"/)
count = 0
do while (count.lt.nfiles)
   count = count + 1
   print("Plotting image "+count+" of "+nfiles)
   count = count - 1

   ;----------------------------------;
   ;Get info from sounding file header;
   ;----------------------------------;
   stn_nmbr = systemfunc("sed -n 4p "+files(count)+" | awk '{print $6}'")
   dattimslash = systemfunc("sed -n 4p "+files(count)+" | awk '{print $9}'")
   nlines = stringtoint(systemfunc("cat "+files(count)+" | wc | awk '{print $1}'"))
   datatable  = readAsciiTable(files(count),ncols,"float",nhead)
   dattimsplit = str_split(dattimslash, "/")
   dattim = dattimsplit(0)+"_"+dattimsplit(1)
   stn_name = stn_names(ind(stn_nmbr.eq.stn_nmbrs))

   ;---------;
   ;Read data;
   ;---------;
   data = readAsciiTable(files(count),ncols,"float",nhead)
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
   i = 0
   j = 0
   hght_label = new(hght_label_size,"float")
   pres_coord = new(hght_label_size,"float")
   x_coord    = new(hght_label_size,"float")
   do while(i .lt. hght_label_size)
      hght_label(i) = hght(j)
      pres_coord(i) = pres(j)
      x_coord(i)    = 4.8
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
   wks = gsn_open_wks("png",stn_name+dattim)
   res = True
   res@tiMainString  = "DATE/TIME: "+dattim+"      "+stn_name
   res@tiXAxisString = "Bulk Richardson Number"
   res@tiYAxisString = "Pressure [mb]"
   res@xyLineColors = (/"blue"/)
   res@xyLineThicknesses = (/3/)
   res@xyDashPattern = 0
   res@trYReverse = True        ;Invert the pressure axis
   res@xyYStyle = "Log"         ;Make the pressure axis logarithmic
   res@tmYLMode = "Explicit"    ;Explicitly set the tick marks and labels below
   res@tfPolyDrawOrder = "Draw"
   res@tmYLValues = (/150,200,300,400,500,600,700,800,900,1000/) ;Tick mark values
   res@tmYLLabels = (/150,200,300,400,500,600,700,800,900,1000/) ;Tick mark labels
   res@trXMinF = 0.	;X axis min
   res@trXMaxF = 5.	;X axis max
   res@trYMinF = 150.	;Y axis min
   res@trYMaxF = 1020.	;Y axis max
   res@gsnDraw = False  ;Don't draw plot until we overlay height labels
   res@gsnFrame = False ;and BRCH<0.25 indicator lines

   plot = gsn_csm_xy(wks,brch,pres,res)

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
   i=0
   if(.not.all(ismissing(brch25ind)))
      do while (i.lt.brch25ind_size)
         y_coord_line = (/pres(brch25ind(i)),pres(brch25ind(i))/)
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
   delete(hght_label_string)
   delete(text)
   delete(brch25ind)
   delete(lines)

   count = count + 1
end do
