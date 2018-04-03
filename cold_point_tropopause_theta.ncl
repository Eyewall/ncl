load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

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
   troppress = new(ndrops,"float")    ;Array for tropopause pressures
   troptheta = new(ndrops,"float")    ;Array for tropopause potential temperatures
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

      ;--------------------------------;
      ;Calculate potential temperatures;
      ;--------------------------------;
      tropopause_temp_k = tropopause_temp + 273.15
      theta_k = tropopause_temp_k*(1000./tropopause_pressure)^(287./1004.)   
      theta = theta_k - 273.15

      if(tropind.lt.max(ind(z)))then   ;Make sure we're getting an actual CPT and not
         trophghts(drop) = tropopause_height ;just top of the sounding
         troptemps(drop) = tropopause_temp      
         troppress(drop) = tropopause_pressure
         troptheta(drop) = theta
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
   trop_pres_avg = avg(troppress)
   trop_theta_avg = avg(troptheta)
   trop_hght_stddev = dim_stddev(trophghts)
   trop_temp_stddev = dim_stddev(troptemps)
   trop_pres_stddev = dim_stddev(troppress)
   trop_theta_stddev = dim_stddev(troptheta)

   trop_avgs(i) = systemfunc("echo "+idfile+" | colrm 1 34")+"  Height Avg: "+trop_hght_avg+"   Height Stdev: "+trop_hght_stddev+"  Trop Theta Avg: "+trop_theta_avg+"  Trop Theta Stdev: "+trop_theta_stddev+"  Trop Pres Avg: "+trop_pres_avg+"  Trop Pres Std Dev: "+trop_pres_stddev+"  nsondes: "+nsondes
   asciiwrite("troppress_"+identifier+"_"+i+"_CPT.txt",troppress)
   asciiwrite("troptheta_"+identifier+"_"+i+"_CPT.txt",troptheta)
   delete(trophghts)
   delete(troptemps)
   delete(troppress)
   delete(troptheta)
   print(trop_avgs)
end do
   asciiwrite("trop_avgs_CPT_"+identifier+"_theta.txt",trop_avgs)

