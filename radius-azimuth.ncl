load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-------------------------------------------------;
;Patrick Duran                                    ;
;1/2/2014                                         ;
;radius-azimuth.ncl                               ;
;                                                 ;
;Will read in an input file of radii and azimuths,;
;convert to Cartesian, and plot on an XY plot, set;
;up to look like a polar plot with storm center at;
;the origin.                                      ;
;-------------------------------------------------;

;----------------------------------------------------;
;THIS IS A CIRCLE PLOTTING PROCEDURE TO BE USED LATER;
;SEE BELOW FOR DATA PROCESSING AND PLOTTING CODE.....;
;----------------------------------------------------;
undef("circle_ll")
procedure circle_ll(wks:graphic,plt:graphic,x0:numeric,y0:numeric,r:numeric,res:logical)

begin
 rot = 0.0
 scale = 1.0
 th = ispan(0,360,1)
 pi = acos(-1.0)

 res1 = res
 if(res)then
  if(isatt(res,"Scale"))then
   scale = res@Scale
   delete(res1@Scale)
  end if
  if(isatt(res,"Rotation"))then
   rot = res@Rotation
   delete(res1@Rotation)
  end if
 end if

 getvalues plt
  "trXMinF":xmin
  "trXMaxF":xmax
  "trYMinF":ymin
  "trYMaxF":ymax
  "vpXF":vpx0
  "vpYF":vpy1
  "vpWidthF":vpw
  "vpHeightF":vph
 end getvalues

 rx = r/(xmax-xmin)
 ry = rx*vpw/vph

 xpts1 = cos(th*pi/180)
 ypts1 = sin(th*pi/180)*scale

 xpts2 = xpts1*cos(rot*pi/180) - ypts1*sin(rot*pi/180)
 ypts2 = xpts1*sin(rot*pi/180) + ypts1*cos(rot*pi/180)

 xpts = rx*xpts2*(xmax-xmin) + x0
 ypts = ry*ypts2*(ymax-ymin) + y0
 str = unique_string("circle_ll")
 plt@$str$ = gsn_add_polyline(wks,plt,xpts,ypts,res1)
 delete(str)
 delete(xpts1)
 delete(ypts1)
 delete(xpts2)
 delete(ypts2)
 delete(th)
 delete(res1)

end

;-----------------------------------------;
;PROCESS AND PLOT THE RADIOSONDE LOCATIONS;
;-----------------------------------------;
;Set some parameters
pi = 3.141592
maxrad = 1000.   ;Maximum radius in kilometers
radius_file = "/jm13/pduran/unix_scripts_and_c++/radii.dat"     ;File containing radii
azimuth_file = "/jm13/pduran/unix_scripts_and_c++/azimuths.dat" ;File containing azimuths
hurdatfile = "/jm13/pduran/hurdat2-atlantic-1851-2012-060513_NO_SPACES.txt"
sonde_dir = "/jm13/pduran/1+6sec_sondes_1dir/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_QC"

;Get number of lines in input files
nlines_rad = stringtoint(systemfunc("wc "+radius_file+" | awk '{print($1)}'"))
nlines_azi = stringtoint(systemfunc("wc "+azimuth_file+" | awk '{print($1)}'"))

;Make sure the files have the same number of lines
if(nlines_rad.ne.nlines_azi)then
   print("ERROR: Radius and azimuth files are different lengths!")
   exit
end if

;Get sonde location data
radius_data = asciiread(radius_file,nlines_rad,"string")
azimuth_data = asciiread(azimuth_file,nlines_azi,"string")

;Initialize variables and create arrays
index = 0
numsondes = 1
TD = 0
TS = 0
CAT1 = 0
CAT2 = 0
CAT3 = 0
CAT4 = 0
CAT5 = 0
ne_quad = 0
se_quad = 0
sw_quad = 0
nw_quad = 0
ne_quad_maxrad = 0
se_quad_maxrad = 0
sw_quad_maxrad = 0
nw_quad_maxrad = 0
rad250 = 0
rad250to500 = 0
rad500to750 = 0
rad750to1000 = 0
radii_final = new(100000,"float")
azimuths_final = new(100000,"float")

;Loop through all lines in input file
do i=0,nlines_rad-1
   i = i + 1
   systemtime = systemfunc("date")
   print("Processing line "+i+" of "+nlines_rad+"   "+systemtime)
   i = i - 1
   ;Get data from input files
   radline = radius_data(i)
   aziline = azimuth_data(i)
   stn = systemfunc("echo "+radline+" | awk '{print($1)}' | sed s%\.\/%%g")
   dattim = systemfunc("echo "+radline+" | awk '{print($3)}'")
   date = systemfunc("echo "+dattim+" | colrm 7 10")
   time = systemfunc("echo "+dattim+" | colrm 9 10 | colrm 1 6")
   dattim_hurdat_format = date+","+time
   ;Get number of radii and azimuths in this line of the file
   nrads = stringtoint(systemfunc("echo "+radline+" | awk -F' ' '{print NF ; exit}'")) - 3
   nazis = stringtoint(systemfunc("echo "+aziline+" | awk -F' ' '{print NF ; exit}'")) - 3
   if(nrads.ne.nazis)then
      print("ERROR: Different number of radii and azimuths!")
      exit
   end if
   ;Loop through each radius/azimuth
   do j=0,nrads-1
      jj = j + 4
      radius = stringtofloat(systemfunc("echo "+radline+" | awk '{print($"+jj+")}'"))
      azimuth = stringtofloat(systemfunc("echo "+aziline+" | awk '{print($"+jj+")}'"))
      ;We need to take the opposite of the azimuth angles because the
      ;azimuths in the input file are drawn from the station to the
      ;storm, while we need azimuths dwawn from the storm to the station
         if((azimuth.gt.180).and.(azimuth.lt.360))then
            azimuth = azimuth - 180
         else if(azimuth.lt.180)then
            azimuth = azimuth + 180
         end if
         end if
      ;Calculate the number of sondes in each quadrant for ALL radii
      if((azimuth.gt.0).and.(azimuth.lt.90))then
         ne_quad = ne_quad + 1
      else if((azimuth.gt.90).and.(azimuth.lt.180))then
         se_quad = se_quad + 1
      else if((azimuth.gt.180).and.(azimuth.lt.270))then
         sw_quad = sw_quad + 1
      else if((azimuth.gt.270).and.(azimuth.lt.360))then
         nw_quad = nw_quad + 1
      end if
      end if
      end if
      end if
      ;Determine the intensity of the storm(s) that correspond(s) to this
      ;rawinsonde
      hurdat = systemfunc("grep -i "+dattim_hurdat_format+" "+hurdatfile)
      nhurdats = dimsizes(hurdat)
      do k=0,nhurdats-1
         hurdat_split = str_split(hurdat(k),",")
         lat_string = hurdat_split(3)
         lon_string = hurdat_split(4)
         sondelat = stringtofloat(systemfunc("head "+sonde_dir+stn+"-"+dattim+suffix+" | sed -n 5p | awk '{print($3)}'"))
         sondelon = stringtofloat(systemfunc("head "+sonde_dir+stn+"-"+dattim+suffix+" | sed -n 5p | awk '{print($6)}'"))
         hurlat = stringtofloat(systemfunc("echo "+lat_string+" | sed s/N//g"))
         hurlon = stringtofloat(systemfunc("echo "+lon_string+" | sed s/W//g"))
         distance = gc_latlon(sondelat,sondelon,hurlat,hurlon,2,4)
         if(distance.le.maxrad)then
            vmax = hurdat_split(5)
            if(vmax.le.33)then
               TD = TD + 1
            else if((vmax.gt.33).and.(vmax.le.63))then
               TS = TS + 1
            else if((vmax.gt.63).and.(vmax.le.82))then
               CAT1 = CAT1 + 1
            else if((vmax.gt.82).and.(vmax.le.95))then
               CAT2 = CAT2 + 1
            else if((vmax.gt.95).and.(vmax.le.113))then
               CAT3 = CAT3 + 1
            else if((vmax.gt.113).and.(vmax.le.135))then
               CAT4 = CAT4 + 1
            else if(vmax.gt.135)then
               CAT5 = CAT5 + 1
            end if
            end if
            end if
            end if
            end if
            end if
            end if
         end if 
      end do
      delete(hurdat)   
      ;If we're within the maximum radius...
      if(radius.le.maxrad)then
         radii_final(index) = radius
         azimuths_final(index) = azimuth
         index = index + 1
         numsondes = numsondes + 1
         ;Calculate the number of sondes in each quadrant
         if((azimuth.gt.0).and.(azimuth.lt.90))then
            ne_quad_maxrad = ne_quad_maxrad + 1
         else if((azimuth.gt.90).and.(azimuth.lt.180))then
           se_quad_maxrad = se_quad_maxrad + 1
         else if((azimuth.gt.180).and.(azimuth.lt.270))then
           sw_quad_maxrad = sw_quad_maxrad + 1
         else if((azimuth.gt.270).and.(azimuth.lt.360))then
           nw_quad_maxrad = nw_quad_maxrad + 1
         end if
         end if
         end if
         end if
         ;Calculate the number of sondes in each radial bin
         if(radius.le.250)then
           rad250 = rad250 + 1
         else if((radius.le.500).and.(radius.gt.250))then
           rad250to500 = rad250to500 + 1
         else if((radius.le.750).and.(radius.gt.500))then
           rad500to750 = rad500to750 + 1
         else if((radius.le.1000).and.(radius.gt.750))then
           rad750to1000 = rad750to1000 + 1
         end if
         end if
         end if
         end if
         ;Determine the intensity distribution for the sondes
         
      end if
   end do
end do
print(" ")
print("---ALL SONDES---")
print("NE Quadrant: "+ne_quad)
print("SE Quadrant: "+se_quad)
print("SW Quadrant: "+sw_quad)
print("NW Quadrant: "+nw_quad)
print(" ")
print("---SONDES WITHIN "+maxrad+"---")
print("NE Quadrant: "+ne_quad_maxrad)
print("SE Quadrant: "+se_quad_maxrad)
print("SW Quadrant: "+sw_quad_maxrad)
print("NW Quadrant: "+nw_quad_maxrad)
print(" ")
print("---SONDES WITHIN---")
print("0-250km: "+rad250)
print("250-500km: "+rad250to500)
print("500-750km: "+rad500to750)
print("750-1000km: "+rad750to1000)
print(" ")
print("---SONDES BY STORM CATEGORY---")
print("Tropical Depression :"+TD)
print("Tropical Storm: "+TS)
print("Category 1: "+CAT1)
print("Category 2: "+CAT2)
print("Category 3: "+CAT3)
print("Category 4: "+CAT4)
print("Category 5: "+CAT5)

;Convert degrees to radians and get x,y coordinates of sonde locations
azi_rad = azimuths_final*2*pi/360
x = radii_final*sin(radii_final)
y = radii_final*cos(azi_rad)

;Plot the points and overlay radii circles and axis labels
wks = gsn_open_wks("png","sonde_locations")
res = True
polyres = True
res@tiMainString = "Sonde Locations WRT Storm Center   N = "+numsondes
res@xyMonoMarkLineMode = "True"
res@xyMarkLineMode = "Markers"
res@xyMarker = 16
res@xyMarkerColor = "black"
res@trXMinF = -maxrad
res@trXMaxF = maxrad
res@trYMinF = -maxrad
res@trYMaxF = maxrad 
res@gsnMaximize = True
res@gsnDraw = False
res@gsnFrame = False
polyres@gsLineColor = "black"
polyres@gsLineThicknessF = 4.
plot = gsn_csm_xy(wks,x,y,res)
dum1 = gsn_add_polyline(wks,plot,(/0,0/),(/-maxrad,maxrad/),polyres)
dum2 = gsn_add_polyline(wks,plot,(/-maxrad,maxrad/),(/0,0/),polyres)

;Draw circles
do i=250,1000,250
   circle_ll(wks,plot,0,0,i,polyres)
end do

draw(plot)
frame(wks)

