load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

thresh = -70  ;Threshold brightness temperature value [deg C]
tbfile = "/jm13/pduran/hs3/ir/tb/TbC_list.txt" ;Containing brightness temperatures and sonde filenames
classdir = "/jm13/pduran/hs3/classifications/" ;Containing sonde filenames in text files by classification

;Get numbers of lines in each classification file so it can be read
nlinessmooth    = stringtoint(systemfunc("wc "+classdir+"smooth.txt | awk '{print($1)}'"))
nlinessharp     = stringtoint(systemfunc("wc "+classdir+"sharp.txt  | awk '{print($1)}'") ) 
nlinesmulti     = stringtoint(systemfunc("wc "+classdir+"multiple.txt  | awk '{print($1)}'"))
nlinesuncertain = stringtoint(systemfunc("wc "+classdir+"uncertain.txt | awk '{print($1)}'"))

;Get sonde filenames from classification files
smoothfiles    = asciiread(classdir+"smooth.txt",nlinessmooth,"string")
sharpfiles     = asciiread(classdir+"sharp.txt",nlinessharp,"string")
multifiles     = asciiread(classdir+"multiple.txt",nlinesmulti,"string")
uncertainfiles = asciiread(classdir+"uncertain.txt",nlinesuncertain,"string")

;Get brightness temperature values and sonde filenames from Tb file
tb_values = stringtofloat(systemfunc("awk '{print($1)}' "+tbfile))
sondefiles = systemfunc("awk '{print($2)}' "+tbfile+" | awk -F '/' '{print $NF}'")

;Now find the sonde filenames that meet the Tb criterion
filestoget = sondefiles(ind(tb_values.le.thresh))

;Loop through each file with Tb below threshold, and iterate the appropriate category;s count
smooth = 0
sharp = 0
multi = 0
uncertain = 0
do i=0,dimsizes(filestoget)-1
   fil = filestoget(i)
   if(any(fil.eq.smoothfiles))then
      smooth = smooth + 1
   else if(any(fil.eq.sharpfiles))then
      sharp = sharp + 1
   else if(any(fil.eq.multifiles))then
      multi = multi + 1
   else if(any(fil.eq.uncertainfiles))then
      uncertain = uncertain + 1
   end if
   end if
   end if
   end if
end do

total = smooth+sharp+multi+uncertain
print("Total number of sondes that met threshold requirement = "+total)
print(smooth)
print(sharp)
print(multi)
print(uncertain)
