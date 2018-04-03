load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;------------------------------------------------------------------
;average_tropopause_by_station.ncl
;Patrick duran
;6/19/2014
;
;Reads in an idlist file, finds all unique stations, and calculates
;an average tropopause each station. Writes station ID and 
;corresponding average tropopaus height to tropopause_averages.txt.
;------------------------------------------------------------------

idfile = "/jm13/pduran/unix_scripts_and_c++/2014/allsondes_0-1000"
dropdir =  "/jm13/pduran/allsondes_2014_subdirs/xxxxx/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit"

   station = xxxxx
   soundings = systemfunc("ls "+dropdir)
   theirtrops = new(dimsizes(soundings),"float")
   nsoundings = dimsizes(soundings)   ;Number of sounding files in the directory
   nsondes = 0                        ;Number of usable sondes
   do k=0,nsoundings-1
      unixk = k + 1
      nlines = stringtoint(systemfunc("wc "+dropdir+"/"+soundings(k)+" | awk '{print($1)}'"))
      if(nlines.gt.7)then 
         sounding = dropdir+"/"+soundings(k)
         print(soundings(k)+"  "+systemfunc("date"))
         DropData = readAsciiTable(sounding,10,"float",7)
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
   
         ;Convert units and determine tropopause height
         p_invert = p(::-1)     ;Pressure must be monotonically increasing
         tc_invert = tc(::-1)   ;Must also invert temperature so it will match with p
         tk = tc_invert + 273.15       ;Temperature must be Kelvin
         opt = False
         trop_hght = trop_wmo(p_invert,tk,0,opt)    ;Pressure altitude of tropopause [hPa]
         trop_hght@_FillValue = -999
         if(.not.ismissing(trop_hght))then
            trop_hght_z = z(minind(abs(trop_hght-p)))  ;Altitude of tropopause [m]
         end if
   
         ;--------------------;
         ;Calculate lapse rate;
         ;--------------------;
   ;      ztop = max(ind(z))
   ;      tctop = max(ind(tc))
   ;      top = min((/ztop,tctop/))
   ;      z1  = z(0:top-1)   ;Offset height arrays by 1
   ;      z2  = z(1:top)      
   ;      tc1 = tc(0:top-1) ;Offset temperature arrays by 1
   ;      tc2 = tc(1:top)    
   ;      tdiffs = tc2 - tc1  ;Finite temperature differences between each level
   ;      zdiffs = z2 - z1    ;Finite height differences between each level
   ;      lapse_rate = tdiffs / zdiffs   ;Lapse rate [*C/m]
   ;      lapse_rate = lapse_rate * 1000 ;Convert to [*C/km]
   ;      if(.not.all(ismissing(p)))then   
   ;         ;Now calculate average lapse rate over 2 km above current level
   ;         ninds = dimsizes(lapse_rate)
   ;         avg_lapse_rate = new(ninds,"float")
   ;         do j=0,ninds-21
   ;         do j=0,ninds-11
   ;            avg_lapse_rate(j) = avg(lapse_rate(j:(j+20)))
   ;            avg_lapse_rate(j) = avg(lapse_rate(j:(j+10)))
   ;         end do
   ;         if(.not.ismissing((min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2))))))then
   ;            tropopause_pressure = p(min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2))))
   ;            tropopause_pressure@_FillValue = -999
   ;            if(.not.ismissing(tropopause_pressure))then
   ;               tropopause_height = z(min(ind((lapse_rate.gt.-2).and.(avg_lapse_rate.gt.-2))))
   ;            end if   
   ;            ;Write to tropopause pressure arrays so that averages may be calculated
   ;            mytrops(k) = tropopause_height
            if(.not.ismissing(trop_hght))then
               theirtrops(k) = trop_hght_z
               nsondes = nsondes + 1
             end if
   ;         end if
   
   
         ;--------------------;
         ;Delete old variables;
         ;--------------------;
         delete(DropData)
         delete(p)
         delete(p_invert)
         delete(tc_invert)
         delete(tk)
         delete(tc)
         delete(tdc)
         delete(z)
         delete(u)
         delete(v)
   ;      delete(z1)
   ;      delete(z2)
   ;      delete(tc1)
   ;      delete(tc2)
   ;      delete(tdiffs)
   ;      delete(zdiffs)
      end if
   end do    ;End sounding loop


   ;Calculate average tropopause for this station and the standard deviation
;   mytrops_avg = avg(mytrops)
   theirtrops_avg = avg(theirtrops)
;   mytrops_stddev = dim_stddev(mytrops)
   theirtrops_stddev = dim_stddev(theirtrops)
;   delete(mytrops)
   delete(theirtrops)

   ;Print to output file
   head = [/(/"Station ID    Avg Trop Height     Std Dev     nsondes"/)/]
   data = [/station,theirtrops_avg,theirtrops_stddev,nsondes/]
   write_table("/jm13/pduran/ncl/tropopause_averages.txt","a",data,"%s%8.2f%7.2f%4i")
   delete(soundings)
