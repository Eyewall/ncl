load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/wind_rose.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

path = "/lz11/lslawsky/data/sounding_data/KILX/soundings/12z/"
files = systemfunc("ls "+path)
nfiles = dimsizes(files)

wdir_array = new(nfiles,"float")
wspd_array = new(nfiles,"float")
wdir_array@_FillValue = 999.
wspd_array@_FillValue = 999.
i = 2022
do while (i.lt.nfiles)
   i = i + 1
   print("Processing file "+i+" of "+nfiles)
   i = i - 1
   raobfile = files(i)
   year = stringtoint(systemfunc("cat "+path+raobfile+" | sed -n 1p | awk '{print($1)}'"))
   month = stringtoint(systemfunc("cat "+path+raobfile+" | sed -n 1p | awk '{print($2)}'"))
   day = stringtoint(systemfunc("cat "+path+raobfile+" | sed -n 1p | awk '{print($3)}'"))
   hour = 12 ;<----Change this if you want 00z instead of 12z
   
   if ((month.eq.12).or.(month.eq.1).or.(month.eq.2)) then ;<----Change this for other seasons
      ;Read in the data;
      system("cat "+path+raobfile+" | colrm 1 11 > temp.dat")
      nrows = stringtoint(systemfunc("wc temp.dat | awk '{print($1)}'"))
      ncols = stringtoint(systemfunc("awk -F' ' '{print NF ; exit}' temp.dat"))
      data = asciiread("temp.dat",(/nrows,ncols/),"float")
      wspd = data(:,3)
      wdir = data(:,4)
      hght = data(:,5)

      ;Subtract station altitude from height array
      hght = hght - 178
      
      ;Get the wind speed and diretion at the height closest to 80 meters and write to arrays
      wdir_array(i) = wdir(minind(abs(hght-80)))
      wspd_array(i) = wspd(minind(abs(hght-80)))

      ;Delete arrays
      delete(data)
      delete(wspd)
      delete(wdir)
      delete(hght)
   end if
   i = i + 1
end do

print("Plotting wind rose")
;Plot wind rose
numPetals = 8
circFr    = 10

wks = gsn_open_wks("ps","windroseDJF")
res = True
res@tiMainString = "Wind Rose: KILX"
plot = WindRoseBasic(wks,wspd_array,wdir_array,numPetals,circFr,res)

system("\rm -f temp.dat") ;Remove temporary file
