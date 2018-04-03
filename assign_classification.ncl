load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

binsize = 10
radii = "500-1500km"
thresh = ispan(-80,30,binsize)  ;Threshold brightness temperature values [deg C]
tbfile = "/jm13/pduran/hs3/ir/tb/TbC_list_"+radii+".txt" ;Containing brightness temperatures and sonde filenames
classdir = "/jm13/pduran/hs3/classifications/" ;Containing sonde filenames in text files by classification
outputdir = "/jm13/pduran/hs3/ir/tb/"          ;Directory in which to write output file
outfilename = "sonde_ir_threshold_vals_"+binsize+"Cbins_"+radii+".txt"

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

;Now loop through the threshold values
data = new((/dimsizes(thresh),6/),"integer")
data@_FillValue = -999
data = 0
do j=0,dimsizes(thresh)-1

   ;Get sonde filesnames that meet the current threshold criterion
   if(all(ismissing(ind(tb_values.le.thresh(j)))))then
      data(j,0) = thresh(j)
      j = j + 1
   end if
   filestoget = sondefiles(ind(tb_values.le.thresh(j)))
   
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
   data(j,0) = thresh(j)
   data(j,1) = smooth
   data(j,2) = sharp
   data(j,3) = multi
   data(j,4) = uncertain
   data(j,5) = total
   delete(filestoget)
end do

;Write to oyutput file
output = [/data(:,0),data(:,1),data(:,2),data(:,3),data(:,4),data(:,5)/]
header = new(5,"string")
header(0) = "OUTPUT FROM ASSIGN_CLASSIFICATION.NCL. LISTED ARE THE NUMBER OF SONDES IN EACH CLASS"
header(1) = "THAT ARE DEPLOYED WITHIN AN IR BRIGHTNESS TEMPERATURE LESS THAN THE THRESHOLD VALUE."
header(2) = " " 
header(3) = "THRESHOLD VALUE   SMOOTH   SHARP   MULTI   UNCERTAIN   TOTAL"
header(4) = "---------------   ------   -----   -----   ---------   -----"
asciiwrite("header.txt",header)
write_table("tempvals.txt","w",output,"%9i%13i%8i%7i%7i%11i")
system("cat header.txt tempvals.txt > "+outfilename)
system("mv "+outfilename+" "+outputdir)
system("\rm header.txt tempvals.txt")
