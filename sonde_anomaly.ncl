load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
load "/nfs/jm13/pduran/ncl/functions/interpolate_old.ncl"

;---------------------------------------------
; sonde_anomaly.ncl
; Patrick Duran
; 08 February 2016
; 
; Computes the temperature anomalies from the
; Dunion (2011) Moist Tropical Sounding for
; a list of dropsondes. Will plot a vertical
; cross-section of the anomalies, if desired.
;---------------------------------------------
;meansounding = "dunion"  ;Options: "dunion", "jordan", or "mexican"
meansoundings = (/"dunion","jordan","mexican"/)
do isnd=0,dimsizes(meansoundings)-1
   meansounding = meansoundings(isnd)
   titletimestr = 1   ;Set to 0 to include time string in title; 1 to not include
   storm    = "patricia"
   flight   = "20151023"
   transect = "transect1"
   maxhght  = 20000  ;Maximum height to pull (m)
   minhght  = 0
   dz       = 100
   minx     = -200   ;Mininmum x coordinate of the fixed grid to interpolate to
   maxx     = 200    ;Maximum x coordinate of the fixed grid to interpolate to
   x_spacng = 1      ;Grid spacing of the fixed grid
   nradii   = (maxx-minx)/x_spacng+1
   nlevels  = maxhght/dz+1
   tropfile = "trophghts"+flight+"_"+transect
   sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+flight+"/"
   listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+flight+"/"+transect
   outfile  = "/jm13/pduran/web/tci/cross_sections/anomalies/"+storm+"/"+flight+"/"+transect+"_"+meansounding
   if(meansounding.eq."dunion")then
      avg_file = "/jm13/pduran/dropsondes/dunion_moisttropical_sounding"
   else if(meansounding.eq."jordan")then
      avg_file = "/jm13/pduran/dropsondes/jordan_hurricane_season_sounding"
   else if(meansounding.eq."mexican")then
      avg_file = "/jm13/pduran/dropsondes/acapulco+manzanillo_october2015_mean_sounding"
   end if
   end if
   end if
   interp   = 1   ;Interpolate across missing values in the radial direction?
                   ;0=Do not interpolate, 1=Interpolate
   driftopt = 0   ;Account for sonde drift in interpolation script? (0=No,1=Yes)
   type     = 1   ;Plot as total distance from start of flight let (0) or
                  ;distance from storm center (1)?
   axisorient = 1 ;X-Axis orientation (0=Leftmost side represents the first sonde in the
                  ;                      transect, 1=Leftmost side is West
   
   if(flight.eq."20151021")then
      if(transect.eq."transect1")
         centerlat = 13.38   ;Transect 1 did not have a center crossing!!
         centerlon = -99.26
         centersonde = 7
         if(axisorient.eq.1)then
            centersonde = 16
         end if
      else    ;Transect 2
         centerlat = 12.99   ;Sonde nearest the interpolated center location for VORTEX msgs
         centerlon = -99.27  ;Also zero wind center in sondes... 
         centersonde = 7
         if(axisorient.eq.1)then
            centersonde = 21
         end if
      end if
   else if(flight.eq."20151022")then
      if(transect.eq."transect1")then
         centerlat = 15.09      ;Sonde nearest the interpolated center location for VORTEX msgs   
         centerlon = -104.12
         centersonde = 14
      else   ;Transect 2
         centerlat = 15.23      ;Sonde nearest the interpolated center location for VORTEX msgs
         centerlon = -104.22
         centersonde = 16
      end if
   else if(flight.eq."20151023")then
   ;   centerlat = 18.58     ;Upper-tropospheric pressure minimum
   ;   centerlon = -105.20
   ;   centersonde = 13
      centerlat = 18.61      ;Sonde nearest the zero wind center AND nearest VORTEX track  
      centerlon = -105.22
      centersonde = 14
      if(axisorient.eq.1)then
         centersonde = 32
      end if
   else if(flight.eq."20151002")then
      centerlat = 23.83    ;Determined by combination of QC notes and meridional velocity
      centerlon = -74.65
      centersonde = 9
   else if(flight.eq."20151003")then
      centerlat = 26.18    ;Determined by combination of QC notes and meridional velocity
      centerlon = -71.28
      centersonde = 7
   else if(flight.eq."20151004")then
      centerlat = 31.81    ;Determine by IR imagery
      centerlon = -66.48
      centersonde = 10     ;Note that I chopped off some sondes from the high-density transect
   end if
   end if
   end if
   end if
   end if
   end if
   
   
   ;------------------------------;
   ;SET UP THE BASE STATE SOUNDING;
   ;------------------------------;
   ;Get data from average file that we'll use to compute anomalies
   average  := readAsciiTable(avg_file,3,"float",2)
   hght_avg := average(:,0)
      t_avg := average(:,1)
   theta_avg:= average(:,2)
   
   ;Interpolate the values to vertical levels defined by dz
   hghts = fspan(0,maxhght,maxhght/dz+1)
   avg_t = linint1(hght_avg,t_avg,False,hghts,0)
   avg_theta = linint1(hght_avg,theta_avg,False,hghts,0)
   
   infiles    = sondedir+systemfunc("cat "+listfile)
   nfiles     = dimsizes(infiles)
   ;If axisorient=1, we need to invert the X axis on 10/21 and 10/23
   if(axisorient.eq.1)
      if(flight.eq."20151021".or.flight.eq."20151023")then
         infiles = infiles(::-1)
      end if
   end if
   
   ;----------------------------;
   ;GET DATA FROM EACH DROPSONDE;
   ;----------------------------;
   tc      = new((/nfiles,nlevels/),"float") 
   p      = new((/nfiles,nlevels/),"float")
   td = new((/nfiles,nlevels/),"float")
   u = new((/nfiles,nlevels/),"float")
   v = new((/nfiles,nlevels/),"float")
   hght = new((/nfiles,nlevels/),"float")
   rh = new((/nfiles,nlevels/),"float")
   lat       = new((/nfiles,nlevels/),"float")
   lon       = new((/nfiles,nlevels/),"float")
   cp_pres    = new(nradii,"float")
   cp_temp    = new(nradii,"float")
   cp_theta   = new(nradii,"float")
   trop_z    := new(nradii,"float")
   droplat    = new(nfiles,"float")
   droplon    = new(nfiles,"float")
   tc@_FillValue      = -9999.0
   p@_FillValue      = -9999.0
   td@_FillValue      = -9999.0
   u@_FillValue      = -9999.0
   v@_FillValue      = -9999.0
   hght@_FillValue      = -9999.0
   rh@_FillValue      = -9999.0
   lat@_FillValue       = -9999.0
   lon@_FillValue       = -9999.0
   trop_z@_FillValue     = -9999.0
   cp_pres@_FillValue    = -9999.0
   
   do i=0,nfiles-1
      unixi = i+1
      print("Processing sonde "+unixi+" of "+nfiles)
      ;Read input file and assign variables
      data := readAsciiTable(infiles(i),10,"float",7)
      data@_FillValue = -9999.0
      nhghts = dimsizes(data(:,5))
      p   (i,:nhghts-1) = data(:,0)
      tc  (i,:nhghts-1) = data(:,1)
      td  (i,:nhghts-1) = data(:,2)
      u   (i,:nhghts-1) = data(:,3)
      v   (i,:nhghts-1) = data(:,4)
      hght(i,:nhghts-1) = data(:,5)
      rh  (i,:nhghts-1) = data(:,6)
      lat (i,:nhghts-1) = data(:,7)
      lon (i,:nhghts-1) = data(:,8)
   
      ;Get drop latitude and longitude from header
      droplat(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $3}'"))
      nfields = stringtoint(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print NF}'"))
      if(nfields.eq.9)then
         droplon(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $5}' | sed 's/=//'"))
      else
         droplon(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $6}'"))
      end if
   end do
   
   ;Create array of drop distances for the fixed grid
   ;If flight is from north to south, we multiply by -1 (because the 
   ;interpolation script assumes distance is negative north of the
   ;storm center) and then flip all of the arrays.
   dropdistances = fspan(minx,maxx,nradii)
   dropdist = new((/nradii,nlevels/),"float")
   dropdist = conform(dropdist,dropdistances,0)
   
   ;Interpolate all of the variables to a fixed radial grid
   vars = interpolate(nlevels,nradii,dropdistances,minhght,maxhght,centerlat,centerlon,centersonde,p,tc,td,u,v,hght,rh,lat,lon,droplat,droplon,driftopt)
   pres           = vars[0]
   tempc          = vars[1]
   dewpc          = vars[2]
   zonal_v        = vars[3]
   merid_v        = vars[4]
   rh            := vars[5]
   lats           = vars[6]
   lons           = vars[7]
   droplocs       = vars[8]
   missingpts_p   = vars[9]
   missingpts_tc  = vars[10]
   missingpts_td  = vars[11]
   missingpts_u   = vars[12]
   missingpts_v   = vars[13]
   missingpts_rh  = vars[14]
   missingpts_lat = vars[15]
   missingpts_lon = vars[16]
   dropxcoords    = vars[17]
   
   ;Compute some variables
   theta = (tempc+273.15)*(1000/pres)^0.286
   hght_fixedgrid = fspan(0,maxhght,nlevels)/1000.
   z_interp = conform(tempc,hght_fixedgrid,1)
   
   ;Compute tropopause pressure
   do i=0,nradii-1
      if(.not.all(ismissing(tempc(i,:))))then
         cp_temp (i) = min(tempc(i,:))
         cp_pres (i) = pres(i,(minind(tempc(i,:))))
         if(cp_pres(i).gt.200)then
            cp_pres(i) = cp_pres@_FillValue
         end if
         cp_theta(i) = (cp_temp(i)+273.15)*(1000/cp_pres(i))^0.286
      end if
   end do
   cp_pres&radii = dropdistances
   
   ;Compute anomalies
   temp_anom  = tempc
   theta_anom = theta
   do i=0,nradii-1
      temp_anom(i,:)  = tempc(i,:) - avg_t
      theta_anom(i,:) = theta(i,:) - avg_theta
   
      ;Get the tropopause height from tropopause pressure by linear interpolation
      if(min(p).lt.200.and..not.ismissing(cp_pres(i)).and.dimsizes(ind(.not.ismissing(pres(i,:)))).gt.1)then
         diffs = abs(pres(i,:)-cp_pres(i))
         diffs_sort = diffs(ind(.not.ismissing(diffs)))
         qsort(diffs_sort)
         p1 = pres(i,ind(diffs.eq.diffs_sort(0)))
         p2 = cp_pres(i)
         p3 = min(pres(i,ind(diffs.eq.diffs_sort(1))))
         z1 = min(z_interp(i,ind(diffs.eq.diffs_sort(0))))
         z3 = min(z_interp(i,ind(diffs.eq.diffs_sort(1))))
         z2 = (p2-p1)*(z3-z1)/(p3-p1)+z1
         trop_z(i) = z2
         delete([/diffs,diffs_sort/])
      else
         trop_z(i) = trop_z@_FillValue
      end if
   
      ;Compute distance along flight track
      if(i.gt.0.and.type.eq.0)then
         dropdist(i) = dropdist(i-1) + gc_latlon(droplat(i-1),droplon(i-1),droplat(i),droplon(i),2,4)
      end if
   end do
   ;print("Smoothing the tropopause line...")
   ;trop_z = smooth_121(trop_z,0,10)  ;Smooth the tropopause line
   
   
   
   
   
   
   
   delete(trop_z)
   
   nlines   = stringtoint(systemfunc("wc "+tropfile+" | awk '{print $1}'"))
   trop_z   = asciiread(tropfile,nlines,"float")
   trop_z@_FillValue = -9999
   if(flight.eq."20151021".or.flight.eq."20151023")then
      if(axisorient.eq.1)then
         trop_z = trop_z(::-1)
      end if
   end if
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   ;Set thresholds for cold point temperature and height to eliminate
   ;sondes that don't have data in upper levels
   cp_pres = where(cp_temp.gt.-60,cp_pres@_FillValue,cp_pres)
   cp_theta= where(cp_temp.gt.-60,cp_theta@_FillValue,cp_theta)
   cp_temp = where(cp_temp.gt.-60,cp_temp@_FillValue,cp_temp)
   
   ;Compute total distance along the transect
   totaldist = round(max(droplocs)-min(droplocs),0)
   
   ;Compute distance from storm center
   ;gc_latlon doesn't check for missing values, so we'll just perform a
   ;quick fix by setting all distances greater than 2000 km to missing
   ;if(type.eq.1)
   ;   dist = dist + gc_latlon(centerlat,centerlon,lats,lons,2,4)
   ;   dropdist = gc_latlon(centerlat,centerlon,droplat,droplon,2,4)
   ;   dist@_FillValue = -9999.
   ;   dropdist@_FillValue = -9999.
   ;   dist = where(dist.gt.2000,dist@_FillValue,dist)
   ;   dropdist = where(dropdist.gt.2000,dropdist@_FillValue,dropdist)
   ;   dropdist(0:(centersonde-1)) = dropdist(0:(centersonde-1))*-1.
   ;   totaldist = round(dropdist(dimsizes(dropdist)-1) - dropdist(0),0) ;Total distance along transect
   ;end if
   
   ;Clean up
   delete([/data,p,tc,td,u,v,hght,rh,lat,lon/])
   
   ;-------------------------------------------------------;
   ;CREATE ARRAYS FOR PLOTTING AND SET COORDINATE VARIABLES;
   ;-------------------------------------------------------;
   ;TEMPERATURE ANOMALY
   plot_temp_anom = transpose(temp_anom)
   plot_temp_anom!0 = "height"
   plot_temp_anom!1 = "radius"
   plot_temp_anom&height = fspan(0,maxhght,nlevels)/1000.
   plot_temp_anom&radius = dropdistances
   
   ;POTENTIAL TEMPERATURE ANOMALY
   plot_theta_anom = transpose(theta_anom)
   copy_VarMeta(plot_temp_anom,plot_theta_anom)
   
   ;------------------------------------------------------------------;
   ;Interpolate across missing values in radius, if option is selected;
   ;------------------------------------------------------------------;
   if(interp.eq.1)then
      ;These will ultimately be boolean arrays; 0 where no interpolation is
      ;performed and 2 where interpolation is performed
      missingpts_temp  = transpose(missingpts_tc) 
      missingpts_theta = transpose(missingpts_tc)
      missingpts_trop_z = trop_z
      ;Perform linear interpolation
      plot_temp_anom  = linmsg(plot_temp_anom,0)
      plot_theta_anom = linmsg(plot_theta_anom,0)
      trop_z_interp   = linmsg(trop_z,0)
      ;Set boolean arrays. We will plot these arrays using hatching where
      ;interpolation is performed and overlay them on the r-z plots.
   ;   missingpts_temp = where(ismissing(missingpts_temp).and..not.ismissing(plot_temp_anom),2,0)
   ;   missingpts_theta = where(ismissing(missingpts_theta).and..not.ismissing(plot_theta_anom),2,0)
   ;   missingpts_trop_z = where(ismissing(missingpts_trop_z).and..not.ismissing(trop_z_interp),2,0)
      out_suffix = "_interp"
   else
      out_suffix = "_nointerp"
   end if
   
   ;--------------;
   ;Draw the plots;
   ;--------------;
   ;SET SOME RESOURCES FOR HATCHING
   hatch_res = True
   hatch_res@gsnDraw = False
   hatch_res@gsnFrame = False
   hatch_res@cnFillOn = True
   hatch_res@cnInfoLabelOn = False
   hatch_res@cnLinesOn = False
   hatch_res@cnLineLabelsOn = False
   hatch_res@lbLabelBarOn = False
   hatch_res@cnLevelSelectionMode = "ManualLevels"
   hatch_res@cnMinLevelValF = 1
   hatch_res@cnMaxLevelValF = 2
   hatch_res@cnLevelSpacingF = 1
   hatch_res@cnMonoFillPattern = True
   ;hatch_res@cnMonoFillColor = True
   hatch_res@cnFillPattern = 12
   hatch_res@cnFillColors = (/-1,1,1,1,1,1/)
   hatch_res@cnFillBackgroundColor = -1  ;Make background transparent
   hatch_res@trYMinF = 0.
   hatch_res@trYMaxF = 18.5
   hatch_res@trXMinF = min(droplocs)
   hatch_res@trXMaxF = max(droplocs)
   
   ;TEMPERATURE ANOMALIES
   wks       = gsn_open_wks("png",outfile+"_temp"+out_suffix)
   wks_theta = gsn_open_wks("png",outfile+"_theta"+out_suffix)
   gsn_define_colormap(wks,"BlWhRe")
   res = True
   res@tiMainOn = False
   res@tiMainString = "Temperature Anomalies From Dunion (2011) Moist Tropical Sounding (K)  "+flight+"  "+transect
   res@gsnStringFontHeightF = 0.018
   res@gsnRightString = "~F33~q~F21~ Anomaly (K)"
   if(flight.eq."20151002".or.flight.eq."20151021")then
   ;   res@tiYAxisOn = True
   ;   res@tiYAxisString = "Height (km)"
      res@gsnLeftString = "d) Total distance = "+totaldist+" km"
      if(titletimestr.eq.0)then
         res@gsnLeftString = "e) 21 October 1952-2009 UTC"
      else
         res@gsnLeftString = "21 October"
      end if
   else
      res@tiYAxisOn = False
   ;   res@tmYLLabelsOn = False
      if(flight.eq."20151003".or.flight.eq."20151022")then
         res@gsnLeftString = "e) Total distance = "+totaldist+" km"
         if(titletimestr.eq.0)then
            res@gsnLeftString = "f) 22 October 1815-1827 UTC"
         else
            res@gsnLeftString = "22 October"
         end if
         if(transect.eq."transect2")then
            if(titletimestr.eq.0)then
               res@gsnLeftString = "g) 22 October 1857-1913 UTC"
            else
               res@gsnLeftString = "22 October"
            end if
         end if
      else if (flight.eq."20151004".or.flight.eq."20151023")then
         res@gsnLeftString = "f) Total distance = "+totaldist+" km"
         if(titletimestr.eq.0)then
            res@gsnLeftString = "h) 23 October 1957-2012 UTC"
         else
            res@gsnLeftString = "23 October"
         end if
      end if
      end if
   end if
   if(flight.eq."20151021")then
      res@tiXAxisString = "W                 Distance from storm center (km)                 E"
   else if(flight.eq."20151022")then
      res@tiXAxisString = "NW                Distance from storm center (km)                SE"
      if(transect.eq."transect2")then
         res@tiXAxisString = "SW                Distance from storm center (km)                NE"
      end if
   else if(flight.eq."20151023")then
      res@tiXAxisString = "NW                Distance from storm center (km)                SE"
   end if
   end if
   end if
   res@tiMainFontHeightF = 0.01
   res@tiXAxisFontHeightF = 0.017
   res@tiYAxisFontHeightF = 0.017
   res@trYMinF = 0.
   res@trYMaxF = 18.5
   res@trXMinF = min(droplocs)
   res@trXMaxF = max(droplocs)
   res@cnInfoLabelOn = False
   res@cnLevelSpacingF = 2.
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF = -18
   res@cnMaxLevelValF = 18
   res@cnFillOn = True
   res@cnLinesOn = False
   ;res@cnExplicitLineLabelsOn = True
   ;res@cnMonoLevelFlag = False
   ;cnLineLabelArray = ispan(-32,32,2)
   ;res@cnLineLabelStrings = tostring(cnLineLabelArray)
   ;print(res@cnLineLabelStrings)
   ;res@cnLevelFlags = new(dimsizes(res@cnLineLabelStrings),"string")
   ;res@cnLevelFlags(:) = "NoLine"
   ;res@cnLevelFlags(ind(mod(cnLineLabelArray,4).eq.0)) = "LabelOnly"
   ;print(res@cnLevelFlags)
   res@lbLabelBarOn = False
   res@lbOrientation = "Vertical"
   res@lbAutoManage = False
   res@lbLabelFontHeightF = 0.02
   res@tmYLMode = "Explicit"
   res@tmYLValues = (/16.0,16.5,17.0,17.5,18.0,18.5/)
   res@tmYLLabels = (/"16.0","16.5","17.0","17.5","18.0","18.5"/)
   res@tmYLMinorValues = fspan(16,18.5,26)
   res@tmYROn = False
   res@tmXTOn = False
   res@tmXBLabelFontHeightF = 0.016
   res@tmYLLabelFontHeightF = 0.016
   res@gsnMaximize = True
   res@gsnDraw = False
   res@gsnFrame = False
   res@cnMissingValFillColor = "Black"
   res@cnMissingValFillPattern = 12
   if(flight.eq."20151022".or.flight.eq."20151023")then
      res@tiYAxisOn = False
   ;   res@tmYLLabelsOn = False
   end if
   theta_res = res
   theta_res@cnMinLevelValF = -30
   theta_res@cnMaxLevelValF = 30
   theta_res@cnLineLabelsOn = True
   hatch_plot_temp  = gsn_csm_contour(wks,missingpts_temp,hatch_res)
   hatch_plot_theta = gsn_csm_contour(wks_theta,missingpts_theta,hatch_res)
   temp_anom_img = gsn_csm_contour(wks,plot_temp_anom,res)
   theta_anom_img = gsn_csm_contour(wks_theta,plot_theta_anom,theta_res)
   overlay(temp_anom_img,hatch_plot_temp)
   overlay(theta_anom_img,hatch_plot_theta)
   
   ;Overlay lines that represent drop locations
   ;liney = new((/dimsizes(dropdist),2/),"float")
   ;linex = liney
   ;locs  = new(dimsizes(dropdist),"graphic")
   ;   do i=0,dimsizes(locs)-1
   ;      linex(i,:) = dropdist(i)
   ;      liney(i,0) = res@trYMinF
   ;      liney(i,1) = res@trYMaxF
   ;      lineres = False
   ;      locs(i) = gsn_add_polyline(wks,temp_anom_img,linex(i,:),liney(i,:),lineres)
   ;   end do
   
   ;Add vertical line at x=0
   zerolineres = True
   zerolineres@gsLineDashPattern = 16
   zerolineres@gsLineThicknessF = 6.
   zeroline_temp = gsn_add_polyline(wks,temp_anom_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
   zeroline_theta = gsn_add_polyline(wks_theta,theta_anom_img,(/0,0/),(/res@trYMinF,res@trYMaxF/),zerolineres)
   
   ;Add tropopause height line
   tropres = True
   tropres@gsLineColor = "dark green"
   tropres@gsLineThicknessF = 18.
   trophght_temp  = gsn_add_polyline(wks,temp_anom_img,dropxcoords,trop_z_interp,tropres)
   trophght_theta = gsn_add_polyline(wks_theta,theta_anom_img,dropxcoords,trop_z_interp,tropres)
   
   ;Overlay digits that represent drop locations
   labelx = new(floattoint(ceil(dimsizes(droplocs)/2.)),"float")
   labely = labelx
   labely = res@trYMinF+0.11
   labely = 16.04
   locs   = new(dimsizes(dropdistances),"graphic")
   j=0
   do i=0,dimsizes(droplocs)-1
      if(i.eq.0.or.mod(i,2).eq.0)then   ;We will only make labels for every other sonde loc
         labelx(j) = droplocs(i)
         j=j+1
      end if
      text = tostring(ispan(1,nfiles,2))   ;Only make a label for every other sonde location
      txres = True
      txres@txFont = 30
      txres@txFontHeightF = 0.015
      txres@txFontColor = "black"
      dum  = gsn_add_text(wks,temp_anom_img,text,labelx,labely,txres)
      dum2 = gsn_add_text(wks_theta,theta_anom_img,text,labelx,labely,txres)
   end do
   
   draw(temp_anom_img)
   frame(wks)
   draw(theta_anom_img)
   frame(wks_theta)
   
   ;POTENTIAL TEMPERATURE ANOMALIES
   ;wks = gsn_open_wks("png",outfile+"_theta"+out_suffix)
   ;res@tiMainString = "Potential Temperature Anomalies from Dunion (2011) Moist Tropical Sounding (K)   "+flight+"  "+transect
   
   ;theta_anom_img = gsn_csm_contour(wks_theta,plot_theta_anom,res)
   ;draw(theta_anom_img)
   ;frame(wks_theta)
   printMinMax(missingpts_temp,False)
end do
