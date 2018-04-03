load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/skewt_func_ivan.ncl"

;----------------------------------------------------------------;
; find_all_sondes_with_unstable_layer.ncl                                    
; Patrick Duran                                           
; 7/28/2015
; Called by: NONE
; Dependencies: NONE
; Will find all sondes that have bulk Richardson number less than
; 0.25 at a user-specified vertical level, as well as all sondes
; that do not have Rb < 0.25 at that level and print to two
; separate output files.
;----------------------------------------------------------------;

opt = 2  ;Set to 0 to use an idlist file; set to 1 to use pre-made files
         ;created by pull_brch_stab_shear.ncl; set to 2 to use pre-made
         ;files and output perturbations from the mean
         ;OPT=0 is generally defunct....
radii = "0-1000"
dropdir = "/jm13/pduran/rawinsondes/allsondes_brch_nomaxbrch/"
suffix = "-RAWIN_6S-BOGFIX-T8C_KM-100m-loc.edit_400m_datv"
outdir = "/jm13/pduran/web/"
bot = 9 ;Bottom and top of layer to search (km)
top = 17

if(opt.eq.0)then   ;OPT EQUAL ZERO; FOR OPT EQUALS 1, SEE BELOW
   idlist = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/biggerbins/allsondes_"+radii+".idlist"
   outfile1_prefix = "low_rb_sonde_list_"+radii+"km"+bot+"-"+top+"km"
   outfile2_prefix = "no_low_rb_sonde_list_"+radii+"km"+bot+"-"+top+"km"

   ;UNCOMMENT IF NEED TO RUN FOR A DIFFERENT LAYER...IF NOT, NO NEED TO TAKE TIME
   ;TO FIND ALL OF THE FILES YET AGAIN
   ids     = systemfunc("awk '{print($2)}' "+idlist)
   dattims = systemfunc("awk '{print($4)}' "+idlist)
   
   system("\rm "+outfile1+" "+outfile2)
   system("touch "+outfile1+" "+outfile2)
   nids = dimsizes(ids)
   do i=0,nids-1
      unixi = i +1
      print("Processing file "+unixi+" of "+nids)
      dropfile = dropdir+ids(i)+"-"+dattims(i)+suffix
      if(.not.ismissing(systemfunc("ls "+dropfile)).and.stringtoint(systemfunc("wc "+dropfile+" | awk '{print($1)}'")).gt.100)then
         dropdata = readAsciiTable(dropfile,13,"float",7)
         heights = dropdata(:,5)
         brchs   = dropdata(:,10) 
         levelind = ind(heights.eq.compositelevel*1000)
         brch = brchs(levelind)
         if(brch.lt.0.25)then
            system("echo "+dropfile+" >> "+outfile1)
         else
            system("echo "+dropfile+" >> "+outfile2)
         end if
         delete([/dropdata,heights,brchs/])
      end if
   end do
   
   averages = new((/2,201,13/),"float",-9999.)
   do k=0,1
      if(k.eq.0)then
         filelist = outfile1
      else
         filelist = outfile2
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
   
   ;Set data for SkewT and stabshear plots
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
   plevel_var1 = p1(ind(z1.eq.compositelevel*1000))
   plevel_var2 = p2(ind(z2.eq.compositelevel*1000))
   print(plevel_var1)
   print(plevel_var2)
   
   ;Plot first SkewT
   filename = "avg_skewt_"+radii+"km_"+compositelevel+"km"
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
   
   ;Plot and overlay second SkewT
   dataOpts@linePatternTemperature = 2
   dataOpts@linePatternDewPt = 2
   skewt_data = skewT_PlotData   (wks,skewt_bkgd,p2,tc2,tdc2,z2,u2,v2,dataOpts)
   frame(wks)
   system("mv "+filename+".png "+outdir)
   
   ;Plot stabshear
   hght = z1 / 1000
   data = new((/4,201/),float)
   data@_FillValue = -9999.
   data(0,:) = stab1   ;Stability from file1
   data(1,:) = shear1  ;Shear from file1
   data(2,:) = stab2   ;Stability from file2
   data(3,:) = shear2  ;Shear from file2
   
   filename2 = "avg_stabshear_"+radii+"km_"+compositelevel+"km"
   wks = gsn_open_wks("png",filename2)
   res = True
   res@tiXAxisString = "Shear and Stability Terms"
   res@tiYAxisString = "Height [km]"
   res@xyLineColors = (/"red","blue","red","blue"/)
   res@xyLineThicknesses = (/3,3,3,3/)
   res@xyDashPatterns = (/0,0,1,1/)
   res@tmYROn = False
   res@tmXTOn = False
   res@gsnMaximize = True
   
   ;----------------------------;
   ;Set x and y axis min and max;
   ;----------------------------;
   res@trXMinF = 0.
   res@trXMaxF = 3.
   res@trYMinF = 9.
   res@trYMaxF = 17.
   
   plot2 = gsn_csm_xy(wks,data,hght,res)
   system("mv "+filename2+".png "+outdir)

;-------------------------;
;OPT=1 - OUTPUT RAW VALUES;
;-------------------------;
else if(opt.eq.1)then
   infile_brch  = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/rzfiles/allhurricanes_"+radii+".idlist_brch.txt"
   infile_stab  = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/rzfiles/allhurricanes_"+radii+".idlist_stab.txt"
   infile_shear = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/allhurricanes/2015/rzfiles/allhurricanes_"+radii+".idlist_shear.txt"
   outfile1_prefix = "low_rb_sonde_list_"+radii+"km"+bot+"-"+top+"km"
   outfile2_prefix = "no_low_rb_sonde_list_"+radii+"km"+bot+"-"+top+"km"
   
   brchs  = readAsciiTable(infile_brch,201,"float",5) 
   stabs  = readAsciiTable(infile_stab,201,"float",5) 
   shears = readAsciiTable(infile_shear,201,"float",5)

   brchs@_FillValue = -9999.
   stabs@_FillValue = -9999.
   shears@_FillValue = -9999.
   brchs  = where(brchs.eq.-999,-9999,brchs)
   stabs  = where(stabs.eq.-999,-9999,stabs)
   shears = where(shears.eq.-999,-9999,shears)

   brch_sub_1d  = ndtooned(brchs(:,bot*10:top*10))
   stab_sub_1d  = ndtooned(stabs(:,bot*10:top*10))
   shear_sub_1d = ndtooned(shears(:,bot*10:top*10))

   ;Find where brch < 0.25 and where brch >= 0.25 and get stab and shear values
   stab_lt = stab_sub_1d(ind(brch_sub_1d.lt.0.25))
   shear_lt = shear_sub_1d(ind(brch_sub_1d.lt.0.25))
   stab_ge = stab_sub_1d(ind(brch_sub_1d.ge.0.25))
   shear_ge = shear_sub_1d(ind(brch_sub_1d.ge.0.25))

   asciiwrite(outfile1_prefix+"_stab.txt",stab_lt)
   asciiwrite(outfile1_prefix+"_shear.txt",shear_lt)
   asciiwrite(outfile2_prefix+"_stab.txt",stab_ge)
   asciiwrite(outfile2_prefix+"_shear.txt",shear_ge)

;---------------------------;
;OPT=2 - OUPUT PERTURBATIONS;
;---------------------------;
else if(opt.eq.2)then
   intordiurnal = "ts+td"
   if(intordiurnal.eq."allhurricanes".or.intordiurnal.eq."ts+td")then
      avgfilesdir = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/avgs/"
      rawfilesdir = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/"+intordiurnal+"/2015/rzfiles/"
      suffix = ".idlist"
   else if(intordiurnal.eq."00z".or.intordiurnal.eq."12z")then
      avgfilesdir = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/"+intordiurnal+"/2015/avgs/"
      rawfilesdir = "/nfs/jm13/pduran/unix_scripts_and_c++/2014/diurnal/"+intordiurnal+"/2015/rzfiles/"
      suffix = "km"
   else
      print("Invalid intordiurnal selection...Exiting.")
      exit
   end if
   end if
   radii_split = str_split(radii,"-")
   innerrad_index = stringtoint(radii_split(0))/100
   outerrad_index = stringtoint(radii_split(1))/100
   nfiles = outerrad_index-innerrad_index
   do l=0,nfiles-1
      unixl = l + 1
      print("Processing file "+unixl+" of "+nfiles)
      innerrad = l*100
      outerrad = (l+1)*100 

      infile_avg = avgfilesdir+"averages_radbin_"+l
      infile_brch  = rawfilesdir+intordiurnal+"_"+innerrad+"-"+outerrad+suffix+"_brch_radbin"+l+".txt"
      infile_stab  = rawfilesdir+intordiurnal+"_"+innerrad+"-"+outerrad+suffix+"_stab_radbin"+l+".txt"
      infile_shear = rawfilesdir+intordiurnal+"_"+innerrad+"-"+outerrad+suffix+"_shear_radbin"+l+".txt"

      avgs   = readAsciiTable(infile_avg,4,"float",1)
      brchs  = readAsciiTable(infile_brch,201,"float",5) 
      stabs  = readAsciiTable(infile_stab,201,"float",5) 
      shears = readAsciiTable(infile_shear,201,"float",5)

      avgs@_FillValue = -9999.
      brchs@_FillValue = -9999.
      stabs@_FillValue = -9999.
      shears@_FillValue = -9999.
      brchs  = where(brchs.eq.-999,-9999,brchs)
      stabs  = where(stabs.eq.-999,-9999,stabs)
      shears = where(shears.eq.-999,-9999,shears)

      dims = dimsizes(stabs)
      stab_perturbs  = new((/dims(0),201/),"float")
      shear_perturbs = new((/dims(0),201/),"float")
      do m=0,dims(0)-1
         stab_perturbs(m,:)  = stabs(m,:)-avgs(:,1)
         shear_perturbs(m,:) = shears(m,:)-avgs(:,2)
      end do

      outfile1_prefix = "low_rb_sonde_list_"+radii+"km"+bot+"-"+top+"km"
      outfile2_prefix = "no_low_rb_sonde_list_"+radii+"km"+bot+"-"+top+"km"
      brch_sub_1d  = ndtooned(brchs(:,bot*10:top*10))
      stab_sub_1d  = ndtooned(stab_perturbs(:,bot*10:top*10))
      shear_sub_1d = ndtooned(shear_perturbs(:,bot*10:top*10))
   
      ;Find where brch < 0.25 and where brch >= 0.25 and get stab and shear values
      stab_lt = stab_sub_1d(ind(brch_sub_1d.lt.0.25))
      shear_lt = shear_sub_1d(ind(brch_sub_1d.lt.0.25))
      stab_ge = stab_sub_1d(ind(brch_sub_1d.ge.0.25))
      shear_ge = shear_sub_1d(ind(brch_sub_1d.ge.0.25))
   
      asciiwrite(outfile1_prefix+"_stab_perturbs.tmp"+l,stab_lt)
      asciiwrite(outfile1_prefix+"_shear_perturbs.tmp"+l,shear_lt)
      asciiwrite(outfile2_prefix+"_stab_perturbs.tmp"+l,stab_ge)
      asciiwrite(outfile2_prefix+"_shear_perturbs.tmp"+l,shear_ge)

      delete([/avgs,brchs,stabs,shears,stab_perturbs,shear_perturbs,brch_sub_1d,stab_sub_1d/])
      delete([/shear_sub_1d,stab_lt,shear_lt,stab_ge,shear_ge/])
   end do
   system("cat "+outfile1_prefix+"*_stab_perturbs.tmp* > "+outfile1_prefix+"_stab_perturbs.txt")
   system("cat "+outfile1_prefix+"*_shear_perturbs.tmp* > "+outfile1_prefix+"_shear_perturbs.txt")
   system("cat "+outfile2_prefix+"*_stab_perturbs.tmp* > "+outfile2_prefix+"_stab_perturbs.txt")
   system("cat "+outfile2_prefix+"*_shear_perturbs.tmp* > "+outfile2_prefix+"_shear_perturbs.txt")
   system("\rm *_stab_perturbs.tmp* *_shear_perturbs.tmp*")
end if
end if
end if
