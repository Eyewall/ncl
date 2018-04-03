load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_4col.ncl"
;**************************************************

;--------;
;Get data;
;--------;
dropfile = "raw_sounding_thermo.txt"
nrows = stringtoint(systemfunc("cat "+dropfile+" | wc | awk '{print $1}'"))
ncols = 4

DropData  = asciiread(dropfile,(/nrows,ncols/),"float")
p   = DropData(:,0)
tc  = DropData(:,1)
tdc = DropData(:,2)
z   = DropData(:,3)
u = new(dimsizes(z),"float")
v = new(dimsizes(z),"float")
u   = 0
v   = 0
p@_FillValue = -999.
tc@_FillValue = -999.
tdc@_FillValue = -999.
z@_FillValue = -999.

;-----------;
;Create plot;
;-----------;
wks = gsn_open_wks("png","rawskewt")
skewtOpts                 = True
skewtOpts@DrawColAreaFill = False    ; default is False
skewtOpts@tiMainString    = "RAW SKEWT"
skewtOpts@DrawFahrenheit  = False   ; default is True

dataOpts           = True     ; options describing data and ploting
dataOpts@Wthin     = 2        ; plot every n-th wind barb
skewt_bkgd = skewT_BackGround (wks, skewtOpts)
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p,tc,tdc,z,u,v,dataOpts)
draw (skewt_bkgd)
draw (skewt_data)
frame(wks)

;--------------------;
;Delete old variables;
;--------------------;
delete(DropData)
delete(p)
delete(tc)
delete(tdc)
delete(z)
delete(u)
delete(v)
