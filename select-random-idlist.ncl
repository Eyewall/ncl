load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-----------------------------------------------------------------
;select-random-idlist.ncl
;Patrick Duran
;2/20/2014
;
;-----------------------------------------------------------------

;-----------------;
;GET DISTRIBUTIONS;
;-----------------;
dir = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/"
hours = (/"00z","06z","12z","18z"/)
hours_int = new((/3,4/),"float")
hours_int(:,0) = 2
hours_int(:,1) = 4
hours_int(:,2) = 6
hours_int(:,3) = 8
pcts = new((/3,4/),"float")

fractions = new((/3,4,10/),"float")  ;(/intensity,time,radial_bin/)
fractions!0 = "intensity"
fractions!1 = "time"
fractions!2 = "radial_bin"

totals = fractions
totalsondes = totals
;totals = new((/3,4,10/),"float")
;totals!0 = "intensity"
;totals!1 = "time"
;totals!2 = "radial bin"

do hournum=0,3
   hour = hours(hournum)
;   idfiles_major    = systemfunc("ls majorhurricanes*.idlist")
;   idfiles_nonmajor = systemfunc("ls nonmajorhurricanes*.idlist")
;   idfiles_tstd     = systemfunc("ls ts+td*.idlist")
   nsondes_total = stringtofloat(systemfunc("cat "+dir+hour+"/*_*_*-*.idlist | wc"))
   nmajor    = stringtofloat(systemfunc("cat "+dir+hour+"/majorhurricanes*.idlist | wc"))
   nnonmajor = stringtofloat(systemfunc("cat "+dir+hour+"/nonmajorhurricanes*.idlist | wc"))
   ntstd     = stringtofloat(systemfunc("cat "+dir+hour+"/ts+td*.idlist | wc"))
   fraction_major    = nmajor/nsondes_total
   fraction_nonmajor = nnonmajor/nsondes_total
   fraction_tstd     = ntstd/nsondes_total
   totalpct = fraction_major+fraction_nonmajor+fraction_tstd
   pcts(0,hournum) = fraction_major * 100
   pcts(1,hournum) = (fraction_nonmajor+fraction_major) * 100
   pcts(2,hournum) = (fraction_tstd+fraction_major+fraction_nonmajor) * 100
;   print("------------"+hour+"------------")
;   print("Total Percent Major: "+fraction_major)
;   print("Total Percent Nonmajor: "+fraction_nonmajor)
;   print("Total Percent TD+TS: "+fraction_tstd)
;   print(" ")
   do radi=0,9
      rad = radi*100
      bottom = rad
      top    = rad + 100
      nsondes_total = stringtofloat(systemfunc("cat "+dir+hour+"/*_*_"+bottom+"-"+top+"*.idlist | wc"))
      nmajor    = stringtofloat(systemfunc("cat "+dir+hour+"/majorhurricanes*"+bottom+"-"+top+".idlist | wc"))
      nnonmajor = stringtofloat(systemfunc("cat "+dir+hour+"/nonmajorhurricanes*"+bottom+"-"+top+".idlist | wc"))
      ntstd     = stringtofloat(systemfunc("cat "+dir+hour+"/ts+td*"+bottom+"-"+top+".idlist | wc"))
      fraction_major    = nmajor/nsondes_total
      fraction_nonmajor = nnonmajor/nsondes_total
      fraction_tstd     = ntstd/nsondes_total
;      print(bottom+"-"+top+" Percent Major: "+fraction_major)
;      print(bottom+"-"+top+" Percent Nonmajor: "+fraction_nonmajor)
;      print(bottom+"-"+top+" Percent TD+TS: "+fraction_tstd)
      fractions(0,hournum,radi) = fraction_major
      fractions(1,hournum,radi) = fraction_nonmajor
      fractions(2,hournum,radi) = fraction_tstd
      totals(0,hournum,radi) = nmajor
      totals(1,hournum,radi) = nnonmajor
      totals(2,hournum,radi) = ntstd
      totalsondes(0,hournum,radi) = nsondes_total
      totalsondes(1,hournum,radi) = nsondes_total
      totalsondes(2,hournum,radi) = nsondes_total
   end do
end do
;print(fractions)
;print(totals)

;We will now take the fractions for the 00z time and multiply them by the totals in all of the
;times to get the total number of sondes in each radial bin for each time that we should
;randomly select.
dist_selection = 0    ;Time off of which you want to base the distribution (0=00z, 1=06z, 2=12z, 3=18z)
dist_selection_array = fractions
do iter = 0,3
   dist_selection_array(:,iter,:) = fractions(:,dist_selection,:)
end do
nsondes_to_select = totals(:,:,:)
nsondes_to_select = totalsondes * dist_selection_array 
print(nsondes_to_select(:,:,:))

;hist_wks = gsn_open_wks("png","diurnal_histogram")
;histres = True
;histres@gsnMaximize = True
;;histres@gsnXYBarChart = True
;histres@trXMinF = 0
;histres@trXMaxF = 10
;histres@tmXBMode = "Explicit"
;histres@tmXBValues = (/2,4,6,8,10/)
;histres@tmXBLabels = (/"00","06","12","18"," "/)
;histres@tiXAxisString = "Time (UTC)"
;histres@tiYAxisString = "Percent"
;histres@xyLineColors = (/"white","white","white"/)
;histres@tmYROn = False
;histres@tmXTOn = False
;histres@gsnDraw = False
;histres@gsnFrame = False
;histplot = gsn_csm_xy(hist_wks,hours_int,pcts,histres)
;
;dum = new(12,"graphic")
;dumind = 0
;do j=0,2
;   do i=0,3
;      bres = True
;      if(j.eq.0)then
;         bres@gsFillColor = "red"
;      else if(j.eq.1)then
;         bres@gsFillColor = "orange"
;      else if(j.eq.2)then
;         bres@gsFillColor = "blue"
;      end if
;      end if
;      end if
;      y_upper = pcts(j,i)
;      y_lower = 0.
;      if(j.gt.0)then
;         y_lower = pcts(j-1,i)
;      end if
;      ybar = (/y_lower,y_upper,y_upper,y_lower,y_lower/)
;      if(i.eq.0)then
;         xbar = (/1.5,1.5,2.5,2.5,1.5/)
;      else if(i.eq.1)then
;         xbar = (/3.5,3.5,4.5,4.5,3.5/)
;      else if(i.eq.2)then
;         xbar = (/5.5,5.5,6.5,6.5,5.5/)
;      else if(i.eq.3)then
;         xbar = (/7.5,7.5,8.5,8.5,7.5/)
;      end if
;      end if
;      end if
;      end if
;      dum(dumind) = gsn_add_polygon(hist_wks,histplot,xbar,ybar,bres)
;      dumind = dumind+1
;   end do
;end do
;
;draw(histplot)
;frame(hist_wks)

exit

;----------;
;PARAMETERS;
;----------;
iddir = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/"

;----------------;
;Get idlist files;
;----------------;
idfiles1 = systemfunc("ls "+iddir+"00z/allsondes_00z*km")
idfiles2 = systemfunc("ls "+iddir+"06z/allsondes_06z*km")
idfiles3 = systemfunc("ls "+iddir+"12z/allsondes_12z*km")
idfiles4 = systemfunc("ls "+iddir+"18z/allsondes_18z*km")

;Check to be sure that there are the same number of id files in each dir
nfiles1 = dimsizes(idfiles1)
nfiles = (/dimsizes(idfiles2),dimsizes(idfiles3),dimsizes(idfiles4)/)
if(any(nfiles.ne.nfiles1))then
   print("ERROR: Not the same number of idlist files in every directory.")
   exit
end if

;---------------------------------------;
;Find time with minumum number of sondes; 
;for each intensity/radius bin          ;
;---------------------------------------;
getnums = new(10,"integer")
random = new((/4,10000/),"string")
randomindex = 0
do i=0,nfiles1-1
   unixi = i + 1
;   print("Processing "+unixi+" of "+nfiles1)
   sondes1 = systemfunc("cat "+idfiles1(i))
   sondes2 = systemfunc("cat "+idfiles2(i))
   sondes3 = systemfunc("cat "+idfiles3(i))
   sondes4 = systemfunc("cat "+idfiles4(i))
   numsondes1 = dimsizes(sondes1) 
   numsondes2 = dimsizes(sondes2) 
   numsondes3 = dimsizes(sondes3)
   numsondes4 = dimsizes(sondes4) 
   numsondesarray = (/numsondes1,numsondes2,numsondes3,numsondes4/)
   getnum = min(numsondesarray)   ;# of sondes to randomly select from each time
   getnums(i) = getnum
   if(getnum.ne.0)then 

      random_indices1 = new(getnum,"integer")
      low  = 0
      high = numsondes1
      con = (high-low)/32766.0
      srand(stringtoint(systemfunc("clock | colrm 43 | colrm 1 36")))
      do k=0,getnum-1
         random_indices1(k) = floattointeger(low+con*rand())
      end do

      random_indices2 = new(getnum,"integer")
      low  = 0
      high = numsondes2
      con = (high-low)/32766.0
      srand(stringtoint(systemfunc("clock | colrm 43 | colrm 1 36")))
      do k=0,getnum-1
         random_indices2(k) = floattointeger(low+con*rand())
      end do

      random_indices3 = new(getnum,"integer")
      low  = 0
      high = numsondes3
      con = (high-low)/32766.0
      srand(stringtoint(systemfunc("clock | colrm 43 | colrm 1 36")))
      do k=0,getnum-1
         random_indices3(k) = floattointeger(low+con*rand())
      end do

      random_indices4 = new(getnum,"integer")
      low  = 0
      high = numsondes4
      con = (high-low)/32766.0
      srand(stringtoint(systemfunc("clock | colrm 43 | colrm 1 36")))
      do k=0,getnum-1
         random_indices4(k) = floattointeger(low+con*rand())
      end do

      ;random_indices1 = generate_unique_indices(numsondes1)
      ;random_indices2 = generate_unique_indices(numsondes2)
      ;random_indices3 = generate_unique_indices(numsondes3)
      if(getnum.eq.1)then
         random(0,randomindex) = sondes1(random_indices1(0))
         random(1,randomindex) = sondes2(random_indices2(0))
         random(2,randomindex) = sondes3(random_indices3(0))
         random(3,randomindex) = sondes4(random_indices4(0))
      else
         do j=0,getnum-1
            random(0,randomindex) = sondes1(random_indices1(j))
            random(1,randomindex) = sondes2(random_indices2(j))
            random(2,randomindex) = sondes3(random_indices3(j))
            random(3,randomindex) = sondes4(random_indices4(j))
            randomindex = randomindex + 1
         end do
      end if
      delete([/random_indices1,random_indices2,random_indices3,random_indices4/])
   end if
   delete([/sondes1,sondes2,sondes3,sondes4/])
   print("Iteration "+unixi+" of "+nfiles1+" completed")
end do

print(getnums)

asciiwrite("tmp1",random(0,:))
asciiwrite("tmp2",random(1,:))
asciiwrite("tmp3",random(2,:))
asciiwrite("tmp4",random(3,:))

system("sed '/missing/d' tmp1 > allintensities_random_uniform_00z.idlist")
system("sed '/missing/d' tmp2 > allintensities_random_uniform_06z.idlist")
system("sed '/missing/d' tmp3 > allintensities_random_uniform_12z.idlist")
system("sed '/missing/d' tmp4 > allintensities_random_uniform_18z.idlist")
system("\rm tmp1 tmp2 tmp3 tmp4")
