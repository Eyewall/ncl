load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

infile = "/jm13/pduran/unix_scripts_and_c++/ListOfStations_reduced.dat" 
nlines = stringtoint(systemfunc("wc "+infile+" | awk '{print($1)}'"))

data = asciiread(infile,(/nlines,3/),"float")
stations_int = floattoint(data(:,0))
stations_string = sprinti("%0.0i",stations_int)
stations_string_formatted = sprinti("%0.5i",stations_int)
lats = data(:,1)
lons = data(:,2)

wks = gsn_open_wks("png","stations_nsondes")
res = True
res@mpMinLatF = 10  
res@mpMaxLatF = 55
res@mpMinLonF = -130
res@mpMaxLonF = -58
res@mpDataBaseVersion = "Ncarg4_1"
res@mpDataSetName = "Earth..2"
res@mpOutlineBoundarySets = "AllBoundaries"
res@mpCountyLineColor = "background"  ;Make county boundaries invisible
res@mpUSStateLineThicknessF = 2
res@mpNationalLineThicknessF = 2
res@mpUSStateLineColor = "black"
res@mpFillOn = False
res@mpGeophysicalLineThicknessF = 2.
res@mpGridAndLimbOn = False
res@mpGridLineDashPattern = 5
res@mpGridLineThicknessF = 1.
res@tmXBLabelsOn = False
res@tmYLLabelsOn = False
res@tmXBOn = False
res@tmXTOn = False
res@tmYLOn = False
res@tmYROn = False
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False
plot = gsn_csm_map_ce(wks,res)

txres = True
txres@txFontHeightF = 0.018
txres@txFontColor = "blue"
txres@txPerimOn = True
txres@txPerimSpaceF = 0
txres@txPerimColor = "white"
txres@txBackgroundFillColor = "white"
dum = gsn_add_text(wks,plot,stations_string,lons,lats,txres)

draw(plot)
frame(wks)
