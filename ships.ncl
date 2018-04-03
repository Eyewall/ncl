;**************************************************
; skewt_frd.ncl
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "skewt_func.ncl"
;**************************************************

;--------------------;
;Get SHIPS text files;
;--------------------;
num_newfiles = 0
do while(num_newfiles.eq.0)
   system("wget -N 'ftp://ftp.nhc.noaa.gov/atcf/stext/*.txt'")
   system("find ./archive/ -name '*.txt' > files.tmp")
   system("diff archive.log files.tmp > newfiles.tmp")
   num_newfiles = stringtoint(systemfunc("wc newfiles.tmp | awk '{print($1)}'"))
   if(num_newfiles.eq.0)then   ;If no new files, sleep for 5 minutes
      sleep(60*5)
   end if
end do
infiles = systemfunc("sed 1d newfiles.tmp | colrm 1 2")

;--------------------------;
;Loop through all new files;
;--------------------------;
nfiles = dimsizes(infiles)
do j = 0,nfiles-1
   infile = systemfunc("ls "+dir+"*.txt")
   
   ;----------------------;
   ;Get header information;
   ;----------------------;
   name = systemfunc("sed -n 3p "+infile+" | awk '{print($2)}'")
   date = systemfunc("sed -n 3p "+infile+" | awk '{print($4)}'")
   time = systemfunc("sed -n 3p "+infile+" | awk '{print($5)}'")+" UTC"
   
   infile_split = str_split(infile,"/")
   filename = systemfunc("echo "+infile_split(4)+" | colrm 21")
   
   ;--------------------------------------;
   ;Get maximum wind (kt) from decay SHIPS;
   ;--------------------------------------;
   system("sed '10,83d' "+infile+" | sed '1,5d' | colrm 1 15 > ships.tmp")
   nrows = stringtoint(systemfunc("wc ships.tmp | awk '{print($1)}'"))
   data = asciiread("ships.tmp",4,"string")
   vmax_land = stringtofloat(str_split(data(1)," "))
   delete(data)
   
   ;------------------------------------------------;
   ;Get individual contributions to intensity change;
   ;------------------------------------------------;
   system("sed '58,83d' "+infile+" | sed '56d' | sed '1,37d' | colrm 1 24 > ships.tmp")
   data = asciiread("ships.tmp",19,"string")
   smc      = stringtofloat(str_split(data(0)," "))	;Sample mean change
   sst_pot  = stringtofloat(str_split(data(1)," "))	;SST potential
   vshr_mag = stringtofloat(str_split(data(2)," "))	;Vertical shear magnitude
   vshr_adj = stringtofloat(str_split(data(3)," "))	;Vertical shear adjusted
   vshr_dir = stringtofloat(str_split(data(4)," "))	;Vertical shear direction
   persist  = stringtofloat(str_split(data(5)," "))	;Persistence
   trop_tmp = stringtofloat(str_split(data(6)," "))	;200/250 mb temperature
   thte_exc = stringtofloat(str_split(data(7)," "))	;Theta-e excess
   mid_rh   = stringtofloat(str_split(data(8)," "))	;700-500 mb relative humidity
   gfs_vort = stringtofloat(str_split(data(9)," "))	;GFS vortex tendency
   env_vort = stringtofloat(str_split(data(10)," "))	;850 mb environmental vorticity
   upr_div  = stringtofloat(str_split(data(11)," "))	;200 mb divergence
   tmp_adv  = stringtofloat(str_split(data(12)," "))	;850-700 temperature advection
   motion   = stringtofloat(str_split(data(13)," "))	;Zonal storm motion
   str_lvl  = stringtofloat(str_split(data(14)," "))	;Steering level pressure
   clim_pk  = stringtofloat(str_split(data(15)," "))	;Days from clim. peak
   goes     = stringtofloat(str_split(data(16)," "))	;GOES predictors
   ohc      = stringtofloat(str_split(data(17)," "))	;Ocean heat content
   total    = stringtofloat(str_split(data(18)," "))	;Total change
   hours = (/6,12,18,24,36,48,60,72,84,96,108,120/)*1.
   
   ;-------------------------------;
   ;Find minimum and maximum values;
   ;-------------------------------;
   mins = new(19,"float")
   maxs = new(19,"float")
   do i=0,18
      mins(i) = min(stringtofloat(str_split(data(i)," ")))
      maxs(i) = max(stringtofloat(str_split(data(i)," ")))
   end do
   
   ;------------------------------------;
   ;Put data into one array for plotting;
   ;------------------------------------;
   contribs = new((/19,12/),"float")
   do i=0,18
      contribs(i,:) = stringtofloat(str_split(data(i)," "))
   end do
   
   ;--------------------------------------;
   ;Plot contributions to intensity change;
   ;--------------------------------------;
   linethicknesses = mins
   linethicknesses = 4
   linethicknesses(18) = 6
   linedashes = linethicknesses
   linedashes = 0
   wks = gsn_open_wks("png",filename)
   res = True
   res@tiMainFontHeightF = 0.02
   res@tiXAxisFontHeightF = 0.02
   res@tiYAxisFontHeightF = 0.02
   res@tiMainString  = date+" "+time+" SHIPS Predictor Contributions"
   res@tiXAxisString = "Forecast hour"
   res@tiYAxisString = "Contribution to intensity change [kt]"
   ;res@xyLineColors  = (/"red","magenta","blue","cadetblue","green","darkgreen","orange",\
   ;                      "orchid","purple","red4","grey20","grey50","palevioletred",\
   ;                      "lightslateblue","mistyrose3","tan","springgreen","sienna",\
   ;                      "black"/)
   res@xyLineColors = (/"red","red4","blue","blue4","green","green4","magenta","magenta4",\
                        "cyan","cyan4","darkorange","darkorange4","purple","purple4",\
                        "gold","gold4","grey20","grey50","black"/)
   res@xyLineThicknesses = linethicknesses
   res@xyDashPattern = linedashes
   res@trXMinF = 6
   res@trXMaxF = 120
   res@trYMinF = min(mins)-1
   res@trYMaxF = max(maxs)+1
   res@tmXBMode = "Explicit"
   res@tmXBValues = (/6,12,18,24,36,48,60,72,84,96,108,120/)*1.
   res@tmXBLabels = (/6,12,18,24,36,48,60,72,84,96,108,120/)*1.
   
   res@tmXTOn = False
   res@tmYROn = False
   
   res@tfPolyDrawOrder = "Draw"
   res@gsnDraw = False
   res@gsnFrame = False
   plot = gsn_csm_xy(wks,hours,contribs,res)
   
   polyres = True
   polyres@gsFillColor = "gray"
   polyres@gsFillIndex = 8
   dum = gsn_add_polygon(wks,plot,(/6,120,120,6/),(/min(mins)-1,min(mins)-1,0,0/),polyres)
   
   draw(plot)
   frame(wks)
   
   system("\rm ships.tmp")
end do
