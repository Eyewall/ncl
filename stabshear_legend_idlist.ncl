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

class   = "allhurricanes"
time    = "00z"
dropdir = "/jm13/pduran/1+6sec_sondes_SEP2014_brch/"
iddir   = "/jm13/pduran/unix_scripts_and_c++/2014/"+class+"/200kmbins/avg/"+time+"/"
suffix  = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"

idfiles = systemfunc("ls "+iddir+"*z")
nidfiles = dimsizes(idfiles)
;do index=0,nidfiles-1
   do index=0,1
   unixi = index + 1
   ;radbin = systemfunc("echo "+idfiles(index)+" | cut -d'/' -f8 | cut -d'_' -f2 | cut -d'.' -f1")
   radbin = systemfunc("echo "+idfiles(index)+" | cut -d'/' -f10 | cut -d'_' -f2")
   idlist = systemfunc("cat "+idfiles(index))
   ndrops = dimsizes(idlist)
   drop = 0
   system("mkdir "+class+"_"+radbin+"_"+time+"_stabshear")
   do drop=0,ndrops-1
      unixdrop = drop + 1
      print("Plotting image "+unixdrop+" of "+ndrops+" in idfile "+unixi+" of "+nidfiles)
      stn = systemfunc("echo "+idlist(drop)+" | awk '{print($2)}'")
      dattim = systemfunc("echo "+idlist(drop)+" | awk '{print($4)}'")
      dropfile = stn+"-"+dattim+suffix
      if(.not.ismissing(systemfunc("ls "+dropdir+dropfile)))then
         nlines = stringtoint(systemfunc("cat "+dropdir+dropfile+" | wc | awk '{print $1}'"))
         datatable  = readAsciiTable(dropdir+dropfile,13,"float",7)
         upperbound = nlines - 7

         ;-------------------------------------------------------------;
         ;To plot multiple curves, put data into multidimensional array;
         ;-------------------------------------------------------------;
         data = new((/2,upperbound/),float)
         data(0,:) = datatable(:upperbound-1,9)  ;STAB values
         data(1,:) = datatable(:upperbound-1,11) ;VSHR values
         hght      = datatable(:upperbound-1,5)
         pres      = datatable(:upperbound-1,0)
         brch      = datatable(:upperbound-1,10)
         data@_FillValue = -9999. 
         hght@_FillValue = -9999.
         pres@_FillValue = -9999.
         brch@_FillValue = -9999.

         ;--------------------------;
         ;Get data for height labels;
         ;--------------------------;
;         hght_label_size = dimsizes(hght)/2
;         i = 0
;         j = 0
;         hght_label = new(hght_label_size,"float")
;         pres_coord = new(hght_label_size,"float")
;         x_coord    = new(hght_label_size,"float")
;         do while(i .lt. hght_label_size)
;            hght_label(i) = hght(j)
;            pres_coord(i) = pres(j)
;            x_coord(i)    = 3.8
;            i=i+1
;            j=j+2
;         end do
;         hght_label_string = flt2string(hght_label)

         if(.not.all(ismissing(ind(brch.lt.0.25))))
            hght_coord = hght(ind(brch.lt.0.25))
            hght_label = flt2string(hght_coord)
            x_coord = new(dimsizes(hght_label),"float")
            x_coord = max(data(1,:))
         else
            hght_coord = -9999
            hght_label = -9999
            x_coord = -9999
         end if

         ;--------------------------------------;
         ;Get data for BRCH<0.25 indicator lines;
         ;--------------------------------------;
         brch25ind = ind(brch.lt.0.25)
         brch25ind_size = dimsizes(brch25ind)
         brch25ind@_FillValue = -999

         ;----------------------;
         ;Set plotting resources;
         ;----------------------;
         filename = class+"_"+radbin+"_"+stn+"-"+dattim+"_"+time+"_stabshear"
         wks = gsn_open_wks("png",filename)
         res  = True
         res@tiMainString  = "DATE/TIME: "+dattim+"      STATION: "+stn
         res@tiXAxisString = "Shear and Stability Terms"
         res@tiYAxisString = "Height [m]"
         res@xyLineColors = (/"red","blue"/)
         res@xyLineThicknesses = (/2,2/)
         res@xyDashPattern = 0
;         res@trYReverse = True	;Invert the pressure axis
;         res@xyYStyle = "Log"		;Make the pressure axis logarithmic
;         res@tmYLMode = "Explicit"	;Explicitly set the tick marks and labels below
         res@tfPolyDrawOrder = "Draw"
;         res@tmYLValues = (/100,150,200,250,300,350,400,450,500,600,700,800,900,1000/)
;         res@tmYLLabels = (/100,150,200,250,300,350,400,450,500,600,700,800,900,1000/)
;          res@tmYLValues = (/50,100,150,200,300,400,500,600,700,800,900,1000/)
;          res@tmYLLabels = (/50,100,150,200,300,400,500,600,700,800,900,1000/)
          res@gsnMaximize = True

         ;----------------------------;
         ;Set x and y axis min and max;
         ;----------------------------;
         res@trXMinF = 0.
         res@trXMaxF = max(data(1,:))
         res@trYMinF = 0
         res@trYMaxF = 20

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
         plot = gsn_csm_xy (wks,data,hght,res)

         ;-----------------------------;
         ;Add BRCH<0.25 indicator lines;
         ;-----------------------------;
         lineres = True
         lineres@gsLineColor   = "magenta"
         lineres@gsLineThicknessF = 7.0
         lines = new(brch25ind_size,graphic)
         x_coord_line = new(2,float)
         y_coord_line = new(2,float)
         x_coord_line = (/0.,max(data(1,:))/)
         i=0
         if(.not.all(ismissing(brch25ind)))
            do while (i.lt.brch25ind_size)
               y_coord_line = (/hght(brch25ind(i)),hght(brch25ind(i))/)
               ;print(y_coord_line)
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
         text = gsn_add_text(wks,plot,hght_label,x_coord,hght_coord,txres)

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
         delete(hght_coord)
         delete(x_coord)
         delete(x_coord_line)
;         delete(hght_label_string)
         delete(brch)
         delete(text)
         delete(brch25ind)
         delete(brch25ind_size)
         delete(lines)
      end if
   end do
   system("mv *"+class+"_"+radbin+"*stabshear.png "+class+"_"+radbin+"_"+time+"_stabshear")
   delete(idlist)
end do
