load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-----------------------------------------------------------------; 
; flight_level_altitude.ncl
; Patrick Duran
; 07 October 2015 
; 
; Will read in a netCDF file containing 1-Hz flight-level aircraft
; data and plot a time series of the aircraft's altitude and
; potential temperature.
;-----------------------------------------------------------------;

;----------------;
;DATA DIRECTORIES;
;----------------;
ncfile = "/nfs/jm13/pduran/case_studies/ivan/flight_level/data/040915na.cdf"

;----------;
;PARAMETERS;
;----------;
minalt = 12000          ;The altitude the plane must be above for plotting to occur [meters]

;---------------------;
;Get flight level data;
;---------------------;
flightdata  = addfile(ncfile,"r")
alt         = flightdata->GPALT        ;Altitude
base_time   = flightdata->base_time    ;Base time (Seconds since Jan 1, 1970)
flight_time = flightdata->time_offset  ;Time since base_time (seconds)
theta       = flightdata->THETA 
time_sec    = base_time + flight_time  ;Observation times (Seconds since Jan 1, 1970)
flight_time_minu = flight_time/60      ;Convert flight time to minutes for use in plotting


;--------------------------;
;Get altitudes above minalt;
;--------------------------;
bottomind = min(ind(alt.gt.minalt))
topind    = max(ind(alt.gt.minalt))
altitudes = alt(bottomind:topind) / 1000
thetas    = theta(bottomind:topind)
times     = flight_time_minu(bottomind:topind)
print(times(0))

wks = gsn_open_wks("png","/jm13/pduran/web/ivan_flight_altitude")
altres = True
altres@xyLineThicknesses = 3
altres@tiYAxisString = "Altitude (km)"
altres@tiXAxisString = "Flight time (minutes)"
altres@trXMinF = times(0)
altres@trXMaxF = times(dimsizes(times)-1)
altres@gsnMaximize = True

thetares = altres
thetares@tiYAxisString = "Potential Temperature (K)"
thetares@tiYAxisFontColor = "red"
thetares@xyLineColor = "red"
;plot = gsn_csm_xy2(wks,times,altitudes,thetas,altres,thetares)
plot = gsn_csm_xy(wks,times,altitudes,altres)
