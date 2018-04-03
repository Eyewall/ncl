load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"

;----------------------------------------------------------------;
; composite-on-unstable-layer.ncl                                    
; Patrick Duran                                           
; 7/1/2015
; Called by: NONE
; Dependencies: NONE
;----------------------------------------------------------------;

intordiurnal = "diurnal"
opts = (/"12z","00z"/)
;opt = "ts+td"
;if(intordiurnal.eq."diurnal")then
;   idlist = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/"+opt+"/200kmbins/overlap/allsondes_"+opt+"_100-300km"
;else
;   idlist = "/jm13/pduran/unix_scripts_and_c++/2014/"+opt+"/200kmbins/overlap/"+opt+"_100-300.idlist"
;end if
dropdir = "/jm13/pduran/rawinsondes/allsondes_brch/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"
compositelevel = 13000 ;Vertical level on which to search for unstable layer (meters)
radbin = "100-300km"
outdir = "/jm13/pduran/web/"
;outfile = "low_rb_sonde_list_14km.txt"


;UNCOMMENT IF NEED TO RUN FOR A DIFFERENT LEVEL...IF NOT, NO NEED TO TAKE TIME
;TO FIND ALL OF THE FILES YET AGAIN
;if(intordiurnal.eq."diurnal")then
;   ids     = systemfunc("awk '{print($1)}' "+idlist+" | colrm 1 2")
;   dattims = systemfunc("awk '{print($3)}' "+idlist)
;else
;   ids     = systemfunc("awk '{print($2)}' "+idlist)
;   dattims = systemfunc("awk '{print($4)}' "+idlist)
;end if
;
;system("\rm "+outfile)
;system("touch "+outfile)
;nids = dimsizes(ids)
;do i=0,nids-1
;   unixi = i +1
;   print("Processing file "+unixi+" of "+nids)
;   dropfile = dropdir+ids(i)+"-"+dattims(i)+suffix
;   dropdata = readAsciiTable(dropfile,13,"float",7)
;   heights = dropdata(:,5)
;   brchs   = dropdata(:,10) 
;   levelind = ind(heights.eq.compositelevel)
;   brch = brchs(levelind)
;   if(brch.lt.0.25)then
;      system("echo "+dropfile+" >> "+outfile)
;   end if
;   delete([/dropdata,heights,brchs/])
;end do

averages = new((/2,201,13/),"float",-9999.)
do k=0,1
   opt = opts(k)
   if(intordiurnal.eq."intensity")then
      filelist = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+opt+"/200kmbins/overlap/low_rb_sonde_list_13km.txt"
   else
      filelist = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/"+opt+"/200kmbins/overlap/low_rb_sonde_list_13km.txt"
   end if
   files = systemfunc("cat "+filelist)
   nfiles = dimsizes(files)
   sounding_data = new((/nfiles,201,13/),"float",-9999.)
   do j=0,nfiles-1
      unixj = j + 1
      print("Processing sonde "+unixj+" of "+nfiles)
      dropfile = files(j)
      thissonde = readAsciiTable(dropfile,13,"float",7)
      thissonde@_FillValue = -9999.
      sounding_data(j,:,:) = thissonde(0:200,:)
      delete(thissonde)
   end do
   averages(k,:,:) = dim_avg_n_Wrap(sounding_data,0)
   delete([/files,sounding_data/])
end do

;Set data for SkewT plots
p1     = averages(0,:,0)
tc1    = averages(0,:,1)
tdc1   = averages(0,:,2)
z1     = averages(0,:,5)
u1     = averages(0,:,3) * 1.94384449
v1     = averages(0,:,4) * 1.94384449
brch1  = averages(0,:,10)
stab1  = averages(0,:,9)
shear1 = averages(0,:,11)

p2     = averages(1,:,0)
tc2    = averages(1,:,1)
tdc2   = averages(1,:,2)
z2     = averages(1,:,5)
u2     = averages(1,:,3) * 1.94384449
v2     = averages(1,:,4) * 1.94384449
brch2  = averages(1,:,10)
stab2  = averages(1,:,9)
shear2 = averages(1,:,11)

;Get pressures of this vertical level
plevel_var1 = p1(ind(z1.eq.compositelevel))
plevel_var2 = p2(ind(z2.eq.compositelevel))
print(plevel_var1)
print(plevel_var2)

;Plot first SkewT
filename = "avg_skewt_"+intordiurnal+"_"+radbin+"_"+compositelevel+"km"
wks = gsn_open_wks("png",filename)
skewtOpts = True
skewtOpts@DrawColAreaFill = False    ; default is False
;skewtOpts@tiMainString    = "DATE/TIME: "+dattim+"      DROP ID: "+dropid
skewtOpts@DrawFahrenheit  = False   ; default is True
dataOpts           = True     ; options describing data and ploting
dataOpts@Wthin     = 2        ; plot every n-th wind barb
skewt_bkgd = skewT_BackGround (wks, skewtOpts)
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p1,tc1,tdc1,z1,u1,v1,dataOpts)
draw (skewt_bkgd)
draw (skewt_data)

;Plot second SkewT
dataOpts@linePatternTemperature = 2
dataOpts@linePatternDewPt = 2
skewt_data = skewT_PlotData   (wks,skewt_bkgd,p2,tc2,tdc2,z2,u2,v2,dataOpts)
frame(wks)
system("mv "+filename+".png "+outdir)
