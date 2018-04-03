load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

flag = 0   ;Set to 0 for plots of 4 times on same plot
           ;Set to 1 for plots of 0-500 and 500-1000 km avgs @ same time
nsmth = 10 ;Number of times to apply 1-2-1 smoother in the vertical
hour = "00"  ;Only used if flag = 1

if(flag.eq.0)then
   infile1 = "/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/200kmbins/avg/0-400km/allhurricanes_0-400.idlist.ncnt.245.avgedit"
   infile2 = "/jm13/pduran/unix_scripts_and_c++/2014/ts+td/200kmbins/avg/0-400km/ts+td_0-400.idlist.ncnt.1019.avgedit"

   file1 = readAsciiTable(infile1,28,"float",7)
   file2 = readAsciiTable(infile2,28,"float",7)
   
   ;-------------------------------------------------------------;
   ;To plot multiple curves, put data into multidimensional array;
   ;-------------------------------------------------------------;
   data = new((/2,201/),"float")
   data(0,:) = file1(:,9)
   data(1,:) = file2(:,9)  
   data@_FillValue = -9999.
stab = file2(:,9)
shear = file2(:,11)

   ;APPLY 1-2-1 SMOOTHER IN THE VERTICAL
   data_smth = data
   apply = 0
   do while(apply.lt.nsmth)
      do j=0,1
         data_smth(j,:) = wgt_runave(data_smth(j,:),(/0.25,0.50,0.25/),0)
         print("Smoothed dimension "+j+" for the "+apply+"th time")
      end do
      apply = apply + 1
   end do
   
   hghts = file1(:,5)
   hghts = hghts / 1000 ;Convert to km

;stab_at_shear_max = stab(maxind(shear(90:))+90)
;print(stab_at_shear_max)
;exit
   
   ;----------------------;
   ;Set plotting resources;
   ;----------------------;
   wks_res = "png"
   ;wks_res@wkOrientation = "portrait"
   ;wks_res@wkPaperWidthF = 3.25
   ;wks_res@wkPaperHeightF = 4.206
   wks = gsn_open_wks(wks_res,"rb_numerator_avgs_by_intensity")
   
   res = True
   res@gsnMaximize = True
   res@gsnPaperOrientation = "portrait"
   res@gsnPaperMargin = 0.
;   res@tiMainString = "RB Numerator Averages (0-500 km, N=252)"
;   res@tiXAxisString = "Shear Term"
   res@tiYAxisString = "Height (km)"
   res@xyLineColors = (/"red","blue"/)
   res@xyLineThicknesses = (/3,3/)
   res@xyDashPattern = 0
   res@trXMinF = 0    ;X axis min
   res@trXMaxF = 3     ;X axis max
   res@trYMinF = 9.   ;Y axis min
   res@trYMaxF = 17.  ;Y axis max
   res@tmYROn = False
   res@tmXTOn = False
   
   ;------------;
   ;Add a legend;
   ;------------;
   res@pmLegendDisplayMode = "Always"
   res@pmLegendSide = "Right"
   res@pmLegendOrthogonalPosF = -0.335 ;Move legend left
   res@pmLegendParallelPosF   = 0.1 ;Move legend down
   res@pmLegendWidthF = 0.20
   res@pmLegendHeightF = 0.10
   res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
   res@lgPerimOn = False             ;Turn on/off box around legend
   res@lgLabelFontHeightF = 0.02
   res@xyExplicitLegendLabels = (/"Hurricanes","TD+TS"/)
   res@gsnDraw = False
   res@gsnFrame = False

   plot = gsn_csm_xy(wks,data_smth,hghts,res)

   ;---------------;
   ;Add panel label;
   ;---------------;
   txres = True
   txres@txFontHeightF = 0.03
   txres@txPerimOn = True
   txres@txPerimSpaceF = 0.3
   txres@txBackgroundFillColor = "white"
   txres@txJust = "topleft"   
   dum1 = gsn_add_text(wks,plot,"a) Stability Term",0,17,txres)

   draw(plot)
   frame(wks)

else if(flag.eq.1)then
   infile1 = systemfunc("ls /jm13/pduran/unix_scripts_and_c++/allsondes_"+hour+"z_avg/*-0-500*.avgedit")
   infile2 = systemfunc("ls /jm13/pduran/unix_scripts_and_c++/allsondes_"+hour+"z_avg/*-500-1000*.avgedit")
   file1 = readAsciiTable(infile1,28,"float",7)
   file2 = readAsciiTable(infile2,28,"float",7)

   ;-------------------------------------------------------------;
   ;To plot multiple curves, put data into multidimensional array;
   ;-------------------------------------------------------------;
   data = new((/2,201/),"float")
   data(0,:) = file1(:,11)
   data(1,:) = file2(:,11)  
   data@_FillValue = -9999.
   print(data)
    
   hghts = file1(:,5)
   hghts = hghts / 1000 ;Convert to km

   ;----------------------;
   ;Set plotting resources;
   ;----------------------;
   wks_res = "png"
   ;wks_res@wkOrientation = "portrait"
   ;wks_res@wkPaperWidthF = 3.25
   ;wks_res@wkPaperHeightF = 4.206
   wks = gsn_open_wks(wks_res,"rb_numerator_avgs_by_radius"+hour+"UTC")

   res = True
   res@gsnMaximize = True
   res@gsnPaperOrientation = "portrait"
   res@gsnPaperMargin = 0.
   res@tiMainString = "RB Numerator Averages ("+hour+" UTC)"
   res@tiXAxisString = "RB Numerator"
   res@tiYAxisString = "Height (km)"
   res@xyLineColors = (/"red","blue"/)
   res@xyLineThicknesses = (/3,3/)
   res@xyDashPattern = 0
   res@trXMinF = 0.6    ;X axis min
   res@trXMaxF = 1.4     ;X axis max
   res@trYMinF = 9.   ;Y axis min
   res@trYMaxF = 14.  ;Y axis max
   res@tmYROn = False
   res@tmXTOn = False

   ;------------;
   ;Add a legend;
   ;------------;
   res@pmLegendDisplayMode = "Always"
   res@pmLegendSide = "Right"
   res@pmLegendOrthogonalPosF = -0.325 ;Move legend left
   res@pmLegendParallelPosF   = 0.1 ;Move legend down
   res@pmLegendWidthF = 0.20
   res@pmLegendHeightF = 0.10
   res@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
   res@lgPerimOn = False             ;Turn on/off box around legend
   res@lgLabelFontHeightF = 0.02
   res@xyExplicitLegendLabels = (/"0-500 km","500-1000 km"/)

   plot = gsn_csm_xy(wks,data,hghts,res)
end if
end if
