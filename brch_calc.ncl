load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/meteo.ncl"

;-----------------------------------------------------------------
;brch_calc.ncl
;Patrick Duran
;3/20/2015
;-----------------------------------------------------------------

;----------;
;PARAMETERS;
;----------;
dropdir =  "/jm13/pduran/dropsondes/hs3/"
suffix  =  "eol"
dz = 400   ;Layer thickness (m) over which to calculate BRCH
g  = 9.81  ;Gravitational acceleration (m/s^2)

;------------------;
;Loop through files;
;------------------;
drops  = systemfunc("ls "+dropdir+"*"+suffix)
ndrops = dimsizes(drops)

do i=0,ndrops-1
   ;---------;
   ;Read data;
   ;---------;
   dropfile = drops(i)
   print(dropfile)
   DropData = readAsciiTable(dropfile,17,"float",14)
   DropData@_FillValue = -999.
   p  = DropData(:,4)
   z  = DropData(:,13)
   tc = DropData(:,5)
   u  = DropData(:,8)
   v  = DropData(:,9)

   ;---------------------------;
   ;Interpolate to 100-m levels;
   ;---------------------------;
   ;Get top nonmissing height
   top_hght = z(min(ind(.not.ismissing(z))))
   flag = False
   factor = 1
   div = top_hght
   do while(flag.eq.False)
      if(div.gt.10.and.div.lt.100)then
         top_hght = floor(div)
         flag = True
      else 
         factor = factor * 10
         div = div/10
      end if
   end do
   top_hght = top_hght * factor

   ;Perform interpolation
   nlevs = floattoint(top_hght / 100 + 1)
;   hghts_inc = fspan(0,top_hght,nlevs)
   z_incr = z(::-1)
   z_incr_no_missing = z_incr(ind(.not.ismissing(z_incr)))
   temphghts = z_incr_no_missing(ind(.not.ismissing(z_incr_no_missing))) / factor*10
   ;floorhghts = floor(temphghts) * factor
   floorhghts = round(temphghts,1) * factor/10
   asciiwrite("hghts_tmp",floorhghts)
   hghts_inc = stringtofloat(systemfunc("uniq hghts_tmp"))
   system("rm hghts_tmp")
   hghts = hghts_inc(::-1)
   hghts@_FillValue = -999.

;   pres_interp = linint1_Wrap(z_incr_no_missing,p(ind(.not.ismissing(z))),False,hghts_inc,0)
   p_interp  = wrf_interp_1d(p(ind(.not.ismissing(z))),z_incr_no_missing,hghts_inc)
   tc_interp = wrf_interp_1d(tc(ind(.not.ismissing(z))),z_incr_no_missing,hghts_inc) 
   u_interp  = wrf_interp_1d(u(ind(.not.ismissing(z))),z_incr_no_missing,hghts_inc)
   v_interp  = wrf_interp_1d(v(ind(.not.ismissing(z))),z_incr_no_missing,hghts_inc)

   ;--------------------;
   ;Perform calculations;
   ;--------------------;
   p_pa  = p_interp*100                  ;Convert pressure to Pascals
   tk    = tc_interp+273.15              ;Convert temperature to Kelvin
   theta = pot_temp_n(p_pa,tk,1,0) ;Potential temperature (K)
   
   ;Get layer over which to calculate
   nlevels = dimsizes(theta)
   brch = new(nlevels,float)
   do j=0,nlevels-1
     ztop = hghts(j)
     if((.not.(ismissing(theta(j)))).and.(.not.(ismissing(u(j)))).and.(.not.(ismissing(v(j)))))then
        zdiff = ztop - hghts
        botind = ind(zdiff.eq.dz)
        if(.not.ismissing(botind))then
           tophght   = hghts(j)
           bothght   = hghts(botind)
           theta_bar = avg(theta(j:botind))
           dtheta_dz = (theta(botind)-theta(j))/(hghts(botind)-hghts(j))
           delta_u   = u(botind)-u(j)
           delta_v   = v(botind)-v(j)
           delta_z   = dz 
           brch(j) = (g/theta_bar*dtheta_dz)/((delta_u^2+delta_v^2)/delta_z^2)
        end if
        delete(zdiff)
     end if
   end do

   ;----------------;
   ;Plotting Routine;
   ;----------------;
   filename = systemfunc("echo "+dropfile+" | awk -F'/' '{print $NF}'")
   wks = gsn_open_wks("png",filename+"_brch")
   res = True
   res@tiMainString  = filename
   res@tiXAxisString = "Bulk Richardson Number"
   res@tiYAxisString = "Pressure [mb]"
   res@xyLineColors = (/"blue"/)
   res@xyLineThicknesses = (/3/)
   res@xyDashPattern = 0
   res@trYReverse = True        ;Invert the pressure axis
   res@xyYStyle = "Log"         ;Make the pressure axis logarithmic
   res@tmYLMode = "Explicit"    ;Explicitly set the tick marks and labels below
   res@tfPolyDrawOrder = "Draw"
   res@tmYLValues = (/100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark values
   res@tmYLLabels = (/100,150,200,300,400,500,600,700,800,900,1000/) ;Tick mark labels
   res@trXMinF = 0.     ;X axis min
   res@trXMaxF = 5.     ;X axis max
   res@trYMinF = 100.   ;Y axis min
   res@trYMaxF = 1020.  ;Y axis max

   plot = gsn_csm_xy(wks,brch,p_interp,res)

   delete([/DropData,p,z,tc,u,v,z_incr,z_incr_no_missing,temphghts,floorhghts,hghts_inc/])
   delete([/hghts,p_interp,tc_interp,u_interp,v_interp,p_pa,tk,theta,brch/])
end do
