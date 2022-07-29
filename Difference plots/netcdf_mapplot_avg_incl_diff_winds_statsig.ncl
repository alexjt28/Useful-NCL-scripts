begin

;-------------------------------------------------------------------------------------------------------------------
; This script takes a time series from climate model output as netCDF files and plots the average spatial difference
; It is a dense script and is optimized for flexibility and functionality. It has the following capabilities:
; -Plot spatial maps for a flexible number of cases, times, and at various levels of the atmosphere
; -Plot differences between the various cases
; -Overlay wind vectors on top of the spatial map
; -Calculate and display statistical significance of differences between cases
;
; An example is provided using monthly files from two cases to plot precipitation in mm/day
;
; Author: Alex Thompson
; Date: 7/2/2019
; File name: netcdf_mapplot_avg_incl_diff_winds_statsig.ncl 
;
;-------------------------------------------------------------------------------------------------------------------

;************************************************
;************************************************
; SET ALL VARIABLES IN THIS SECTION
;************************************************
;************************************************

;------------------------------------------------
; Add filepaths for time series data here
;------------------------------------------------

 ; Add file paths in accordance to the example below
 ; CASES = (/ "CASE1_filepath", "CASE2_filepath", "CASE3_filepath", etc./)       
 ; cases = (/ "case1 name", "case2 name", "case3 name", etc./)

 CASES = (/ "[example... path 1 goes here]", "[example... path 2 goes here]", "[example... path 3 goes here]" /)

 cases = (/ "[example name 1]","[example name 2]","[example name 3]"/)

; How many cases are active for this script? The following command calculates this for you
 numcases = count_unique_values(CASES)

; Is there a special name for these cases to include in the output file name?
 name = "[example description here]"

;-------------------------------------------------------
; Are the netCDF files a list of separate monthly files?
;-------------------------------------------------------

 monthly = "Yes"

; If "Yes", input list of years and months separated by commas
; If daily output, include days in "MON", see instructions below
; If multiple files, input "{" in L1 and L2 and "}" in R1 and R2

 L1  = "{"                                       ; one year: ""  multiple years: "{"
 R1  = "}"                                       ; one year: ""  multiple years: "}"
 YR  = "01,02,03,04,05,06,07,08,09,10"           ; years: 01,02,03,etc.
 L2  = "{"                                       ; one month/day: ""  multiple months/days: "{"
 R2  = "}"                                       ; one month/day: ""  multiple months/days: "}"
 MON = "01,02,03,04,05,06,07,08,09,10,11,12"     ; monthly: 01,02,etc. daily: 01-01,01-06,etc.
 END = ".nc" 

; For output file name, specify dates below

 YEARS  = "1-10"
 SEASON = "Annual" 

;------------------------------------------------
; Specify the fields and properties here
;------------------------------------------------ 

; Which variable(s) to plot? Can perform math operations on these variables 

 VAR1 = "PRECC" 
 VAR2 = "PRECL"

; What are the units of the variable?
 UNITS = "mm/day"

; Which Math operation to perform if there are two variables? 
 MATH = "add"   ; options:  "add"->VAR1+VAR2, "sub"->VAR1-VAR2, "mul"->VAR1*VAR2, "div"->VAR1/VAR2

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
 MULT = 86400000.0  ; this factor turns m/s into mm/day

;--------------------------------------------------------------
; Do you want to overlay wind vectors? 
;--------------------------------------------------------------

 OVERLAY_WIND = "Yes" 

 WIND_LEVEL   = "850"                      ; Text string in hPa
 WIND_UNITS   = "m/s"                      ; Text string
 wind_lev_ind = ind(lev_p .eq. WIND_LEVEL) ; wind_lev_ind converts WIND_LEVEL to the corresponding index of lev_p

;--------------------------------------------------------------
; Do you want to plot statistical significance?
;--------------------------------------------------------------

 statsig = "Yes"

 ; Statistical significance options

 siglvl     = 0.05     ; 0.10 = 90% confidence; 0.05 = 95% confidence; 0.01 = 99% confidence 
 samplesize = "small"  ; if "small", equiv sample size used; if "large", # of years used
 iflag      = True     ; True if two original samples are assumed to have different pop. variances, False is same
 tval_opt   = False    ; True to return additional statistical probabilities, False to return only probabilities

 ; Plotting specifications

 gsnShadeFillType = "pattern"  ; Color or pattern fill for statistical significance overlay, default="color"
 gsnShadeLow      = 17         ; Type of shading: 3=slanted, 6=crosshatching, 17=dots (https://www.ncl.ucar.edu/Document/Graphics/Images/fillpatterns.png)

;--------------------------------------------------------------
; Do you want to print out the average over a specified region?
;--------------------------------------------------------------

; Latitude:  +=north, -=south
; Longitude: 0-180=E, 180-360=W (when indexing using lon_flip)

; Do you want a global average?
 Global = "Yes"

; Do you want an average over a specific region?
 Region = "Yes"

 south_lat = 19.0
 north_lat = 32.0
 west_lon  = 340.0
 east_lon  = 30.0

; Do you want an average at a specific grid point?
 Point = "Yes"

 latpoint = 20.0
 lonpoint = 10.0

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = ""+SEASON+"_year"+YEARS+"_"+VAR1+""+MATH+""+VAR2+"_"+LEVEL+"_"+name+""

;-----------------------------------------------------------
; Specify contour levels for absolute and difference values
;-----------------------------------------------------------

; Manual Levels for absolute contour plotting (1=ON, 0=OFF) 
 ManLevAbs = 0      
 abs_hival = 15.0  ; float
 abs_loval = 0.0   ; float
 abs_spval = 1.0   ; float

; Manual Levels for difference contour plotting (1=ON, 0=OFF)
 ManLevDif = 0
 dif_hival = 4.0   ; float
 dif_loval = -4.0  ; float
 dif_spval = 0.5   ; float

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
  LatMin = -15  ; negative values = °S
  LatMax = 40   ; positive values = °N
  LonMin = -50  ; negative values = °W
  LonMax = 50   ; positive values = °E
 end if

;-------------------------------------------------
; Contour specifications
;-------------------------------------------------

 cnFillOn       = True        ; Fill in contours? 
 cnFillMode     = "AreaFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 cnLinesOn      = False       ; Contour lines?
 cnLineLabelsOn = False       ; Contour line labels?
 gsnAddCyclic   = True        ; Eliminates gap in longitudinal data

;---------------------------------------------
; Wind vector specifications
;---------------------------------------------

if (OVERLAY_WIND .eq. "Yes") then
 
 gsnScalarContour        = True                                 ; True sets wind scalars
 mpFillOn                = False                                ; True disables wind values over continents, False enables them
 vcRefAnnoOrthogonalPosF = -1.0 ;(top right)                    ; Move ref vector up/down, default=0.02
 vcRefMagnitudeF         = 5.0                                  ; Define reference vector magnitude, default=0.0
 vcRefLengthF            = 0.045                                ; Define length of reference vector
 vcGlyphStyle            = "CurlyVector"                        ; "CurlyVector"(best), "LineArrow", "FillArrow", "WindBarb"
 vcRefAnnoFont           = 21                                   ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 vcRefAnnoFontHeightF    = 0.01                                 ; Font height for reference vector label
 vcRefAnnoString1        = ""+vcRefMagnitudeF+" "+WIND_UNITS+"" ; Reference vector label string
 vcMinDistanceF          = 0.017                                ; Distance between wind vectors, default=0.0

end if

;------------------------------------------------
; Titles and text on the plot 
;------------------------------------------------

; Left string is in upper left corner
; Center string is in upper center
; Right string is in upper right corner

; Left, Center, and Right text strings

 gsnLeftString   = "~F21~"+SEASON+" "+VAR1+""+MATH+""+VAR2+""
 gsnCenterString = "" ; Defined in code as each index of "cases"
 gsnRightString  = ""

; Text positions

 gsnLeftStringOrthogonalPosF   = 0.05  ; Left string up/down position
 gsnCenterStringOrthogonalPosF = 0.05  ; Center string up/down position
 gsnRightStringOrthogonalPosF  = 0.05  ; Right string up/down position

; Text size

 gsnLeftStringFontHeightF   = 0.012 ; Left string font size
 gsnCenterStringFontHeightF = 0.020 ; Center string font size
 gsnRightStringFontHeightF  = 0.012 ; Right string font size

; Axes text size and stride
 
 tmXBLabelFontHeightF = 0.014  ; X-axis font height, default=0.02    
 tmYLLabelFontHeightF = 0.014  ; Y-axis font height, default=0.02
 gsnMajorLatSpacing   = 20     ; Latitude stride
 gsnMajorLonSpacing   = 30     ; Longitude stride

;------------------------------------------------
; Color and label bar specifications
;------------------------------------------------

; Colors
 
 lbLabelBarOn        = True
 ColorTable          = "BlAqGrYeOrReVi200"  ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 ReverseColorTable   = False                ; Reverse color table order? 
 gsnSpreadColors     = True                 ; if True, reduces colors used from color table
 gsnSpreadColorStart =  20                  ; Index to start with: default=2 
 gsnSpreadColorEnd   = -20                  ; Index to end with: default=-1

; Label Bar Style

 pmLabelBarOrthogonalPosF = 0.08               ; Up and down position of label bar, default=0.02
 lbOrientation            = "horizontal"       ; Orientation of label bar: "horizontal" or "vertical"
 lbLabelStride            = 2                  ; How many labels to skip
 lbBoxEndCapStyle         = "TriangleBothEnds" ; What shape to have at the ends of the label bar, options are:
                                               ; "TriangleBothEnds", "TriangleLowEnd", "TriangleHighEnd", "RectangleEnds"
; Label Text

 lbLabelFontHeightF = 0.01   ; Size of label font, default=0.02
 lbLabelAngleF      = 0      ; Angle of the label text, default=0.0
 lbLabelFont        = 21     ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml 

; Label Bar Title Text - displays units

 lbTitleString      = "~F21~"+UNITS+"" ; Label bar title text string
 lbTitlePosition    = "Right"          ; Where to place label bar title text string
                                       ; "Top","Bottom","Left","Right" 
 lbTitleDirection   = "Across"         ; Direction of title text: "Across" or "Down"
 lbTitleFont        = 21               ; Title font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml 
 lbTitleFontHeightF = 0.012            ; Title font size, default=0.025 

;------------------------------------------------
; Plot tick marks
;------------------------------------------------

 tmXBLabelFont = 21  ; X-axis tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml 
 tmYLLabelFont = 21  ; Y-axis tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 
 tmXBMinorOn = True  ; Draws X-axis minor ticks
 tmYLMinorOn = True  ; Draws Y-axis minor ticks

 pmTickMarkDisplayMode = "Never"  ; "Always" draws ° but reduces custom options

;------------------------------------------------
; Figure size
;------------------------------------------------

 vpWidthF  = 0.7  ; How far the figure stretches horizontally, default=0.6
 vpHeightF = 0.6  ; How far the figure stretches vertically, default=0.6
 vpXF      = 0.2  ; Where the figure begins horizontally, default=0.2
 vpYF      = 0.85 ; Where the figure begins vertically, default=0.8

 gsnPaperOrientation = "Portrait"  ; Orientation of plot: "Portrait", "Landscape", or default="auto"
 gsnMaximize = True                ; Maximizes plot to workstation

 ; Do you want to include the final figures together in one panel plot?

 Panelplot = "Yes"

;************************************************
;************************************************
; BELOW IS THE ACTUAL CODE FOR THIS SCRIPT
; ALL VARIABLES ARE SET AT THIS POINT
;************************************************
;************************************************

;************************************************
; Read in variables
;-----------------------------------------------*
; Loop starts here
;-----------------------------------------------*
;************************************************

 do i=1,numcases

 ; Read in variables and scale them
   if (monthly .eq. "Yes") then

     fil = systemfunc("ls "+CASES(i-1)+""+L1+""+YR+""+R1+"-"+L2+""+MON+""+R2+""+END+"")
     ins = addfiles(fil,"r")
     ListSetType(ins,"cat")
      var1      = ins[:]->$VAR1$
      var1_orig = var1*MULT
     if (VAR2 .ne. "") then
      var2      = ins[:]->$VAR2$
      var2_orig = var2*MULT
     end if

     if (LEVEL .ne. "") then

      ; Converts from sigma to pressure coordinates
       lev            = var1&lev
       numlevs_subone = dimsizes(lev)-1
       hybm1          = ins[:]->hybm(0:numlevs_subone) ; hybm is the 'sigma' coordinate
       hyam1          = ins[:]->hyam(0:numlevs_subone) ; create a bogus hyam 1D array
       P0             = ins[:]->P0(0)
       P0mb           = P0*0.01
       ps1            = ins[:]->PS   ; these are in Pa
       intyp          = 1

       var1_lev = vinth2p(var1_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var1_orig,var1_lev)
       var1_time = var1_lev(:,lev_ind,:,:)
      if (VAR2 .ne. "") then 
       var2_lev = vinth2p(var2_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var2_orig,var2_lev)
       var2_time = var2_lev(:,lev_ind,:,:)
      end if

     else 
      
       var1_time = var1_orig
      if (VAR2 .ne. "") then
       var2_time = var2_orig
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

  var_averg = dim_avg_n_Wrap(var_time,0)

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

if (monthly .eq. "Yes") then

 ; Read in variables
 u_prelev = ins[:]->U
 v_prelev = ins[:]->V

 ; Convert from sigma to pressure
 if (WIND_LEVEL .ne. "")
  wlev            = u_prelev&lev
  wnumlevs_subone = dimsizes(wlev)-1
  whybm1          = ins[:]->hybm(0:wnumlevs_subone) ; hybm is the 'sigma' coordinate
  whyam1          = ins[:]->hyam(0:wnumlevs_subone) ; create a bogus hyam 1D array
  wP0             = ins[:]->P0(0)
  wP0mb           = wP0*0.01
  wps1            = ins[:]->PS   ; these are in Pa
  wintyp          = 1
  ulev = vinth2p(u_prelev,whyam1,whybm1,lev_p,wps1,wintyp,wP0mb,1,False)
  copy_VarAtts(u_prelev,ulev)
  vlev = vinth2p(v_prelev,whyam1,whybm1,lev_p,wps1,wintyp,wP0mb,1,False)
  copy_VarAtts(v_prelev,vlev)
 end if

 ; Take pressure level and average
 U = dim_avg_n_Wrap(ulev(:,wind_lev_ind,:,:),0)
 V = dim_avg_n_Wrap(vlev(:,wind_lev_ind,:,:),0)

 ; lonFlip
 U_flip = lonFlip(U)
 V_flip = lonFlip(V)

end if

end if

;************************************************************
; Step 1 to calculate statistical significance if necessary
; Step 2 occurs after the loop finishes
;-----------------------------------------------------------*
; Loop continues here...
;-----------------------------------------------------------*
;************************************************************

if (statsig .eq. "Yes") then

 ; Quantify number of years and months of data input
  delim     = ","
  numyears  = str_fields_count(YR,delim)
  nummonths = str_fields_count(MON,delim)

 ; Reshape to array of annual averages (annual avgs,lat,lon)
  var_time_4d = reshape(var_time, (/numyears,nummonths,dimsizes(lat),dimsizes(lon)/))
  var_years   = dim_avg_n_Wrap(var_time_4d,1) ; averages out the "months" index

  var_years!0   = "time"
  var_years!1   = "lat"
  var_years!2   = "lon"
  var_years&lat = lat
  var_years&lon = lon

 ; Calculate variance and sample size
  variances = dim_variance_n_Wrap(var_years,0)
  if (samplesize .eq. "small") then
    sizeequiv = equiv_sample_size(var_years(lat|:,lon|:,time|:), siglvl, 0)
  else if (samplesize .eq. "large") then 
    sizeequiv = numyears
  end if
  end if

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
 if (statsig .eq. "Yes") then
 printVarSummary(var_years)
 end if
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
    if (statsig .eq. "Yes") then
     var_years_case1 = var_years
     variances_case1 = variances
     sizeequiv_case1 = sizeequiv
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
    if (statsig .eq. "Yes") then
     var_years_case2 = var_years
     variances_case2 = variances
     sizeequiv_case2 = sizeequiv
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
    if (statsig .eq. "Yes") then
     var_years_case3 = var_years
     variances_case3 = variances
     sizeequiv_case3 = sizeequiv
    end if
   end if

; If more than three cases, include another if/then here to accommodate...

; Now delete the unneeded variables

  delete([/fil,ins,var1,var1_orig,var1_time,var_averg,var_averg_flip/])
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
  delete([/u_prelev,v_prelev,wlev,wnumlevs_subone,whybm1,whyam1,wP0,wP0mb,wps1,wintyp,ulev,vlev,U,V,U_flip,V_flip/])
 end if
 if (statsig .eq. "Yes") then
  delete([/delim,numyears,nummonths,var_time_4d,var_years,variances,sizeequiv/])
 end if

end do

;-------------------------------------------------*
; Loop is done.
;-------------------------------------------------*

;**************************************************************
; Step 2 to calculate statistical significance if necessary
;**************************************************************

; Perform student's t-test and return boolean probability variable for necessary differences

if (statsig .eq. "Yes") then

  if (numcases .eq. 2) then
    
    ttest_2_1 = ttest(var_averg_case2,variances_case2,sizeequiv_case2,var_averg_case1,variances_case1,sizeequiv_case1,iflag,tval_opt)      
    prob_2_1  = where(ttest_2_1.ge.siglvl, 1., 0.)

    prob_2_1!0   = "lat"
    prob_2_1!1   = "lon"
    prob_2_1&lat = lat
    prob_2_1&lon = lon

  end if

  if (numcases .eq. 3) then

    ttest_2_1 = ttest(var_averg_case2,variances_case2,sizeequiv_case2,var_averg_case1,variances_case1,sizeequiv_case1,iflag,tval_opt)          
    prob_2_1  = where(ttest_2_1.ge.siglvl, 1., 0.)

    prob_2_1!0   = "lat"
    prob_2_1!1   = "lon"
    prob_2_1&lat = lat
    prob_2_1&lon = lon

    ttest_3_2 = ttest(var_averg_case3,variances_case3,sizeequiv_case3,var_averg_case2,variances_case2,sizeequiv_case2,iflag,tval_opt)
    prob_3_2  = where(ttest_3_2.ge.siglvl, 1., 0.)

    prob_3_2!0   = "lat"
    prob_3_2!1   = "lon"
    prob_3_2&lat = lat
    prob_3_2&lon = lon

    ttest_3_1 = ttest(var_averg_case3,variances_case3,sizeequiv_case3,var_averg_case1,variances_case1,sizeequiv_case1,iflag,tval_opt)
    prob_3_1  = where(ttest_3_1.ge.siglvl, 1., 0.)

    prob_3_1!0   = "lat"
    prob_3_1!1   = "lon"
    prob_3_1&lat = lat
    prob_3_1&lon = lon

  end if

end if

;***********************************************************
; Compute average values over a certain region if necessary
;***********************************************************

if (Global .eq. "Yes" .or. Region .eq. "Yes" .or. Point .eq. "Yes") then
  print("********************")
  print("AVERAGE VALUES")
  print("*******************")
end if

;-----------
; Global
;-----------

if (Global .eq. "Yes") then
 
  print("Global average "+cases(0)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+avg(var_averg_case1_flip)+"")
 
  if (numcases .ge. 2) then
  print("Global average "+cases(1)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+avg(var_averg_case2_flip)+"")
  end if  
 
  if (numcases .ge. 3) then
  print("Global average "+cases(2)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" = "+avg(var_averg_case3_flip)+"")
  end if

end if

;-----------
; Region
;-----------

if (Region .eq. "Yes") then

 rad = 4.0*atan(1.0)/180.0
 gw  = (cos(lat*rad))/2

 lat_s = min(ind(lat .ge. south_lat))
 lat_n = max(ind(lat .le. north_lat))

 if (west_lon .ge. 180.0) then
  lon_w = min(ind(lon_flip .ge. west_lon))
 else if (west_lon .lt. 180) then
  lon_w = max(ind(lon_flip .le. west_lon))
 end if
 end if

 if (east_lon .ge. 180.0) then
  lon_e = min(ind(lon_flip .ge. east_lon))
 else if (east_lon .lt. 180.0) then 
  lon_e = max(ind(lon_flip .le. east_lon))
 end if
 end if

 print(""+cases(0)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case1_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))  

 if (numcases .ge. 2) then
 print(""+cases(1)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case2_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

 if (numcases .ge. 3) then
 print(""+cases(2)+" "+VAR1+""+MATH+""+VAR2+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(var_averg_case3_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 end if

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

end if

;************************************************
; Make the plot 
;************************************************

; Define workstation

 wks = gsn_open_wks(file_type,outputfilename)
 
 res = True

;---------------------------------------------
; Statistical significance
;---------------------------------------------

 if (statsig .eq. "Yes") then
  opt                  = True
  opt@gsnShadeFillType = gsnShadeFillType
  opt@gsnShadeLow      = gsnShadeLow
  stres                = True
  stres@gsnDraw        = False
  stres@gsnFrame       = False
  stres@cnLinesOn      = False
  stres@cnInfoLabelOn  = False
  stres@cnLineLabelsOn = False
  stres@gsnAddCyclic   = True 
 end if

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

;--------------------------------------
; Contour specifications
;--------------------------------------

 res@cnFillOn       = cnFillOn
 res@cnFillMode     = cnFillMode
 res@cnLinesOn      = cnLinesOn
 res@cnLineLabelsOn = cnLineLabelsOn
 res@gsnAddCyclic   = gsnAddCyclic

;----------------------------------
; Wind vector specifications
;----------------------------------

if (OVERLAY_WIND .eq. "Yes") then

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

end if 

;------------------------------------------------
; Titles and text on the plot
;------------------------------------------------

; Left, Center, and Right text strings

 res@gsnLeftString   = gsnLeftString
 res@gsnCenterString = gsnCenterString
 res@gsnRightString  = gsnRightString

; Text positions

 res@gsnLeftStringOrthogonalPosF   = gsnLeftStringOrthogonalPosF 
 res@gsnCenterStringOrthogonalPosF = gsnCenterStringOrthogonalPosF  
 res@gsnRightStringOrthogonalPosF  = gsnRightStringOrthogonalPosF  
 
; Text size
 res@gsnLeftStringFontHeightF   = gsnLeftStringFontHeightF
 res@gsnCenterStringFontHeightF = gsnCenterStringFontHeightF
 res@gsnRightStringFontHeightF  = gsnRightStringFontHeightF

; Axes text size and stride
 res@tmXBLabelFontHeightF = tmXBLabelFontHeightF
 res@tmYLLabelFontHeightF = tmYLLabelFontHeightF
 res@gsnMajorLatSpacing   = gsnMajorLatSpacing 
 res@gsnMajorLonSpacing   = gsnMajorLonSpacing

;--------------------------------------
; Color and label bar specifications
;--------------------------------------

; Colors

 res@lbLabelBarOn = lbLabelBarOn
 gsn_define_colormap(wks,""+ColorTable+"")
 if (ReverseColorTable .eq. "True") then
  gsn_reverse_colormap(wks)
 end if
 res@gsnSpreadColors     = gsnSpreadColors
 res@gsnSpreadColorStart = gsnSpreadColorStart
 res@gsnSpreadColorEnd   = gsnSpreadColorEnd

; Label Bar Style
 res@pmLabelBarOrthogonalPosF = pmLabelBarOrthogonalPosF
 res@lbOrientation            = lbOrientation
 res@lbLabelStride            = lbLabelStride
 res@lbBoxEndCapStyle         = lbBoxEndCapStyle

; Label Text
 res@lbLabelFontHeightF = lbLabelFontHeightF 
 res@lbLabelAngleF      = lbLabelAngleF 
 res@lbLabelFont        = lbLabelFont 

; Label Bar Title Text - displays units
 res@lbTitleString      = lbTitleString
 res@lbTitlePosition    = lbTitlePosition 
 res@lbTitleDirection   = lbTitleDirection
 res@lbTitleFont        = lbTitleFont
 res@lbTitleFontHeightF = lbTitleFontHeightF

;-----------------
; Plot tick marks
;-----------------

 res@tmXBLabelFont = tmXBLabelFont
 res@tmYLLabelFont = tmYLLabelFont

 res@tmXBMinorOn = tmXBMinorOn
 res@tmYLMinorOn = tmYLMinorOn
 
 res@pmTickMarkDisplayMode = pmTickMarkDisplayMode

;-------------------------
; Figure size
;-------------------------

 res@vpWidthF   = vpWidthF
 res@vpHeightF  = vpHeightF
 res@vpXF       = vpXF
 res@vpYF       = vpYF

 res@gsnMaximize         = gsnMaximize
 res@gsnPaperOrientation = gsnPaperOrientation

;***********************************************************
; Make the plot
;***********************************************************

;----------------------------------------
; Absolute value map plots
;----------------------------------------

if (OVERLAY_WIND .eq. "No") then

 res@gsnCenterString = cases(0)
 plot1 = gsn_csm_contour_map_ce(wks,var_averg_case1_flip,res)

 if (numcases .ge. 2) then
 res@gsnCenterString = cases(1)
 plot2 = gsn_csm_contour_map_ce(wks,var_averg_case2_flip,res)
 end if

 if (numcases .ge. 3) then
 res@gsnCenterString = cases(2)
 plot3 = gsn_csm_contour_map_ce(wks,var_averg_case3_flip,res)
 end if

else

 res@gsnCenterString = cases(0)
 plot1 = gsn_csm_vector_scalar_map(wks,U_case1_flip,V_case1_flip,var_averg_case1_flip,res)

 if (numcases .ge. 2) then
 res@gsnCenterString = cases(1)
 plot2 = gsn_csm_vector_scalar_map(wks,U_case2_flip,V_case2_flip,var_averg_case2_flip,res)
 end if

 if (numcases .ge. 3) then
 res@gsnCenterString = cases(2)
 plot3 = gsn_csm_vector_scalar_map(wks,U_case3_flip,V_case3_flip,var_averg_case3_flip,res)
 end if

end if

;------------------------------------
; Difference plots
;------------------------------------

; Set the difference contour levels

 if (ManLevDif .eq. 1) then
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMaxLevelValF       =  dif_hival
   res@cnMinLevelValF       =  dif_loval
   res@cnLevelSpacingF      =  dif_spval
 end if

if (OVERLAY_WIND .eq. "No") then

 if (numcases .eq. 2) then
  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_contour_map_ce(wks,var_averg_case2_flip-var_averg_case1_flip,res)
  if (statsig .eq. "Yes") then
    stats1 = gsn_csm_contour(wks,prob_2_1,stres)
    stats2 = gsn_contour_shade(stats1, 0.1, 0.0, opt)
    overlay(diff_2_1,stats1)
    draw(diff_2_1)
    frame(wks)
  end if
 end if

 if (numcases .eq. 3) then
  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_contour_map_ce(wks,var_averg_case2_flip-var_averg_case1_flip,res)
  if (statsig .eq. "Yes") then
    stats1 = gsn_csm_contour(wks,prob_2_1,stres)
    stats2 = gsn_contour_shade(stats1, 0.1, 0.0, opt)
    overlay(diff_2_1,stats1)
    draw(diff_2_1)
    frame(wks)
  end if
  res@gsnCenterString = ""+cases(2)+"-"+cases(1)+""
  diff_3_2 = gsn_csm_contour_map_ce(wks,var_averg_case3_flip-var_averg_case2_flip,res)
  if (statsig .eq. "Yes") then
    stats3 = gsn_csm_contour(wks,prob_3_2,stres)
    stats4 = gsn_contour_shade(stats3, 0.1, 0.0, opt)
    overlay(diff_3_2,stats3)
    draw(diff_3_2)
    frame(wks)
  end if
  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_contour_map_ce(wks,var_averg_case3_flip-var_averg_case1_flip,res)
  if (statsig .eq. "Yes") then
    stats5 = gsn_csm_contour(wks,prob_3_1,stres)
    stats6 = gsn_contour_shade(stats5, 0.1, 0.0, opt)
    overlay(diff_3_1,stats5)
    draw(diff_3_1)
    frame(wks)
  end if
 end if

else

 if (numcases .eq. 2) then
  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_vector_scalar_map(wks,U_case2_flip-U_case1_flip,V_case2_flip-V_case1_flip,var_averg_case2_flip-var_averg_case1_flip,res)
  if (statsig .eq. "Yes") then
    stats1 = gsn_csm_contour(wks,prob_2_1,stres)
    stats2 = gsn_contour_shade(stats1, 0.1, 0.0, opt)
    overlay(diff_2_1,stats1)
    draw(diff_2_1)
    frame(wks)
  end if
 end if

 if (numcases .eq. 3) then
  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_vector_scalar_map(wks,U_case2_flip-U_case1_flip,V_case2_flip-V_case1_flip,var_averg_case2_flip-var_averg_case1_flip,res)
  if (statsig .eq. "Yes") then
    stats1 = gsn_csm_contour(wks,prob_2_1,stres)
    stats2 = gsn_contour_shade(stats1, 0.1, 0.0, opt)
    overlay(diff_2_1,stats1)
    draw(diff_2_1)
    frame(wks)
  end if
  res@gsnCenterString = ""+cases(2)+"-"+cases(1)+""
  diff_3_2 = gsn_csm_vector_scalar_map(wks,U_case3_flip-U_case2_flip,V_case3_flip-V_case2_flip,var_averg_case3_flip-var_averg_case2_flip,res)
  if (statsig .eq. "Yes") then
    stats3 = gsn_csm_contour(wks,prob_3_2,stres)
    stats4 = gsn_contour_shade(stats3, 0.1, 0.0, opt)
    overlay(diff_3_2,stats3)
    draw(diff_3_2)
    frame(wks)
  end if
  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_vector_scalar_map(wks,U_case3_flip-U_case1_flip,V_case3_flip-V_case1_flip,var_averg_case3_flip-var_averg_case1_flip,res)
  if (statsig .eq. "Yes") then
    stats5 = gsn_csm_contour(wks,prob_3_1,stres)
    stats6 = gsn_contour_shade(stats5, 0.1, 0.0, opt)
    overlay(diff_3_1,stats5)
    draw(diff_3_1)
    frame(wks)
  end if
 end if

end if

;-----------------------
; Panel plot
;-----------------------

if (Panelplot .eq. "Yes") then

 if (numcases .eq. 2) then
   gsn_panel(wks,(/plot1,plot2,diff_2_1/),(/3,1/),res)
 else if (numcases .eq. 3) then
   gsn_panel(wks,(/plot1,plot2,plot3,diff_2_1,diff_3_2,diff_3_1/),(/2,3/),res)
 end if
 end if

end if

end
