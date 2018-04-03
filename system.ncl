; skewt_netcdf.ncl

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "skewt_func_netcdf.ncl"
;Get list of files and their number
diri = "/jm13/pduran/sandy/drops/netcdf/"
FileList = systemfunc("ls " + diri + "*.nc")
nfiles = (dimsizes(FileList))

;Loop through all the files
do i=0,nfiles-1
   ;Get global attributes
   f = addfile(FileList(i),"r")    ;Get dropsonde file
   date = (f@Launch_Date)          ;Drop date
   time = (f@Launch_Time)          ;Drop time
   id   = (f@SondeID)              ;Dropsonde ID
   acft = (f@Aircraft_Information) ;Aircraft
   comm = (f@Comments)             ;Comments

   ;Get data for SkewT plotting
   pres = f->pres       ;Pressure (mb)
   temp = f->temp       ;Temperature (C)
   relh = f->relh       ;Relative Humidity (%)
   hght = f->hght       ;GPS Altitude of dropsonde (m)
   wdir = f->wdir       ;Wind direction (deg)
   wspd = f->wspd       ;Wind speed (m/s)
   dlat = f->aclat      ;Drop latitude (deg)
   dlon = f->aclon      ;Drop longitude (deg)

   ;Calculate dew point temperature using Magnus-Teten formulation
   a=17.27 
   b=237.7
   alpha = log(relh*.01)+(a*temp/(b+temp))
   dwpt = b*alpha/(a-alpha)
   print(dwpt)

   ;Create plot
;   wks  = gsn_open_wks ("png", date"_"+time)
   wks = gsn_open_wks ("png", time)

; --- Create background skew-T and plot sounding----------------

  skewtOpts                 = True
  skewtOpts@DrawColAreaFill = False
  skewtOpts@tiMainString    = time
;  skewtOpts@tiMainString    = "DATE/TIME: "+date; "/"+time"      DROP ID: "+id 
  skewtOpts@DrawFahrenheit  = False

  dataOpts           = True     ; options describing data and plotting
  dataOpts@Wthin     = 60        ; plot every n-th wind barb
  skewt_bkgd = skewT_BackGround (wks, skewtOpts)
  skewt_data = skewT_PlotData   (wks, skewt_bkgd, pres,temp,dwpt,hght \
                                    ,wspd,wdir,dataOpts)
  draw (skewt_bkgd)
  draw (skewt_data)
  frame(wks)

end do
