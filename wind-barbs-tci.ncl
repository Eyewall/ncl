load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/nfs/jm13/pduran/ncl/functions/meteo.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
;----------------------------------------------------------------;
; wind-barbs-tci.ncl                                    
; Patrick Duran                                           
; 216 November 2016
; Pulls data from .edit files and plots wind barbs at
; user-defined height levels.
;----------------------------------------------------------------;

storm    = "patricia"
date     = "20151022"
transect = "transect1"
dz       = 100    ;Spacing of input grid (m)
maxhght  = 20000  ;Maximum height to plot (m)
minhght  = 0      ;Minimum height to plot (m)
dzplot   = 1000   ;Height spacing of plots (m)
sondedir = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/storm-relative/"
listfile = "/nfs/jm13/pduran/dropsondes/onr/finalqc/edit/"+date+"/storm-relative/"+transect
prefix   = "A"
suffix   = "-WB57_TCI-100m-noEC-mfx500-sm0x-loc.edit-srel"
outdir   = "/jm13/pduran/web/tci/planviews/"+storm+"/"+date+"/"+transect+"/"
driftopt = 0      ;0 = All wind barbs plotted at the dropsonde deployment location
                  ;1 = Accounts for sonde drift
ninput  = (maxhght-minhght)/dz+1
nlevels = (maxhght-minhght)/dzplot+1

system("mkdir "+outdir)

infiles = sondedir+systemfunc("cat "+listfile)
nfiles  = dimsizes(infiles)

droplats = new(nfiles,"float")
droplons = new(nfiles,"float")
u        = new((/nfiles,ninput/),"float")
v        = new((/nfiles,ninput/),"float")
hght     = new((/nfiles,ninput/),"float")
lat      = new((/nfiles,ninput/),"float")
lon      = new((/nfiles,ninput/),"float")
u@_FillValue    = -9999.0
v@_FillValue    = -9999.0
hght@_FillValue = -9999.0
lat@_FillValue  = -9999.0
lon@_FillValue  = -9999.0

print(infiles)
do i=0,nfiles-1
   unixi = i+1
   print("Reading sonde "+unixi+" of "+nfiles)
   ;Read input file and assign variables
   data := readAsciiTable(infiles(i),10,"float",7)
   data@_FillValue = -9999.0
   nhghts = dimsizes(data(:,5))
   u   (i,:nhghts-1) = data(:,3)
   v   (i,:nhghts-1) = data(:,4)
   hght(i,:nhghts-1) = data(:,5)
   lat (i,:nhghts-1) = data(:,7)
   lon (i,:nhghts-1) = data(:,8)

   droplats(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $3}' "))
   nfields = stringtoint(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print NF}'"))
   if(nfields.eq.9)then
      droplons(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $5}' | sed 's/=//'"))
   else
      droplons(i) = stringtofloat(systemfunc("sed -n 5p "+infiles(i)+" | awk '{print $6}'"))
   end if
end do
u := transpose(u)
v := transpose(v)
printVarSummary(u)
levs = fspan(minhght,maxhght,nlevels)
do j=0,nlevels-1
   ;Set filename and create workstation
   if(driftopt.eq.0)then
      filename = outdir+"windbarbs_nodrift_"+levs(j)+"m"
   else if(driftopt.eq.1)then
      filename = outdir+"windbarbs_drift_"+levs(j)+"m"
   end if
   end if
   unixj = j+1
   print("Plotting image "+unixj+" of "+nlevels+" Outfile: "+filename)
   hghtind = toint(levs(j)/dz)
   wks = gsn_open_wks("png",filename)
   res = True
   res@tiMainString   = str_capital(storm)+"  "+date+"  "+transect+"  Storm relative wind barbs"
   res@tiMainFontHeightF = 0.013
   res@vcRefMagnitudeF = 10.
   res@vcRefLengthF    = 0.05
   res@vcMinDistanceF  = .05   ;Thin the barbs
   res@vcGlyphStyle    = "WindBarb"
   res@gsnMaximize     = True
   plot = gsn_vector(wks,u,v,res)
end do
