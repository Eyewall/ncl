load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  ; Load the NCL files that contain the
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   ; gsn_* functions used below.
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

dir = "/jm13/pduran/rawinsondes/allsondes_brch_nomaxbrch/"

files = systemfunc("ls "+dir+"*datv")
nfiles = dimsizes(files)
system("\rm numconsecutivemissings")

do i=0,nfiles-1
   unixi = i + 1
   sondefile = files(i)
   print("Processing file "+sondefile+"    (File "+unixi+" of "+nfiles+")")
   if(stringtoint(systemfunc("wc "+sondefile+" | awk '{print($1)}'")).lt.178)then
      print("LESS THAN 178 LINES IN FILE "+sondefile)
   else
      shearvals = stringtofloat(systemfunc("sed -n '98,178'p "+sondefile+" | awk '{print($12)}'"))
      shearvals@_FillValue = -9999.
      missinginds = ind(ismissing(shearvals))
      nummissing = dimsizes(missinginds) 
      count = 0
      maxcount = 0
      do j=0,nummissing-2
         diff = missinginds(j+1) - missinginds(j)
         if(diff.eq.1)then
            count = count + 1
            if(count.gt.maxcount)then
               maxcount = count
            end if
         else
            count = 0
         end if
      end do
      system("echo "+maxcount+" >> numconsecutivemissings")
;      system("echo "+nummissing+" >> nummissing")
;      if(nummissing.lt.10)then
;         system("mv "+sondefile+" nolargegaps")
;      else
;         maxshear = max(shearvals)
;         asciiwrite("maxshearval"+unixi,maxshear)
;         if(maxshear.lt.20)then
;            system("echo "+sondefile+" >> lookinggood")
;         end if
;      end if
   delete(missinginds)
   end if
end do
