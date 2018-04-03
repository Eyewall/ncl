load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;--------------------------------------------------
;Patrick Duran
;22 September 2016
;
;Computes an average sounding from all soundings
;in an input directory. Current input data format
;is the University of Wyoming sounding format.
;
;23 June 2017: Added functionality to read EOL files
;10 August 2017: Added mixing ratio output
;28 November 2017: Added option to fill top of sounding
;--------------------------------------------------

type = 1  ;0=University of Wyoming; 1=EOL
assumerh = 1  ;0=Do not assume an RH above a particular level
              ;1=Assume a 50% RH above the level defined below
rhmaxlev = 11500
fill     = 2  ;0=Do not fill the top of the sounding
              ;1=Assume isothermal profile above level fillmin
              ;2=Lineraly interpolate to values set below
fillmin  = 19000  ;If fill=1, level above which to fill
;dir = "/jm13/pduran/rawinsondes/wyoming/trimmed_sondes/"
dir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151021/"
outfile = dir+"average.txt"
minhght = 0     ;Minimum height to interpolate to
maxhght = 35000 ;Maximum height to interpolate to
dz = 100   ;Grid spacing to interpolate to (m)
nlevs = (maxhght-minhght)/dz+1

system("\rm "+outfile)
infiles = systemfunc("ls "+dir)
nfiles = dimsizes(infiles)

if(fill.eq.2) ;Set values for top of sounding
   ;These came from the CFSR, as output by
   ;/jm13/pduran/ncl/cm1/cfsr.ncl
   p_fill = (/70,50,30,20,10/)*1.0
   t_fill = (/-71.95,-65.25,-57.35,-50.95,-41.85/)
end if

;Define interpolated arrays
hght_int = fspan(minhght,maxhght,nlevs)
hght_int@_FillValue = -9999.
pres_int = new((/nlevs,nfiles/),"float")
pres_int@_FillValue = -9999.
temp_int = pres_int
thta_int = pres_int
mixrat_int = pres_int
;Interpolate each sonde to fixed grid
do i=0,nfiles-1
   unixi = i + 1
   print("Interpolating sonde "+unixi+" of "+nfiles)
   infile = infiles(i)
   if(type.eq.0)then
      input := readAsciiTable(dir+infile,11,"float",6)
      input@_FillValue = -9999.
      pres  := input(:,0)
      hght  := input(:,1)
      temp  := input(:,2)
      rh    := input(:,4)
      thta  := input(:,8)
   else if(type.eq.1)then
      ;Throw out all lines that have missing altitudes
      ;to avoid linint1 throwing "xi must be monotinically
      ;increasing" errors.
      system("awk '(NR>=14) && ($14 > 0) ' "+dir+infile+" > tmpsounding.txt")
      ;Read data and compute theta
      input := readAsciiTable("tmpsounding.txt",17,"float",0)
;      input := readAsciiTable(dir+infile,17,"float",14)
      input@_FillValue = -999.
      hght  := input(:,13)
      temp  := input(:, 5)
      pres  := input(:,4)
      rh    := input(:,7)
      thta  := pot_temp(pres*100,temp+273.15,0,False)
      ;If desired, set RH to 50% above selected level
      if(assumerh.eq.1)then
         assumeinds := ind(hght.gt.rhmaxlev)
         if(.not.all(ismissing(assumeinds)))then
            rh(assumeinds) = 50.
         end if
      end if
      mixrat:= mixhum_ptrh(pres,temp+273.15,rh,-1)
      mixrat@_FillValue = -999.
   end if
   end if
   ;Reverse arrays so that they're monotonically increasing
   ;so that we can use linint1 function
   hght = hght(::-1)
   temp = temp(::-1)
   pres = pres(::-1)
   thta = thta(::-1)
   mixrat = mixrat(::-1)
   if(.not.all(ismissing(hght)))
      pint  := linint1(hght,pres,False,hght_int,0)
      tint  := linint1(hght,temp,False,hght_int,0)
      thint := linint1(hght,thta,False,hght_int,0)
      mixratint := linint1(hght,mixrat,False,hght_int,0)
      pres_int(0:dimsizes (pint)-1,i) = pint
      temp_int(0:dimsizes (tint)-1,i) = tint
      thta_int(0:dimsizes(thint)-1,i) = thint
      mixrat_int(0:dimsizes(mixratint)-1,i) = mixratint
   else
      pres_int(:,i) = pres_int@_FillValue
      temp_int(:,i) = temp_int@_FillValue
      thta_int(:,i) = thta_int@_FillValue
      mixrat_int(:,i) = mixrat_int@_FillValue
   end if
end do

;Find number of nonmissing temperatures at each level
nnonmissing = new(nlevs,"integer")
do j=0,nlevs-1
   nnonmissing(j) = dimsizes(ind(.not.ismissing(temp_int(j,:))))
end do

;Compute averages
pavg    = dim_avg(pres_int)
tavg    = dim_avg(temp_int)
thtaavg = dim_avg(thta_int)
mixratavg   = dim_avg(  mixrat_int)

;Fill top part of sounding, if selected
;Some constants for barometric formula:
g = 9.81      ;Gravitational acceleration (m/s^2)
M = 0.0289644 ;Molar mass of air (kg/mol)
R = 8.3144598 ;Gas constant (J/mol/K)
hb= fillmin
if(fill.eq.1)then
   fillinds = ind(hght_int.ge.fillmin)
   tavg(fillinds) = tavg(min(fillinds)-1)
   tb = tavg(min(fillinds)-1)+273.15
   pb = pavg(min(fillinds)-1)
   ;Compute pressures using barometric formula
   pavg(fillinds) = pb*exp((-g*M*(hght_int(fillinds)-hb))/(R*tb))
   ;Compute potential temperature using assumed pressures
   thtaavg = pot_temp(pavg*100,tavg+273.15,0,False)
   if(assumerh.eq.1)then
       ;Compute mixing ratio for filled values using assumed RH
       rhval = mixratavg
       rhval = 50.
       mixratavg = mixhum_ptrh(pavg,tavg+273.15,rhval,-1)
   end if
else if(fill.eq.2)then
   fillinds = ind(hght_int.ge.fillmin)
   tb = tavg(min(fillinds)-1)+273.15
   pb = pavg(min(fillinds)-1)
   pavg(fillinds) = pb*exp((-g*M*(hght_int(fillinds)-hb))/(R*tb))
   ;Interpolate values we're filling with to the uniform grid
end if

;Output
outlist = [/hght_int,pavg,tavg,thtaavg,mixratavg,nnonmissing/]
write_table(outfile,"w",outlist,"%8.2f%8.2f%8.2f%8.2f%8.2f%4i")
print( "Output writeen to "+outfile)
