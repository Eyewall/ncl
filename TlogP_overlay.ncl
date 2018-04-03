load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

prefix = "/jm13/pduran/allsondes_2014_1dir/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit"

stn1 =    "11641"
dattim1 = "0409010000"
stn2 =    "12919"
dattim2 = "9809110000" 
;infile 1 is major hurricane, infile2 is ts+td

outfilename = stn1+"-"+dattim1+"+"+stn2+"-"+dattim2

infile1 = prefix+stn1+"-"+dattim1+suffix
infile2 = prefix+stn2+"-"+dattim2+suffix

file1 = readAsciiTable(infile1,10,"float",7)
file2 = readAsciiTable(infile2,10,"float",7)

filesizes = new(2,"integer")
temp = dimsizes(file1)
filesizes(0) = temp(0)
temp = dimsizes(file2)
filesizes(1) = temp(0)

p1 = file1(:,0)
t1 = file1(:,1)
p2 = file2(:,0)
t2 = file2(:,1)

p1@_FillValue = -9999
p2@_FillValue = -9999
t1@_FillValue = -9999
t2@_FillValue = -9999

mint1 = min(t1)
mint2 = min(t2)
maxt1 = max(t1)
maxt2 = max(t2)

wks = gsn_open_wks("png",outfilename)

resR = True    ;Applies to right axis data
resR@gsnMaximize = True
resR@gsnPaperOrientation = "portrait"
resR@gsnPaperMargin = 0
resR@tiXAxisString = "Temperature (C)"
resR@tiYAxisString = "Pressure (mb)"
resR@trYReverse = True        ;Invert the pressure axist
resR@xyYStyle = "Log"         ;Make the pressure axis logarithmic
resR@tmYLMode = "Explicit"    ;Explicitly set the tick marks and labels below
resR@tfPolyDrawOrder = "Draw"
resR@tmYLValues = (/50,100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark values
resR@tmYLLabels = (/50,100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark labels
resR@trXMinF = min((/mint1,mint2/))     ;X axis min
resR@trXMaxF = max((/maxt1,maxt2/))     ;X axis max
resR@trYMinF = 50.   ;Y axis min
resR@trYMaxF = 1000.  ;Y axis max
resR@xyLineColors = "blue"
resR@xyLineThicknesses = 3
resR@xyExplicitLegendLabels = "TD or TS"
resR@pmLegendDisplayMode = "Always"
resR@pmLegendSide = "Right"
resR@pmLegendOrthogonalPosF = -0.5 ;Move legend left
resR@pmLegendParallelPosF   = 0.7 ;Move legend down
resR@pmLegendWidthF = 0.20
resR@pmLegendHeightF = 0.10
resR@lgBoxMinorExtentF = 0.15      ;Shorten the lines in the legend
resR@lgPerimOn = False             ;Turn on/off box around legend
resR@lgLabelFontHeightF = 0.02

resL = resR     ;Applies to left axis data
resL@xyLineColors = "red"
resL@xyLineThicknesses = 3

resR@tmYROn = False
resR@tmYRLabelsOn = False
resR@tiYAxisOn = False
resR@tiXAxisOn = False
resR@tmXTOn = False
resR@tmXTLabelsOn = False

resL@xyExplicitLegendLabels = "Major"
resL@pmLegendParallelPosF = 0.75

plot = gsn_csm_x2y2(wks,t1,t2,p1,p2,resL,resR)

exit


dropdir =  "/jm13/pduran/allsondes_2014_1dir/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit"
identifier = "ts+td"
;idfiles = systemfunc("ls /jm13/pduran/ncl/*hurricanes*.idlist")
idfiles = systemfunc("ls /jm13/pduran/unix_scripts_and_c++/2014/"+identifier+"/"+identifier+"*.idlist")
nidfiles = dimsizes(idfiles)

trop_avgs = new(nidfiles,"string")
do i=0,nidfiles-1
   idfile = idfiles(i)
   ndrops  = stringtoint(systemfunc("wc "+idfile+" | awk '{print $1}'"))
   trophghts = new(ndrops,"float")    ;Array for my tropopause height
   troptemps = new(ndrops,"float")    ;Array for tropopause temperature
   nsondes = 0
   drop = 0
   do while(drop.lt.ndrops)
      unixdrop = drop + 1
      print("Processing sonde "+unixdrop+" of "+ndrops+" in idfile "+i+" of "+nidfiles)
      ;--------;
      ;Get data;
      ;--------;
      stn = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($2)}'")
      dattime = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($4)}'")
      dropfile = dropdir+stn+"-"+dattime+suffix
      system("cp "+dropfile+" dropfile.tmp")
      ;Replace all -9999 values with -999. This is necessary because the script
      ;uses floats, for which the missing value flag is -999.
      system("`sed -i 's/-9999/-999/g' dropfile.tmp`")
      ndroplevels = stringtoint(systemfunc("cat dropfile.tmp | wc | awk '{print $1}'"))
      dropid = systemfunc("sed -n 4p dropfile.tmp | awk '{print $6}'")
      dattimslash = systemfunc("sed -n 4p dropfile.tmp | awk '{print $9}'")
      dattimsplit = str_split(dattimslash, "/")
      dattim = dattimsplit(0)+"_"+dattimsplit(1)
if(stringtoint(systemfunc("wc dropfile.tmp | awk '{print($1)}'")).gt.7)then
      DropData  = readAsciiTable("dropfile.tmp",10,"float",7)
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

   if((dimsizes(z).gt.100).and.(dimsizes(tc).gt.100))then  ;Only find tropopause
      ;------------------------------;            ;if we have data above z=10 km
      ;Find the cold point tropopause;
      ;------------------------------;
      tropopause_pressure = p(minind(tc(100:))+100)   ;Constrain to be able 10 km
      tropopause_height   = z(minind(tc(100:))+100)   ;(Subscript 100 = 10 km)
      tropopause_temp     = min(tc(100:))
      tropopause_pressure@_FillValue = -999
      tropopause_height@_FillValue = -999     
      tropopause_temp@_FillValue = -999
      tropind = minind(tc(100:))+100       ;Index of cold point tropopause

      if(tropind.lt.max(ind(z)))then   ;Make sure we're getting an actual CPT and not
         trophghts(drop) = tropopause_height
         troptemps(drop) = tropopause_temp      
      end if

      if(.not.ismissing(tropopause_height))then
         nsondes = nsondes + 1
      end if
   end if
      ;--------------------;
      ;Delete old variables;
      ;--------------------;
      delete(DropData)
      delete(p)
      delete(tc)
      delete(tdc)
      delete(z)
      delete(u)
      delete(v)
end if
   drop = drop + 1
   end do
   ;Calculate average tropopause for this radial bin and the standard deviation
   trop_hght_avg = avg(trophghts)
   trop_temp_avg = avg(troptemps)
   trop_hght_stddev = dim_stddev(trophghts)
   trop_temp_stddev = dim_stddev(troptemps)
   trop_avgs(i) = systemfunc("echo "+idfile+" | colrm 1 34")+"  Height Avg: "+trop_hght_avg+"   Height Stdev: "+trop_hght_stddev+"  Temp Avg: "+trop_temp_avg+"  Temp Stdev: "+trop_temp_stddev+"  nsondes: "+nsondes
   asciiwrite("trophghts_"+identifier+"_"+i+"_CPT.txt",trophghts)
   asciiwrite("troptemps_"+identifier+"_"+i+"_CPT.txt",troptemps)
   delete(trophghts)
   delete(troptemps)
   print(trop_avgs)
end do
   asciiwrite("trop_avgs_500m_"+identifier+"_wmo.txt",trop_avgs)

