load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"

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


