;------------------------------------------------------------------------------------------------------------------------
; This script reads in soil water isotopes from a climatology netCDF file, weights them by soil water and rooting depth 
; fraction, and produces a map plot of each case's average values and differences between cases. Functionality for 
; weighting by length of month is included. This script includes functionality for calculating values from twelve (12) 
; separate cases; however, it can be easily modified to increase/decrease this number.
;
; Author: Alex Thompson
; Date: 7/29/2022
;------------------------------------------------------------------------------------------------------------------------

begin

;************************************************
;************************************************
; SET ALL VARIABLES IN THIS SECTION
;************************************************
;************************************************

;------------------------------------------------
; Add filepaths for time series data here
;------------------------------------------------

; Add file paths

 CASE1  = "[CASE1 filepath]"
 CASE2  = "[CASE2 filepath]"
 CASE3  = "[CASE3 filepath]"
 CASE4  = "[CASE4 filepath]"
 CASE5  = "[CASE5 filepath]"
 CASE6  = "[CASE6 filepath]"
 CASE7  = "[CASE7 filepath]"
 CASE8  = "[CASE8 filepath]"
 CASE9  = "[CASE9 filepath]"
 CASE10  = "[CASE10 filepath]"
 CASE11  = "[CASE11 filepath]"
 CASE12  = "[CASE12 filepath]"

 CASES = (/ CASE1, CASE2, CASE3, CASE4, CASE5, CASE6, CASE7, CASE8, CASE9, CASE10, CASE11, CASE12 /)

 cases = (/ "case1", "case2", "case3", "case4", "case5", "case6", "case7", "case8", "case9", "case10", "case11", "case12"  /)

; Is there a special name for these cases to include in the output file name?
 name = "_12cases"

 numcases = 12

;-------------------------------------------------------
; Timing 
;-------------------------------------------------------

; Indices to read in (For time series, 0:1199 is 100 yrs, 600:1199 is 50 yrs; For climatology, use 0:11)
 begi = 0
 endi = 11

; For output file name, specify dates below

 YEARS  = ""

; Season to plot from 0 to 11
 SEASON    = "ANN" 
  MON = (/ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 /)
 ;MON = (/  11,0,1 /) ; DJF
 ;MON = (/  2,3,4  /) ; MAM
 ;MON = (/  5,6,7  /) ; JJA
 ;MON = (/  8,9,10 /) ; SON
; MON needs indices not actual months

 numyears  = ((endi-begi)+1)/12 
 nummonths = count_unique_values(MON) 
 MONarray = new((/numyears*nummonths/),integer)

; This loop calculates what MON should be! Do not modify
 i = 0
 do y=0,(numyears*nummonths)-nummonths
   MONarray(y:y+nummonths-1) = MON + i*12
   y=y+nummonths-1
   i=i+1
 end do  

;------------------------------------------------
; Specify the fields and properties here
;------------------------------------------------ 

; Plot weighted or unweighted isotope values?
 WT = "wt"  ; "wt" or "" (blank)

; Which variable(s) to plot? Can perform math operations on these variables 

 WTVAR = "H2OSOI" ; Special cases: "PRECT" and "H2OSOI"
 ISO   = "d18O"   ; "d18O", "dHDO", or "dexcess"
 Liso  = "soil"  ; Special cases: "precip" or "soil"
 Hiso  = "soil"  ; Else, input variable names here

; Variable for averaging over soil levels for rooting depth avgs

 ROOTING_VAR = "ROOTR_COLUMN" ; "ROOTFR", "ROOTR", "ROOTR_COLUMN"

; What are the units of the variable?
 UNITS = "permil"
 ptiny = 1.E-18

;--------------------------------------------------------------
; Do you want to print out the average over a specified region?
;--------------------------------------------------------------

; Latitude:  +=north, -=south
; Longitude: 0-180=E, 180-360=W (when indexing using lon_flip)

; Do you want a global average?
 Global = "Yes"

; Do you want an average over a specific region?
 Region = "Yes"

 southlat = 18.0
 northlat = 33.3
 westlon  = 247.5
 eastlon  = 257.5

; Do you want an average at a specific grid point?
 Point = "No"

 latpoint = 20.0
 lonpoint = 10.0

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = "pdfs/"+SEASON+"_year"+YEARS+"_"+WTVAR+"-"+WT+"_"+ISO+""+Liso+"_"+ROOTING_VAR+"wgt_"+name+""

;-----------------------------------------------------------
; Specify contour levels for absolute and difference values
;-----------------------------------------------------------

if (ISO .eq. "dHDO") then

; Manual Levels for absolute contour plotting (1=ON, 0=OFF) 
 ManLevAbs = 1      
 abs_hival = 12.0  ; float
 abs_loval = -100.0 ; float
 abs_spval = 4.0   ; float

; Manual Levels for difference contour plotting (1=ON, 0=OFF)
 ManLevDif = 1
 dif_hival = 30.0   ; float
 dif_loval = -30.0  ; float
 dif_spval = 2.0   ; float

else if (ISO .eq. "d18O") then 

; Manual Levels for absolute contour plotting (1=ON, 0=OFF)
 ManLevAbs = 1
 abs_hival = 0.0  ; float
 abs_loval = -20.0 ; float
 abs_spval = 1.0   ; float

; Manual Levels for difference contour plotting (1=ON, 0=OFF)
 ManLevDif = 1
 dif_hival = 3.0   ; float
 dif_loval = -3.0  ; float
 dif_spval = 0.2   ; float

end if
end if

;---------------------------------------------
; Zoom into any world region in particular?
;---------------------------------------------

 World = 0  ; 1=entire world, 0=zoomed in to coordinate values in second block 

 if (World .eq. 1) then
  LatMin = -90
  LatMax = 90
  LonMin = -180
  LonMax = 180
 else
  LatMin = 0  ; negative values = °S
  LatMax = 50   ; positive values = °N
  LonMin = -140; negative values = °W
  LonMax = -50  ; positive values = °E
 end if

;-------------------------------------------------
; Important plot specifications to set here
;-------------------------------------------------

 ColorTableName = "cmp_haxby" ; "BlAqGrYeOrReVi200" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 ColorTableNameDif = "BlueYellowRed" ; "BlAqGrYeOrReVi200" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 LeftString     = "~F21~"+SEASON+" "+WTVAR+""+WT+"-"+ISO+"_"+Liso+""
 CenterString   = ""
 RightString    = ""

 Panelplot = "No"

;-----------------------------
; Monthly weights
;-----------------------------

; 0ka
wgt_00ka = (/ 0.08493151, 0.076712325, 0.08493151, 0.08219178, 0.08493151, 0.08219178, 0.08493151, 0.08493151, 0.08219178, 0.08493151, 0.08219178, 0.08493151 /)

; 03ka
wgt_03ka = (/ 0.087671233, 0.079452055, 0.087671233, 0.084931507, 0.084931507, 0.082191781, 0.082191781, 0.082191781, 0.079452055, 0.082191781, 0.082191781, 0.084931507 /)

; 06ka
wgt_06ka = (/ 0.087671233, 0.082191781, 0.087671233, 0.084931507, 0.084931507, 0.079452055, 0.082191781, 0.079452055, 0.079452055, 0.082191781, 0.082191781, 0.087671233 /)

; 09ka
wgt_09ka = (/ 0.090410959, 0.082191781, 0.087671233, 0.082191781, 0.082191781, 0.076712329, 0.079452055, 0.079452055, 0.079452055, 0.084931507, 0.084931507, 0.090410959 /)

; 12ka
wgt_12ka = (/ 0.090410959, 0.079452055, 0.084931507, 0.079452055, 0.079452055, 0.076712329, 0.079452055, 0.082191781, 0.082191781, 0.087671233, 0.087671233, 0.090410959 /)

; 14ka
wgt_14ka = (/ 0.087671233, 0.079452055, 0.084931507, 0.079452055, 0.079452055, 0.076712329, 0.082191781, 0.082191781, 0.082191781, 0.087671233, 0.087671233, 0.090410959 /)

; 16ka
wgt_16ka = (/ 0.087671233, 0.076712329, 0.082191781, 0.079452055, 0.079452055, 0.079452055, 0.082191781, 0.084931507, 0.084931507, 0.087671233, 0.087671233, 0.087671233 /)

; 18ka
wgt_18ka = (/ 0.084931507, 0.076712329, 0.082191781, 0.079452055, 0.082191781, 0.079452055, 0.084931507, 0.084931507, 0.084931507, 0.087671233, 0.084931507, 0.087671233 /)

; 21ka
wgt_21ka = (/ 0.084931507, 0.076712329, 0.084931507, 0.082191781, 0.084931507, 0.082191781, 0.084931507, 0.084931507, 0.082191781, 0.084931507, 0.082191781, 0.084931507 /)

if (SEASON .eq. "ANN") then
  wgt_mon_1  = wgt_00ka
  wgt_mon_2  = wgt_03ka
  wgt_mon_3  = wgt_06ka
  wgt_mon_4  = wgt_06ka
  wgt_mon_5  = wgt_06ka
  wgt_mon_6  = wgt_09ka
  wgt_mon_7  = wgt_09ka
  wgt_mon_8  = wgt_12ka
  wgt_mon_9  = wgt_14ka
  wgt_mon_10 = wgt_16ka
  wgt_mon_11 = wgt_18ka
  wgt_mon_12 = wgt_21ka
else
  wgt_mon_1  = wgt_00ka(MON)/sum(wgt_00ka(MON))
  wgt_mon_2  = wgt_03ka(MON)/sum(wgt_03ka(MON))
  wgt_mon_3  = wgt_06ka(MON)/sum(wgt_06ka(MON))
  wgt_mon_4  = wgt_06ka(MON)/sum(wgt_06ka(MON))
  wgt_mon_5  = wgt_06ka(MON)/sum(wgt_06ka(MON))
  wgt_mon_6  = wgt_09ka(MON)/sum(wgt_09ka(MON))
  wgt_mon_7  = wgt_09ka(MON)/sum(wgt_09ka(MON))
  wgt_mon_8  = wgt_12ka(MON)/sum(wgt_12ka(MON))
  wgt_mon_9  = wgt_14ka(MON)/sum(wgt_14ka(MON))
  wgt_mon_10 = wgt_16ka(MON)/sum(wgt_16ka(MON))
  wgt_mon_11 = wgt_18ka(MON)/sum(wgt_18ka(MON))
  wgt_mon_12 = wgt_21ka(MON)/sum(wgt_21ka(MON))
end if

;************************************************
;************************************************
; BELOW IS THE ACTUAL CODE FOR THIS SCRIPT
; VARIABLES ARE SET AT THIS POINT
; ADDITIONAL PLOT SPECS ARE SET AFTER CODE
;************************************************
;************************************************

;************************************************
; Read in variables
;-----------------------------------------------*
; Loop starts here
;-----------------------------------------------*
;************************************************

 do i=1,numcases

;----------------------
; Identify weights
;----------------------

 if (i .eq. 1) then
   wgt_mon = wgt_mon_1
 else if (i .eq. 2) then
   wgt_mon = wgt_mon_2
 else if (i .eq. 3) then
   wgt_mon = wgt_mon_3
 else if (i .eq. 4) then
   wgt_mon = wgt_mon_4
 else if (i .eq. 5) then
   wgt_mon = wgt_mon_5
 else if (i .eq. 6) then
   wgt_mon = wgt_mon_6
 else if (i .eq. 7) then
   wgt_mon = wgt_mon_7
 else if (i .eq. 8) then
   wgt_mon = wgt_mon_8
 else if (i .eq. 9) then
   wgt_mon = wgt_mon_9
 else if (i .eq. 10) then
   wgt_mon = wgt_mon_10
 else if (i .eq. 11) then
   wgt_mon = wgt_mon_11
 else if (i .eq. 12) then
   wgt_mon = wgt_mon_12
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if
 end if

; For seasonal cycle of isotopes, need to loop through each month

 ; First initialize variables

 delim           = ","
 numyrs          = ((endi-begi)+1)/12
 nummonths       = count_unique_values(MON)
 dimfil          = CASES(i-1)
 dimins          = addfile(dimfil,"r")
 dimvar          = dimins->$WTVAR$
 lat             = dimvar&lat
 lon             = dimvar&lon
 levgrnd         = dimvar&levgrnd
 iso_d18O_seasonal    = new((/12,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
 iso_d18O_wt_seasonal = new((/12,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
 iso_dHDO_seasonal    = new((/12,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
 iso_dHDO_wt_seasonal = new((/12,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
 root_time            = new((/12,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
 iso_wt_rooted_seasonal = new((/12,dimsizes(lat),dimsizes(lon)/),float)

 ; Now loop through each month

 do k=0,11

 ; Initialize variables
    wtvar           = new((/numyrs,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
    lightiso_d18O   = new((/numyrs,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
    heavyiso_d18O   = new((/numyrs,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
    lightiso_dHDO   = new((/numyrs,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)
    heavyiso_dHDO   = new((/numyrs,dimsizes(levgrnd),dimsizes(lat),dimsizes(lon)/),float)

 ; Create indexing array

  MONindex = ispan(k,numyrs*nummonths-1,12)

 ; Read in variables and scale them
   
     fil = CASES(i-1)
     ins = addfile(fil,"r")

   ; Read in variable to weight isotopic values by
     wtvar      = ins->$WTVAR$(MONindex,:,:,:)
     wtvar_time = wtvar

   ; Finish processing the variable to weight by
        
     ndims_wtvar = dimsizes(wtvar_time)
     wtvar_5d = reshape(wtvar_time, (/ ndims_wtvar(0), 1, ndims_wtvar(1), ndims_wtvar(2), ndims_wtvar(3) /))
    
  ; Now read in isotopic values
    
     ; d18O
      if (Liso .eq. "soil") then
        lightiso_d18O = ins->H2OSOI_H2OTR(MONindex,:,:,:)
        heavyiso_d18O = ins->H2OSOI_H218O(MONindex,:,:,:)
      end if

     ; dHDO
      if (Liso .eq. "soil") then
        lightiso_dHDO = ins->H2OSOI_H2OTR(MONindex,:,:,:)
        heavyiso_dHDO = ins->H2OSOI_HDO(MONindex,:,:,:)
      end if

    ; Apply time indexing

    ; d18O
     lightiso_d18O_time = lightiso_d18O
     heavyiso_d18O_time = heavyiso_d18O

    ; dHDO
     lightiso_dHDO_time = lightiso_dHDO
     heavyiso_dHDO_time = heavyiso_dHDO

   ; Calculate delta values

   ; d18O
    lightiso_d18O_time = where(lightiso_d18O_time.lt.ptiny,ptiny,lightiso_d18O_time)
    iso_d18O = (heavyiso_d18O_time/lightiso_d18O_time - 1.) * 1000.

   ; dHDO
    lightiso_dHDO_time = where(lightiso_dHDO_time.lt.ptiny,ptiny,lightiso_dHDO_time)
    iso_dHDO = (heavyiso_dHDO_time/lightiso_dHDO_time - 1.) * 1000.

   ; Amount-weight the delta value

    wtvar_5d_fixed = where(wtvar_5d .le. 0, wtvar_5d@_FillValue, wtvar_5d)

   ; d18O
    iso_d18O_5d = reshape(iso_d18O, (/ndims_wtvar(0), 1, ndims_wtvar(1), ndims_wtvar(2), ndims_wtvar(3)/))
    iso_d18O_wt_seasonal(k,:,:,:) = dim_sum_n(wtvar_5d_fixed * iso_d18O_5d, 1) / dim_sum_n(wtvar_5d_fixed, 1)

   ; dHDO
    iso_dHDO_5d = reshape(iso_dHDO, (/ndims_wtvar(0), 1, ndims_wtvar(1), ndims_wtvar(2), ndims_wtvar(3) /))
    iso_dHDO_wt_seasonal(k,:,:,:) = dim_sum_n(wtvar_5d_fixed * iso_dHDO_5d, 1) / dim_sum_n(wtvar_5d_fixed, 1)

   ; Apply isotope type

    if (ISO .eq. "d18O") then
      iso_wt_seasonal = iso_d18O_wt_seasonal
    else if (ISO .eq. "dHDO") then
      iso_wt_seasonal = iso_dHDO_wt_seasonal
    else if (ISO .eq. "dexcess") then
      iso_wt_seasonal = iso_dHDO_wt_seasonal - 8 * iso_d18O_wt_seasonal 
    end if
    end if
    end if

;*************************************************************************
; Weight averaged weighted isotope variable by fractional rooting depth
;------------------------------------------------------------------------*
; Loop continues here...
;------------------------------------------------------------------------*
;*************************************************************************

; Read in rooting depth

  root     = ins->$ROOTING_VAR$
  root_mon = root(MONindex,:,:,:)

; Reshape root variable to be (years,levgrnd,lat,lon)

  ndims_root = dimsizes(root_mon)
  root_3d    = reshape(root_mon, (/ ndims_root(0), ndims_root(1), ndims_root(2) /))

 ; Remove values of <0 so weighting can occur
  root_3d = where(root_3d .le. 0, root_3d@_FillValue, root_3d)

  root_time(k,:,:,:) = root_3d

 ; Weight the isotopes by the fractional rooting depth
  iso_wt_rooted_seasonal(k,:,:) = dim_sum_n(iso_wt_seasonal(k,:,:,:)*root_time(k,:,:,:),0) / dim_sum_n(root_time(k,:,:,:),0)

end do

;************************************************
; Define lat/lon and metadata for variables
;-----------------------------------------------*
; Loop continues here...
;-----------------------------------------------*
;************************************************

; Variable metadata set here

 iso_wt_rooted_seasonal!0   = "time"
 iso_wt_rooted_seasonal!1   = "lat"
 iso_wt_rooted_seasonal!2   = "lon"
 iso_wt_rooted_seasonal&lat = lat
 iso_wt_rooted_seasonal&lon = lon

;******************************************************
; Average variable by time for final (lat,lon) variable 
;-----------------------------------------------------*
; Loop continues here...
;-----------------------------------------------------*
;******************************************************

 iso_wt_avg_rooted = dim_avg_wgt_n_Wrap(iso_wt_rooted_seasonal(MON,:,:),wgt_mon,0,0) 

;*********************************************************
; Define metadata for final variable and perform lonFlip
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

; Metadata

 iso_wt_rooted_seasonal!0   = "time"
 iso_wt_rooted_seasonal!1   = "lat"
 iso_wt_rooted_seasonal!2   = "lon"
 iso_wt_rooted_seasonal&lat = lat
 iso_wt_rooted_seasonal&lon = lon

 iso_wt_avg_rooted!0   = "lat"
 iso_wt_avg_rooted!1   = "lon"
 iso_wt_avg_rooted&lat = lat
 iso_wt_avg_rooted&lon = lon

; lonFlip

 lon_flip = lonFlip(lon)
 iso_wt_avg_rooted_flip = lonFlip(iso_wt_avg_rooted)

; Take root variable (yrs,levgrnd,lat,lon) and sum by levgrnd and avg by time

 root_sum      = dim_sum_n(root_time,1)
 root_avg      = dim_avg_n_Wrap(root_sum,0)
 root_avg_flip = lonFlip(root_avg)

;**************************************************
; Save the required variables and delete the rest
;-------------------------------------------------*
; Loop continues here...
;-------------------------------------------------*
;**************************************************

; Print summaries of each saved variable for this case of the loop

 print("**************************")
 print("For CASE"+i+"...")
 print(""+cases(i-1)+"")
 print("**************************")
 printVarSummary(iso_wt_avg_rooted)
 printVarSummary(iso_wt_avg_rooted_flip)
 print("**************************")
 print("End loop for CASE"+i+"...")
 print("**************************")

;-----------------------------------------------------------
; Saved variables are of the following dimensions:
;
; iso                    -> (time[yr&mon],levgrnd,lat,lon)
; iso_wt                 -> (time[yr],levgrnd,lat,lon)
; iso_wt_rooted          -> (yr,lat,lon)
; iso_wt_avg_rooted      -> (lat,lon)
; iso_wt_avg_rooted_flip -> (lat,lon_flip)
; root_time              -> (yr,lat,lon_flip)
; root_avg               -> (lat,lon_flip)
; root_avg_flip          -> (lat,lon_flip)
;
;-----------------------------------------------------------

 ; Save corresponding variables
   if (i .eq. 1) then
     iso_wt_avg_rooted_case1      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case1_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 2) then
     iso_wt_avg_rooted_case2      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case2_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 3) then
     iso_wt_avg_rooted_case3      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case3_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 4) then
     iso_wt_avg_rooted_case4      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case4_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 5) then
     iso_wt_avg_rooted_case5      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case5_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 6) then
     iso_wt_avg_rooted_case6      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case6_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 7) then
     iso_wt_avg_rooted_case7      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case7_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 8) then
     iso_wt_avg_rooted_case8      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case8_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 9) then
     iso_wt_avg_rooted_case9      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case9_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 10) then
     iso_wt_avg_rooted_case10      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case10_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 11) then
     iso_wt_avg_rooted_case11      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case11_flip = iso_wt_avg_rooted_flip
   end if

   if (i .eq. 12) then
     iso_wt_avg_rooted_case12      = iso_wt_avg_rooted
     iso_wt_avg_rooted_case12_flip = iso_wt_avg_rooted_flip
   end if
 
; If more than three cases, include another if/then here to accommodate...

; Now delete the unneeded variables

;  delete([/fil,ins,nummonths,wtvar,ndims_wtvar,wtvar_time,wtvar_5d,lightiso_d18O,heavyiso_d18O,lightiso_d18O_time,heavyiso_d18O_time,iso_d18O,iso_d18O_5d,lightiso_dHDO,heavyiso_dHDO,lightiso_dHDO_time,heavyiso_dHDO_time,iso_dHDO,iso_dHDO_5d,wtvar_5d_fixed,iso_d18O_wt,iso_dHDO_wt,iso,iso_wt,root,root_mon,iso_wt_avg_rooted,iso_wt_avg_rooted_flip,ndims_root,root_5d,root_years,root_flipped,root_time,iso_wt_rooted,root_avg,root_avg_flip/])

end do

;-------------------------------------------------*
; Loop is done.
;-------------------------------------------------*

;***********************************************************
; Compute average values over a certain region if necessary
;***********************************************************

if (Global .eq. "Yes" .or. Region .eq. "Yes" .or. Point .eq. "Yes") then
  print("********************")
  print("AVERAGE VALUES")
  print("*******************")
end if

 rad = 4.0*atan(1.0)/180.0
 gw  = (cos(lat*rad))/2

;-----------
; Global
;-----------

if (Global .eq. "Yes") then
 
  print("Global average "+cases(0)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case1_flip,gw,1.0,0)+"")
  print("Global average "+cases(1)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case2_flip,gw,1.0,0)+"")
  print("Global average "+cases(2)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case3_flip,gw,1.0,0)+"")
  print("Global average "+cases(3)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case4_flip,gw,1.0,0)+"")
  print("Global average "+cases(4)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case5_flip,gw,1.0,0)+"")
  print("Global average "+cases(5)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case6_flip,gw,1.0,0)+"")
  print("Global average "+cases(6)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case7_flip,gw,1.0,0)+"")
  print("Global average "+cases(7)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case8_flip,gw,1.0,0)+"")
  print("Global average "+cases(8)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case9_flip,gw,1.0,0)+"")
  print("Global average "+cases(9)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case10_flip,gw,1.0,0)+"")
  print("Global average "+cases(10)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case11_flip,gw,1.0,0)+"")
  print("Global average "+cases(11)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case12_flip,gw,1.0,0)+"")

end if

;-----------
; Region
;-----------

if (Region .eq. "Yes") then

 lat_s = min(ind(lat .ge. southlat))
 lat_n = max(ind(lat .le. northlat))

 if (westlon .ge. 180.0) then
  lon_w = min(ind(lon_flip .ge. westlon))
 else if (westlon .lt. 180) then
  lon_w = max(ind(lon_flip .le. westlon))
 end if
 end if

 if (eastlon .ge. 180.0) then
  lon_e = min(ind(lon_flip .ge. eastlon))
 else if (eastlon .lt. 180.0) then 
  lon_e = max(ind(lon_flip .le. eastlon))
 end if
 end if

 print(""+cases(0)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case1_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))  
 print(""+cases(1)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case2_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(2)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case3_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(3)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case4_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(4)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case5_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(5)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case6_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(6)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case7_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(7)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case8_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(8)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case9_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(9)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case10_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(10)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case11_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(11)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_rooted_case12_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))

 w_slat = min(ind(lat .ge. 25))
 w_nlat = max(ind(lat .le. 32))
 w_wlon = min(ind(lon_flip .ge. 350))
 w_elon = max(ind(lon_flip .le. 10))

 e_slat = min(ind(lat .ge. 10))
 e_nlat = max(ind(lat .le. 17))
 e_wlon = max(ind(lon_flip .le. 20))
 e_elon = max(ind(lon_flip .le. 40))

end if

;-----------
; Point
;-----------

if (Point .eq. "Yes") then

 lat_point = min(ind(lat .ge. latpoint))
 if (lonpoint .gt. 180) then
  lon_point = min(ind(lon_flip .ge. lonpoint))
 else
  lon_point = max(ind(lon_flip .le. lonpoint))
 end if

 print(""+cases(0)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case1_flip(lat_point,lon_point)))
 print(""+cases(1)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case2_flip(lat_point,lon_point)))
 print(""+cases(2)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case3_flip(lat_point,lon_point)))
 print(""+cases(3)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case4_flip(lat_point,lon_point)))
 print(""+cases(4)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case5_flip(lat_point,lon_point)))
 print(""+cases(5)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case6_flip(lat_point,lon_point)))
 print(""+cases(6)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case7_flip(lat_point,lon_point)))
 print(""+cases(7)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case8_flip(lat_point,lon_point)))
 print(""+cases(8)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case9_flip(lat_point,lon_point)))
 print(""+cases(9)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case10_flip(lat_point,lon_point)))
 print(""+cases(10)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case11_flip(lat_point,lon_point)))
 print(""+cases(11)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_rooted_case12_flip(lat_point,lon_point)))

end if

;***************************************************
; Specifications for the plot are determined below 
;***************************************************

; Define workstation

 wks = gsn_open_wks(file_type,outputfilename)
 
 res = True

;-----------------------------------------------------------
; Specify contour levels for absolute and difference values
;...........................................................
; This is for absolute values, diff values come later
;-----------------------------------------------------------

 if (ManLevAbs .eq. 1) then
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMaxLevelValF       =  abs_hival
   res@cnMinLevelValF       =  abs_loval
   res@cnLevelSpacingF      =  abs_spval
 end if

;---------------------------------------------
; Zoom into any world region in particular?
;---------------------------------------------

 res@mpMinLatF = LatMin
 res@mpMaxLatF = LatMax
 res@mpMinLonF = LonMin
 res@mpMaxLonF = LonMax

;-------------------------------------------------
; Contour specifications
;-------------------------------------------------

 res@cnFillOn       = True        ; Fill in contours?
 res@cnFillMode     = "AreaFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 res@cnLinesOn      = False       ; Contour lines?
 res@cnLineLabelsOn = False       ; Contour line labels?
 res@gsnAddCyclic   = True        ; Eliminates gap in longitudinal data

;------------------------------------------------
; Titles and text on the plot
;------------------------------------------------

; Left string is in upper left corner
; Center string is in upper center
; Right string is in upper right corner

; Left, Center, and Right text strings

 res@gsnLeftString   = LeftString 
 res@gsnCenterString = CenterString
 res@gsnRightString  = RightString

; Text positions

 res@gsnLeftStringOrthogonalPosF   = 0.05  ; Left string up/down position
 res@gsnCenterStringOrthogonalPosF = 0.05  ; Center string up/down position
 res@gsnRightStringOrthogonalPosF  = 0.05  ; Right string up/down position

; Text size

 res@gsnLeftStringFontHeightF   = 0.012 ; Left string font size
 res@gsnCenterStringFontHeightF = 0.020 ; Center string font size
 res@gsnRightStringFontHeightF  = 0.012 ; Right string font size

; Axes text size and stride

 res@tmXBLabelFontHeightF = 0.014  ; X-axis font height, default=0.02
 res@tmYLLabelFontHeightF = 0.014  ; Y-axis font height, default=0.02
 res@gsnMajorLatSpacing   = 20     ; Latitude stride
 res@gsnMajorLonSpacing   = 30     ; Longitude stride

;------------------------------------------------
; Color and label bar specifications
;------------------------------------------------

; Colors

 gsn_define_colormap(wks,""+ColorTableName+"")  ; Set at beginning of script by ColorTable
 ReverseColorTable = False                  ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if
 res@lbLabelBarOn         = True             ; True turns on label bar            
 res@gsnSpreadColors      = False            ; if True, reduces colors used from color table
 res@gsnSpreadColorStart  = 2; 20              ; Index to start with: default=2
 res@gsnSpreadColorEnd    = -2;-20              ; Index to end with: default=-1

; Label Bar Style

 res@pmLabelBarOrthogonalPosF = 0.08               ; Up and down position of label bar, default=0.02
 res@lbOrientation            = "horizontal"       ; Orientation of label bar: "horizontal" or "vertical"
 res@lbLabelStride            = 2                  ; How many labels to skip
 res@lbBoxEndCapStyle         = "TriangleBothEnds" ; What shape to have at the ends of the label bar, options are:
                                               ; "TriangleBothEnds", "TriangleLowEnd", "TriangleHighEnd", "RectangleEnds"
; Label Text

 res@lbLabelFontHeightF = 0.01   ; Size of label font, default=0.02
 res@lbLabelAngleF      = 0      ; Angle of the label text, default=0.0
 res@lbLabelFont        = 21     ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

; Label Bar Title Text - displays units

 res@lbTitleString      = "~F21~"+UNITS+"" ; Label bar title text string
 res@lbTitlePosition    = "Right"          ; Where to place label bar title text string
                                       ; "Top","Bottom","Left","Right"
 res@lbTitleDirection   = "Across"         ; Direction of title text: "Across" or "Down"
 res@lbTitleFont        = 21               ; Title font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@lbTitleFontHeightF = 0.012            ; Title font size, default=0.025

;------------------------------------------------
; Plot tick marks
;------------------------------------------------

 res@tmXBLabelFont = 21  ; X-axis tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@tmYLLabelFont = 21  ; Y-axis tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

 res@tmXBMinorOn = True  ; Draws X-axis minor ticks
 res@tmYLMinorOn = True  ; Draws Y-axis minor ticks

 res@pmTickMarkDisplayMode = "Never"  ; "Always" draws ° but reduces custom options

;------------------------------------------------
; Figure size
;------------------------------------------------

 res@vpWidthF  = 0.7  ; How far the figure stretches horizontally, default=0.6
 res@vpHeightF = 0.6  ; How far the figure stretches vertically, default=0.6
 res@vpXF      = 0.2  ; Where the figure begins horizontally, default=0.2
 res@vpYF      = 0.85 ; Where the figure begins vertically, default=0.8

 res@gsnPaperOrientation = "Portrait"  ; Orientation of plot: "Portrait", "Landscape", or default="auto"
 res@gsnMaximize = True                ; Maximizes plot to workstation

;*************************************************************
; Make the plot - unwgt/wgted isotope plots based on if/then
;*************************************************************

;----------------------------------------
; Absolute value map plots
;----------------------------------------

 res@gsnCenterString = cases(0)
 plot1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case1_flip,res)

 res@gsnCenterString = cases(1)
 plot2 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case2_flip,res)

 res@gsnCenterString = cases(2)
 plot3 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case3_flip,res)

 res@gsnCenterString = cases(3)
 plot4 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case4_flip,res)

 res@gsnCenterString = cases(4)
 plot5 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case5_flip,res)

 res@gsnCenterString = cases(5)
 plot6 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case6_flip,res)

 res@gsnCenterString = cases(6)
 plot7 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case7_flip,res)

 res@gsnCenterString = cases(7)
 plot8 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case8_flip,res)

 res@gsnCenterString = cases(8)
 plot9 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case9_flip,res)

 res@gsnCenterString = cases(9)
 plot10 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case10_flip,res)

 res@gsnCenterString = cases(10)
 plot11 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case11_flip,res)

 res@gsnCenterString = cases(11)
 plot12 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case12_flip,res)

;------------------------------------
; Difference plots
;------------------------------------

; Set the difference contour levels

 gsn_define_colormap(wks,""+ColorTableNameDif+"")
 ReverseColorTable = False                 ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if

 if (ManLevDif .eq. 1) then
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMaxLevelValF       =  dif_hival
   res@cnMinLevelValF       =  dif_loval
   res@cnLevelSpacingF      =  dif_spval
 end if

  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case2_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case3_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(3)+"-"+cases(0)+""
  diff_4_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case4_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(4)+"-"+cases(0)+""
  diff_5_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case5_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(5)+"-"+cases(0)+""
  diff_6_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case6_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(6)+"-"+cases(0)+""
  diff_7_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case7_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(7)+"-"+cases(0)+""
  diff_8_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case8_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(8)+"-"+cases(0)+""
  diff_9_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case9_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(9)+"-"+cases(0)+""
  diff_10_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case10_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(10)+"-"+cases(0)+""
  diff_11_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case11_flip-iso_wt_avg_rooted_case1_flip,res)

  res@gsnCenterString = ""+cases(11)+"-"+cases(0)+""
  diff_12_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_rooted_case12_flip-iso_wt_avg_rooted_case1_flip,res)

end
