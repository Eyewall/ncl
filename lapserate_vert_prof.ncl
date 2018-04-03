;**************************************************
; skewt_frd.ncl
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/meteo.ncl"
;**************************************************

dir = "/jm13/pduran/dropsondes/onr/Gonzalo/eol/"
outputdir = "/jm13/pduran/web/onr/gonzalo/lapserate/"
dropfiles = systemfunc("ls "+dir+"*.eol")
ndropfiles = dimsizes(dropfiles)

do i=0,ndropfiles-1
   unixi = i + 1
   system("echo Plotting sonde "+unixi+" of "+ndropfiles+"   "+dropfiles(i))
   dropfile = dropfiles(i)

   ;Get header information;
   date    = systemfunc("echo "+dropfile+" | awk -F'/' '{print $(NF)}' | awk -F'_' '{print $1}' | colrm 1 1")
   time    = systemfunc("echo "+dropfile+" | awk -F'/' '{print $(NF)}' | awk -F'_' '{print $2}'")

   ;Get sounding information;
   DropData = readAsciiTable(dropfile,17,"float",14)
   tc   = DropData (:,5)     ; temperature  [C]    
   z    = DropData (:,13)    ; geopotential [m] 
   tc@_FillValue = -999
   z@_FillValue  = -999

   n_nonmissing_tc = dimsizes(ind(.not.ismissing(tc)))
   n_nonmissing_z  = dimsizes(ind(.not.ismissing(z)))
   if(n_nonmissing_tc.lt.10).or.(n_nonmissing_z.lt.10)then
      system("echo Either all temperature or height data are missing...Cannot calculate lapse rate.")
   else
      ;Eliminate missing values from arrays
      nonmissing = ind(.not.(ismissing(tc)).and..not.(ismissing(z)))
      if(isdefined("nonmissing"))then
         Z  = z(nonmissing)
         TC = tc(nonmissing)     
      else
         Z  = z
         TC = tc
      end if

      ;Calculate lapse rate;
      lapserate = lapse_rate(Z,TC,0)

      ;Convert Z to km for plotting
      Z = Z/1000

      ;Plot vertical profile;
      filename = date+"_"+time+"_lapserate"
      wks  = gsn_open_wks ("png",filename)
      res = True
      res@tiMainString = "DATE/TIME: "+date+"_"+time+" UTC"
      res@tiXAxisString = "Lapse Rate (K/km)"
      res@tiYAxisString = "Height (km)"
      res@xyLineColor = "blue"
      res@xyLineThicknesses = 3
      res@gsnMaximize = True
      res@gsnDraw = False
      res@gsnFrame = False

      res@trXMinF = -15.
      res@trXMaxF = 15.
      res@trYMinF = 0.
      res@trYMaxF = 20.
      plot = gsn_csm_xy(wks,lapserate,Z,res)

      ;Add dry adiabatic lapse rate indicator line
      lineres = True
      lineres@gsLineColor = "black"
      lineres@gsLineThicknessF = 3.
      lineres@gsLineDashPattern = 16
      line = gsn_add_polyline(wks,plot,(/9.8,9.8/),(/res@trYMinF,res@trYMaxF/),lineres)
      draw(plot)
      frame(wks)
      system("mv "+filename+".png "+outputdir)
      delete([/TC,Z,lapserate/])
   end if
   delete([/DropData,tc,z/])
   if(isdefined("nonmissing"))then
      delete(nonmissing)
   end if
end do
