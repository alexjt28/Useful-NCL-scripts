;-------------------------------------------------------------------------------------------------------------------
; This script reads in variables from a climatology netCDF file and produces a map plot of each case's average
; values and differences between cases. This script specifically lets the user specify the grid cells with which 
; to plot data. This is especially useful for comparisons to paleoproxy databases. Functionality for weighting by 
; length of month is included. This script includes functionality for calculating values from twelve (5) separate 
; cases; however, it can be easily modified to increase/decrease this number.
;
; Author: Alex Thompson
; Date: 7/29/2022
;-------------------------------------------------------------------------------------------------------------------

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
 CASE5  = "[CASE6 filepath]"
 CASE5  = "[CASE7 filepath]"
 CASE5  = "[CASE8 filepath]"
 CASE5  = "[CASE9 filepath]"
 CASE5  = "[CASE10 filepath]"
 CASE5  = "[CASE11 filepath]"
 CASE5  = "[CASE12 filepath]"

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

;------------------------------------------------
; Specify the fields and properties here
;------------------------------------------------ 

; Which variable(s) to plot? Can perform math operations on these variables 

 VAR1 = "TREFHT"
 VAR2 = ""

; What are the units of the variable?
 UNITS = "K"

; Which Math operation to perform if there are two variables? 
 MATH = "" ; options:  "add"->VAR1+VAR2, "sub"->VAR1-VAR2, "mul"->VAR1*VAR2, "div"->VAR1/VAR2

; Plot at a specific atmospheric pressure level? Specify value in hPa (ex. "850") or leave blank ("")
 LEVEL = ""

 ; Define pressure levels with this array
  lev_p = ispan(0,1000,50)  ; ex. Pressure array goes from 0 hPa to 1000 hPa by 50 hPa
  lev_p!0         = "lev_p"                  ; variable/dim name
  lev_p&lev_p     =  lev_p                   ; create coordinate variable
  lev_p@long_name = "pressure"               ; attach some attributes
  lev_p@units     = "hPa"
  lev_p@positive  = "down"
  lev_ind = ind(lev_p .eq. LEVEL) ; lev_ind converts LEVEL into the corresponding index of lev_p 

; Do you want to scale the variables by a certain factor?
 MULT = 1.0 

; If you need to plot soil water...
 SOIL_LEV = 8 

;--------------------------------------------------------------
; Do you want to overlay wind vectors?
;--------------------------------------------------------------

 OVERLAY_WIND = "No"

 WIND_LEVEL   = "200"                      ; Text string in hPa
 WIND_UNITS   = "m/s"                      ; Text string
 wind_lev_ind = ind(lev_p .eq. WIND_LEVEL) ; wind_lev_ind converts WIND_LEVEL to the corresponding index of lev_p

;--------------------------------------------------------------
; Do you want to print out the average over a specified region?
;--------------------------------------------------------------

; Latitude:  +=north, -=south
; Longitude: 0-180=E, 180-360=W (when indexing using lon_flip)

; Do you want a global average?
 Global = "Yes"

; Do you want an average over a specific region?
 Region = "Yes"

 southlat =  21.7
 northlat =  37.0
 westlon  = 245.0
 eastlon  = 260.0

; Do you want an average at a specific grid point?
 Point = "No"

 latpoint = 20.0
 lonpoint = 10.0

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = "pdfs/"+SEASON+"_year"+YEARS+"_"+VAR1+""+MATH+""+VAR2+"_"+LEVEL+"_winds"+OVERLAY_WIND+""+WIND_LEVEL+"_"+name+""

;-----------------------------------------------------------
; Specify contour levels for absolute and difference values
;-----------------------------------------------------------

; Manual Levels for absolute contour plotting (1=ON, 0=OFF) 
 ManLevAbs = 1      
 abs_hival = 310.0 
 abs_loval = 250.0
 abs_spval =   5.0

; Manual Levels for difference contour plotting (1=ON, 0=OFF)
 ManLevDif = 1
 dif_hival = 5.0 
 dif_loval = -5.0
 dif_spval = 1.0

;---------------------------------------------
; Zoom into any world region in particular?
;---------------------------------------------

 World = 1  ; 1=entire world, 0=zoomed in to coordinate values in second block 

 if (World .eq. 1) then
  LatMin = -90
  LatMax = 90
  LonMin = -180
  LonMax = 180
 else
  LatMin = 0; -60  ; negative values = °S
  LatMax = 50;  80; 40   ; positive values = °N
  LonMin = -140; -100; -90  ; negative values = °W
  LonMax = -50; -20; 60   ; positive values = °E
 end if

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

;-------------------------------------------------
; Important plot specifications to set here
;-------------------------------------------------

 ColorTableName = "cmp_haxby" ; "MPL_BrBG" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 ColorTableNameDif = "BlueYellowRed" ; "MPL_BrBG" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 LeftString     = "~F21~"+SEASON+" "+VAR1+""+MATH+""+VAR2+""
 CenterString   = ""
 RightString    = ""

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

 ; Read in variables and scale them

     fil = CASES(i-1) 
     ins = addfile(fil,"r")

   if (LEVEL .eq. "") then


     if (VAR1 .eq. "H2OSOI" .OR. VAR1 .eq. "TSOI") then
      var1      = ins->$VAR1$(begi:endi,:,:,:)
     else
      var1      = ins->$VAR1$(begi:endi,:,:)
     end if

     if (VAR1 .eq. "H2OSOI" .OR. VAR1 .eq. "TSOI") then
      var1_orig = var1(begi:endi,SOIL_LEV,:,:)*MULT
     else
      var1_orig = var1*MULT
     end if
     if (VAR2 .ne. "") then
      var2      = ins->$VAR2$(begi:endi,:,:)
      var2_orig = var2*MULT
     end if

     var1_time = var1_orig(:,:,:)
    if (VAR2 .ne. "") then
     var2_time = var2_orig(:,:,:)
    end if

    else if (LEVEL .ne. "") then
     
      var1      = ins->$VAR1$(begi:endi,:,:,:)
      var1_orig = var1*MULT
     if (VAR2 .ne. "") then
      var2      = ins->$VAR2$(begi:endi,:,:,:)
      var2_orig = var2*MULT
     end if

      ; Converts from sigma to pressure coordinates
       lev            = var1&lev
       numlevs_subone = dimsizes(lev)-1
       hybm1          = ins->hybm(0:numlevs_subone) ; hybm is the 'sigma' coordinate
       hyam1          = ins->hyam(0:numlevs_subone) ; create a bogus hyam 1D array
       P0             = ins->P0(0)
       P0mb           = P0*0.01
       ps1            = ins->PS   ; these are in Pa
       intyp          = 1

       var1_lev = vinth2p(var1_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var1_orig,var1_lev)
       var1_time = var1_lev(:,lev_ind,:,:)
      if (VAR2 .ne. "") then 
       var2_lev = vinth2p(var2_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var2_orig,var2_lev)
       var2_time = var2_lev(:,lev_ind,:,:)
      end if

     end if
     end if

;************************************************
; Define lat/lon and metadata for variables
;-----------------------------------------------*
; Loop continues here...
;-----------------------------------------------*
;************************************************

; Latitude and Longitude set here
 lat = var1&lat
 lon = var1&lon

; Variable metadata set here

   var1_time!0   = "time"
   var1_time!1   = "lat"
   var1_time!2   = "lon"
   var1_time&lat = lat
   var1_time&lon = lon
  if (VAR2 .ne. "") then
   var2_time!0   = "time"
   var2_time!1   = "lat"
   var2_time!2   = "lon"
   var2_time&lat = lat
   var2_time&lon = lon
  end if

;************************************************
; Perform math operator if necessary
;-----------------------------------------------*
; Loop continues here...
;-----------------------------------------------*
;************************************************

if (VAR2 .ne. "") then

 if (MATH .eq. "add") then
  var_time = var1_time + var2_time
 else if (MATH .eq. "sub") then
  var_time = var1_time - var2_time 
 else if (MATH .eq. "mul") then
  var_time = var1_time * var2_time
 else if (MATH .eq. "div") then
  var_time = var1_time / var2_time
 end if
 end if
 end if
 end if
 else

  var_time = var1_time

end if

;************************************************
; Average over entire time series
;-----------------------------------------------*
; Loop continues here...
;-----------------------------------------------*
;************************************************

; Convert to climatology if not already exists 
  var_months = clmMonTLL(var_time)

; Select months for average
  var_averg = dim_avg_wgt_n_Wrap(var_months(MON,:,:),wgt_mon,0,0)

;*********************************************************
; Define metadata for final variable and perform lonFlip
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

; Metadata

 var_averg!0   = "lat"
 var_averg!1   = "lon"
 var_averg&lat = lat
 var_averg&lon = lon

 var_hold = var_averg

;-------------------------------
; Specify grid cells to include
;_______________________________

 coords_in = addfile("[filepath to file with 2d lat and lon, such as variables LATIXY and LONGXY]","r")
 lat2d     = coords_in->LATIXY
 lon2d     = coords_in->LONGXY

 latval = (/ 31.43,   32.08,   33.5 /)  ; example lats
 lonval = (/ -110.5, -105.2, -105.2 /)  ; example lons

 nm = getind_latlon2d(lat2d,lon2d,latval,lonval)
 lats = nm(:,0)
 lons = nm(:,1)

 ;print(lats)
 ;print(lons)
 
 var_averg = var_averg@_FillValue

 do z=0,dimsizes(lats)-1
   var_averg(lats(z),lons(z)) = var_hold(lats(z),lons(z))
 end do

; lonFlip

 lon_flip       = lonFlip(lon)
 var_averg_flip = lonFlip(var_averg)

;*********************************************************
; Read in wind vectors if necessary
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

if (OVERLAY_WIND .eq. "Yes") then

 ; Read in variables
 u_prelev = ins->U(begi:endi,:,:,:)
 v_prelev = ins->V(begi:endi,:,:,:)

 ; Convert from sigma to pressure
 if (WIND_LEVEL .ne. "")
  wlev            = u_prelev&lev
  wnumlevs_subone = dimsizes(wlev)-1
  whybm1          = ins->hybm(0:wnumlevs_subone) ; hybm is the 'sigma' coordinate
  whyam1          = ins->hyam(0:wnumlevs_subone) ; create a bogus hyam 1D array
  wP0             = ins->P0(0)
  wP0mb           = wP0*0.01
  wps1            = ins->PS(begi:endi,:,:)   ; these are in Pa
  wintyp          = 1
  ulev = vinth2p(u_prelev,whyam1,whybm1,lev_p,wps1,wintyp,wP0mb,1,False)
  copy_VarAtts(u_prelev,ulev)
  vlev = vinth2p(v_prelev,whyam1,whybm1,lev_p,wps1,wintyp,wP0mb,1,False)
  copy_VarAtts(v_prelev,vlev)
 end if

 ; Calculate climatology
 U_seas = clmMonTLL(ulev(:,wind_lev_ind,:,:))
 V_seas = clmMonTLL(vlev(:,wind_lev_ind,:,:))

 ; Take pressure level and average
 U = dim_avg_wgt_n_Wrap(U_seas(MON,:,:),wgt_mon,0,0)
 V = dim_avg_wgt_n_Wrap(V_seas(MON,:,:),wgt_mon,0,0)

 ; lonFlip
 U_flip = lonFlip(U)
 V_flip = lonFlip(V)

end if

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
 printVarSummary(var1_orig)
 printVarSummary(var1_time)
 printVarSummary(var_averg)
 printVarSummary(var_averg_flip)
 if (OVERLAY_WIND .eq. "Yes") then
 printVarSummary(U_flip)
 end if
 print("**************************")
 print("End loop for CASE"+i+"...")
 print("**************************")

;-----------------------------------------------------------
; Saved variables are of the following dimensions:
;
; var1_orig      -> (time,lat,lon) or (time,lev,lat,lon)
; var1_time      -> (time,lat,lon)
; var_years      -> (yrs,lat,lon)
; var_averg      -> (lat,lon)
; var_averg_flip -> (lat,lon_flip)
; U/V_flip       -> (lat,lon_flip) (if necessary)
;
;-----------------------------------------------------------

 ; Save corresponding variables
   if (i .eq. 1) then
     var1_orig_case1 = var1_orig
     var1_time_case1 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case1 = var2_orig
     var2_time_case1 = var2_time
    end if
     var_averg_case1      = var_averg
     var_averg_case1_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case1      = U
     V_case1      = V
     U_case1_flip = U_flip
     V_case1_flip = V_flip
    end if
   end if

   if (i .eq. 2) then
     var1_orig_case2 = var1_orig
     var1_time_case2 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case2 = var2_orig
     var2_time_case2 = var2_time
    end if
     var_averg_case2      = var_averg
     var_averg_case2_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case2      = U
     V_case2      = V
     U_case2_flip = U_flip
     V_case2_flip = V_flip
    end if
   end if

   if (i .eq. 3) then
     var1_orig_case3 = var1_orig
     var1_time_case3 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case3 = var2_orig
     var2_time_case3 = var2_time
    end if
     var_averg_case3      = var_averg
     var_averg_case3_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case3      = U
     V_case3      = V
     U_case3_flip = U_flip
     V_case3_flip = V_flip
    end if
   end if

   if (i .eq. 4) then
     var1_orig_case4 = var1_orig
     var1_time_case4 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case4 = var2_orig
     var2_time_case4 = var2_time
    end if
     var_averg_case4      = var_averg
     var_averg_case4_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case4      = U
     V_case4      = V
     U_case4_flip = U_flip
     V_case4_flip = V_flip
    end if
   end if

   if (i .eq. 5) then
     var1_orig_case5 = var1_orig
     var1_time_case5 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case5 = var2_orig
     var2_time_case5 = var2_time
    end if
     var_averg_case5      = var_averg
     var_averg_case5_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case5      = U
     V_case5      = V
     U_case5_flip = U_flip
     V_case5_flip = V_flip
    end if
   end if

   if (i .eq. 6) then
     var1_orig_case6 = var1_orig
     var1_time_case6 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case6 = var2_orig
     var2_time_case6 = var2_time
    end if
     var_averg_case6      = var_averg
     var_averg_case6_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case6      = U
     V_case6      = V
     U_case6_flip = U_flip
     V_case6_flip = V_flip
    end if
   end if

   if (i .eq. 7) then
     var1_orig_case7 = var1_orig
     var1_time_case7 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case7 = var2_orig
     var2_time_case7 = var2_time
    end if
     var_averg_case7      = var_averg
     var_averg_case7_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case7      = U
     V_case7      = V
     U_case7_flip = U_flip
     V_case7_flip = V_flip
    end if
   end if

   if (i .eq. 8) then
     var1_orig_case8 = var1_orig
     var1_time_case8 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case8 = var2_orig
     var2_time_case8 = var2_time
    end if
     var_averg_case8      = var_averg
     var_averg_case8_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case8      = U
     V_case8      = V
     U_case8_flip = U_flip
     V_case8_flip = V_flip
    end if
   end if

   if (i .eq. 9) then
     var1_orig_case9 = var1_orig
     var1_time_case9 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case9 = var2_orig
     var2_time_case9 = var2_time
    end if
     var_averg_case9      = var_averg
     var_averg_case9_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case9      = U
     V_case9      = V
     U_case9_flip = U_flip
     V_case9_flip = V_flip
    end if
   end if

   if (i .eq. 10) then
     var1_orig_case10 = var1_orig
     var1_time_case10 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case10 = var2_orig
     var2_time_case10 = var2_time
    end if
     var_averg_case10      = var_averg
     var_averg_case10_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case10      = U
     V_case10      = V
     U_case10_flip = U_flip
     V_case10_flip = V_flip
    end if
   end if

   if (i .eq. 11) then
     var1_orig_case11 = var1_orig
     var1_time_case11 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case11 = var2_orig
     var2_time_case11 = var2_time
    end if
     var_averg_case11      = var_averg
     var_averg_case11_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case11      = U
     V_case11      = V
     U_case11_flip = U_flip
     V_case11_flip = V_flip
    end if
   end if

   if (i .eq. 12) then
     var1_orig_case12 = var1_orig
     var1_time_case12 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case12 = var2_orig
     var2_time_case12 = var2_time
    end if
     var_averg_case12      = var_averg
     var_averg_case12_flip = var_averg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case12      = U
     V_case12      = V
     U_case12_flip = U_flip
     V_case12_flip = V_flip
    end if
   end if

; If more than three cases, include another if/then here to accommodate...

; Now delete the unneeded variables

  delete([/fil,ins,var1,var1_orig,var1_time,var_months,var_averg,var_averg_flip/])
 if (VAR2 .ne. "") then
  delete([/var2,var2_orig,var2_time/])
 end if
 if (LEVEL .ne. "") then
  delete([/lev,numlevs_subone,hybm1,hyam1,P0,P0mb,ps1,intyp,var1_lev/])
   if (VAR2 .ne. "") then
     delete(var2_lev)
   end if
 end if
 if (OVERLAY_WIND .eq. "Yes") then
  delete([/u_prelev,v_prelev,wlev,wnumlevs_subone,whybm1,whyam1,wP0,wP0mb,wps1,wintyp,ulev,vlev,U_seas,V_seas,U,V,U_flip,V_flip/])
 end if

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
 print(lat)
 print(lon_flip)
;-----------
; Global
;-----------

if (Global .eq. "Yes") then

  print("Global average "+cases(0)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case1_flip,gw,1.0,0)+"")
  print("Global average "+cases(1)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case2_flip,gw,1.0,0)+"")
  print("Global average "+cases(2)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case3_flip,gw,1.0,0)+"")
  print("Global average "+cases(3)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case4_flip,gw,1.0,0)+"")
  print("Global average "+cases(4)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case5_flip,gw,1.0,0)+"")
  print("Global average "+cases(5)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case6_flip,gw,1.0,0)+"")
  print("Global average "+cases(6)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case7_flip,gw,1.0,0)+"")
  print("Global average "+cases(7)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case8_flip,gw,1.0,0)+"")
  print("Global average "+cases(8)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case9_flip,gw,1.0,0)+"")
  print("Global average "+cases(9)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case10_flip,gw,1.0,0)+"")
  print("Global average "+cases(10)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case11_flip,gw,1.0,0)+"")
  print("Global average "+cases(11)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+wgt_areaave_Wrap(var_averg_case12_flip,gw,1.0,0)+"")
 
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

print("Northern NAM region")

 print(""+SEASON+" "+cases(0)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case1_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))  

 if (numcases .ge. 2) then
 print(""+SEASON+" "+cases(1)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case2_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

 if (numcases .ge. 3) then
 print(""+SEASON+" "+cases(2)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case3_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

 if (numcases .ge. 4) then
 print(""+SEASON+" "+cases(3)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case4_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

 if (numcases .ge. 5) then
 print(""+SEASON+" "+cases(4)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case5_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

 if (numcases .ge. 6) then
 print(""+SEASON+" "+cases(5)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case6_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

  if (numcases .ge. 7) then
 print(""+SEASON+" "+cases(6)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case7_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

  if (numcases .ge. 8) then
 print(""+SEASON+" "+cases(7)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case8_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

  if (numcases .ge. 9) then
 print(""+SEASON+" "+cases(8)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case9_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

  if (numcases .ge. 10) then
 print(""+SEASON+" "+cases(9)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case10_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

  if (numcases .ge. 11) then
 print(""+SEASON+" "+cases(10)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case11_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

  if (numcases .ge. 12) then
 print(""+SEASON+" "+cases(11)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case12_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
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

 print(""+cases(0)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(var_averg_case1_flip(lat_point,lon_point)))

 if (numcases .ge. 2) then
 print(""+cases(1)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(var_averg_case2_flip(lat_point,lon_point)))
 end if

 if (numcases .ge. 3) then
 print(""+cases(2)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(var_averg_case3_flip(lat_point,lon_point)))
 end if

 if (numcases .ge. 4) then
 print(""+cases(3)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(var_averg_case4_flip(lat_point,lon_point)))
 end if

 if (numcases .ge. 5) then
 print(""+cases(4)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(var_averg_case5_flip(lat_point,lon_point)))
 end if

 if (numcases .ge. 6) then
 print(""+cases(5)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(var_averg_case6_flip(lat_point,lon_point)))
 end if

 lon_flip_fix = lon_flip
 do z=0,dimsizes(lon_flip)-1
 if (lon_flip(z) .gt. 179.0) then
   lon_flip_fix(z) = lon_flip(z)-360
 end if
end do

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
 res@cnFillMode     = "RasterFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
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
 ReverseColorTable = False         ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if
 res@lbLabelBarOn         = True             ; True turns on label bar
 res@gsnSpreadColors      = False             ; if True, reduces colors used from color table
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

;----------------------------------
; Wind vector specifications
;----------------------------------

if (OVERLAY_WIND .eq. "Yes") then

 vcRefMagnitudeF = 5.0   ; Define reference vector magnitude, default=0.0

 res@gsnScalarContour        = True                                 ; True sets wind scalars
 res@mpFillOn                = False                                ; True disables wind values over continents, False enables them
 res@vcRefAnnoOrthogonalPosF = -1.0 ;(top right)                    ; Move ref vector up/down, default=0.02
 res@vcRefMagnitudeF         = vcRefMagnitudeF                      ; Define reference vector magnitude, default=0.0
 res@vcRefLengthF            = 0.045                                ; Define length of reference vector
 res@vcGlyphStyle            = "CurlyVector"                        ; "CurlyVector"(best), "LineArrow", "FillArrow", "WindBarb"
 res@vcRefAnnoFont           = 21                                   ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@vcRefAnnoFontHeightF    = 0.01                                 ; Font height for reference vector label
 res@vcRefAnnoString1        = ""+vcRefMagnitudeF+" "+WIND_UNITS+"" ; Reference vector label string
 res@vcMinDistanceF          = 0.017                                ; Distance between wind vectors, default=0.0

end if

;------------------------------------------------
; Figure size
;------------------------------------------------

 res@vpWidthF  = 0.7  ; How far the figure stretches horizontally, default=0.6
 res@vpHeightF = 0.6  ; How far the figure stretches vertically, default=0.6
 res@vpXF      = 0.2  ; Where the figure begins horizontally, default=0.2
 res@vpYF      = 0.85 ; Where the figure begins vertically, default=0.8

 res@gsnPaperOrientation = "Portrait"  ; Orientation of plot: "Portrait", "Landscape", or default="auto"
 res@gsnMaximize = True                ; Maximizes plot to workstation

;***********************************************************
; Make the plot
;***********************************************************

;----------------------------------------
; Absolute value map plots
;----------------------------------------

if (OVERLAY_WIND .eq. "No") then

 res@gsnCenterString = cases(0)
 plot1 = gsn_csm_contour_map_ce(wks,var_averg_case1_flip,res)

 res@gsnCenterString = cases(1)
 plot2 = gsn_csm_contour_map_ce(wks,var_averg_case2_flip,res)

 res@gsnCenterString = cases(2)
 plot3 = gsn_csm_contour_map_ce(wks,var_averg_case3_flip,res)

 res@gsnCenterString = cases(3)
 plot4 = gsn_csm_contour_map_ce(wks,var_averg_case4_flip,res)

 res@gsnCenterString = cases(4)
 plot5 = gsn_csm_contour_map_ce(wks,var_averg_case5_flip,res)

 res@gsnCenterString = cases(5)
 plot6 = gsn_csm_contour_map_ce(wks,var_averg_case6_flip,res)

 res@gsnCenterString = cases(6)
 plot7 = gsn_csm_contour_map_ce(wks,var_averg_case7_flip,res)

 res@gsnCenterString = cases(7)
 plot8 = gsn_csm_contour_map_ce(wks,var_averg_case8_flip,res)

 res@gsnCenterString = cases(8)
 plot9 = gsn_csm_contour_map_ce(wks,var_averg_case9_flip,res)

 res@gsnCenterString = cases(9)
 plot10 = gsn_csm_contour_map_ce(wks,var_averg_case10_flip,res)

 res@gsnCenterString = cases(10)
 plot11 = gsn_csm_contour_map_ce(wks,var_averg_case11_flip,res)

 res@gsnCenterString = cases(11)
 plot12 = gsn_csm_contour_map_ce(wks,var_averg_case12_flip,res)

else

 res@gsnCenterString = cases(0)
 plot1 = gsn_csm_vector_scalar_map(wks,U_case1_flip,V_case1_flip,var_averg_case1_flip,res)

 res@gsnCenterString = cases(1)
 plot2 = gsn_csm_vector_scalar_map(wks,U_case2_flip,V_case2_flip,var_averg_case2_flip,res)

 res@gsnCenterString = cases(2)
 plot3 = gsn_csm_vector_scalar_map(wks,U_case3_flip,V_case3_flip,var_averg_case3_flip,res)

 res@gsnCenterString = cases(3)
 plot4 = gsn_csm_vector_scalar_map(wks,U_case4_flip,V_case4_flip,var_averg_case4_flip,res)

 res@gsnCenterString = cases(4)
 plot5 = gsn_csm_vector_scalar_map(wks,U_case5_flip,V_case5_flip,var_averg_case5_flip,res)

 res@gsnCenterString = cases(5)
 plot6 = gsn_csm_vector_scalar_map(wks,U_case6_flip,V_case6_flip,var_averg_case6_flip,res)

 res@gsnCenterString = cases(6)
 plot7 = gsn_csm_vector_scalar_map(wks,U_case7_flip,V_case7_flip,var_averg_case7_flip,res)

 res@gsnCenterString = cases(7)
 plot8 = gsn_csm_vector_scalar_map(wks,U_case8_flip,V_case8_flip,var_averg_case8_flip,res)

 res@gsnCenterString = cases(8)
 plot9 = gsn_csm_vector_scalar_map(wks,U_case9_flip,V_case9_flip,var_averg_case9_flip,res)

 res@gsnCenterString = cases(9)
 plot10 = gsn_csm_vector_scalar_map(wks,U_case10_flip,V_case10_flip,var_averg_case10_flip,res)

 res@gsnCenterString = cases(10)
 plot11 = gsn_csm_vector_scalar_map(wks,U_case11_flip,V_case11_flip,var_averg_case11_flip,res)

 res@gsnCenterString = cases(11)
 plot12 = gsn_csm_vector_scalar_map(wks,U_case12_flip,V_case12_flip,var_averg_case12_flip,res)

end if

;------------------------------------
; Difference plots
;------------------------------------

; Set the difference contour levels

 gsn_define_colormap(wks,""+ColorTableNameDif+"")
 ReverseColorTable = False          ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if

 if (ManLevDif .eq. 1) then
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMaxLevelValF       =  dif_hival
   res@cnMinLevelValF       =  dif_loval
   res@cnLevelSpacingF      =  dif_spval
 end if

if (OVERLAY_WIND .eq. "No") then

  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_contour_map_ce(wks,var_averg_case2_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_contour_map_ce(wks,var_averg_case3_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(3)+"-"+cases(0)+""
  diff_4_1 = gsn_csm_contour_map_ce(wks,var_averg_case4_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(4)+"-"+cases(0)+""
  diff_5_1 = gsn_csm_contour_map_ce(wks,var_averg_case5_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(5)+"-"+cases(0)+""
  diff_6_1 = gsn_csm_contour_map_ce(wks,var_averg_case6_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(6)+"-"+cases(0)+""
  diff_7_1 = gsn_csm_contour_map_ce(wks,var_averg_case7_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(7)+"-"+cases(0)+""
  diff_8_1 = gsn_csm_contour_map_ce(wks,var_averg_case8_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(8)+"-"+cases(0)+""
  diff_9_1 = gsn_csm_contour_map_ce(wks,var_averg_case9_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(9)+"-"+cases(0)+""
  diff_10_1 = gsn_csm_contour_map_ce(wks,var_averg_case10_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(10)+"-"+cases(0)+""
  diff_11_1 = gsn_csm_contour_map_ce(wks,var_averg_case11_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(11)+"-"+cases(0)+""
  diff_12_1 = gsn_csm_contour_map_ce(wks,var_averg_case12_flip-var_averg_case1_flip,res)

else

  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_vector_scalar_map(wks,U_case2_flip-U_case1_flip,V_case2_flip-V_case1_flip,var_averg_case2_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_vector_scalar_map(wks,U_case3_flip-U_case1_flip,V_case3_flip-V_case1_flip,var_averg_case3_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(3)+"-"+cases(0)+""
  diff_4_1 = gsn_csm_vector_scalar_map(wks,U_case4_flip-U_case1_flip,V_case4_flip-V_case1_flip,var_averg_case4_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(4)+"-"+cases(0)+""
  diff_5_1 = gsn_csm_vector_scalar_map(wks,U_case5_flip-U_case1_flip,V_case5_flip-V_case1_flip,var_averg_case5_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(5)+"-"+cases(0)+""
  diff_6_1 = gsn_csm_vector_scalar_map(wks,U_case6_flip-U_case1_flip,V_case6_flip-V_case1_flip,var_averg_case6_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(6)+"-"+cases(0)+""
  diff_7_1 = gsn_csm_vector_scalar_map(wks,U_case7_flip-U_case1_flip,V_case7_flip-V_case1_flip,var_averg_case7_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(7)+"-"+cases(0)+""
  diff_8_1 = gsn_csm_vector_scalar_map(wks,U_case8_flip-U_case1_flip,V_case8_flip-V_case1_flip,var_averg_case8_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(8)+"-"+cases(0)+""
  diff_9_1 = gsn_csm_vector_scalar_map(wks,U_case9_flip-U_case1_flip,V_case9_flip-V_case1_flip,var_averg_case9_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(9)+"-"+cases(0)+""
  diff_10_1 = gsn_csm_vector_scalar_map(wks,U_case10_flip-U_case1_flip,V_case10_flip-V_case1_flip,var_averg_case10_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(10)+"-"+cases(0)+""
  diff_11_1 = gsn_csm_vector_scalar_map(wks,U_case11_flip-U_case1_flip,V_case11_flip-V_case1_flip,var_averg_case11_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(11)+"-"+cases(0)+""
  diff_12_1 = gsn_csm_vector_scalar_map(wks,U_case12_flip-U_case1_flip,V_case12_flip-V_case1_flip,var_averg_case12_flip-var_averg_case1_flip,res)

end if

end
