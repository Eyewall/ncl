;**************************************************
; skewt_3.ncl
;
; Concepts illustrated:
;   - Drawing Skew-T plots
;   - Thinning the wind barbs in a Skew-T plot
;   - Customizing the background of a Skew-T plot
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;**************************************************

; --- Read Data ----------------------------------------;
;dropdir = "/jm13/djv/soundings/NOAM_6sec/pduran_sondes/processed/sondes/"
dropdir =  "/jm13/pduran/rawinsondes/allsondes_brch/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"
identifiers = (/"allhurricanes","ts+td"/)
identifiers = "allsondes"
do ids=0,dimsizes(identifiers)-1
   ;idfiles = systemfunc("ls /jm13/pduran/ncl/*hurricanes*.idlist")
   ;idfiles = systemfunc("ls /jm13/pduran/unix_scripts_and_c++/2014/"+identifiers(ids)+"/200kmbins/"+identifiers(ids)+"*.idlist")
   idfiles = systemfunc("ls /jm13/pduran/unix_scripts_and_c++/2014/allsondes_overlap/*km")
   ;idfiles = systemfunc("ls /jm13/pduran/unix_scripts_and_c++/2014/"+identifiers(ids)+"/200kmbins/overlap/*idlist")
   nidfiles = dimsizes(idfiles)
   
   trop_pres_avg = new(nidfiles,"float")
   trop_pres_avg@_FillValue = -9999
   trop_hght_avg = trop_pres_avg 
   trop_temp_avg = trop_pres_avg 
   trop_pres_stddev = trop_pres_avg 
   trop_hght_stddev = trop_pres_avg 
   trop_temp_stddev = trop_pres_avg 
   nsondes_array = new(nidfiles,"integer")
   nsondes_array@_FillValue = -9999
   rad_bin = new(nidfiles,"string")
   do i=0,nidfiles-1
      idfile = idfiles(i)
      unixi = i + 1
      idfile_split = str_split(idfile,"_")
      rad_bin_split = str_split(idfile_split(4),".")
      rad_bin(i) = rad_bin_split(0)
      ndrops  = stringtoint(systemfunc("wc "+idfile+" | awk '{print $1}'"))
      trop_pressures = new(ndrops,"float") ;Array for NCL-calculated tropopauses
      trop_pressures@_FillValue = -9999
      trop_heights   = trop_pressures 
      trop_temps     = trop_pressures 
      nsondes = 0
      do drop=0,ndrops-1
         unixdrop = drop + 1
         print("Processing sonde "+unixdrop+" of "+ndrops+" in idfile "+unixi+" of "+nidfiles)
   
         stn = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($1)}' | colrm 1 2")
         dattime = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($3)}'")
         dropfile = dropdir+stn+"-"+dattime+suffix
   
         if(.not.ismissing(systemfunc("ls "+dropfile)))then
            DropData  = readAsciiTable(dropfile,13,"float",7)
            p   = DropData(:,0)
            tc  = DropData(:,1)
            tdc = DropData(:,2)
            z   = DropData(:,5)
            u   = DropData(:,3) * 1.94384449 ;Convert to kt
            v   = DropData(:,4) * 1.94384449
            p@_FillValue = -9999.
            tc@_FillValue = -9999.
            tdc@_FillValue = -9999.
            z@_FillValue = -9999.
            u@_FillValue = (-9999. * 1.94384449)
            v@_FillValue = (-9999. * 1.94384449)
            
            ;Convert units and determine tropopause height
            if(.not.all(ismissing(p)))then
               p_invert = p(::-1)      ;Pressure must be monotonically increasing
               tc_invert = tc(::-1)    ;Must also invert temperature so it will match with p
               tk = tc_invert + 273.15 ;Temperature must be Kelvin
               trop_pres = trop_wmo(p_invert,tk,0,False)    ;Pressure altitude of tropopause [hPa]
               trop_pres = where(trop_pres.eq.-999,-9999,trop_pres)
               trop_pres@_FillValue = -9999
               if(.not.ismissing(trop_pres))then
                  trop_pressures(drop) = trop_pres
                  trop_heights(drop)   = z(minind(abs(trop_pres-p)))  ;Altitude of tropopause [m]
                  trop_temps(drop)     = tc(minind(abs(trop_pres-p)))
                  nsondes = nsondes + 1
               end if
               delete([/p_invert,tc_invert,tk/]) 
            end if   ;if(.not.all(ismissing(p)))
            delete([/DropData,p,tc,tdc,z,u,v/])
         end if   ;if(ndroplevels.gt.7)
      end do   ;Drops loop
     
      ;Calculate averages and standard deviations 
      trop_pres_avg(i) = avg(trop_pressures)
      trop_hght_avg(i) = avg(trop_heights)
      trop_temp_avg(i) = avg(trop_temps)
      trop_pres_stddev(i) = stddev(trop_pressures)
      trop_hght_stddev(i) = stddev(trop_heights)
      trop_temp_stddev(i) = stddev(trop_temps)
      nsondes_array(i) = nsondes
      
      ;Write out individual tropopause data to output files for each idfile
      outfilename = "trops_"+identifiers(ids)+"_"+i+"_wmo.txt"
      ioutput = [/trop_pressures,trop_heights,trop_temps/]
      write_table(outfilename,"w",ioutput,"%16.1f%16.1f%16.1f")
      delete([/trop_pressures,trop_heights,trop_temps/])
   
      ;Write averages and standard deviations to output file
      header = new(2,"string")
      header(0) = "RADIAL BIN   AVG TROP PRES   SIGMA TROP PRES   AVG TROP HGHT   SIGMA TROP HGHT   AVG TROP TEMP   SIGMA TROP TEMP   NSONDES"
      header(1) = "----------   -------------   ---------------   -------------   ---------------   -------------   ---------------   -------"
      output = [/rad_bin,trop_pres_avg,trop_pres_stddev,trop_hght_avg,trop_hght_stddev,trop_temp_avg,trop_temp_stddev,nsondes_array/]
      asciiwrite("header"+identifiers(ids)+".txt",header)
      write_table("temp"+identifiers(ids)+".txt","w",output,"%8s%14.1f%16.1f%16.1f%16.1f%16.1f%16.1f%12i")   
      system("cat header"+identifiers(ids)+".txt temp"+identifiers(ids)+".txt > trop_avgs_"+identifiers(ids)+"_wmo.txt")
      system("\rm header"+identifiers(ids)+".txt temp"+identifiers(ids)+".txt")
   
   end do
end do
