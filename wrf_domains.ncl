load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

ncdf_outer = addfile("wrfout_d01_2012-10-22_12:00:00.nc","r")
ncdf_inner = addfile("wrfout_d02_2012-10-22_14:00:00.nc","r")

outerlats = ncdf_outer->XLAT
outerlons  = ncdf_outer->XLONG
innerlats  = ncdf_inner->XLAT
innerlons  = ncdf_inner->XLONG

;print(innerlats(0,308,:))
;print(innerlons(:,:,704))
;print(outerlats(:,:,0))
;print(outerlons(:,:,0))

innerlons_west =  (innerlons(0,:,0))
innerlons_east =  (innerlons(0,:,704))
innerlons_north = (innerlons(0,0,::-1))
innerlons_south = (innerlons(0,0,:))
innerlats_west =  (innerlats(0,:,0))
innerlats_east =  (innerlats(0,::-1,0))
innerlats_south = (innerlats(0,308,:))
innerlats_north = (innerlats(0,0,:))
innerboxlats1 = array_append_record(innerlats_west,innerlats_south,0)
innerboxlats2 = array_append_record(innerboxlats1,innerlats_east,0)
innerboxlats  = array_append_record(innerboxlats2,innerlats_north,0)
innerboxlons1 = array_append_record(innerlons_west,innerlons_south,0)
innerboxlons2 = array_append_record(innerboxlons1,innerlons_east,0)
innerboxlons  = array_append_record(innerboxlons2,innerlons_north,0)

outerlons_west = outerlons(0,:,0)
outerlons_east = outerlons(0,:,272)
outerlons_north = outerlons(0,0,::-1)
outerlons_south = outerlons(0,0,:)
outerlats_west = outerlats(0,:,0)
outerlats_east = outerlats(0,::-1,0)
outerlats_south = outerlats(0,0,:)
outerlats_north = outerlats(0,142,:)
outerboxlats1 = array_append_record(outerlats_west,outerlats_south,0)
outerboxlats2 = array_append_record(outerboxlats1,outerlats_east,0)
outerboxlats  = array_append_record(outerboxlats2,outerlats_north,0)
outerboxlons1 = array_append_record(outerlons_west,outerlons_south,0)
outerboxlons2 = array_append_record(outerboxlons1,outerlons_east,0)
outerboxlons  = array_append_record(outerboxlons2,outerlons_north,0)

wks = gsn_open_wks("png","domains")
res = True
res@mpMinLatF = -10  
res@mpMaxLatF = 40
res@mpMinLonF = -110
res@mpMaxLonF = -10
res@mpFillOn = False
res@mpGeophysicalLineThicknessF = 3.
res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLineThicknessF = 1.
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False
plot = gsn_csm_map_ce(wks,res)
innerres = True
innerres@gsLineColor = "red"
innerres@gsLineThicknessF = 5
outerres = innerres
outerres@gsLineColor = "dark green"
innerbox = gsn_add_polyline(wks,plot,innerboxlons,innerboxlats,innerres)
outerbox = gsn_add_polyline(wks,plot,outerboxlons,outerboxlats,outerres)

delete(innerlats)
delete(innerlons)
delete(outerlats)
delete(outerlons)

draw(plot)
frame(wks)
