load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-----------------------------------------------------------------
;subcritical-frequency.ncl
;Patrick Duran
;2/8/2014
;
;Will read in a list of idlist files containing the station id,
;date/time, and radii (not used here), and perform the following:
;Will calculate the percentage of sondes with frequency less than
;that specified in the PARAMETERS section at each level of the
;input editsonde files. Output files will be written to the iddir
;directory specified under PARAMETERS with the suffix .freq.
;-----------------------------------------------------------------

;----------;
;PARAMETERS;
;----------;
iddir = "/jm13/pduran/unix_scripts_and_c++/allsondes_18z_avg/"
dropdir =  "/jm13/pduran/allsondes_brch/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_QC_QC2_400m_datv"
brch_thresh = 2.5    ;Threshold bulk Richardson number value
alt_max = 20000      ;Highest altitude [m]
dz = 100             ;Distance between each height level [m]

;----------;
;Get idlist;
;----------;
idfiles = systemfunc("ls "+iddir+"allintensities_random_uniform-*km")
nidfiles = dimsizes(idfiles)

nlevels_out = alt_max / dz + 1
hghts = ispan(0,alt_max,dz)
do i=0,nidfiles-1
   unixi = i + 1
   print("Processing idfile "+unixi+" of "+nidfiles+"  "+systemfunc("date"))
   idfile = idfiles(i)
   ndrops  = stringtoint(systemfunc("wc "+idfile+" | awk '{print $1}'"))
   subcrit_obs = new(nlevels_out,float,-9999)
   total_obs = new(nlevels_out,float,-9999)
   subcrit_obs = 0
   total_obs = 0
   do drop=0,ndrops-1
      unixdrop = drop + 1
      print("Processing sonde "+unixdrop+" of "+ndrops+" in idfile "+unixi+" of "\
            +nidfiles+"  "+systemfunc("date"))
      ;--------;
      ;Get data;
      ;--------;
      stn = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($1)}' | colrm 1 2")
      dattime = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($3)}'")
      dropfile = dropdir+stn+"-"+dattime+suffix
      system("cp "+dropfile+" dropfile.tmp")
      if(stringtoint(systemfunc("wc dropfile.tmp | awk '{print($1)}'")).gt.7)then
         DropData  = readAsciiTable("dropfile.tmp",13,"float",7)
         hght = DropData(:,5)
;TODO" Change below back to correct column for BRCH
         brch = DropData(:,11)
         hght@_FillValue = -9999.
         brch@_FillValue = -9999.
         do j=0,nlevels_out-1
            if(.not.ismissing(brch(j)))then
               total_obs(j) = total_obs(j) + 1
;TODO: Change back to .lt. below
               if(brch(j).gt.brch_thresh)then
                  subcrit_obs(j) = subcrit_obs(j) + 1
               end if
            end if
         end do
         delete([/DropData,hght,brch/])
      end if
   end do
   total_obs = where(total_obs.ne.0,total_obs,total_obs@_FillValue) ;Avoid divide by zero errors
;   subcrit_freq = new(dimsizes(subcrit_obs),float,-9999)   ;Initialize array so it is type float
   subcrit_freq = subcrit_obs / total_obs * 100
   head = [/(/" HGHT  %SUBCRIT   N_TOT"/)/]
   data = [/hghts,subcrit_freq,total_obs/]
;TODO: Change back to .lt. below (both lines)
   write_table(idfile+".freq.shear.gt."+brch_thresh,"w",head,"%s")
   write_table(idfile+".freq.shear.gt."+brch_thresh,"a",data,"%5.1i%9.1f%9.0f")
end do
