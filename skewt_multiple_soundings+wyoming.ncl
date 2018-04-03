load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_hs3_75mb.ncl"

;sondefile1 = "/jm13/pduran/dropsondes/hs3/2012/D20120914_224108_recomp_P.2QC.eol"
;sondefile2 = "/jm13/pduran/dropsondes/hs3/2012/D20120914_225650_recomp_P.1QC.eol"
;sondefile3 = "/jm13/pduran/dropsondes/hs3/2012/D20120914_231355_recomp_P.2QC.eol" 
sondefile1  = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151021/QC_20151021-193443-6801.eol"
sondefile2  = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151022/QC_20151022-182225-8BFC.eol"
sondefile3  = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151023/QC_20151023-200116-6FCE.eol"
sondefile4  = "/nfs/jm13/pduran/rawinsondes/wyoming/trimmed_sondes/average.txt"
outdir = "/jm13/pduran/web/"

;----------------------------;
;Get data from first dropfile;
;----------------------------;
DropData1 = readAsciiTable(sondefile1,17,"float",14)
p1    = DropData1 (:,4)    ; pressure     [mb] 
tc1   = DropData1 (:,5)    ; temperature  [C]    
tdc1  = DropData1 (:,6)    ; relative humidity [%]
z1    = DropData1 (:,13)    ; geopotential [m] 
wspd1 = DropData1 (:,10)    ; wind speed   [m/s]    
wdir1 = DropData1 (:,11)    ; meteorological wind dir   
lats1 = DropData1 (:,15)   ; latitudes [deg N]
lons1 = DropData1 (:,14)   ; longitudes [deg E]
p1@_FillValue  = -999
tc1@_FillValue = -999
tdc1@_FillValue = -999
z1@_FillValue  = -999
wspd1@_FillValue = -999
wdir1@_FillValue = -999
lats1@_FillValue = -999
lons1@_FillValue = -999

;-----------------------------;
;Get data from second dropfile;
;-----------------------------;
DropData2 = readAsciiTable(sondefile2,17,"float",14)
p2    = DropData2 (:,4)    ; pressure     [mb] 
tc2   = DropData2 (:,5)    ; temperature  [C]    
tdc2  = DropData2 (:,6)    ; relative humidity [%]
z2    = DropData2 (:,13)    ; geopotential [m] 
wspd2 = DropData2 (:,10)    ; wind speed   [m/s]    
wdir2 = DropData2 (:,11)    ; meteorological wind dir   
lats2 = DropData2 (:,15)   ; latitudes [deg N]
lons2 = DropData2 (:,14)   ; longitudes [deg E]
p2@_FillValue  = -999
tc2@_FillValue = -999
tdc2@_FillValue = -999
z2@_FillValue  = -999
wspd2@_FillValue = -999
wdir2@_FillValue = -999
lats2@_FillValue = -999
lons2@_FillValue = -999

;----------------------------;
;Get data from third dropfile;
;----------------------------;
DropData3 = readAsciiTable(sondefile3,17,"float",14)
p3    = DropData3 (:,4)    ; pressure     [mb] 
tc3   = DropData3 (:,5)    ; temperature  [C]    
tdc3  = DropData3 (:,6)    ; relative humidity [%]
z3    = DropData3 (:,13)    ; geopotential [m] 
wspd3 = DropData3 (:,10)    ; wind speed   [m/s]    
wdir3 = DropData3 (:,11)    ; meteorological wind dir   
lats3 = DropData3 (:,15)   ; latitudes [deg N]
lons3 = DropData3 (:,14)   ; longitudes [deg E]
p3@_FillValue  = -999
tc3@_FillValue = -999
tdc3@_FillValue = -999
z3@_FillValue  = -999
wspd3@_FillValue = -999
wdir3@_FillValue = -999
lats3@_FillValue = -999
lons3@_FillValue = -999

;------------------------------;
;Get data from Wyoming dropfile;
;------------------------------;
DropData4 = readAsciiTable(sondefile4,5,"float",0)
DropData4@_FillValue = -9999
z4  = DropData4(:,0)
p4  = DropData4(:,1)
tc4 = DropData4(:,2)
wspd4 = new(dimsizes(z4),"float")
wspd4@_FillValue = -999
wdir4 = wspd4
tdc4  = wspd4
tdc4 = 30

;Convert wind speed to kt
wspd1 = wspd1 * 1.944
wspd2 = wspd2 * 1.944
wspd3 = wspd3 * 1.944

;----------------;
;Plot first SkewT;
;----------------;
filename = "skewt_patricia_3flights"
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
wspd3 = wspd3@_FillValue
skewt_bkgd = skewT_BackGround (wks,skewtOpts)
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

;Plot fourth SkewT
dataOpts@colTemperature = "black"
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p4,tc4,tdc4,z4,wspd4,wdir4,dataOpts)
frame(wks)

system("mv "+filename+".png "+outdir)
