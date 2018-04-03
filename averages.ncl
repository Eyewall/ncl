load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; averages.ncl                                    
; Patrick Duran                                           
; 6/23/2015
;----------------------------------------------------------------;

nrads   = 10
nlevels = 201   ;Number of vertical levels in the dataset
                   ;Corresponds to number of columns in input files
levelstart = 0 ;Vertical level to start on (in hundreds of meters)
levelend   = 200 ; Vertical level to end on (in hundreds of meters)
;inputdir = "/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/rzfiles/"
;outputdir = "/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/avgs/"
inputdir  = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/rzfiles/"
outputdir = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/avgs/"

;First of all, create height array
heights = ispan(levelstart*100,levelend*100,100)

;Get files
stabvals  = systemfunc("ls "+inputdir+"*stab*")
shearvals = systemfunc("ls "+inputdir+"*shear*")

average_stab = new((/nrads,levelend-levelstart+1/),"float")
average_shear = average_stab
average_stab@_FillValue = -9999.
average_shear@_FillValue = -9999.
;Loop through radii (input files)
do i=0,nrads-1
   unixi = i + 1
   print("Radial bin "+unixi+" of "+nrads)
   ;These two arrays are [nsondes]x[nlevels]
   brcharray_stab  = readAsciiTable(stabvals(i),nlevels,"float",5)
   brcharray_shear  = readAsciiTable(shearvals(i),nlevels,"float",5)
   brcharray_stab@_FillValue = -9999.
   brcharray_shear@_FillValue = -9999.
   ;Loop through levels
   do j=levelstart,levelend
      thislevel_stab = brcharray_stab(:,j)
      thislevel_shear = brcharray_shear(:,j)
      asciiwrite("stab.tmp",thislevel_stab)
      asciiwrite("shear.tmp",thislevel_shear)
      if(.not.all(ismissing(thislevel_stab)))then
         average_stab(i,j-levelstart) = avg(thislevel_stab)
      end if
      if(.not.all(ismissing(thislevel_shear)))then
         average_shear(i,j-levelstart) = avg(thislevel_shear)
      end if
      delete([/thislevel_stab,thislevel_shear/])
   end do
   average_brch = average_stab/average_shear

   ;Write averages to output file
   system("echo '   HEIGHT   STAB    SHEAR    BRCH' > header.tmp")
   matrix = new((/nlevels,4/),"float")
   matrix(:,0) = heights
   matrix(:,1) = average_stab(i,:)
   matrix(:,2) = average_shear(i,:)
   matrix(:,3) = average_brch(i,:)
   outfilename = "averages_radbin_"+i
   opt = True
   opt@fout = "matrix.tmp"
   write_matrix(matrix,"f9.0,f9.2,f9.2,f9.2",opt)
   system("cat header.tmp matrix.tmp > "+outputdir+outfilename)
   delete([/brcharray_stab,brcharray_shear,average_brch,matrix/])
end do
system("\rm header.tmp matrix.tmp")
