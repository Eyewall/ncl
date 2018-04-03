load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;;###########################################################################;;
; This file contains various subroutines used in plot programs:
; DV_PANEL: 2/13: Proc to divide viewport into varois panels(1-8)
; CREATE_WKS: 2/13:Func to create a Workstation maximizing 8.5x11 sq area
; GRAB_BASE_RES: 2/13: Func to set up various map plotting parameters
; GET_NCOLS_ASCTAB: 7/13: Func to get the number of columns in ASCII tablefile
; GET_CONTPARM: 7/13:Func to define some contour plotting params
; GET_VECPARM: 7/13:Func to define some vector plotting params
; PLOT_LETMAP: 7/13: Func to plot letters on a map
;;###########################################################################;;


;;###########################################################################;;
undef("create_wks")
;;###########################################################################;;
function create_wks(out_fil:string, col_tab:string, type:string)

;; Function to create a Workstation maximizing 8.5x11 square area
;  Need names of output plot file and color_table as input
;  Author djv  (modified version of M. Janiga's routine)
;  Last Update: 2/13

begin
; PS/PDF 8.5x11" limits: x= 0 612 y=0 792
;                 def  : x=36 612-36 y=126 792-126
;  wks_type = "ps"        ; or "pdf"

  outtyp = type
  yoff = 95
  xoff = 5
  type@wkDeviceUpperY = 792 - yoff
  type@wkDeviceLowerY = yoff
  type@wkDeviceUpperX = 612 - xoff
  type@wkDeviceLowerX = xoff
  type@wkOrientation = "portrait"
  wks = gsn_open_wks(outtyp, out_fil)   
  gsn_define_colormap(wks, col_tab)   
  return(wks)
end

;;###########################################################################;;
undef("grab_base_res")
;;###########################################################################;;
;; Set the base (universal) settings
;;Function to set up various map plotting parameters
;  Author djv  (modified version of M. Janiga's routine)
;  Last Update: 2/13
;; 
function grab_base_res(opt:logical)
begin
  
  res = True

; Specify the high-level interfaces
  res@gsnDraw      =  False     ; Do not draw the plot
  res@gsnFrame     =  False     ; Do not advance the frame

  res@gsnMajorLatSpacing = 10
  res@gsnMinorLatSpacing = 2
  res@gsnMajorLonSpacing = 10
  res@gsnMinorLonSpacing = 2

; Specify the map resources
  res@mpDataBaseVersion           = "MediumRes"     
  res@mpDataSetName               = "Earth..4"
  res@mpGeophysicalLineColor      = "gray20"   
  res@mpGeophysicalLineThicknessF = 2        
  res@mpNationalLineColor         = res@mpGeophysicalLineColor  
  res@mpOutlineBoundarySets       = "National"       
  res@mpOutlineOn                 = True               
  res@mpUSStateLineColor          = res@mpGeophysicalLineColor

;  res@mpFillOn                    = True      
       

; Specify the gridding resources
  res@mpGridAndLimbOn             = False
  res@mpGridLatSpacingF           = 10
  res@mpGridLonSpacingF           = 10
  res@mpGridLineColor             = "gray20"
  res@mpGridLineThicknessF        = 0.5
  res@mpGridLineDashPattern       = 1       ; make lat/lon lines dash


; Set the tick mark resources
;  res@tmXTLabelsOn    = True
;  res@tmYRLabelsOn    = True
  res@tmXBLabelFontHeightF  = 0.023         
  res@tmYLLabelFontHeightF  = 0.023
  res@tmXTLabelFontHeightF  = 0.0
  res@tmYRLabelFontHeightF  = 0.023
  res@tmXBMajorLengthF = 0.012
  res@tmXBMinorLengthF = 0.007


  return(res)
 
end

;;###########################################################################;; 
 undef("dv_panel")
;;###########################################################################;;
; Will set a workspace array for a multi-paneled plot.
; Author djv  
; Last updated 2/13
; Need #panels and logical option array as input

procedure dv_panel(npan:integer,vpxylocs[*][*][*]:float,vpXYLBoffset[*][*][*]:float,res:logical)
begin

; Determine plot sizes depending on npan and margins
  margin = .04
  size = new((8),"float")
  scale = new((8),"float")
  size = (/0.8,0.4,0.28,0.4,0.28,0.28,0.20,0.20/)
  scale = (/0.8,0.5,0.33,0.5,0.33,0.33,0.25,0.25/)
  vpXYLBoffset = new((/3,2,8/),"float")         ;XY offset locs for labbar
  width = size(npan-1)
  height = size(npan-1)
  scale_fact = scale(npan-1)


; Define viewport xylocs of each panel based on npan(left/top)
; array   vpxylocs(/pan#,xy,npan/),"float")
  vpxylocs = new((/8,2,8/),"float")


  if (npan .eq. 1) then
   vpxylocs(0,0,0) = 2.5*margin
   vpxylocs(0,1,0) = 1-1.5*margin
   vpXYLBoffset(0,0,1) =  0.5                ; xoffset last plt on lft
   vpXYLBoffset(0,1,1) =  0.05               ; yoffset last plt on lft
   vpXYLBoffset(1,0,0) =  0.5                ; xoffset last plt on rgt
   vpXYLBoffset(1,1,0) =  0.05               ; yoffset last plt on rgt
   vpXYLBoffset(2,0,0) =  0.5                ; xoffset last plt on cen
   vpXYLBoffset(2,1,0) =  0.12               ; yoffset last plt on cen
  end if

; 2pan vert
  if (npan .eq. 2) then
   vpxylocs(0,0,1) = 0.5-(size(npan-1)/2.)          ; upperx
   vpxylocs(0,1,1) = 2.*size(npan-1)+(3.5*margin)   ; uppery
   vpxylocs(1,0,1) = 0.5-(size(npan-1)/2.)          ; lowerx
   vpxylocs(1,1,1) = size(npan-1)+(2.3*margin)      ; lowery
   vpXYLBoffset(0,0,1) =  0.5                ; xoffset last plt on lft
   vpXYLBoffset(0,1,1) =  0.04               ; yoffset last plt on lft
   vpXYLBoffset(1,0,1) =  0.5                ; xoffset last plt on rgt
   vpXYLBoffset(1,1,1) =  0.04               ; yoffset last plt on rgt
   vpXYLBoffset(2,0,1) =  0.5                ; xoffset last plt on cen
   vpXYLBoffset(2,1,1) =  0.12               ; yoffset last plt on cen
  end if

  if (npan .eq. 3) then
   vpxylocs(0,0,2) = 0.5-(size(npan-1)/2.)          ; upperx
   vpxylocs(0,1,2) = 3.*size(npan-1)+(3.7*margin)   ; uppery
   vpxylocs(1,0,2) = 0.5-(size(npan-1)/2.)          ; midx
   vpxylocs(1,1,2) = 2.*size(npan-1)+(2.9*margin)   ; midy
   vpxylocs(2,0,2) = 0.5-(size(npan-1)/2.)          ; lowerx
   vpxylocs(2,1,2) = size(npan-1)+(2.1*margin)      ; lowery
   vpXYLBoffset(0,0,2) =  0.5                ; xoffset last plt on lft
   vpXYLBoffset(0,1,2) =  0.02               ; yoffset last plt on lft
   vpXYLBoffset(1,0,2) =  0.5                ; xoffset last plt on rgt
   vpXYLBoffset(1,1,2) =  0.02               ; yoffset last plt on rgt
   vpXYLBoffset(2,0,2) =  0.5                ; xoffset last plt on cen
   vpXYLBoffset(2,1,2) =  0.12               ; yoffset last plt on cen
  end if

   if (npan .eq. 4 ) then
   vpxylocs(0,0,3) = 0.5-size(npan-1)-margin        ; upper-leftx
   vpxylocs(0,1,3) = 2.*size(npan-1)+(3.3*margin)   ; upper-lefty
   vpxylocs(1,0,3) = 0.5+(margin)                   ; upper-rightx
   vpxylocs(1,1,3) = 2.*size(npan-1)+(3.3*margin)   ; upper-righty
   vpxylocs(2,0,3) = 0.5-size(npan-1)-margin        ; lower-leftx
   vpxylocs(2,1,3) = size(npan-1)+(2.1*margin)      ; lower-lefty
   vpxylocs(3,0,3) = 0.5+(margin)                   ; lower-rightx
   vpxylocs(3,1,3) = size(npan-1)+(2.1*margin)      ; lower-righty
   vpXYLBoffset(0,0,3) =  1.1575             ; xoffset last plt on lft
   vpXYLBoffset(0,1,3) =  0.05               ; yoffset last plt on lft
   vpXYLBoffset(1,0,3) = -0.0875             ; xoffset last plt on rgt
   vpXYLBoffset(1,1,3) =  0.05               ; yoffset last plt on rgt
   vpXYLBoffset(2,0,3) = -0.0875             ; xoffset last plt on cen
   vpXYLBoffset(2,1,3) =  0.08               ; yoffset last plt on cen
  end if

  if (npan .eq. 5) then
   vpxylocs(0,0,4) = 0.5-size(npan-1)-margin/2.     ; upper-leftx
   vpxylocs(0,1,4) = 3.*size(npan-1)+(3.7*margin)   ; upper-lefty
   vpxylocs(1,0,4) = 0.5+(margin)                   ; upper-rightx
   vpxylocs(1,1,4) = 3.*size(npan-1)+(3.7*margin)   ; upper-righty
   vpxylocs(2,0,4) = 0.5-size(npan-1)-margin/2.     ; mid-leftx
   vpxylocs(2,1,4) = 2.*size(npan-1)+(2.9*margin)   ; mid-lefty
   vpxylocs(3,0,4) = 0.5+(margin)                   ; mid-rightx
   vpxylocs(3,1,4) = 2.*size(npan-1)+(2.9*margin)   ; mid-righty
   vpxylocs(4,0,4) = 0.5-(size(npan-1)/2.)+margin/4 ; lower-midx
   vpxylocs(4,1,4) = size(npan-1)+(2.1*margin)      ; lower-midy
   vpXYLBoffset(0,0,4) =  1.1575             ; xoffset last plt on lft
   vpXYLBoffset(0,1,4) =  0.05               ; yoffset last plt on lft
   vpXYLBoffset(1,0,4) = -0.0875             ; xoffset last plt on rgt
   vpXYLBoffset(1,1,4) =  0.05               ; yoffset last plt on rgt
   vpXYLBoffset(2,0,4) =  0.5                ; xoffset last plt on cen
   vpXYLBoffset(2,1,4) =  0.13               ; yoffset last plt on cen
  end if

  if (npan .eq. 6) then
   vpxylocs(0,0,5) = 0.5-size(npan-1)-margin/2      ; upper-leftx
   vpxylocs(0,1,5) = 3.*size(npan-1)+(3.7*margin)   ; upper-lefty
   vpxylocs(1,0,5) = 0.5+(margin)                   ; upper-rightx
   vpxylocs(1,1,5) = 3.*size(npan-1)+(3.7*margin)   ; upper-righty
   vpxylocs(2,0,5) = 0.5-size(npan-1)-margin/2      ; mid-leftx
   vpxylocs(2,1,5) = 2.*size(npan-1)+(2.9*margin)   ; mid-lefty
   vpxylocs(3,0,5) = 0.5+(margin)                   ; mid-rightx
   vpxylocs(3,1,5) = 2.*size(npan-1)+(2.9*margin)   ; mid-righty
   vpxylocs(4,0,5) = 0.5-size(npan-1)-margin/2      ; lower-leftx
   vpxylocs(4,1,5) = size(npan-1)+(2.1*margin)      ; lower-lefty
   vpxylocs(5,0,5) = 0.5+(margin)                   ; lower-rightx
   vpxylocs(5,1,5) = size(npan-1)+(2.1*margin)      ; lower-righty
   vpXYLBoffset(0,0,5) =  1.1575             ; xoffset last plt on lft
   vpXYLBoffset(0,1,5) =  0.05               ; yoffset last plt on lft
   vpXYLBoffset(1,0,5) = -0.0875             ; xoffset last plt on rgt
   vpXYLBoffset(1,1,5) =  0.05               ; yoffset last plt on rgt
   vpXYLBoffset(2,0,5) = -0.0875             ; xoffset last plt on cen
   vpXYLBoffset(2,1,5) =  0.05               ; yoffset last plt on cen
  end if

  if (npan .eq. 7) then
   vpxylocs(0,0,6) = 0.5-size(npan-1)-margin/2        ; upper-leftx
   vpxylocs(0,1,6) = 4.*size(npan-1)+(4.55*margin)    ; upper-lefty
   vpxylocs(1,0,6) = 0.5+(margin)                     ; upper-rightx
   vpxylocs(1,1,6) = 4.*size(npan-1)+(4.55*margin)    ; upper-righty
   vpxylocs(2,0,6) = 0.5-size(npan-1)-margin/2        ; mid2-leftx
   vpxylocs(2,1,6) = 3.*size(npan-1)+(3.75*margin)    ; mid2-lefty
   vpxylocs(3,0,6) = 0.5+(margin)                     ; mid2-rightx
   vpxylocs(3,1,6) = 3.*size(npan-1)+(3.75*margin)    ; mid2-righty
   vpxylocs(4,0,6) = 0.5-size(npan-1)-margin/2        ; mid1-leftx
   vpxylocs(4,1,6) = 2.*size(npan-1)+(2.95*margin)    ; mid1-lefty
   vpxylocs(5,0,6) = 0.5+(margin)                     ; mid1-rightx
   vpxylocs(5,1,6) = 2.*size(npan-1)+(2.95*margin)    ; mid1-righty
   vpxylocs(6,0,6) = 0.5-(size(npan-1)/2.)+margin/4          ; lower-midx
   vpxylocs(6,1,6) = size(npan-1)+(2.1*margin)            ; lower-midy
   vpXYLBoffset(0,0,6) =  1.1575             ; xoffset last plt on lft
   vpXYLBoffset(0,1,6) =  0.05               ; yoffset last plt on lft
   vpXYLBoffset(1,0,6) = -0.0875             ; xoffset last plt on rgt
   vpXYLBoffset(1,1,6) =  0.05               ; yoffset last plt on rgt
   vpXYLBoffset(2,0,6) =  0.52               ; xoffset last plt on cen
   vpXYLBoffset(2,1,6) =  0.17                ; yoffset last plt on cen
  end if

  if (npan .eq. 8) then
   print(npan)
   vpxylocs(0,0,7) = 0.5-size(npan-1)-margin/2.       ; upper-leftx
   vpxylocs(0,1,7) = 4.*size(npan-1)+(4.55*margin)    ; upper-lefty
   vpxylocs(1,0,7) = 0.5+(margin)                     ; upper-rightx
   vpxylocs(1,1,7) = 4.*size(npan-1)+(4.55*margin)    ; upper-righty
   vpxylocs(2,0,7) = 0.5-size(npan-1)-margin/2.       ; mid2-leftx
   vpxylocs(2,1,7) = 3.*size(npan-1)+(3.75*margin)    ; mid2-lefty
   vpxylocs(3,0,7) = 0.5+(margin)                     ; mid2-rightx
   vpxylocs(3,1,7) = 3.*size(npan-1)+(3.75*margin)    ; mid2-righty
   vpxylocs(4,0,7) = 0.5-size(npan-1)-margin/2.       ; mid1-leftx
   vpxylocs(4,1,7) = 2.*size(npan-1)+(2.95*margin)    ; mid1-lefty
   vpxylocs(5,0,7) = 0.5+(margin)                     ; mid1-rightx
   vpxylocs(5,1,7) = 2.*size(npan-1)+(2.95*margin)    ; mid1-righty
   vpxylocs(6,0,7) = 0.5-size(npan-1)-margin/2.       ; lower-leftx
   vpxylocs(6,1,7) = size(npan-1)+(2.1*margin)        ; lower-lefty
   vpxylocs(7,0,7) = 0.5+(margin)                     ; lower-midx
   vpxylocs(7,1,7) = size(npan-1)+(2.1*margin)            ; lower-midy
   vpXYLBoffset(0,0,7) =  1.1575             ; xoffset last plt on lft
   vpXYLBoffset(0,1,7) =  0.05               ; yoffset last plt on lft
   vpXYLBoffset(1,0,7) = -0.13               ; xoffset last plt on rgt
   vpXYLBoffset(1,1,7) =  0.0                ; yoffset last plt on rgt
   vpXYLBoffset(2,0,7) = -0.13               ; xoffset last plt on cen
   vpXYLBoffset(2,1,7) =  0.17                ; yoffset last plt on cen
  end if

  res             = True
  res@vpWidthF    = width
  res@vpHeightF   = height
  res@scale       = scale_fact
  res@mpShapeMode = "FixedAspectFitBB"   

  ylab = 0
  if (ismissing(res@tmXTLabelsOn)) then     ;XTLabel def=F
   print("XTLAB=F")
  else
   ylab = ylab+1
  end if
 
  if (ismissing(res@tmXBLabelsOn) .or. (isdefined(res@tmXBLabelsOn).and.res@tmXBLabelsOn .eq. "True" )) then     ;XBlabel def=T
   ylab = ylab+1
  else
   print("XBLAB=F")
  end if

  xlab = 0
  if (ismissing(res@tmYRLabelsOn)) then     ;YRLabel def=F
   print("YRLAB=F")
  else
   xlab = xlab+1
  end if
 
  if (ismissing(res@tmYLLabelsOn) .or. (isdefined(res@tmYLLabelsOn).and.res@tmYLLabelsOn .eq. "True" )) then     ;YLlabel def=T
   xlab = xlab+1
  else
   print("YLLAB=F")
  end if
  print ("UUUU "+ylab+" "+xlab)


; DEFINE SOME LABEL BAR PARAMETERS
;*********************************
  res@pmLabelBarHeightF       = 0.075
  res@pmLabelBarWidthF        = 0.4
  res@lbLabelAutoStride       = True         ; space out labelbar labs
  res@lbBoxMajorExtentF       = 1.0
;  res@lbLabelAlignment        = "InteriorEdges"    ; (InteriorEdges,BoxCenters"
  res@lbLabelAlignment        = "BoxCenters"    ; (InteriorEdges,
  res@lbLabelFontHeightF      = 0.012
  res@lbLabelFontThicknessF   = 1.0
  res@lbPerimOn               = False
  res@lbOrientation           = "Horizontal"

  return(res)
end

;;###########################################################################;;
;; Function to get number of columns on ASCII table for use in readAsciiTable
;;###########################################################################;;
undef("get_ncols_asctab")
  function get_ncols_asctab(filnam:string)

begin
  
  sys_cmd = " awk 'NR == 1 {print NF}  ' "+filnam+" >tmpcols"
  system(sys_cmd)
  scols = systemfunc (" cat tmpcols")      ;systemfunc returns STRING!
  cols=stringtoint(scols)
  sys_cmd = " rm tmpcols"
  system(sys_cmd)
  print("number of columns in "+filnam+" ="+cols)
  return(cols)
end

;;###########################################################################;;
;; Function to define certain contour plotting characteristics
;;###########################################################################;;
undef("get_contparm")
  function get_contparm(opt:logical)
begin
  opt = True
  opt@cnHighLabelFontHeightF     = 0.018      ; change H font
  opt@cnHighLabelFontThicknessF  = 3.01
  opt@cnHighLabelBackgroundColor = -1         ; make H background transparent
  opt@cnHighLabelFormat          =" @#0;1.2g" 
  opt@cnLowLabelFontHeightF      = 0.014      ; change L font
  opt@cnLowLabelBackgroundColor  = -1         ; make L background transparent
  opt@cnLowLabelFormat           =" @#0;1.3g" 
  opt@cnInfoLabelOn              = False
  return(opt)
end

;;###########################################################################;;
;; Function to define certain vector plotting characteristics
;;###########################################################################;;
undef("get_vecparm")
  function get_vecparm(opt:logical)
begin
  opt = True
  opt@vcLineArrowHeadMaxSizeF   = 0.008
  opt@vcLineArrowHeadMinSizeF   = 0.008
  opt@vcGlyphStyle            = "LineArrow"     ; turn on curley vecvtors
  opt@vcRefAnnoPerimOn      = False
  opt@vcRefAnnoString1      = "$VMG$ m/s" 
  opt@vcRefAnnoString2On    = False    ;Turns off string "Reference Vector"
  opt@vcRefAnnoFontHeightF  = 0.018
  opt@vcRefAnnoFontThicknessF = 1.2
  opt@vcRefAnnoExplicitMagnitudeF = 20
  opt@vcRefLengthF              = 0.05              ;define length of ref
  opt@vcRefAnnoArrowMinOffsetF   = 0.25
  opt@vcRefAnnoArrowSpaceF       = 0.5
  opt@vcRefAnnoBackgroundColor = -1                 ; Transparent
  opt@vcRefAnnoArrowLineColor   = "black"           ; change ref vector color
  opt@vcRefAnnoArrowUseVecColor = False             ;don't use vec colr inref
  opt@vcRefAnnoFont  = 0
;  opt@vcRefAnnoSide = "Right"                    ;side to put refvec
  return(opt)
end

;;###########################################################################;;
;; Function to plot letters on a map
;;###########################################################################;;
undef("Plot_letmap")
procedure Plot_letmap(wks:graphic,plot[*]:graphic,numlet:integer,frme:integer,xlat[*]:float,xlon[*]:float,let_id[*]:integer,let_col[*]:integer,jloc[*]:integer, size:float,thick[*]:float,opt:logical)

begin
   tres                      = True                ; text mods desired
   letlab = new((/52/),"string")
   marker1 = new((/8,100/),graphic)
   letlab = (/"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"/)

   if (numlet .gt. 0 ) then
    do j = 0,numlet-1
     print("Plot stormloc2 "+xlon(jloc(j))+" "+xlat(jloc(j))+" "+jloc(j))
     tres@txFontHeightF        = 0.95*size               ; make smaller
     tres@txFontColor          = let_col(jloc(j))
     tres@txFont               = 4                  ;helv=21 ;roman 4
     tres@txFontThicknessF     = thick(jloc(j))
     xlat1=xlat(jloc(j))+.0
     xlon1=xlon(jloc(j))+.0
     marker1(frme,j) = gsn_add_text(wks,plot(frme),letlab(let_id(jloc(j))-1),xlon1,xlat1,tres)
     tres@txFontHeightF        = size               ; make smaller
     tres@txFontColor          = 1
     tres@txFont               = 4                  ;helv thk=22
     tres@txFontThicknessF     = thick(jloc(j))+1
     marker1(frme,j) = gsn_add_text(wks,plot(frme),letlab(let_id(jloc(j))-1),xlon(jloc(j)),xlat(jloc(j)),tres)
    end do
   end if
   return
end

