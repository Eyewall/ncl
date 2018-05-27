load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_hs3_dissertation.ncl"

sondefile1 = "/jm13/pduran/dropsondes/hs3/eol/2012/rf03/D20120914_224108_P.QC.eol"
sondefile2 = "/jm13/pduran/dropsondes/hs3/eol/2012/rf03/D20120914_225650_P.QC.eol"
sondefile3 = "/jm13/pduran/dropsondes/hs3/eol/2012/rf03/D20120914_231355_P.QC.eol" 
;sondefile1  = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151021/QC_20151021-193443-6801.eol"
;sondefile2  = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151022/QC_20151022-182225-8BFC.eol"
;sondefile3  = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151023/QC_20151023-200116-6FCE.eol"

;day = "20151022"
;if(day.eq."20151022")then
;   sondefile1 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151022/QC_20151022-182149-5E66.eol"
;   sondefile2 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151022/QC_20151022-182301-3872.eol"
;   sondefile3 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151022/QC_20151022-182413-366D.eol"
;end if
;if(day.eq."20151023")then
;   sondefile1 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151023/QC_20151023-200238-8BCE.eol"
;   sondefile2 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151023/QC_20151023-200116-6FCE.eol"
;   sondefile3 = "/nfs/jm13/pduran/dropsondes/onr/finalqc/eol/20151023/QC_20151023-200017-C147.eol"
;end if
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

;Convert wind speed to kt
wspd1 = wspd1 * 1.944
wspd2 = wspd2 * 1.944
wspd3 = wspd3 * 1.944

;----------------;
;Plot first SkewT;
;----------------;
filename = "skewt_hs3"
wks  = gsn_open_wks ("png",filename)
skewtOpts                 = True
skewtOpts@DrawColAreaFill = False
skewtOpts@DrawFahrenheit  = False
skewtOpts@tiMainString = "b)"
skewtOpts@tiMainFontHeightF = 0.02
skewtOpts@tiMainOffsetXF = -0.42
dataOpts           = True
dataOpts@Wthin     = 15        ; plot every n-th wind barb
dataOpts@colTemperature = "magenta"
dataOpts@linePatternTemperature = 0
dataOpts@lineThicknessTemperature = 5.
dataOpts@colDewPt = "white"
wspd1 = wspd1@_FillValue
wspd2 = wspd2@_FillValue
wspd3 = wspd3@_FillValue
skewt_bkgd = skewT_BackGround (wks,skewtOpts)
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p1,tc1,tdc1,z1,wspd1,wdir1,dataOpts)
draw(skewt_bkgd)
draw(skewt_data)

;Plot second SkewT
dataOpts@colTemperature = "dark green"
dataOpts@linePatternTemperature = 0
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p2,tc2,tdc2,z2,wspd2,wdir2,dataOpts)

;Plot third SkewT
dataOpts@colTemperature = "blue"
dataOpts@linePatternTemperature = 0
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p3,tc3,tdc3,z3,wspd3,wdir3,dataOpts)

;Add text labels
;if(day.eq."20151022")then
;   text = (/"Sonde 12 (NW Eyewall)","Sonde 14 (Eye)","Sonde 16 (NE Eyewall)"/)
;else if(day.eq."20151023")then
;   text = (/"Sonde 28 (NW Eyewall)","Sonde 32 (Eye)","Sonde 35 (NE Eyewall)"/)
;end if
;end if
;colors = (/"blue","orange","red"/)
;txx    = (/0.2,0.2,0.2/)
;txy    = (/0.16,0.13,0.1/)
;do txi=0,dimsizes(text)-1
;   txres = True
;   txres@txFontColor = colors(txi)
;   txres@txFontHeightF = 0.02
;   txres@txJust = "CenterLeft"
;   gsn_text_ndc(wks,text(txi),txx(txi),txy(txi),txres)
;end do

frame(wks)

system("mv "+filename+".png "+outdir)
