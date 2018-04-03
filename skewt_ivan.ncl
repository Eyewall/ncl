;**************************************************
; skewt_3.ncl
;
; Concepts illustrated:
;   - Drawing Skew-T plots
;   - Thinning the wind barbs in a Skew-T plot
;   - Customizing the background of a Skew-T plot
;**************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"
;**************************************************

; --- Read Data ----------------------------------------;
  diri = "INSERTDIRECTORYHERE"
  dropfile = "INSERTFILEHERE"
  windfile = "winds.tmp"
  ndroplevels = 1088
  ndropcols = 10 
  DropData = asciiread (diri+dropfile , (/ndroplevels,ndropcols/), "float") 
  WindData = asciiread (diri+windfile , (/ndroplevels,2/), "float")
; order: Surface is 'bottom'  eg: 1000,950,935,897,...  
                         
;  print(DropData(:,0))
  p    = DropData (:,0)    ; pressure     [mb / hPa] 
  tc   = DropData (:,1)    ; temperature  [C]    
  tdc  = DropData (:,2)    ; dew pt temp  [C]   
  z    = DropData (:,5)    ; geopotential [gpm] 
  wspd = WindData (:,0)    ; wind speed   [knots or m/s]    
  wdir = WindData (:,1)    ; meteorological wind dir   
;*************************
; create plot
;*************************
  wks  = gsn_open_wks ("png", "INSERTPSFILENAMEHERE")

; --- Create background skew-T and plot sounding----------------

  skewtOpts                 = True
  skewtOpts@DrawColAreaFill = False    ; default is False
  skewtOpts@tiMainString    = "DATE/TIME: DATTIMHERE      DROP ID: DROPIDHERE" ; Title" 
  skewtOpts@DrawFahrenheit  = False   ; default is True

  dataOpts           = True     ; options describing data and ploting
  dataOpts@Wthin     = 2        ; plot every n-th wind barb
  skewt_bkgd = skewT_BackGround (wks, skewtOpts)
  skewt_data = skewT_PlotData   (wks, skewt_bkgd, p,tc,tdc,z \
                                    , wspd,wdir, dataOpts)
  draw (skewt_bkgd)
  draw (skewt_data)
  frame(wks)
