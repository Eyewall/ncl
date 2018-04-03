load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

dir = "/jm13/pduran/hs3/classifications/"
;files = systemfunc("ls /jm13/pduran/hs3/classifications/")
;print(files)
;
;fil = dir+files(2)
;fil2 = dir+files(1)
;fil3 = dir+files(0)
;fil4 = dir+files(3)
;nlines = stringtoint(systemfunc("wc "+fil+" | awk '{print($1)}'"))
;numbers = asciiread(fil,nlines,"integer")
;numbers2 = asciiread(fil2,nlines,"integer")
;numbers3 = asciiread(fil3,nlines,"integer")
;numbers4 = asciiread(fil4,nlines,"integer")
;
;nnums = dimsizes(numbers)
;do i=0,nnums-1
;   numb = numbers(i)
;   indices = ind(numbers2.eq.numb)
;   if(.not.ismissing(indices))
;      print(numbers2(indices))
;   end if
;end do
;
;do i=0,nnums-1
;   numb = numbers(i)
;   indices = ind(numbers3.eq.numb)
;   if(.not.ismissing(indices))
;      print(numbers3(indices))
;   end if
;end do
;
;do i=0,nnums-1
;   numb = numbers(i)
;   indices = ind(numbers4.eq.numb)
;   if(.not.ismissing(indices))
;      print(numbers4(indices))
;   end if
;end do

allnums = asciiread(dir+"all.txt",1421,"integer")
allnums_fillin = new(1422,"integer")
allnums_fillin = 0
do i=0,1421
   imgnum = allnums(i)
   allnums_fillin(imgnum) = 1
end do

print(allnums_fillin)
