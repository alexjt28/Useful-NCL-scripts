;-------------------------------------------------------------------------------------------------------------------
; This script reads in variables from a climatology netCDF file and produces a zonal/meridional average of each 
; case's average values and plots the average on an xy plot. This script includes functionality for calculating 
; values from nine (9) separate cases; however, it can be easily modified to increase/decrease this number.
;
; This script DOES NOT include functionality for weighting by the length of each month.
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
 CASE6  = "[CASE6 filepath]"
 CASE7  = "[CASE7 filepath]"
 CASE8  = "[CASE8 filepath]"
 CASE9  = "[CASE9 filepath]"

 CASES = (/ CASE1, CASE2, CASE3, CASE4, CASE5, CASE6, CASE7, CASE8, CASE9 /)

 cases = (/ "case1", "case2", "case3", "case4", "case5", "case6", "case7", "case8", "case9"  /)

; Is there a special name for these cases to include in the output file name?
 name = "_9cases"

 numcases = 9 

;-------------------------------------------------------
; Timing
;-------------------------------------------------------

; Indices to read in (For time series, 0:1199 is 100 yrs, 600:1199 is 50 yrs; For climatology, use 0:11)
 begi = 0
 endi = 11

; For output file name, specify dates below

 YEARS  = ""

; Season to plot from 0 to 11
 SEASON = "ANN"
 MON = (/ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 /)
; MON does not change 

;------------------------------------------------
; Specify the fields and properties here
;------------------------------------------------ 

; Which variable(s) to plot? Can perform math operations on these variables 

 VAR1 = "TREFHT" 
 VAR2 = ""

; What are the units of the variable?
 UNITS = "K"

; Which Math operation to perform if there are two variables? 
 MATH = ""   ; options:  "add"->VAR1+VAR2, "sub"->VAR1-VAR2, "mul"->VAR1*VAR2, "div"->VAR1/VAR2

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
 MULT = 1.0; 86400000.0  ; this factor turns m/s into mm/day

; If you need to plot soil water...
 SOIL_LEV = 0

;--------------------------------------------------------------
; Coordinate averages and XY axes
;--------------------------------------------------------------

; Which coordinate do you want to remain after averaging (lat or lon)?

 CoordAvg = "lat"

; Axes strings

 tiXAxisString = ""       ; X-axis string
 tiYAxisString = "Pressure (hPa)"  ; Y-axis string

; Manual Levels for X-axis coordinates (1=ON, 0=OFF)
 ManLevX = 0      ; 0 for global, 1 for zoom
 xmin    = -180.0 ; LAT: (-°S, +°N), LON: (-°W, +°E),
 xmax    = 180.0  ; LAT: (-°S, +°N), LON: (-°W, +°E)

; If not plotting full atmospheric column, specify here
 ManLevY = 1
 ymin    = 300.0
 ymax    = 1000.0

; Spacing between coordinate ticks
 gsnMajorSpacing = 30   ; Degrees of spacing b/w ticks, ex. 30 leads to 30°N,60°N,90°N ticks

; Limit zonal/meridional region of averaging?
; Latitude: 0 to +90 = north, -90 to 0 = south
; Longitude: 0-177.5=E, 180-360=W (when indexing using lon_flip)
; Global: westlon=180.0, eastlon=177.5

 southlat = -90.0
 northlat = 90.0
 westlon  = 180.0
 eastlon  = 177.5

 if (CoordAvg .eq. "lat") then
   coordname = "lonavg"+westlon+"-"+eastlon+""
 else if (CoordAvg .eq. "lon") then
   coordname = "latavg"+southlat+"-"+northlat+""
 end if
 end if

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = "pdfs/xyplot"+SEASON+"_year"+YEARS+"_"+VAR1+""+MATH+""+VAR2+"_"+LEVEL+"_"+CoordAvg+"_"+name+""

;------------------------------------------------
; Text strings for both plots
;------------------------------------------------

 LeftString     = "~F21~"+VAR1+""+MATH+""+VAR2+" "+LEVEL+" "+SEASON
 CenterString   = ""
 RightString    = ""

;--------------------------------------------------------------
; For xyplot, which region/point do you want to average over?
;--------------------------------------------------------------

 Average = "Region"

; Latitude:  +=north, -=south
; Longitude: 0-180=E, 180-360=W (when indexing using lon_flip)

; If averaging over a region, specify the coordinates to average over

 southlat = -90.0
 northlat = 90.0
 westlon  = 180.0
 eastlon  = 177.5

; If averaging at a point, specify the point to average over

 latpoint = -4.8
 lonpoint = 305.0

;-----------------------------------------------------------
; For xyplot,  XY axes specifications
;-----------------------------------------------------------

; Axes strings

 tmXBValues    = ispan(0,11,1)  ; Array of data locations at which major tick marks will be drawn
 tmXBLabels    = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/) ; Array for tmXBValues
 tiYAxisString = ""+UNITS+""  ; Y-axis string

; Manual Levels for X-axis (1=ON, 0=OFF)
 ManLevX = 0
 xmin    = 0.0  ; Leave this as 0  
 xmax    = 11.0 ; Leave this as 11

; Manual Levels for Y-axis (1=ON, 0=OFF) 
 ManLevY = 0
 ymin    = 2.85
 ymax    = 3.25

;------------------------------------------------
; For xyplot, XY line properties
;------------------------------------------------

; String of line colors, ex. (/ "color1", "color2", "color3" /)

 xyLineColors     = (/ "black", "gold", "orange", "blue", "green4", "red", "purple", "purple4", "grey" /)
 xyLineThicknessF = 1.0  ; default=1.0
 xyDashPatterns   = 0    ; Patterns from https://www.ncl.ucar.edu/Document/Graphics/Images/dashpatterns.png
                         ; 0=straight line, 1=large dashes, 2=dashed(small gap), 14=dashed(large gap)

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

   if (LEVEL .eq. "") then

      var1      = ins->$VAR1$(begi:endi,:,:)
     if (VAR1 .eq. "H2OSOI") then
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

  var_lev = dim_avg_n_Wrap(var_time,0)

;*********************************************************
; Average over lat or lon domain
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

 lon_flip = lonFlip(lon)
 print(lon_flip)

 if (CoordAvg .eq. "lat") then

  var_lev_flip    = lonFlip(var_lev)

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

 if (LEVEL .eq. "") then
  var_avg = dim_avg_n_Wrap(var_lev_flip(:,lon_w:lon_e),1)
 else
  var_avg = dim_avg_n_Wrap(var_lev_flip(:,:,lon_w:lon_e),2)
 end if

 if (LEVEL .eq. "") then
  var_avg!0   = "lat"
  var_avg&lat = lat
 else
  var_avg!0   = "lev"
  var_avg!1   = "lat"
  var_avg&lev = lev_p
  var_avg&lat = lat
 end if

  print("-------------------------------------------------")
  print("Lon averaged over "+lon_flip(lon_w)+" to "+lon_flip(lon_e)+"")
  print("-------------------------------------------------")

 else if (CoordAvg .eq. "lon") then

  rad = 4.0*atan(1.0)/180.0
  gw  = (cos(lat*rad))/2

  lat_s = min(ind(lat .ge. southlat))
  lat_n = max(ind(lat .le. northlat))

  ; Weighted-average when averaging over latitude

 if (LEVEL .eq. "") then
  vardims = dimsizes(var_lev(lat_s:lat_n,:))
  congw = conform_dims((/vardims(0),vardims(1)/),gw(lat_s:lat_n),0)
  var_avg = dim_sum_n(var_lev(lat_s:lat_n,:)*congw,0)/dim_sum_n(congw,0)
 else
  vardims = dimsizes(var_lev(:,lat_s:lat_n,:))
  congw = conform_dims((/vardims(0),vardims(1),vardims(2)/),gw(lat_s:lat_n),1)
  var_avg = dim_sum_n(var_lev(:,lat_s:lat_n,:)*congw,1)/dim_sum_n(congw,1)
 end if

 if (LEVEL .eq. "") then
  var_avg!0   = "lon"
  var_avg&lon = lon
 else
  var_avg!0   = "lev"
  var_avg!1   = "lon"
  var_avg&lev = lev_p
  var_avg&lon = lon
 end if

  print("-------------------------------------------------")
  print("Lat averaged over "+lat(lat_s)+" to "+lat(lat_n)+"")
  print("-------------------------------------------------")

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
 printVarSummary(var1_time)
 printVarSummary(var_time)
 printVarSummary(var_lev)
 printVarSummary(var_avg)
 print("**************************")
 print("End loop for CASE"+i+"...")
 print("**************************")

;-----------------------------------------------------------
; Saved variables are of the following dimensions:
;
; var1_time -> (time,lev,lat,lon)
; var_time  -> (time,lev,lat,lon)
; var_lev   -> (lev,lat,lon)
; var_avg   -> (lev,lat/lon_flip)
;
;-----------------------------------------------------------

 ; Save corresponding variables
   if (i .eq. 1) then
     var1_time_case1 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case1 = var2_time
    end if
     var_time_case1     = var_time
     var_lev_case1      = var_lev
     var_avg_case1      = var_avg
   end if

   if (i .eq. 2) then
     var1_time_case2 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case2 = var2_time
    end if
     var_time_case2     = var_time
     var_lev_case2      = var_lev
     var_avg_case2 = var_avg
   end if

   if (i .eq. 3) then
     var1_time_case3 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case3 = var2_time
    end if
     var_time_case3     = var_time
     var_lev_case3      = var_lev
     var_avg_case3 = var_avg
   end if

   if (i .eq. 4) then
     var1_time_case4 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case4 = var2_time
    end if
     var_time_case4     = var_time
     var_lev_case4      = var_lev
     var_avg_case4 = var_avg
   end if

   if (i .eq. 5) then
     var1_time_case5 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case5 = var2_time
    end if
     var_time_case5     = var_time
     var_lev_case5      = var_lev
     var_avg_case5 = var_avg
   end if

   if (i .eq. 6) then
     var1_time_case6 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case6 = var2_time
    end if
     var_time_case6     = var_time
     var_lev_case6      = var_lev
     var_avg_case6 = var_avg
   end if

   if (i .eq. 7) then
     var1_time_case7 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case7 = var2_time
    end if
     var_time_case7     = var_time
     var_lev_case7      = var_lev
     var_avg_case7 = var_avg
   end if

   if (i .eq. 8) then
     var1_time_case8 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case8 = var2_time
    end if
     var_time_case8     = var_time
     var_lev_case8      = var_lev
     var_avg_case8 = var_avg
   end if

   if (i .eq. 9) then
     var1_time_case9 = var1_time
    if (VAR2 .ne. "") then
     var2_time_case9 = var2_time
    end if
     var_time_case9     = var_time
     var_lev_case9      = var_lev
     var_avg_case9 = var_avg
   end if

; If more than three cases, include another if/then here to accommodate...

; Now delete the unneeded variables

 if (LEVEL .eq. "") then
  delete([/fil,ins,var1,var1_orig,var1_time,var_time,var_lev,var_avg/])
 else
  delete([/fil,ins,var1,var1_orig,numlevs_subone,hybm1,hyam1,P0,P0mb,ps1,intyp,var1_time,var_time,var_lev,var_avg/])
 end if
 if (VAR2 .ne. "") then
  delete([/var2,var2_orig,var2_time/])
 end if; Now delete the unneeded variables

end do

;-------------------------------------------------*
; Loop is done.
;-------------------------------------------------*

;*****************************************************************
; Print values, lat/lon_flip, and region for ease of calculation
;*****************************************************************

print(lat)
print(lon_flip)

if (Print_values .eq. "Yes") then

  print(""+cases(0)+" values = "+var_avg_case1_flip+"")
  print(""+cases(1)+" values = "+var_avg_case2_flip+"")
  print(""+cases(2)+" values = "+var_avg_case3_flip+"")
  print(""+cases(3)+" values = "+var_avg_case4_flip+"")
  print(""+cases(4)+" values = "+var_avg_case5_flip+"")
  print(""+cases(5)+" values = "+var_avg_case6_flip+"")
  print(""+cases(6)+" values = "+var_avg_case7_flip+"")
  print(""+cases(7)+" values = "+var_avg_case8_flip+"")
  print(""+cases(8)+" values = "+var_avg_case9_flip+"")

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
;xyplot
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

 resxy@gsnLeftString   = ""+LeftString+""

; Axes text and tick spacing

 resxy@tmYUseLeft    = True           ; Uses left Y-axis for Y-axis string
 resxy@tmXBMode      = "Explicit"     ; Tick spacing on right X-axis: "Automatic", "Manual", "Explicit"
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

 pmLegendParallelPosF    = 0.65      ; Left/right movement of legend, default=0.5
 pmLegendOrthogonalPosF  = -0.9; -0.30     ; Up/down movement of legend items, default=0.02

;------------------------------
; Make the plot
;------------------------------

; X-axis
if (CoordAvg .eq. "lat") then
  xaxis = lat
else if (CoordAvg .eq. "lon") then
  xaxis = lon
end if
end if 

; Case 1
 resxy@xyExplicitLegendLabels = cases(0)
 resxy@xyLineColors           = xyLineColors(0)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF
 plotxy1 = gsn_csm_xy(wks,xaxis,var_avg_case1,resxy)

; Case 2
 resxy@xyExplicitLegendLabels = cases(1)
 resxy@xyLineColors           = xyLineColors(1)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.04
 plotxy2 = gsn_csm_xy(wks,xaxis,var_avg_case2,resxy)

; Case 3
 resxy@xyExplicitLegendLabels = cases(2)
 resxy@xyLineColors           = xyLineColors(2)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.08
 plotxy3 = gsn_csm_xy(wks,xaxis,var_avg_case3,resxy)

; Case 4
 resxy@xyExplicitLegendLabels = cases(3)
 resxy@xyLineColors           = xyLineColors(3)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.12
 plotxy4 = gsn_csm_xy(wks,xaxis,var_avg_case4,resxy)

; Case 5
 resxy@xyExplicitLegendLabels = cases(4)
 resxy@xyLineColors           = xyLineColors(4)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.16
 plotxy5 = gsn_csm_xy(wks,xaxis,var_avg_case5,resxy)

; Case 6
 resxy@xyExplicitLegendLabels = cases(5)
 resxy@xyLineColors           = xyLineColors(5)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.20
 plotxy6 = gsn_csm_xy(wks,xaxis,var_avg_case6,resxy)

 ; Case 7
 resxy@xyExplicitLegendLabels = cases(6)
 resxy@xyLineColors           = xyLineColors(6)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.24
 plotxy7 = gsn_csm_xy(wks,xaxis,var_avg_case7,resxy)

 ; Case 8
 resxy@xyExplicitLegendLabels = cases(7)
 resxy@xyLineColors           = xyLineColors(7)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.28
 plotxy8 = gsn_csm_xy(wks,xaxis,var_avg_case8,resxy)

 ; Case 9
 resxy@xyExplicitLegendLabels = cases(8)
 resxy@xyLineColors           = xyLineColors(8)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.32
 plotxy9 = gsn_csm_xy(wks,xaxis,var_avg_case9,resxy)

 overlay(plotxy1,plotxy2)
 overlay(plotxy1,plotxy3)
 overlay(plotxy1,plotxy4)
 overlay(plotxy1,plotxy5)
 overlay(plotxy1,plotxy6)
 overlay(plotxy1,plotxy7)
 overlay(plotxy1,plotxy8)
 overlay(plotxy1,plotxy9)
 draw(plotxy1)
 frame(wks)

end
