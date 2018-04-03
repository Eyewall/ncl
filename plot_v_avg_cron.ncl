load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"


;---SET THESE OPTIONS---;
dir = DIR       ;Directory with ncdf files
ndays = NDAYS   ;Length of simulation 
intrvl = INTRVL ;Length of average [hours]
var = VAR       ;Variable to average
webdir = WEBDIR ;Directory where output will be placed
;-----------------------;

;Get list of NetCDF files
;Remember that axisym_hurr_15N_000001.nc corresponds to t=0, so the  number
;in the filename is one greater than the simulation hour, but the array
;subscripts of ndcf_files below will correspond to the actual hour, since
;indexing starts at 0. 

ncdf_files = systemfunc("ls "+dir+"*_0*.nc")
num_ncdf_files = dimsizes(ncdf_files)

ndays = 16
do j=1,ndays
   cntr = j*24
   
   ;Get files for average
   mini = cntr - (intrvl / 2)
   maxi = cntr + (intrvl / 2)
   if((.not.isinteger(mini)).or.(.not.isinteger(maxi)))then
      print("ERROR: mini or maxi is a non-integer array index! Check options.")
      exit
   end if
   if((mini.lt.0).or.(maxi.lt.0))then
      print("ERROR: Averaging interval out of range")
      exit
   end if
   files_to_avg = ncdf_files(mini:maxi)
   numfiles = dimsizes(files_to_avg)
   
   ;Initialize arrays
   infile = addfile(files_to_avg(0),"r")
   u_tot = infile->u
   v_tot = infile->v
   u_tot = 0
   v_tot = 0
   
   ;Calculate averages
   i = 0
   do while(i.lt.numfiles)
      unixi = i + 1
      print("Processing file "+unixi+" of "+numfiles)
      infile = addfile(files_to_avg(i),"r")
      u_tot = u_tot + infile->u
      v_tot = v_tot + infile->v
      z = infile->z
      i = i + 1
   end do
   u_avg = u_tot / numfiles 
   v_avg = v_tot / numfiles
   
   ;Create coordinate variable and name dimension for plotting
   hghts = z
   v_avg!1 = "hght"
   v_avg&hght = hghts
   u_avg!1 = "hght"
   u_avg&hght = hghts
   
   ;Create workstation, set resources, and plot
   filename = "avg_"+var+"_"+sprinti("%0.3i",mini)+"h-"+sprinti("%0.3i",maxi)+"h"
   wks = gsn_open_wks("png",filename)
   gsn_define_colormap(wks,"BlWhRe")
   
   ures = True
   ures@cnFillOn = True
   ures@tiMainString = "Radial Velocity Average "+sprinti("%0.3i",mini)+"h-"+sprinti("%0.3i",maxi)+"h"
   ures@tiXAxisString = "Radius [km]"
   ures@tiYAxisString = "Height [km]"
   ures@cnLevelSelectionMode = "ManualLevels"
   ures@cnLevelSpacingF = 2.
   ures@cnMinLevelValF = -10.
   ures@cnMaxLevelValF = 30.
   ures@gsnMaximize = True
   ures@trYMinF = 0
   ures@trYMaxF = 18
   ures@trXMinF = 0
   ures@trXMaxF = 1000
   ures@gsnSpreadColors = True
   ures@gsnSpreadColorStart = 35
   ures@gsnSpreadColorEnd = 102
   
   vres = ures
   vres@tiMainString = "Tangential Velocity Average "+sprinti("%0.3i",mini)+"h-"+sprinti("%0.3i",maxi)+"h"
   vres@cnLevelSpacingF = 5.
   vres@cnMinLevelValF = -30.
   vres@cnMaxLevelValF = 90.
   
   if(var.eq."u")then
      plot = gsn_csm_contour(wks,u_avg(0,:,0,:),ures)
   else if(var.eq."v")then
      plot = gsn_csm_contour(wks,v_avg(0,:,0,:),vres)
   end if
   end if
end do
