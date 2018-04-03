load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-----------------------------------------------------------------
;calc_avg_wind_idlist.ncl
;Patrick Duran
;2/11/2015
;
;-----------------------------------------------------------------

;----------;
;PARAMETERS;
;----------;
iddir = "/jm13/pduran/unix_scripts_and_c++/2014/allsondes_overlap/"
dropdir =  "/jm13/pduran/rawinsondes/allsondes_brch/"
idsuffix = "km"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"
alt_max = 20000      ;Highest altitude [m]
dz = 100             ;Distance between each height level [m]
max_ndrops = 3500    ;Maximum number of drops in an idfile

;----------;
;Get idlist;
;----------;
idfiles = systemfunc("ls "+iddir+"*"+idsuffix)
nidfiles = dimsizes(idfiles)

;--------------------------------------------------------------------;
;Read data and calculate average wspd for each level in each sounding;
;--------------------------------------------------------------------;
nlevels_out = alt_max / dz + 1
hghts = ispan(0,alt_max,dz)
data = new((/nidfiles,(alt_max/100),max_ndrops/),float)
do i=0,nidfiles-1
   unixi = i + 1
   system("echo Processing idfile "+unixi+" of "+nidfiles+"  "+systemfunc("date"))
   idfile = idfiles(i)
   ndrops  = stringtoint(systemfunc("wc "+idfile+" | awk '{print $1}'"))
   do drop=0,ndrops-1
      unixdrop = drop + 1
      system("echo Processing sonde "+unixdrop+" of "+ndrops+" in idfile "+unixi+" of "\
            +nidfiles+"  "+systemfunc("date"))
      ;--------;
      ;Get data;
      ;--------;
      if(idsuffix.eq."km")then
         stn = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($1)}' | cut -c 3-7")
         dattime = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($3)}'")
      else
         stn = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($2)}'")
         dattime = systemfunc("sed -n "+unixdrop+"p "+idfile+" | awk '{print($4)}'")
      end if
      dropfile = dropdir+stn+"-"+dattime+suffix
      if(.not.ismissing(systemfunc("ls "+dropfile)))then
         DropData  = readAsciiTable(dropfile,13,"float",7)
         u = DropData(:,3)
         v = DropData(:,4)
         u@_FillValue = -9999.
         v@_FillValue = -9999.
         wspd = (u^2 + v^2)^0.5
         data(i,:,drop) = wspd(:(alt_max/100-1))
         delete([/DropData,u,v,wspd/])
      end if
   end do
   print("Averaging finished for radial bin"+unixi)
   print((data(i,:,:)))
end do

;----------------------------------------------------------;
;Calculate average wind speed for each (radius,level) point;
;----------------------------------------------------------;
avg_wspd = dim_avg_n(data,2)
asciiwrite("avg_wspds.txt",avs_wspd)
print(avg_wspd)
print("DONE!!!")

;   subcrit_freq = subcrit_obs / total_obs * 100
;   head = [/(/" HGHT  %SUBCRIT   N_TOT"/)/]
;   data = [/hghts,subcrit_freq,total_obs/]
;   write_table(idfile+".freq.lt."+brch_thresh,"w",head,"%s")
;   write_table(idfile+".freq.lt."+brch_thresh,"a",data,"%5.1i%9.1f%9.0f")
