;-------------------------------------------------------------------------------------------------------------------
; This script reads in variables from a climatology netCDF file and produces a map plot of each case's average
; values and differences between cases, specifically including integrated vapor transport in this script. 
; Functionality for weighting by length of month is included. This script includes functionality for calculating 
; values from five (5) separate cases; however, it can be easily modified to increase/decrease this number.
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

 CASES = (/ CASE1, CASE2, CASE3, CASE4, CASE5 /)

 cases = (/ "case1", "case2", "case3", "case4", "case5" /)

; Is there a special name for these cases to include in the output file name?
 name = "_5cases"

 numcases = 5

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

 VAR0 = "PRECC" ; this is what is plot behind VIMF in contours, need to change code if I change this from Q
 VARL = "PRECL"
 VAR1 = "U"
 VAR2 = "V"
 VAR3 = "Q"

; Top and bottom levels for taking vertical integration over
 top_level = 50.
 sfc_level = 1018.

; What are the units of the variable?
 UNITS = "mm/day"

; Which Math operation to perform if there are two variables? 
 MATH1 = "add"   ; options:  "add"->VAR1+VAR2, "sub"->VAR1-VAR2, "mul"->VAR1*VAR2, "div"->VAR1/VAR2

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
 MULT0 = 86400000.0; 86400000.0  ; this factor turns m/s into mm/day
 MULTL = 86400000.0  ; this factor turns m/s into mm/day
 MULT1 = 1.0  ; this factor turns m/s into mm/day
 MULT2 = 1.0  ; this factor turns m/s into mm/day
 MULT3 = 1.0  ; this factor turns m/s into mm/day

; If you need to plot soil water...
 SOIL_LEV = 0 

;--------------------------------------------------------------
; Do you want to print out the average over a specified region?
;--------------------------------------------------------------

; Latitude:  +=north, -=south
; Longitude: 0-180=E, 180-360=W (when indexing using lon_flip)

; Do you want a global average?
 Global = "Yes"

; Do you want an average over a specific region?
 Region = "Yes"

 southlat = 14.0
 northlat = 23.0
 westlon  = 267.5
 eastlon  = 272.5

; Do you want an average at a specific grid point?
 Point = "No"

 latpoint = 16.0
 lonpoint = 270.0

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = "pdfs/"+SEASON+"_year"+YEARS+"_IVT_and_"+VAR0+MATH1+VARL+"_"+sfc_level+"-"+top_level+"hPa_"+name+""

;-----------------------------------------------------------
; Specify contour levels for absolute and difference values
;-----------------------------------------------------------

; Manual Levels for absolute contour plotting (1=ON, 0=OFF) 
 ManLevAbs = 1      
 abs_hival = 8.0
 abs_loval = 0.0
 abs_spval = 0.5

; Manual Levels for difference contour plotting (1=ON, 0=OFF)
 ManLevDif = 1
 dif_hival = 5.0 
 dif_loval = -5.0 
 dif_spval = 0.5

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
  LatMin =  -40  ; negative values = °S
  LatMax =   90  ; positive values = °N
  LonMin = -150  ; negative values = °W
  LonMax =   60  ; positive values = °E
 end if

;-----------------------------
; Monthly weights
;-----------------------------

; 0ka
wgt_00ka = (/ 0.08493151, 0.076712325, 0.08493151, 0.08219178, 0.08493151, 0.08219178, 0.08493151, 0.08493151, 0.08219178, 0.08493151, 0.08219178, 0.08493151 /)

; 21ka
wgt_21ka = (/ 0.084931507, 0.076712329, 0.084931507, 0.082191781, 0.084931507, 0.082191781, 0.084931507, 0.084931507, 0.082191781, 0.084931507, 0.082191781, 0.084931507 /)

if (SEASON .eq. "ANN") then
  wgt_mon_1  = wgt_00ka
  wgt_mon_2  = wgt_21ka
  wgt_mon_3  = wgt_21ka
  wgt_mon_4  = wgt_21ka
  wgt_mon_5  = wgt_21ka
else
  wgt_mon_1  = wgt_00ka(MON)/sum(wgt_00ka(MON))
  wgt_mon_2  = wgt_21ka(MON)/sum(wgt_21ka(MON))
  wgt_mon_3  = wgt_21ka(MON)/sum(wgt_21ka(MON))
  wgt_mon_4  = wgt_21ka(MON)/sum(wgt_21ka(MON))
  wgt_mon_5  = wgt_21ka(MON)/sum(wgt_21ka(MON))
end if

;-------------------------------------------------
; Important plot specifications to set here
;-------------------------------------------------

 ColorTableName = "cmp_haxby"        ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 ColorTableNameDif = "BlueYellowRed" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 LeftString     = "~F21~"+SEASON+" IVT and "+VAR0+MATH1+VARL
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
end if
end if
end if
end if
end if

; Read in variables and scale them

     fil = CASES(i-1)
     ins = addfile(fil,"r")

      var1      = ins->$VAR1$(begi:endi,:,:,:)  ; U
     if (VAR1 .eq. "H2OSOI") then
      var1_orig = var1(:,SOIL_LEV,:,:)*MULT1
     else
      var1_orig = var1*MULT1
     end if
     if (VAR2 .ne. "") then
      var2      = ins->$VAR2$(begi:endi,:,:,:)  ; V
      var2_orig = var2*MULT2
     end if
     if (VAR3 .ne. "") then
      var3      = ins->$VAR3$(begi:endi,:,:,:)  ; Q
      var3_orig = var3*MULT3
     end if
     if (LEVEL .ne. "" .OR. VAR0 .eq. "Q") then
      var0      = ins->$VAR0$(begi:endi,:,:,:)  ; Q
      var0_orig = var0*MULT0
     else
      var0      = ins->$VAR0$(begi:endi,:,:)  ; Q
      var0_orig = var0*MULT0
     end if
     if (VARL .ne. "") then
      varL      = ins->$VARL$(begi:endi,:,:)
      varL_orig = varL*MULTL
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
       var1_time = var1_lev(:,:,:,:)
      if (VAR2 .ne. "") then
       var2_lev = vinth2p(var2_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var2_orig,var2_lev)
       var2_time = var2_lev(:,:,:,:)
      end if
      if (VAR3 .ne. "") then
       var3_lev = vinth2p(var3_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var3_orig,var3_lev)
       var3_time = var3_lev(:,:,:,:)
      end if

     if (LEVEL .ne. "" .or. VAR0 .eq. "Q") then
       var0_lev = vinth2p(var0_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var0_orig,var0_lev)
       var0_time = var0_lev(:,:,:,:) ; currently does not specify a layer
     else
       var0_time = var0_orig
       if (VARL .ne. "") then
         varL_time = varL_orig
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

   var1_time!0   = "time"  ; U
   var1_time!1   = "lev_p"
   var1_time!2   = "lat"
   var1_time!3   = "lon"
   var1_time&lev_p = lev_p
   var1_time&lat = lat
   var1_time&lon = lon
  if (VAR2 .ne. "") then
   var2_time!0   = "time"  ; V
   var2_time!1   = "lev_p"
   var2_time!2   = "lat"
   var2_time!3   = "lon"
   var2_time&lev_p = lev_p
   var2_time&lat = lat
   var2_time&lon = lon
  end if
  if (VAR3 .ne. "") then
   var3_time!0   = "time"  ; Q
   var3_time!1   = "lev_p"
   var3_time!2   = "lat"
   var3_time!3   = "lon"
   var3_time&lev_p = lev_p
   var3_time&lat = lat
   var3_time&lon = lon
  end if

 if (LEVEL .ne. "" .or. VAR0 .eq. "Q") then
  if (VAR0 .ne. "") then
   var0_time!0   = "time"  ; Q
   var0_time!1   = "lev_p"
   var0_time!2   = "lat"
   var0_time!3   = "lon"
   var0_time&lev_p = lev_p
   var0_time&lat = lat
   var0_time&lon = lon
  end if
 else
  if (VAR0 .ne. "") then
   var0_time!0   = "time"
   var0_time!1   = "lat"
   var0_time!2   = "lon"
   var0_time&lat = lat
   var0_time&lon = lon
  end if
  if (VARL .ne. "") then
   varL_time!0   = "time"
   varL_time!1   = "lat"
   varL_time!2   = "lon"
   varL_time&lat = lat
   varL_time&lon = lon

   ; Account for MATH1 if VARL exists
    if (MATH1 .eq. "add") then
     var0_time = var0_time + varL_time
    else if (MATH .eq. "sub") then
     var0_time = var0_time - varL_time
    else if (MATH .eq. "mul") then
     var0_time = var0_time * varL_time
    else if (MATH .eq. "div") then
     var0_time = var0_time / varL_time
    end if
    end if
    end if
    end if

  end if
 end if

;************************************************
; Perform math operator if necessary
;-----------------------------------------------*
; Loop continues here...
;-----------------------------------------------*
;************************************************

 U_months = clmMonTLLL(var1_time)
 V_months = clmMonTLLL(var2_time)
 Q_months = clmMonTLLL(var3_time)

 UQ_initial = U_months * Q_months
 VQ_initial = V_months * Q_months

 ptop = top_level;  700.
 psfc = sfc_level;  1018.
 psfc@units = "hPa"
 dp = dpres_plevel_Wrap(lev_p,psfc,ptop,0)

 ;print(dp)

 ; Weight each atmospheric layer by dp/g
 g = 9.8 ; m/s^2
 UQ_wgt = new((/12,dimsizes(lev_p),dimsizes(lat),dimsizes(lon)/),float)
 VQ_wgt = new((/12,dimsizes(lev_p),dimsizes(lat),dimsizes(lon)/),float)
  Q_wgt = new((/12,dimsizes(lev_p),dimsizes(lat),dimsizes(lon)/),float)
 do v=0,dimsizes(dp)-1
  UQ_wgt(:,v,:,:) = (100.*dp(v)/g)*(UQ_initial(:,v,:,:)) ; multiply by 100 for the hPa to Pa conversion
  VQ_wgt(:,v,:,:) = (100.*dp(v)/g)*(VQ_initial(:,v,:,:)) ; and this makes the final units work as kg/ms
 end do

; Sum across pressure levels
 var1_UQ_months = dim_sum_n_Wrap(UQ_wgt,1)
 var2_VQ_months = dim_sum_n_Wrap(VQ_wgt,1)

;************************************************
; Average over entire time series
;-----------------------------------------------*
; Loop continues here...
;-----------------------------------------------*
;************************************************

; Convert to climatology

if (LEVEL .ne. "" .OR. VAR0 .eq. "Q") then
 var0_months    = clmMonTLLL(var0_time)
else 
 var0_months    = clmMonTLL(var0_time)
end if

; Select months for average

 var1_UQ     = dim_avg_wgt_n_Wrap(var1_UQ_months(MON,:,:),wgt_mon,0,0) ; averages time
 var2_VQ     = dim_avg_wgt_n_Wrap(var2_VQ_months(MON,:,:),wgt_mon,0,0) ; averages time
if (LEVEL .ne. "" .OR. VAR0 .eq. "Q") then
 var0_levels = dim_avg_wgt_n_Wrap(var0_months(MON,:,:,:),wgt_mon,0,0)    ; averages time
else
 var0_levels = dim_avg_wgt_n_Wrap(var0_months(MON,:,:),wgt_mon,0,0)    ; averages time
end if

if (LEVEL .ne. "" .OR. VAR0 .eq. "Q") then
 var0_avg    = dim_sum_n_Wrap(var0_levels,0)               ; vertically-integrates pressure levels
else
 var0_avg = var0_levels
end if

;*********************************************************
; Define metadata for final variable and perform lonFlip
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

; Metadata

 var1_UQ!0   = "lat"
 var1_UQ!1   = "lon"
 var1_UQ&lat = lat
 var1_UQ&lon = lon
 var2_VQ!0   = "lat"
 var2_VQ!1   = "lon"
 var2_VQ&lat = lat
 var2_VQ&lon = lon
 var0_avg!0   = "lat"
 var0_avg!1   = "lon"
 var0_avg&lat = lat
 var0_avg&lon = lon

; lonFlip

 lon_flip       = lonFlip(lon)

 var1_UQ_flip = lonFlip(var1_UQ)
 var2_VQ_flip = lonFlip(var2_VQ)

 var1_flip = var1_UQ_flip
 var2_flip = var2_VQ_flip

 var0_flip = lonFlip(var0_avg)

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
 printVarSummary(var1)
 printVarSummary(var2)
 printVarSummary(var3)
 printVarSummary(var1_orig)
 printVarSummary(var1_time)
 printVarSummary(var0_flip)
 printVarSummary(var1_flip)
 printVarSummary(var2_flip)
 print("**************************")
 print("End loop for CASE"+i+"...")
 print("**************************")

;-----------------------------------------------------------
; Saved variables are of the following dimensions:
;-----------------------------------------------------------

; Save corresponding variables
   if (i .eq. 1) then
     var1_orig_case1 = var1_orig
     var1_time_case1 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case1 = var2_orig
     var2_time_case1 = var2_time
    end if
     var0_case1_flip = var0_flip
     var1_case1_flip = var1_flip
     var2_case1_flip = var2_flip
   end if

   if (i .eq. 2) then
     var1_orig_case2 = var1_orig
     var1_time_case2 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case2 = var2_orig
     var2_time_case2 = var2_time
    end if
     var0_case2_flip = var0_flip
     var1_case2_flip = var1_flip
     var2_case2_flip = var2_flip
   end if

   if (i .eq. 3) then
     var1_orig_case3 = var1_orig
     var1_time_case3 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case3 = var2_orig
     var2_time_case3 = var2_time
    end if
     var0_case3_flip = var0_flip
     var1_case3_flip = var1_flip
     var2_case3_flip = var2_flip
   end if

   if (i .eq. 4) then
     var1_orig_case4 = var1_orig
     var1_time_case4 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case4 = var2_orig
     var2_time_case4 = var2_time
    end if
     var0_case4_flip = var0_flip
     var1_case4_flip = var1_flip
     var2_case4_flip = var2_flip
   end if

   if (i .eq. 5) then
     var1_orig_case5 = var1_orig
     var1_time_case5 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case5 = var2_orig
     var2_time_case5 = var2_time
    end if
     var0_case5_flip = var0_flip
     var1_case5_flip = var1_flip
     var2_case5_flip = var2_flip
   end if

end do

;-------------------------------------------------*
; Loop is done.
;-------------------------------------------------*
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
 res@cnRasterSmoothingOn = True
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
 ReverseColorTable = True        ; Reverse color table order?
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

;------------------------------------------------
; Figure size
;------------------------------------------------

 res@vpWidthF  = 0.7  ; How far the figure stretches horizontally, default=0.6
 res@vpHeightF = 0.6  ; How far the figure stretches vertically, default=0.6
 res@vpXF      = 0.2  ; Where the figure begins horizontally, default=0.2
 res@vpYF      = 0.85 ; Where the figure begins vertically, default=0.8

 res@gsnPaperOrientation = "Portrait"  ; Orientation of plot: "Portrait", "Landscape", or default="auto"
 res@gsnMaximize = True                ; Maximizes plot to workstation

;------------------------------------------------
; Wind vector specifications
;------------------------------------------------

 WIND_UNITS = "kg m~S~-1~N~ s~S~-1~N~"

 gsnScalarContour        = True                                 ; True sets wind scalars
 mpFillOn                = False                                ; True disables wind values over continents, False enables them
 vcRefAnnoOrthogonalPosF = -1.0 ;(top right)                    ; Move ref vector up/down, default=0.02
 vcRefMagnitudeF         = 500.0                                  ; Define reference vector magnitude, default=0.0
 vcRefLengthF            = 0.045                                ; Define length of reference vector
 vcGlyphStyle            = "CurlyVector"                        ; "CurlyVector"(best), "LineArrow", "FillArrow", "WindBarb"
 vcRefAnnoFont           = 21                                   ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 vcRefAnnoFontHeightF    = 0.01                                 ; Font height for reference vector label
 vcRefAnnoString1        = ""+vcRefMagnitudeF+" "+WIND_UNITS+"" ; Reference vector label string
 vcMinDistanceF          = 0.017                                ; Distance between wind vectors, default=0.0

 res@gsnScalarContour        = gsnScalarContour
 res@mpFillOn                = mpFillOn
 res@vcRefAnnoOrthogonalPosF = vcRefAnnoOrthogonalPosF
 res@vcRefMagnitudeF         = vcRefMagnitudeF
 res@vcRefLengthF            = vcRefLengthF
 res@vcGlyphStyle            = vcGlyphStyle
 res@vcRefAnnoFont           = vcRefAnnoFont
 res@vcRefAnnoFontHeightF    = vcRefAnnoFontHeightF
 res@vcRefAnnoString1        = vcRefAnnoString1
 res@vcMinDistanceF          = vcMinDistanceF

; Difference plots change vcRefMagnitudeF

;***********************************************************
; Make the plot
;***********************************************************

;----------------------------------------
; Absolute value map plots
;----------------------------------------

 res@gsnCenterString = cases(0)
 plot1 = gsn_csm_vector_scalar_map(wks,var1_case1_flip,var2_case1_flip,var0_case1_flip,res)

 res@gsnCenterString = cases(1)
 plot2 = gsn_csm_vector_scalar_map(wks,var1_case2_flip,var2_case2_flip,var0_case2_flip,res)

 res@gsnCenterString = cases(2)
 plot3 = gsn_csm_vector_scalar_map(wks,var1_case3_flip,var2_case3_flip,var0_case3_flip,res)

 res@gsnCenterString = cases(3)
 plot4 = gsn_csm_vector_scalar_map(wks,var1_case4_flip,var2_case4_flip,var0_case4_flip,res)

 res@gsnCenterString = cases(4)
 plot5 = gsn_csm_vector_scalar_map(wks,var1_case5_flip,var2_case5_flip,var0_case5_flip,res)

;------------------------------------
; Difference plots
;------------------------------------

 vcRefMagnitudeF         = 100.0
 res@vcRefMagnitudeF     = vcRefMagnitudeF
 vcRefAnnoString1        = ""+vcRefMagnitudeF+" "+WIND_UNITS+"" ; Reference vector label string
 res@vcRefAnnoString1        = vcRefAnnoString1

; Set the difference contour levels

 gsn_define_colormap(wks,""+ColorTableNameDif+"")
 ReverseColorTable = True           ; Reverse color table order?
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
  diff_2_1 = gsn_csm_vector_scalar_map(wks,var1_case2_flip-var1_case1_flip,var2_case2_flip-var2_case1_flip,var0_case2_flip-var0_case1_flip,res)

  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_vector_scalar_map(wks,var1_case3_flip-var1_case1_flip,var2_case3_flip-var2_case1_flip,var0_case3_flip-var0_case1_flip,res)

  res@gsnCenterString = ""+cases(3)+"-"+cases(0)+""
  diff_4_1 = gsn_csm_vector_scalar_map(wks,var1_case4_flip-var1_case1_flip,var2_case4_flip-var2_case1_flip,var0_case4_flip-var0_case1_flip,res)

  res@gsnCenterString = ""+cases(4)+"-"+cases(0)+""
  diff_5_1 = gsn_csm_vector_scalar_map(wks,var1_case5_flip-var1_case1_flip,var2_case5_flip-var2_case1_flip,var0_case5_flip-var0_case1_flip,res)

end
