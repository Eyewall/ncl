;---------------------------------------------
; polar_scatterplot.ncl
; Patrick Duran
; 31 January 2017
; 
; Plots a scatterplot in polar coordinates,
; of dropsondes WRT a composite TC center.
; Dots are color-coded by intensity.
;---------------------------------------------

indir    = "/nfs/jm13/pduran/hurricanesondes/"
outdir   = "/jm13/pduran/web/hs3/"
;type     = "hs3-sondes" ;hs3-sondes, rawinsondes or allsondes
type     = "rawinsondes" ;hs3-sondes, rawinsondes or allsondes
oneplot  = 1  ;0=Plot all sondes on one plot, 1=Create different plots for each category
catlist  = (/"TD","TS","HU"/)   ;Category list. Used only if oneplot=1
minrad   = 0      ;Minimum plotting radius
maxrad   = 1000   ;Maximum plotting radius
spacing  = 100    ;Spacing of range rings
degtorad = 2*3.141592/360

;---------------;
;Read input file;
;---------------;
infile = indir+type+"_"+minrad+"-"+maxrad+"km"
dropfiles = systemfunc("awk '{print $1}' "+infile)
year      = systemfunc("awk '{print $2}' "+infile)
month     = systemfunc("awk '{print $3}' "+infile)
day       = systemfunc("awk '{print $4}' "+infile)
hour      = systemfunc("awk '{print $5}' "+infile)
minute    = systemfunc("awk '{print $6}' "+infile)
category  = systemfunc("awk '{print $7}' "+infile)
stormlat  = systemfunc("awk '{print $8}' "+infile)
stormlon  = systemfunc("awk '{print $9}' "+infile)
vmax      = systemfunc("awk '{print $10}' "+infile)
pmin      = systemfunc("awk '{print $11}' "+infile)
radius    = systemfunc("awk '{print $12}' "+infile)
azimuth   = systemfunc("awk '{print $13}' "+infile)

;------------------------------------;
;Convert strings to appropriate types;
;------------------------------------;
vmax    := toint(vmax)
radius  := tofloat(radius)
azimuth := tofloat(azimuth)
azirad   = azimuth*degtorad

;---------------------------------------------------;
;Compute x and y coordinates from radius and azimuth;
;---------------------------------------------------;
x = radius*sin(azirad)
y = radius*cos(azirad)

;-----------------------------------;
;Get indices for each storm category;
;-----------------------------------;
tdinds = ind(category.eq."TD")
tsinds = ind(category.eq."TS")
huinds = ind(category.eq."HU")
ntd = dimsizes(tdinds)
nts = dimsizes(tsinds)
nhu = dimsizes(huinds)

;----------------;
;Draw scatterplot;
;----------------;
;Create blank plot
do j=0,dimsizes(catlist)-1
   cat = catlist(j)
   if(oneplot.eq.0)then
      if(type.eq."hs3-sondes")then
         wks  = gsn_open_wks("png",outdir+"droplocs_scatterplot_hs3")
      else if(type.eq."rawinsondes")then
         wks  = gsn_open_wks("png",outdir+"droplocs_scatterplot_rawinsondes")
      end if
      end if
   else
      if(type.eq."hs3-sondes")then
         wks  = gsn_open_wks("png",outdir+"droplocs_scatterplot_hs3_"+cat)
      else if(type.eq."rawinsondes")then
         wks  = gsn_open_wks("png",outdir+"droplocs_scatterplot_rawinsondes_"+cat)
      end if
      end if
   end if
   res  = True
   res@gsnMaximize = True
   if(type.eq."hs3-sondes")then
      res@tiMainString = "HS3 Dropsondes"
   else if(type.eq."rawinsondes")then
      res@tiMainString = "Rawinsondes"
   end if
   end if
   res@tiMainFontHeightF = 0.02
   res@trYMaxF = (maxrad+5)
   res@trYMinF = (maxrad+5)*-1
   res@trXMaxF = (maxrad+5)
   res@trXMinF = (maxrad+5)*-1
   res@tmYLOn = False
   res@tmYROn = False
   res@tmXBOn = False
   res@tmXTOn = False
   res@tmYLBorderOn = False
   res@tmYRBorderOn = False
   res@tmXBBorderOn = False
   res@tmXTBorderOn = False
   plot = gsn_csm_blank_plot(wks,res)
   
   ;Add range rings
   radialextent = maxrad
   ringspacing  = spacing
   nrings = radialextent/ringspacing+1
   ringazi = fspan(0,360,360)
   ringdum = new(nrings,"graphic")
   txdum   = new(nrings,"graphic")
   ringres = True
   ringres@gsLineThicknessF = 3.
   do i=0,nrings-1
      ringx = i*spacing*sin(ringazi*degtorad)
      ringy = i*spacing*cos(ringazi*degtorad)
      ringdum(i) = gsn_add_polyline(wks,plot,ringx,ringy,ringres)
      if(i%2.eq.0.and.i.ne.0)then
         rrlabel = tostring(ringspacing*i)+" km"
         rrlabelres = True
         rrlabelres@txFontHeightF = .01
         rrlabelres@txJust = "centercenter"
         rrlabelres@txPerimOn = True
         rrlabelres@txBackgroundFillColor = "white"
         txdum(i) = gsn_add_text(wks,plot,rrlabel,0,i*spacing,rrlabelres)
      end if
   end do
   
   ;Plot sounding locations
   dotres = True
   dotres@tfPolyDrawOrder = "PreDraw"
   dotres@gsMarkerIndex = 1
   dotres@gsMarkerThicknessF = 10.
   if(oneplot.eq.0.or.(oneplot.eq.1.and.cat.eq."TD"))then
      dotres@gsMarkerColor = "blue"
      gsn_polymarker(wks,plot,x(tdinds),y(tdinds),dotres)
   end if
   if(oneplot.eq.0.or.(oneplot.eq.1.and.cat.eq."TS"))then
      dotres@gsMarkerColor = "orange"
      gsn_polymarker(wks,plot,x(tsinds),y(tsinds),dotres)
   end if
   if(oneplot.eq.0.or.(oneplot.eq.1.and.cat.eq."HU"))then
      dotres@gsMarkerColor = "red"
      gsn_polymarker(wks,plot,x(huinds),y(huinds),dotres)
   end if
   
   ;Add a legend with number of sondes
   txres = True
   txres@txFontHeightF = 0.02
   txres@txJust = "CenterLeft"
   if(oneplot.eq.0.or.(oneplot.eq.1.and.cat.eq."TD"))then
      txres@txFontColor = "blue"
      gsn_text_ndc(wks,"TD (N="+ntd+")",0.05,0.95,txres)
   end if
   if(oneplot.eq.0.or.(oneplot.eq.1.and.cat.eq."TS"))then
      txres@txFontColor = "orange"
      gsn_text_ndc(wks,"TS (N="+nts+")",0.05,0.91,txres)
   end if
   if(oneplot.eq.0.or.(oneplot.eq.1.and.cat.eq."HU"))then
      txres@txFontColor = "red"
      gsn_text_ndc(wks,"HU (N="+nhu+")",0.05,0.87,txres)
   end if
   
   draw(plot)
   frame(wks)
end do
