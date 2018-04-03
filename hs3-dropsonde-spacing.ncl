load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/nfs/jm13/pduran/ncl/functions/meteo.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
;----------------------------------------------------------------;
; hs3-dropsonde-spacing.ncl                                    
; Patrick Duran                                           
; 18 May 2017
; Determines the spacing of HS3 dropsondes for a given year and
; research flight number (rf##)
;----------------------------------------------------------------;

year     = "2014"
rfnum    = "rf10"
sondedir = "/nfs/jm13/pduran/dropsondes/hs3/eol/"+year+"/"+rfnum+"/"
prefix   = "D"
suffix   = "_P.QC.eol"

;Get input files
infiles = systemfunc("ls "+sondedir+prefix+"*"+suffix)
nfiles  = dimsizes(infiles)

;Get drop locations
droplats = new(nfiles,"float")
droplons = new(nfiles,"float")
print(infiles)
do i=0,nfiles-1
   unixi = i+1
   print("Processing sonde "+unixi+" of "+nfiles)
   eolfile = infiles(i)
   droplats(i) = stringtofloat(systemfunc("grep Location "+eolfile+" | awk '{print $9}' | sed 's/,//g'"))
   droplons(i) = stringtofloat(systemfunc("grep Location "+eolfile+" | awk '{print $6}' | sed 's/,//g'"))
end do

;Compute drop spacing
spacings = new(nfiles-1,"float")
do i=0,nfiles-2
   spacings(i) = gc_latlon(droplats(i),droplons(i),droplats(i+1),droplons(i+1),2,4)
end do
minspacing = min(spacings)
maxspacing = max(spacings)
avgspacing = avg(spacings)
medspacing = dim_median(spacings)
;print( spacings)
qsort(spacings)
sorted = spacings
print( sorted)
print( minspacing)
print( maxspacing)
print( avgspacing)
print( medspacing)
