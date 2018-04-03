load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
load "/spare11/ktyle/gem2ncl/ncl6/gem2ncl.ncl"
load "/jm13/pduran/ncl/dv_pltlibs.ncl"

;;###########################################################################;;
;SNPARM = PRES;TMPC;DWPC;UWND;VWND;HGHT;RELH;VSPD;CNT1;CNT2;CNT3;CNT4;CNT5;CNT6;CNT7;CNT8


;-------------------------------------------------------------;
;pltcon-ZR.ncl                                                ;
;djv                                                          ;
;12/10/2013                                                   ;
;                                                             ;
; Reads in dropsonde editfiles averaged into radial bins then ;
; extracts out a user def var and plots a radius/height cross ;
; section   
;
;EDITS
;-----
;Patrick Duran
;   1/28/2014 - Added theta-e plotting functionality
;                                                  ;
;-------------------------------------------------------------;

;Set paths to data

editpath  = "/jm13/pduran/unix_scripts_and_c++/allsondes_18z_avg/"
;editpath = "/jm11/djv/G-IVstudy/processed_sondes/calcs/no-ecmwf/r1000/04f/rad/rhi/" 
nclpath   = systemfunc("pwd")+"/"               

; ################# USER SET PARAMETERS #####################
thresh = 0.25
color_table = (/"white","black","white","cyan","blue","green","yellow","red","magenta","purple"/)
;color_table = (/"white","black","white","blue","green","yellow"/)
oname = "ZR-"
title = "BRCH % < "+thresh+" (18 UTC - 795 Sondes)"
outfile = "brch_18UTC_diurnal.lt."+thresh 

;Read input files
var = new((/181,10/),"float")
snd_files = systemfunc("ls "+editpath+"/*allintensities*.freq.lt."+thresh)
num_snd_files = dimsizes(snd_files)
do i=0,num_snd_files-1
   data = readAsciiTable(snd_files(i),3,"float",1)
   do j=0,180
      if(data(j,2).ge.10)     ;Only get values if >10 obs
         var(j,i) = data(j,1)
      end if
   end do
end do
var = where(var.eq.-9999,var@_FillValue,var)

;Name dimensions and create coordinate variables
var!0 = "height"
var!1 = "radius"
var&height = fspan(0,dimsizes(var(:,0))-1,181) / 10
var&radius = ispan(50,950,100)

;Create workstation
wks = create_wks(outfile,color_table,"png")

  res = True
  res@cnFillOn             = True
  res@cnLineLabelsOn       = False
  res@cnLinesOn            = False
  res@cnFillMode           = "AreaFill"
  res@lbLabelBarOn          = True
  res@cnLevelSelectionMode = "ExplicitLevels"
  if(thresh.eq.1)then
     res@cnLevels = (/20,30,40,50,60,70,80/)
  else
     res@cnLevels = (/5,10,15,20,25,30,35/)
;     res@cnLevels = (/5,10/)
  end if
  res@trYMinF = 9
  res@trYMaxF = 16

  res@tiMainString          = title
  res@lbTitleString = ""
  res@tiYAxisString = "Height [km]"
  res@tiXAxisString = "Radius [km]"

  res@gsnDraw      =  False
  res@gsnFrame     =  False
  res@gsnSpreadColors = False
  res@gsnAddCyclic   = False
 
  res@lbBoxLinesOn          = True
  res@lbOrientation         = "Vertical"
  res@lbLabelAutoStride     = True
  res@lbTitlePosition      = "bottom"
  res@pmLabelBarWidthF     = 0.07
 
  plot = gsn_csm_contour(wks,var,res)
 
  draw(plot)
  frame(wks)
