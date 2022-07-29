;-------------------------------------------------------------------------------------------------------------------
; This script reads in variables from a climatology netCDF file and produces a seasonal cycle plot of each case's
; values (can include differences too) and map plots of each month. Specifically, this script plots integrated 
; vapor transport. This script includes functionality for calculating values from five (5) separate cases; however, 
; it can be easily modified to increase/decrease this number.
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
; Which plots do you want to have?
;------------------------------------------------

 xyplots  = "No"
 mapplots = "Yes" 

 mapdiffs = "No"

 Print_values = "Yes"

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
 MON = (/ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 /)
; MON does not change 

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
 UNITS = "m/s"

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
 MULT0 = 86400000.0  ; this factor turns m/s into mm/day
 MULTL = 86400000.0  ; this factor turns m/s into mm/day
 MULT1 = 1.0  ; this factor turns m/s into mm/day
 MULT2 = 1.0  ; this factor turns m/s into mm/day
 MULT3 = 1.0  ; this factor turns m/s into mm/day

; If you need to plot soil water...
 SOIL_LEV = 0

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = "pdfs/seasonalcycle_year"+YEARS+"_IVT_and_"+VAR0+MATH1+VARL+"_"+name+""

;------------------------------------------------
; Text strings for both plots
;------------------------------------------------

 LeftString     = "~F21~IVT_and_"+VAR0+MATH1+VARL
 CenterString   = ""
 RightString    = ""

;--------------------------------------------------------------
; For xyplot, which region/point do you want to average over?
;--------------------------------------------------------------

 Average = "Region"

; Latitude:  +=north, -=south
; Longitude: 0-180=E, 180-360=W (when indexing using lon_flip)

; If averaging over a region, specify the coordinates to average over

 southlat = 14.0
 northlat = 23.0
 westlon  = 267.5
 eastlon  = 272.5

; If averaging at a point, specify the point to average over

 latpoint = 16.0
 lonpoint = 270

;-----------------------------------------------------------
; For xyplot,  XY axes specifications
;-----------------------------------------------------------

; Axes strings

 tmXBValues    = ispan(0,11,1)  ; Array of data locations at which major tick marks will be drawn
 tmXBLabels    = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/) ; Array for tmXBValues
 tiYAxisString = ""+UNITS+""  ; Y-axis string

; Manual Levels for X-axis (1=ON, 0=OFF)
 ManLevX = 1
 xmin    = 0  ; Leave this as 0  
 xmax    = 11 ; Leave this as 11

; Manual Levels for Y-axis (1=ON, 0=OFF) 
 ManLevY = 0
 ymin    = 0.0
 ymax    = 14.0

;------------------------------------------------
; For xyplot, XY line properties
;------------------------------------------------

; String of line colors, ex. (/ "color1", "color2", "color3" /)

 xyLineColors     = (/ "black", "red", "orange", "blue", "aquamarine" /) 
 xyLineThicknessF = 5.0  ; default=1.0
 xyDashPatterns   = 0    ; Patterns from https://www.ncl.ucar.edu/Document/Graphics/Images/dashpatterns.png
                         ; 0=straight line, 1=large dashes, 2=dashed(small gap), 14=dashed(large gap)

;-----------------------------------------------------------
; For mapplot, specify contour levels for absolute and difference values
;-----------------------------------------------------------

; Manual Levels for contour plotting (1=ON, 0=OFF) 
 ManLevCon = 1      
 hival = 10.0
 loval = 0.0
 spval = 0.5

;---------------------------------------------
; For mapplot, zoom into any world region in particular?
;---------------------------------------------

 World = 0  ; 1=entire world, 0=zoomed in to coordinate values in second block 

 if (World .eq. 1) then
  LatMin = -90
  LatMax = 90
  LonMin = -180
  LonMax = 180
 else
  LatMin = -20;-40 ; negative values = °S
  LatMax = 40;90   ; positive values = °N
  LonMin = -120;-150  ; negative values = °W
  LonMax = 0;60   ; positive values = °E
 end if

;-------------------------------------------------
; For mapplot, important plot specifications to set here
;-------------------------------------------------

 ColorTableName = "cmp_haxby";"BlueYellowRed" ; "MPL_BrBG" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml

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
      var0      = ins->$VAR0$(begi:endi,:,:)  ; var behind vectors
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

; Convert to climatology

if (LEVEL .ne. "" .OR. VAR0 .eq. "Q") then
 var0_months    = clmMonTLLL(var0_time)
else
 var0_months    = clmMonTLL(var0_time)
end if

; Select months for average

 var1_UQ     = var1_UQ_months
 var2_VQ     = var2_VQ_months
if (LEVEL .ne. "" .OR. VAR0 .eq. "Q") then
 var0_levels = var0_months
else
 var0_levels = var0_months
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

 var1_UQ!0   = "time"
 var1_UQ!1   = "lat"
 var1_UQ!2   = "lon"
 var1_UQ&lat = lat
 var1_UQ&lon = lon
 var2_VQ!0   = "time"
 var2_VQ!1   = "lat"
 var2_VQ!2   = "lon"
 var2_VQ&lat = lat
 var2_VQ&lon = lon
 var0_avg!0   = "time"
 var0_avg!1   = "lat"
 var0_avg!2   = "lon"
 var0_avg&lat = lat
 var0_avg&lon = lon

; lonFlip

 lon_flip       = lonFlip(lon)

 var1_UQ_flip = lonFlip(var1_UQ)
 var2_VQ_flip = lonFlip(var2_VQ)

 var1_flip = var1_UQ_flip
 var2_flip = var2_VQ_flip

 var0_flip = lonFlip(var0_avg)

 printVarSummary(var1_flip)

;************************************************
; Average values over region/point
;************************************************

 if (Average .eq. "Region") then

   rad = 4.0*atan(1.0)/180.0
   gw  = (cos(lat*rad))/2

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

   var_seasonal_area_flip = wgt_areaave_Wrap(var0_flip(:,lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0)

 else if (Average .eq. "Point") then

   lat_point = min(ind(lat .ge. latpoint))
  if (lonpoint .gt. 180) then
   lon_point = min(ind(lon_flip .ge. lonpoint))
  else
   lon_point = max(ind(lon_flip .le. lonpoint))
  end if

   var_seasonal_area_flip = var0_flip(:,lat_point,lon_point)

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
     var_seasonal_area_case1_flip = var_seasonal_area_flip
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
     var_seasonal_area_case2_flip = var_seasonal_area_flip
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
     var_seasonal_area_case3_flip = var_seasonal_area_flip
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
     var_seasonal_area_case4_flip = var_seasonal_area_flip
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
     var_seasonal_area_case5_flip = var_seasonal_area_flip
   end if

end do

;-------------------------------------------------*
; Loop is done.
;-------------------------------------------------*

;*****************************************************************
; Print values, lat/lon_flip, and region for ease of calculation
;*****************************************************************

print(lat)
print(lon_flip)

 if (Average .eq. "Region") then

   print("Region = "+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+"-"+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+"-"+lon_e+")")
   AREA = (""+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+"-"+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+"-"+lon_e+")")

 else if (Average .eq. "Point") then

   print("Point = "+lat(lat_point)+","+lon_flip(lon_point)+"("+lat_point+","+lon_point+")")
   AREA = (""+lat(lat_point)+","+lon_flip(lon_point)+"("+lat_point+","+lon_point+")")

 end if
 end if

if (Print_values .eq. "Yes") then

  print(""+cases(0)+" values = "+var_seasonal_area_case1_flip+"")
  print(""+cases(1)+" values = "+var_seasonal_area_case2_flip+"")
  print(""+cases(2)+" values = "+var_seasonal_area_case3_flip+"")
  print(""+cases(3)+" values = "+var_seasonal_area_case4_flip+"")
  print(""+cases(4)+" values = "+var_seasonal_area_case5_flip+"")

end if

;***************************************************
; Specifications for the plot are determined below 
;***************************************************

; Define workstation

 wks = gsn_open_wks(file_type,outputfilename)

 res = True

;------------------------------------------------
; Text size and strings for both plots
;------------------------------------------------

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

;------------------------------------------------
; Figure size
;------------------------------------------------

 res@vpWidthF  = 0.7  ; How far the figure stretches horizontally, default=0.6
 res@vpHeightF = 0.6  ; How far the figure stretches vertically, default=0.6
 res@vpXF      = 0.2  ; Where the figure begins horizontally, default=0.2
 res@vpYF      = 0.85 ; Where the figure begins vertically, default=0.8

 res@gsnPaperOrientation = "Portrait"  ; Orientation of plot: "Portrait", "Landscape", or default="auto"
 res@gsnMaximize = True                ; Maximizes plot to workstation

;************************************************
if (xyplots .eq. "Yes") then
;************************************************

 resxy = res 

;-----------------------------------------------------------
; XY axes specifications
;-----------------------------------------------------------

 ; X-axis limits
 if (ManLevX .eq. 1) then
   resxy@trXMinF = xmin
   resxy@trXMaxF = xmax
 end if

 ; Y-axis limits
 if (ManLevY .eq. 1) then
   resxy@trYMinF = ymin
   resxy@trYMaxF = ymax
 end if

;------------------------------------------------
; Titles and text on the plot
;------------------------------------------------

; Left string is in upper left corner
; Center string is in upper center
; Right string is in upper right corner

; Left, Center, and Right text strings

 resxy@gsnLeftString   = ""+LeftString+" "+AREA+""

; Axes text and tick spacing

 resxy@tmYUseLeft    = True           ; Uses left Y-axis for Y-axis string
 resxy@tmXBMode      = "Explicit"     ; Tick spacing on right X-axis: "Automatic", "Manual", "Explicit"
 resxy@tmXBValues    = tmXBValues     ; Array of data locations at which major tick marks will be drawn
 resxy@tmXBLabels    = tmXBLabels     ; Array for tmXBValues
 resxy@tiXAxisString = ""             ; X-axis string overridden by tmXBLabels
 resxy@tiXAxisFont   = 21             ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 resxy@tiYAxisString = tiYAxisString  ; Y-axis string
 resxy@tiYAxisFont   = 21             ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 resxy@tmYRMode      = "Automatic"    ; Tick spacing on right Y-axis: "Automatic", "Manual", "Explicit"
 resxy@tmYROn        = True           ; True turns on right tick marks, False turns them off
 resxy@tmXBMinorOn   = True           ; True turns on bottom X-axis minor ticks
 resxy@tmYLMinorOn   = True           ; True turns on left Y-axis minor ticks
 resxy@tmXBLabelFont = 21             ; Tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 resxy@tmYLLabelFont = 21             ; Tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

;-------------------
; Legend
;-------------------

 resxy@pmLegendDisplayMode  = "Always"  ; "Always" = draws legend; "Never" = legend not drawn; "NoCreate"= no legend (default)
 resxy@pmLegendSide         = "Top"     ; Where the legend is placed: "Top", "Bottom", "Right", "Left"
 resxy@lgPerimOn            = False     ; Draws a line around the legend, default=True
 resxy@pmLegendWidthF       = 0.3       ; Legend width, default=0.55 when vpWidthF=0.6
 resxy@pmLegendHeightF      = 0.18      ; Legend height, default=0.18 when vpHeightF=0.6
 resxy@lgBoxMinorExtentF    = 0.1       ; Distance between items in the legend, default=0.6
 resxy@lgLabelFontHeightF   = 0.015     ; Label font size, default=0.02
 resxy@lgLabelOffsetF       = 0.04      ; Offset between legend and labels, default=0.02

 ; These values are set here and can be modified in the invidual plot functions below

 pmLegendParallelPosF    = 0.20;  0.65      ; Left/right movement of legend, default=0.5
 pmLegendOrthogonalPosF  = -0.48; -0.30     ; Up/down movement of legend items, default=0.02

;------------------------------
; Make the plot
;------------------------------

; Case 1
 resxy@xyExplicitLegendLabels = cases(0)
 resxy@xyLineColors           = xyLineColors(0)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF
 plotxy1 = gsn_csm_xy(wks,tmXBValues,var_seasonal_area_case1_flip,resxy)

; Case 2
 resxy@xyExplicitLegendLabels = cases(1)
 resxy@xyLineColors           = xyLineColors(1)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.04
 plotxy2 = gsn_csm_xy(wks,tmXBValues,var_seasonal_area_case2_flip,resxy)

; Case 3
 resxy@xyExplicitLegendLabels = cases(2)
 resxy@xyLineColors           = xyLineColors(2)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.08
 plotxy3 = gsn_csm_xy(wks,tmXBValues,var_seasonal_area_case3_flip,resxy)

; Case 4
 resxy@xyExplicitLegendLabels = cases(3)
 resxy@xyLineColors           = xyLineColors(3)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.12
 plotxy4 = gsn_csm_xy(wks,tmXBValues,var_seasonal_area_case4_flip,resxy)

; Case 5
 resxy@xyExplicitLegendLabels = cases(4)
 resxy@xyLineColors           = xyLineColors(4)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.16
 plotxy5 = gsn_csm_xy(wks,tmXBValues,var_seasonal_area_case5_flip,resxy)

 overlay(plotxy1,plotxy2)
 overlay(plotxy1,plotxy3)
 overlay(plotxy1,plotxy4)
 overlay(plotxy1,plotxy5)
 draw(plotxy1)
 frame(wks)

end if

;************************************************
if (mapplots .eq. "Yes") then
;************************************************
 
 resmap = res 

;-----------------------------------------------------------
; Specify contour levels for absolute and difference values
;...........................................................
; This is for absolute values, diff values come later
;-----------------------------------------------------------

 if (ManLevCon .eq. 1) then
   resmap@cnLevelSelectionMode = "ManualLevels"
   resmap@cnMaxLevelValF       =  hival
   resmap@cnMinLevelValF       =  loval
   resmap@cnLevelSpacingF      =  spval
 end if

;---------------------------------------------
; Zoom into any world region in particular?
;---------------------------------------------

 resmap@mpMinLatF = LatMin
 resmap@mpMaxLatF = LatMax
 resmap@mpMinLonF = LonMin
 resmap@mpMaxLonF = LonMax

;-------------------------------------------------
; Contour specifications
;-------------------------------------------------

 resmap@cnFillOn       = True        ; Fill in contours?
 resmap@cnFillMode     = "RasterFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 resmap@cnRasterSmoothingOn = True
 resmap@cnLinesOn      = False       ; Contour lines?
 resmap@cnLineLabelsOn = False       ; Contour line labels?
 resmap@gsnAddCyclic   = True        ; Eliminates gap in longitudinal data

;------------------------------------------------
; Titles and text on the mapplot
;------------------------------------------------

; Left string is in upper left corner
; Center string is in upper center
; Right string is in upper right corner

; Left, Center, and Right text strings

 resmap@gsnLeftString   = LeftString
 resmap@gsnCenterString = CenterString
 resmap@gsnRightString  = RightString

; Text positions

 resmap@gsnLeftStringOrthogonalPosF   = 0.05  ; Left string up/down position
 resmap@gsnCenterStringOrthogonalPosF = 0.05  ; Center string up/down position
 resmap@gsnRightStringOrthogonalPosF  = 0.05  ; Right string up/down position

; Text size

 resmap@gsnLeftStringFontHeightF   = 0.012 ; Left string font size
 resmap@gsnCenterStringFontHeightF = 0.020 ; Center string font size
 resmap@gsnRightStringFontHeightF  = 0.012 ; Right string font size

; Axes text size and stride

 resmap@tmXBLabelFontHeightF = 0.014  ; X-axis font height, default=0.02
 resmap@tmYLLabelFontHeightF = 0.014  ; Y-axis font height, default=0.02
 resmap@gsnMajorLatSpacing   = 20     ; Latitude stride
 resmap@gsnMajorLonSpacing   = 30     ; Longitude stride

;------------------------------------------------
; Color and label bar specifications
;------------------------------------------------

; Colors

 gsn_define_colormap(wks,""+ColorTableName+"")  ; Set at beginning of script by ColorTable
 ReverseColorTable = True                 ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if
 resmap@lbLabelBarOn         = True             ; True turns on label bar
 resmap@gsnSpreadColors      = False            ; if True, reduces colors used from color table
 resmap@gsnSpreadColorStart  =  20              ; Index to start with: default=2
 resmap@gsnSpreadColorEnd    = -20              ; Index to end with: default=-1

; Label Bar Style

 resmap@pmLabelBarOrthogonalPosF = 0.08               ; Up and down position of label bar, default=0.02
 resmap@lbOrientation            = "horizontal"       ; Orientation of label bar: "horizontal" or "vertical"
 resmap@lbLabelStride            = 2                  ; How many labels to skip
 resmap@lbBoxEndCapStyle         = "TriangleBothEnds" ; What shape to have at the ends of the label bar, options are:
                                               ; "TriangleBothEnds", "TriangleLowEnd", "TriangleHighEnd", "RectangleEnds"
; Label Text

 resmap@lbLabelFontHeightF = 0.01   ; Size of label font, default=0.02
 resmap@lbLabelAngleF      = 0      ; Angle of the label text, default=0.0
 resmap@lbLabelFont        = 21     ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

; Label Bar Title Text - displays units

 resmap@lbTitleString      = "~F21~"+UNITS+"" ; Label bar title text string
 resmap@lbTitlePosition    = "Right"          ; Where to place label bar title text string
                                       ; "Top","Bottom","Left","Right"
 resmap@lbTitleDirection   = "Across"         ; Direction of title text: "Across" or "Down"
 resmap@lbTitleFont        = 21               ; Title font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 resmap@lbTitleFontHeightF = 0.012            ; Title font size, default=0.025

;------------------------------------------------
; Plot tick marks
;------------------------------------------------

 resmap@tmXBLabelFont = 21  ; X-axis tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 resmap@tmYLLabelFont = 21  ; Y-axis tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

 resmap@tmXBMinorOn = True  ; Draws X-axis minor ticks
 resmap@tmYLMinorOn = True  ; Draws Y-axis minor ticks

 resmap@pmTickMarkDisplayMode = "Never"  ; "Always" draws ° but reduces custom options

;------------------------------------------------
; Wind vector specifications
;------------------------------------------------

 WIND_UNITS = "kg m~S~-1~N~ s~S~-1~N~"

 gsnScalarContour        = True                                 ; True sets wind scalars
 mpFillOn                = False                                ; True disables wind values over continents, False enables them
 vcRefAnnoOrthogonalPosF = -1.0 ;(top right)                    ; Move ref vector up/down, default=0.02
 vcRefMagnitudeF         = 250.0                                  ; Define reference vector magnitude, default=0.0
 vcRefLengthF            = 0.045                                ; Define length of reference vector
 vcGlyphStyle            = "CurlyVector"                        ; "CurlyVector"(best), "LineArrow", "FillArrow", "WindBarb"
 vcRefAnnoFont           = 21                                   ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 vcRefAnnoFontHeightF    = 0.01                                 ; Font height for reference vector label
 vcRefAnnoString1        = ""+vcRefMagnitudeF+" "+WIND_UNITS+"" ; Reference vector label string
 vcMinDistanceF          = 0.017                                ; Distance between wind vectors, default=0.0

 resmap@gsnScalarContour        = gsnScalarContour
 resmap@mpFillOn                = mpFillOn
 resmap@vcRefAnnoOrthogonalPosF = vcRefAnnoOrthogonalPosF
 resmap@vcRefMagnitudeF         = vcRefMagnitudeF
 resmap@vcRefLengthF            = vcRefLengthF
 resmap@vcGlyphStyle            = vcGlyphStyle
 resmap@vcRefAnnoFont           = vcRefAnnoFont
 resmap@vcRefAnnoFontHeightF    = vcRefAnnoFontHeightF
 resmap@vcRefAnnoString1        = vcRefAnnoString1
 resmap@vcMinDistanceF          = vcMinDistanceF

;------------------------------------------------
; Monthly plot center strings
;------------------------------------------------

 date = (/"~F22~Jan","~F22~Feb","~F22~Mar","~F22~Apr","~F22~May","~F22~Jun","~F22~Jul","~F22~Aug","~F22~Sep","~F22~Oct","~F22~Nov","~F22~Dec"/)

;---------------------------
; Make the plot
;---------------------------

 plotmap = new(144, graphic) ; 12 cases x 12 months each

; Case 1

 i=0
 do while(i.le.11)
    resmap@gsnCenterString = date(i)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(0)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case1_flip(i,:,:),var2_case1_flip(i,:,:),var0_case1_flip(i,:,:),resmap)
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(1)+"-"+cases(0)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case2_flip(i,:,:)-var1_case1_flip(i,:,:),var2_case2_flip(i,:,:)-var2_case1_flip(i,:,:),var0_case2_flip(i,:,:)-var0_case1_flip(i,:,:),resmap)
   end if
   end if
   i=i+1
 end do

 i=12
 do while(i.le.23)
    resmap@gsnCenterString = date(i-12)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(1)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case2_flip(i-12,:,:),var2_case2_flip(i-12,:,:),var0_case2_flip(i-12,:,:),resmap)
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(2)+"-"+cases(0)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case3_flip(i-12,:,:)-var1_case1_flip(i-12,:,:),var2_case3_flip(i-12,:,:)-var2_case1_flip(i-12,:,:),var0_case3_flip(i-12,:,:)-var0_case1_flip(i-12,:,:),resmap)
   end if
   end if
   i=i+1
 end do

 i=24
 do while(i.le.35)
    resmap@gsnCenterString = date(i-24)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(2)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case3_flip(i-24,:,:),var2_case3_flip(i-24,:,:),var0_case3_flip(i-24,:,:),resmap)
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(2)+"-"+cases(0)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case3_flip(i-24,:,:)-var1_case1_flip(i-24,:,:),var2_case3_flip(i-24,:,:)-var2_case1_flip(i-24,:,:),var0_case3_flip(i-24,:,:)-var0_case1_flip(i-24,:,:),resmap)
   end if
   end if
   i=i+1
 end do

 i=36
 do while(i.le.47)
    resmap@gsnCenterString = date(i-36)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(3)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case4_flip(i-36,:,:),var2_case4_flip(i-36,:,:),var0_case4_flip(i-36,:,:),resmap)
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(3)+"-"+cases(0)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case4_flip(i-36,:,:)-var1_case1_flip(i-36,:,:),var2_case4_flip(i-36,:,:)-var2_case1_flip(i-36,:,:),var0_case4_flip(i-36,:,:)-var0_case1_flip(i-36,:,:),resmap)
   end if
   end if
   i=i+1
 end do

 i=48
 do while(i.le.59)
    resmap@gsnCenterString = date(i-48)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(4)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case5_flip(i-48,:,:),var2_case5_flip(i-48,:,:),var0_case5_flip(i-48,:,:),resmap)
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(4)+"-"+cases(0)+""
     plotmap(i) = gsn_csm_vector_scalar_map(wks,var1_case5_flip(i-48,:,:)-var1_case1_flip(i-48,:,:),var2_case5_flip(i-48,:,:)-var2_case1_flip(i-48,:,:),var0_case5_flip(i-48,:,:)-var0_case1_flip(i-48,:,:),resmap)
   end if
   end if
   i=i+1
 end do

end if

end
