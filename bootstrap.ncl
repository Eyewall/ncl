load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------;
; bootstrap.ncl                                    
; Patrick Duran                                           
; 6/23/2015
; Dependencies: randomnumber.cpp
; Differencing convention here is 2-1 (i.e. infile2-infile1)
;----------------------------------------------------------------;

var = "brch"
intordiurnal = "intensity" ;Is this an intensity or a diurnal plot?
nrads   = 10        ;Number of radial bins in the dataset
nlevels = 201      ;Number of vertical levels in the dataset
levelstart = 80    ;Vertical level to start on (in hundreds of meters)
levelend   = 180   ;Vertical level to end on (in hundreds of meters)
ndists     = 10000 ;Number of random distributions to draw
nsmth      = 10    ;Number of times to apply 1-2-1 smoother in the vertical
avg_infile_dir1 = "/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/avgs/"
obs_infile_dir1 = "/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/rzfiles/"
avg_infile_dir2 = "/jm13/pduran/unix_scripts_and_c++/2014/ts+td/2015/avgs/"
obs_infile_dir2 = "/jm13/pduran/unix_scripts_and_c++/2014/ts+td/2015/rzfiles/"

avg_infiles1 = systemfunc("ls "+avg_infile_dir1)
obs_infiles1 = systemfunc("ls "+obs_infile_dir1)
avg_infiles2 = systemfunc("ls "+avg_infile_dir2)
obs_infiles2 = systemfunc("ls "+obs_infile_dir2)
do rad=0,nrads-1
   unixrad = rad + 1
   avg_infile1 = avg_infiles1(rad)
   avg_infile2 = avg_infiles2(rad)
   obs_infile1 = obs_infiles1(rad)
   obs_infile2 = obs_infiles2(rad)
   
   ;Create height array
   heights = ispan(levelstart*100,levelend*100,100)
   nheights = dimsizes(heights)

   ;Create output array   
   output_array = new((/nheights,5/),"float")
   output_array(:,0) = heights

   ;Read input files
   avg_input1 = readAsciiTable(avg_infile_dir1+avg_infile1,4,"float",1)
   avg_input2 = readAsciiTable(avg_infile_dir2+avg_infile2,4,"float",1)
   obs_input1 = readAsciiTable(obs_infile_dir1+obs_infile1,nlevels,"float",5)
   obs_input2 = readAsciiTable(obs_infile_dir2+obs_infile2,nlevels,"float",5)

   ;--------------------------------------------------------;
   ;GET AZIMUTHAL AVERAGES FOR EACH LEVEL OF THIS RADIAL BIN;
   ;--------------------------------------------------------;
   if(var.eq."stab")then
      varavg1 = avg_input1(levelstart:levelend,1)
      varavg2 = avg_input2(levelstart:levelend,1)
   else if(var.eq."shear")then
      varavg1 = avg_input1(levelstart:levelend,2)
      varavg2 = avg_input2(levelstart:levelend:,2)
   else if(var.eq."brch")then
      varavg1 = avg_input1(levelstart:levelend,3)
      varavg2 = avg_input2(levelstart:levelend,3)
   end if
   end if
   end if
   ;Compute observed differences between the averages at each level
   obs_avg_diff = varavg2 - varavg1
   output_array(:,1) = obs_avg_diff

   do i=0,nheights-1
      unixi = i + 1
      system("echo 'Rad Bin '"+unixrad+"' of '"+nrads+"'   Level '"+unixi+" of "+nheights+"'   '`date`")

      ;------------------------------------------------------------------;
      ;GET ALL OBSERVATIONS FOR THIS RADIAL BIN AND PRINT TO OUTPUT FILES;
      ;------------------------------------------------------------------;
      obs_vals1 = obs_input1(:,i+levelstart)
      obs_vals2 = obs_input2(:,i+levelstart)
      nvals1 = dimsizes(obs_vals1)
      nvals2 = dimsizes(obs_vals2)
      ;Pool the two distributions for random selection
      obs_vals_pooled = array_append_record(obs_vals1,obs_vals2,0)
      obs_vals_pooled@_FillValue = -9999.
      nvals_pooled = nvals1+nvals2

      ;-------------------------------------------------;
      ;CALL C++ PROGRAM TO GENERATE RANDOM DISTRIBUTIONS;
      ;-------------------------------------------------;
      print("Generating random distributions...")
      system("/jm13/pduran/unix_scripts_and_c++/randomnumber.out "+ndists+" "+nvals1+" 0 "+nvals_pooled+" rand1.txt")
      system("/jm13/pduran/unix_scripts_and_c++/randomnumber.out "+ndists+" "+nvals2+" 0 "+nvals_pooled+" rand2.txt")

      ;------------------------------------------------------------;
      ;LOOP THROUGH ALL RANDOM DISTRIBUTIONS AND COMPUTE STATISTICS;
      ;------------------------------------------------------------;
      rand_dist_inds1 = asciiread("rand1.txt",(/ndists,nvals1/),"integer")
      rand_dist_inds2 = asciiread("rand2.txt",(/ndists,nvals2/),"integer")
      rand_dist_vals1 = new((/ndists,nvals1/),"float",-9999)
      rand_dist_vals2 = new((/ndists,nvals2/),"float",-9999)
      rand_dist_avgs1 = new(ndists,"float",-9999)
      rand_dist_avgs2 = new(ndists,"float",-9999)
      print( "Computing statistics...")
      do j=0,ndists-1
         unixj = j + 1
         do k=0,nvals1-1
            rand_dist_vals1(j,k) = obs_vals_pooled(rand_dist_inds1(j,k))
         end do
         do k=0,nvals2-1
            rand_dist_vals2(j,k) = obs_vals_pooled(rand_dist_inds2(j,k))
         end do
         rand_dist_avgs1(j) = avg(rand_dist_vals1(j,:))
         rand_dist_avgs2(j) = avg(rand_dist_vals2(j,:)) 
      end do
      rand_diffs = rand_dist_avgs2 - rand_dist_avgs1
   
      ;Average of the differences of the averages...Should be near zero
      avg_rand_diffs = avg(rand_diffs)
   
      ;Percentiles
      p_array = (/0.5,2.5,5,95,97.5,99.5/)*1.0 
      percentiles = new(dimsizes(p_array),"float")
      qsort(rand_diffs)
      do l=0,dimsizes(p_array)-1
         n = p_array(l)/100*dimsizes(rand_diffs) ;Calculate rank
         n_int = floor(n)                 ;Integer component of the rank
         n_dec = n - n_int                ;Decimal component of the rank
         percentile_int = rand_diffs(toint(n_int))
         percentile_dec = rand_diffs(toint(n_int)+1) - percentile_int
         percentiles(l) = percentile_int + percentile_dec
      end do
     
      system("echo '     Observed difference of averages: '"+obs_avg_diff(i))
      system("echo '     0.5th Percentile: '"+percentiles(0))
      system("echo '     2.5th Percentile: '"+percentiles(1))
      system("echo '     5th Percentile: '"+percentiles(2))
      system("echo '     95th Percentile: '"+percentiles(3))
      system("echo '     97th Percentile: '"+percentiles(4))
      system("echo '     99.5th Percentile: '"+percentiles(5))

      ;Determine significance
      issignificant = new(dimsizes(p_array)/2,"integer")
      issignificant = 0  ;Assume null hypothesis; 0=No sig. diff; 1=Sig. Diff
      ;99% confidence interval
      if(obs_avg_diff(i).lt.percentiles(0).or.obs_avg_diff(i).gt.percentiles(5))then
         issignificant = 1 ;If 99th percentile is met, then so are 90th and 95th
      end if
      ;95% confidence interval
      if(obs_avg_diff(i).lt.percentiles(1).or.obs_avg_diff(i).gt.percentiles(4))then
         issignificant(1:2) = 1 ;If 95th percentile is met, then so is 90th
      end if
      ;90% confidence interval
      if(obs_avg_diff(i).lt.percentiles(2).or.obs_avg_diff(i).gt.percentiles(5))then
         issignificant(2) = 1
      end if
      delete([/obs_vals1,obs_vals2,obs_vals_pooled,rand_dist_inds1,rand_dist_inds2,\
               rand_dist_vals1,rand_dist_vals2/])

      ;Write the rest of the applicable info to the output array for this level
      output_array(i,2) = issignificant(2)
      output_array(i,3) = issignificant(1)
      output_array(i,4) = issignificant(0)
   end do
   output_list = [/output_array(:,0),output_array(:,1),output_array(:,2),\
                   output_array(:,3),output_array(:,4)/]
   outfilename = var+"_avgs_"+intordiurnal+"_radbin_"+rad+".txt"
   header  = [/(/" HEIGHT    OBS. DIFF. OF AVGS.  SIG 90%?  SIG 95%?  SIG 99%?"/)/]
   header2 = [/(/" ------    -------------------  --------  --------  --------"/)/]
   write_table(outfilename,"w",header,"%s")
   write_table(outfilename,"a",header2,"%s")
   write_table(outfilename,"a",output_list,"%5.1f%12.2f%14.1f%9.1f%9.1f")
   delete([/obs_input1,obs_input2/])
end do
