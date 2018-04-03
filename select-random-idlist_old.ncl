load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;-----------------------------------------------------------------
;select-random-idlist.ncl
;Patrick Duran
;2/20/2014
;
;-----------------------------------------------------------------

;----------;
;PARAMETERS;
;----------;
iddir = "/jm13/pduran/unix_scripts_and_c++/2014/diurnal/"

;----------------;
;Get idlist files;
;----------------;
idfiles1 = systemfunc("ls "+iddir+"majorhurricanes_*z")
idfiles2 = systemfunc("ls "+iddir+"nonmajorhurricanes_*z")
idfiles3 = systemfunc("ls "+iddir+"ts+td_*z")

;Check to be sure that there are the same number of id files in each dir
nfiles1 = dimsizes(idfiles1)
nfiles = (/dimsizes(idfiles2),dimsizes(idfiles3)/)
if(any(nfiles.ne.nfiles1))then
   print("ERROR: Not the same number of idlist files in every directory.")
   exit
end if

;---------------------------------------;
;Find time with minumum number of sondes; 
;for each intensity/radius bin          ;
;---------------------------------------;
getnums = new(4,"integer")
random = new((/4,10000/),"string")
randomindex = 0
do i=0,nfiles1-1
   unixi = i + 1
;   print("Processing "+unixi+" of "+nfiles1)
   sondes1 = systemfunc("cat "+idfiles1(i))
   sondes2 = systemfunc("cat "+idfiles2(i))
   sondes3 = systemfunc("cat "+idfiles3(i))
   numsondes1 = dimsizes(sondes1) 
   numsondes2 = dimsizes(sondes2) 
   numsondes3 = dimsizes(sondes3) 
   numsondesarray = (/numsondes1,numsondes2,numsondes3/)
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

      ;random_indices1 = generate_unique_indices(numsondes1)
      ;random_indices2 = generate_unique_indices(numsondes2)
      ;random_indices3 = generate_unique_indices(numsondes3)
      if(getnum.eq.1)then
         random(0,randomindex) = sondes1(random_indices1(0))
         random(1,randomindex) = sondes2(random_indices2(0))
         random(2,randomindex) = sondes3(random_indices3(0))
      else
         do j=0,getnum-1
            random(0,randomindex) = sondes1(random_indices1(j))
            random(1,randomindex) = sondes2(random_indices2(j))
            random(2,randomindex) = sondes3(random_indices3(j))
            randomindex = randomindex + 1
         end do
      end if
      delete([/random_indices1,random_indices2,random_indices3/])
   end if
   delete([/sondes1,sondes2,sondes3/])
end do

asciiwrite("tmp1",random(0,:))
asciiwrite("tmp2",random(1,:))
asciiwrite("tmp3",random(2,:))

system("sed '/missing/d' tmp1 > allintensities_random_uniform_major.idlist")
system("sed '/missing/d' tmp2 > allintensities_random_uniform_nonmajor.idlist")
system("sed '/missing/d' tmp3 > allintensities_random_uniform_td+ts.idlist")
system("\rm tmp1 tmp2 tmp3")
