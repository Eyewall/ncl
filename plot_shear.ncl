load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

dir = "/man4/ktyle/WRF/WRFV3/run_chelms/"

;etasurface = 18
etasurface = 8

;Get list of NetCDF files
num_ncdf_files = stringtoint(systemfunc("ls "+dir+"wrfout_d03* | wc"))
ncdf_files = systemfunc("ls "+dir+"wrfout_d02*")

;Loop through all files
i = 0
do while(i.lt.num_ncdf_files)
   i = i + 1
   print("Processing file "+i+" of "+num_ncdf_files)
   i = i - 1
   ;Load GRIB file - DON'T FORGET THE .GRB POSTSCRIPT!!
   wind_file = addfile(ncdf_files(i)+".nc","r")
   ;Get data from GRIB file
   latitude = wind_file->XLAT
   longitude = wind_file->XLONG
   u = wind_file->U
   v = wind_file->V
   msfu = wind_file->MAPFAC_U
   msfv = wind_file->MAPFAC_V
   msfm = wind_file->MAPFAC_M
   cor = wind_file->F
   p = wind_file->P_HYD
   dx = 9000.
   dy = 9000.
   opt = 0
   
   ;Give lat and lon units
   latitude@units="degrees_north"
   longitude@units="degrees_east"
  
   ;Calculate vorticity 
   vort = wrf_avo(u,v,msfu,msfv,msfm,cor,dx,dy,opt)
   
   ;Convert Pa to hPa
   p = p/100.
  
   filename_split = str_split(ncdf_files(i),"/")
   filename = filename_split(5)+"_vort"

   datesplit = str_split(filename,"_")
   title = datesplit(2)+" "+datesplit(3)
 
   minlat = 5
   maxlat = 25
   minlon = -85
   maxlon = -55
   
   res = True
   res@mpMinLatF = minlat
   res@mpMaxLatF = maxlat
   res@mpMinLonF = minlon
   res@mpMaxLonF = maxlon
   
   res@cnFillOn = True
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnLevelSpacingF = 5.
   res@cnMinLevelValF = -20.
   res@cnMaxLevelValF = 20.
   res@gsnMaximize = True
   res@gsnAddCyclic = False
   res@sfXArray = longitude(0,0,:)
   res@sfYArray = latitude(0,:,0)

   res@tiMainString = title+"    Eta Surface "+etasurface
   
   res1 = True
   
   res1@cnLevelSelectionMode = "ManualLevels"
   res1@cnLevelSpacingF = 4.
   res1@gsnMaximize = True
   res1@gsnAddCyclic = False
   res1@sfXArray = longitude(0,0,:)
   res1@sfYArray = latitude(0,:,0)
   
   wks = gsn_open_wks("PNG",filename)
   gsn_define_colormap(wks,"BlWhRe")
   
   ;plot = gsn_csm_contour_map(wks,v(0,15,:,:),res)

   plot = gsn_csm_contour_map_overlay(wks,vort(0,etasurface,:,:),p(0,etasurface,:,:),res,res1)
   ;plot2 = gsn_csm_contour_map(wks,vort(0,8,:,:),res)
   i = i + 1
end do
