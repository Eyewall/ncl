load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/jm13/pduran/ncl/functions/tools.ncl"
;-----------------------------------------------------------;
; totsort.ncl                                    
; Patrick Duran                                           
; 03 April 2016
;
; Will read all overshooting top files (obtained from Sarah
; Griffin/CIMSS) in a given directory and find all TOTs
; within a specified radius from storm center, as defined
; using a best track file interpolated to a 1-minute time
; spacing. Prints all TOT information within the radial bin
; to output files (one file per time) to a directory whose
; name corresponds to the selected radial extent.
;----------------------------------------------------------;

minrad = 0    ;Radius from storm center outside of which to search for TOTs
maxrad = 500  ;Radius from storm center within which to search for TOTs
indir  = "/jm13/pduran/tots/patricia/all/GOES-13/"
outdir = "/jm13/pduran/tots/patricia/"+minrad+"-"+maxrad+"km/"
trackfile = "/jm13/pduran/best-tracks/patricia-1min.txt"

;Create output directory
system("mkdir "+outdir)

;Read track file
track = readAsciiTable(trackfile,10,"float",1)
tracklats = track(:,0)
tracklons = track(:,1)
tracktime = track(:,9)

;Initialize output variables of arbitrary length
outlats = new(1,"float")
outlons = outlats
outtemp = outlats
outmag  = outlats
outanvilz = outlats
outtotz = outlats
outtotp = outlats

;Get TOT files and loop through them all
infiles = systemfunc("ls "+indir)
nfiles  = dimsizes(infiles)
do i=0,nfiles-1
   unixi = i + 1
   system("echo Processing file "+unixi+" of "+nfiles+"    `date`     "+infiles(i))

   ;Get date and time from TOT filename
   totyearday = systemfunc("echo "+infiles(i)+" | awk -F'.' '{print $3}' | cut -c1-7")
   tothr      = systemfunc("echo "+infiles(i)+" | awk -F'.' '{print $4}' | cut -c1-2")
   totmin     = systemfunc("echo "+infiles(i)+" | awk -F'.' '{print $4}' | cut -c3-4")

   ;Read TOT data
   tots := readAsciiTable(indir+infiles(i),7,"float",1)
   totlats := tots(:,0)
   totlons := tots(:,1)
   tottemp := tots(:,2)
   totmag  := tots(:,3)
   anvilz  := tots(:,4)
   totz    := tots(:,5)
   totp    := tots(:,6)

   ;Find track file time that corresponds to TOT time
   totgreg = yyyyddd_to_yyyymmdd(toint(totyearday))
   totyear = stringtoint(systemfunc("echo "+totgreg+" | cut -c1-4"))
   totmon  = stringtoint(systemfunc("echo "+totgreg+" | cut -c5-6"))
   totday  = stringtoint(systemfunc("echo "+totgreg+" | cut -c7-8"))
   totjul  = cd_inv_calendar(totyear,totmon,totday,toint(tothr),toint(totmin),0,\
                             "minutes since 1971-1-1",0)
   flag = 0
   lines  = systemfunc("grep -i "+totjul+" "+trackfile)
   if(ismissing(lines))then
      print("     TOT time is not in track file...Moving to next image.")
      flag = 1
   else
      centerlat = stringtoint(systemfunc("echo "+lines+" | awk '{print $1}'"))
      centerlon = stringtoint(systemfunc("echo "+lines+" | awk '{print $2}'"))
      vmax      = systemfunc("echo "+lines+" | awk '{print $3}'")
      pmin      = systemfunc("echo "+lines+" | awk '{print $4}'")
   end if

   ;If TOT time is in track file, find radius of each TOT, check if it's within
   ;the specified radius range, and get all TOT data for each match
   if(flag.eq.0)
      radii := gc_latlon(centerlat,centerlon,totlats,totlons,2,4)
      valid := ind(radii.ge.minrad.and.radii.lt.maxrad)
      if(.not.all(ismissing(valid)))
         outlats   := totlats(valid)
         outlons   := totlons(valid)
         outtemp   := tottemp(valid)
         outmag    := totmag (valid)
         outanvilz := anvilz (valid)
         outtotz   := totz   (valid)
         outtotp   := totp   (valid)
      else
         flag = 1
      end if
   end if


   ;Print to output file
   outfile = outdir+infiles(i)
   system("echo 'Latitude, Longitude,  temp,   mag, Anvil hgt (km), TOT hgt (km), TOT hgt (hPa)' > header.txt")
   system("touch data.tmp")
   if(flag.eq.0)then
      writelist = [/outlats,outlons,outtemp,outmag,outanvilz,outtotz,outtotp/]
      write_table("data.tmp","w",writelist,"%9.4f%9.4f%6.1f%6.2f%15.3f%14.3f%13.3f")
   end if
   system("cat header.txt data.tmp > "+outfile)
   system("\rm header.txt data.tmp")
end do
