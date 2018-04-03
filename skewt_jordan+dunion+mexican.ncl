load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_hs3_75mb.ncl"

sondefile1  = "/nfs/jm13/pduran/dropsondes/jordan_hurricane_season_sounding"
sondefile2  = "/nfs/jm13/pduran/dropsondes/dunion_moisttropical_sounding"
sondefile3  = "/nfs/jm13/pduran/dropsondes/acapulco+manzanillo_october2015_mean_sounding"
outdir = "/jm13/pduran/web/"
rd = 287.
cp = 1004.

;----------------------------;
;Get data from first dropfile;
;----------------------------;
DropData1 = readAsciiTable(sondefile1,3,"float",2)
z1    = DropData1 (:,0)    ; height     [m] 
tc1   = DropData1 (:,1)    ; temperature  [C]    
th1   = DropData1 (:,2)    ; potential temperature [K]
tdc1  = z1 
wspd1 = z1   
wdir1 = z1
tdc1  = -100
wspd1 = 0
wdir1 = 0
p1 = 1000*(th1/(tc1+273.15))^(-cp/rd)

;-----------------------------;
;Get data from second dropfile;
;-----------------------------;
DropData2 = readAsciiTable(sondefile2,3,"float",2)
z2    = DropData2 (:,0)    ; height     [m] 
tc2   = DropData2 (:,1)    ; temperature  [C]    
th2   = DropData2 (:,2)    ; potential temperature [K]
tdc2  = z2
wspd2 = z2
wdir2 = z2
tdc2  = -100
wspd2 = 0
wdir2 = 0
p2 = 1000*(th2/(tc2+273.15))^(-cp/rd)

;------------------------------;
;Get data from Wyoming dropfile;
;------------------------------;
DropData3 = readAsciiTable(sondefile3,3,"float",2)
z3    = DropData3 (:,0)    ; height     [m] 
tc3   = DropData3 (:,1)    ; temperature  [C]    
th3   = DropData3 (:,2)    ; potential temperature [K]
tdc3  = z3
wspd3 = z3
wdir3 = z3
tdc3  = -100
wspd3 = 0
wdir3 = 0
p3 = 1000*(th3/(tc3+273.15))^(-cp/rd)
tc3@_FillValue = -9999.

;;Convert wind speed to kt
;wspd1 = wspd1 * 1.944
;wspd2 = wspd2 * 1.944
;;wspd3 = wspd3 * 1.944
;
;----------------;
;Plot first SkewT;
;----------------;
filename = "skewt_patricia_jordan+dunion+mexican"
wks  = gsn_open_wks ("png",filename)
skewtOpts                 = True
skewtOpts@DrawColAreaFill = False
skewtOpts@DrawFahrenheit  = False
dataOpts           = True
dataOpts@Wthin     = 15        ; plot every n-th wind barb
dataOpts@colTemperature = "blue"
;dataOpts@linePatternTemperature = 2
dataOpts@colDewPt = "white"
wspd1 = wspd1@_FillValue
wspd2 = wspd2@_FillValue
;wspd3 = wspd3@_FillValue
skewt_bkgd = skewT_BackGround (wks,skewtOpts)
print( p1)
print( tc1)
print( tdc1)
print( z1)
print( wspd1)
print( wdir1)
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p1,tc1,tdc1,z1,wspd1,wdir1,dataOpts)
draw(skewt_bkgd)
draw(skewt_data)

;Plot second SkewT
dataOpts@colTemperature = "orange"
dataOpts@linePatternTemperature = 0
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p2,tc2,tdc2,z2,wspd2,wdir2,dataOpts)

;Plot third SkewT
dataOpts@colTemperature = "red"
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p3,tc3,tdc3,z3,wspd3,wdir3,dataOpts)

frame(wks)

system("mv "+filename+".png "+outdir)
