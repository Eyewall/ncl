load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; brch_percentiles.ncl                                    
; Patrick Duran                                           
; 6/15/2015
; This script reads the output files created by pull_brch_stab_shear.ncl
; and calculates percentiles of BRCH, STAB, and SHEAR, at each
; (r,z) point.
;----------------------------------------------------------------;

nrads   = 9
nlevels = 201   ;Number of vertical levels in the dataset
                   ;Corresponds to number of columns in input files
P = (/5,10,90,95/)*1.0 ;Percentile(s) to calculate
inputdir = "/jm13/pduran/unix_scripts_and_c++/2014/allsondes_overlap/rzfiles/"
outputdir = "/jm13/pduran/unix_scripts_and_c++/2014/allsondes_overlap/percentiles/"

;Get files
brchfiles = systemfunc("ls "+inputdir+"*brch*")
stabfiles = systemfunc("ls "+inputdir+"*stab*")
shearfiles = systemfunc("ls "+inputdir+"*shear*")

;Declare percentile arrays
brch_percentiles = new((/dimsizes(P),nlevels,nrads/),"float")
brch_percentiles@_FillValue = -9999.
stab_percentiles = brch_percentiles
shear_percentiles = brch_percentiles

;Loop through files
do i=0,nrads-1
   unixi = i + 1
   ;Each of these three arrays are [nsondes]x[nlevels]
   brcharray  = readAsciiTable(brchfiles(i),nlevels,"float",5)
   stabarray  = readAsciiTable(stabfiles(i),nlevels,"float",5)
   sheararray = readAsciiTable(shearfiles(i),nlevels,"float",5)
   brcharray@_FillValue = -9999.
   stabarray@_FillValue = -9999.
   sheararray@_FillValue = -9999.

   ;Calculate percentile for each vertical level
   nobs_brch  = new(nlevels,"integer")
   nobs_stab  = new(nlevels,"integer")
   nobs_shear = new(nlevels,"integer")
   do j=0,nlevels-1
      unixj = j + 1
      system("echo Vertical level "+unixj+" of "+nlevels+" in radial bin "+unixi+" of "+nrads+"'  '`date`")
      brchvals  = brcharray(:,j)
      stabvals  = stabarray(:,j)
      shearvals = sheararray(:,j)
      do k=0,dimsizes(P)-1   ;Loop through each percentile desired
         qsort(brchvals)
         qsort(stabvals)
         qsort(shearvals)
         if(all(ismissing(brchvals)))then
            brch_percentiles(k,j,i) = brcharray@_FillValue
            stab_percentiles(k,j,i) = stabarray@_FillValue
            shear_percentiles(k,j,i) = sheararray@_FillValue
            nobs_brch(j) = 0
            nobs_stab(j) = 0
            nobs_shear(j) = 0
         else
            num_nonmissing_brch  = dimsizes(ind(.not.ismissing(brchvals)))
            num_nonmissing_stab  = dimsizes(ind(.not.ismissing(stabvals)))
            num_nonmissing_shear = dimsizes(ind(.not.ismissing(shearvals)))

            nobs_brch(j) = num_nonmissing_brch
            nobs_stab(j) = num_nonmissing_stab
            nobs_shear(j) = num_nonmissing_shear

            nonmissing_brch = brchvals((dimsizes(brchvals)-num_nonmissing_brch):) 
            nonmissing_stab = stabvals((dimsizes(stabvals)-num_nonmissing_stab):)
            nonmissing_shear = shearvals((dimsizes(shearvals)-num_nonmissing_shear):)

            ;Calculate ranks
            n_brch  = P(k)/100*(num_nonmissing_brch*1.0)
            n_stab  = P(k)/100*(num_nonmissing_stab*1.0)
            n_shear = P(k)/100*(num_nonmissing_shear*1.0)

            ;Split rank into its integer and decimal components
            n_brch_int = toint(floor(n_brch))
            n_brch_dec = n_brch - n_brch_int 
            n_stab_int = toint(floor(n_stab))
            n_brch_dec = n_stab - n_stab_int
            n_shear_int = toint(floor(n_shear))
            n_brch_dec = n_shear - n_shear_int

            ;Now determine the percentiles
            if(n_brch_int.eq.0)then
               brch_percentiles(k,j,i) = nonmissing_brch(0)
            else if(n_brch_int.ge.num_nonmissing_brch)then
               brch_percentiles(k,j,i) = nonmissing_brch(dimsizes(nonmissing_brch)-1)
            else if(n_brch_int.gt.0.and.n_brch_int.lt.num_nonmissing_brch)then
               thispercentile_int = nonmissing_brch(n_brch_int)
               thispercentile_dec = nonmissing_brch(n_brch_int+1) - thispercentile_int\
                                       -floor(nonmissing_brch(n_brch_int+1) - thispercentile_int)
               brch_percentiles(k,j,i) = thispercentile_int + thispercentile_dec
            end if
            end if
            end if

            if(n_stab_int.eq.0)then
               stab_percentiles(k,j,i) = nonmissing_stab(0)
            else if(n_stab_int.ge.num_nonmissing_stab)then
               stab_percentiles(k,j,i) = nonmissing_stab(dimsizes(nonmissing_stab)-1)
            else if(n_stab_int.gt.0.and.n_stab_int.lt.num_nonmissing_stab)then
               thispercentile_int = nonmissing_stab(n_stab_int)
               thispercentile_dec = nonmissing_stab(n_stab_int+1) - thispercentile_int\
                                       -floor(nonmissing_stab(n_stab_int+1) - thispercentile_int)
               stab_percentiles(k,j,i) = thispercentile_int + thispercentile_dec
            end if
            end if
            end if

            if(n_shear_int.eq.0)then
               shear_percentiles(k,j,i) = nonmissing_shear(0)
            else if(n_shear_int.ge.num_nonmissing_shear)then
               shear_percentiles(k,j,i) = nonmissing_shear(dimsizes(nonmissing_shear)-1)
            else if(n_shear_int.gt.0.and.n_shear_int.lt.num_nonmissing_shear)then
               thispercentile_int = nonmissing_shear(n_shear_int)
               thispercentile_dec = nonmissing_shear(n_shear_int+1) - thispercentile_int\
                                       -floor(nonmissing_shear(n_shear_int+1) - thispercentile_int)
               shear_percentiles(k,j,i) = thispercentile_int + thispercentile_dec
            end if
            end if
            end if
         delete([/nonmissing_brch,nonmissing_stab,nonmissing_shear/])
         end if    ;If statement to check whether all values are missing      
      end do    ;Percentile loop
      delete([/brchvals,stabvals,shearvals/])
   end do    ;Vertical levels loop

   ;Write to output files
   filename_brch  = outputdir+"brch_percentiles_radbin_"+i+".txt"
   filename_stab  = outputdir+"stab_percentiles_radbin_"+i+".txt"
   filename_shear = outputdir+"shear_percentiles_radbin_"+i+".txt"   
   hghts = ispan(0,(nlevels-1)*100,100)
   head = [/(/" HGHT  5th %ile  10th %ile  90th %ile  95th %ile"/)/]
   brch_data = [/hghts,brch_percentiles(0,:,i),brch_percentiles(1,:,i),brch_percentiles(2,:,i),\
                 brch_percentiles(3,:,i),nobs_brch/]
   stab_data = [/hghts,stab_percentiles(0,:,i),stab_percentiles(1,:,i),stab_percentiles(2,:,i),\
                 stab_percentiles(3,:,i),nobs_stab/]
   shear_data = [/hghts,shear_percentiles(0,:,i),shear_percentiles(1,:,i),shear_percentiles(2,:,i),\
                 shear_percentiles(3,:,i),nobs_shear/]
   write_table(filename_brch,"w",head,"%s")
   write_table(filename_brch,"a",brch_data,"%5.1i%9.1f%9.1f%9.1f%9.1f%9.0f")
   write_table(filename_stab,"w",head,"%s")
   write_table(filename_stab,"a",stab_data,"%5.1i%9.1f%9.1f%9.1f%9.1f%9.0f")
   write_table(filename_shear,"w",head,"%s")
   write_table(filename_shear,"a",shear_data,"%5.1i%9.1f%9.1f%9.1f%9.1f%9.0f")
   delete([/brcharray,stabarray,sheararray/])
end do    ;Radial bin loop
