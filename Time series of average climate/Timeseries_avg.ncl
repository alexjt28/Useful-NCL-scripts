;-------------------------------------------------------------------------------------------------------------------
; This script reads in variables from a timeseries netCDF file and plots the average value over a specified domain
; for the entirety of the time series. Functionality for averaging by annual or seasonal value is included. This 
; script includes functionality for calculating values from five (5) separate cases; however, it can be easily 
; modified to increase/decrease this number.
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

; Indices to read in (For time series, 0:1199 is 100 yrs, 600:1199 is 50 yrs, 0:11 is 1 yr)
 begi = 0
 endi = 1199

; For output file name, specify dates below

 YEARS  = "01-100"

; Season to plot from 0 to 11
 SEASON    = "ANN"
 MON = (/ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 /)
; MON needs indices not actual months

 SEASAVG = "No"

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

; Do you want to scale the variables by a certain factor?
 MULT = 86400000.0  ; this factor turns m/s into mm/day

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

;--------------------------------------------------------------
; Which region or point to take the average over?
;--------------------------------------------------------------

 Average = "Region"  ; "Region" or "Point"

; Latitude:  +=north, -=south
; Longitude: 0-180=E, 180-360=W (when indexing using lon_flip)

; If averaging over a region, specify the coordinates to average over

 southlat = -90.0
 northlat = 90.0
 westlon  = 180.0
 eastlon  = 177.6

; If averaging at a point, specify the point to average over

 latpoint = 20.0
 lonpoint = 10.0

; Do you want to print metadata and the values of the final variable?

 Print_metadata = "Yes"
 Print_Values   = "No"
 PlotAvgValue   = "Yes"

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = "pdfs/"+SEASON+"_year"+YEARS+"_"+VAR1+""+MATH+""+VAR2+"_timeseries_"+name+""

;-----------------------------------------------------------
; XY axes specifications
;-----------------------------------------------------------

; Axes strings

 tiXAxisString = "Months"  ; X-axis string
 tiYAxisString = ""+UNITS+""  ; Y-axis string

; Manual Levels for X-axis (1=ON, 0=OFF)
 ManLevX = 0
 xmin    = 0
 xmax    = 100

; If not plotting full atmospheric column, specify here
 ManLevY = 1
 ymin    = 0
 ymax    = 6

; Reverse Y-axis to emulate atmosphere?
 trYReverse = False

;------------------------------------------------
; XY line properties
;------------------------------------------------

; String of line colors, ex. (/ "color1", "color2", "color3" /)

 xyLineColors     = (/ "orange", "blue", "green4", "red", "black" /)
 xyLineThicknessF = 5.0  ; default=1.0
 xyDashPatterns   = 0    ; Patterns from https://www.ncl.ucar.edu/Document/Graphics/Images/dashpatterns.png
                         ; 0=straight line, 1=large dashes, 2=dashed(small gap), 14=dashed(large gap)

;-------------------------------------------------
; Important plot specifications to set here
;-------------------------------------------------

 LeftString     = "~F21~"+VAR1+""+MATH+""+VAR2+""
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

 ; Read in variables and scale them

     fil = CASES(i-1)
     ins = addfile(fil,"r")

    if (LEVEL .eq. "") then

      var1      = ins->$VAR1$(begi:endi,:,:)
      var1_orig = var1*MULT
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

;*********************************************************
; Define metadata for final variable and perform lonFlip
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

; Metadata

 var_time!0     = "time"
 var_time!1     = "lat"
 var_time!2     = "lon"
 var_time&lat   = lat
 var_time&lon   = lon

; lonFlip

 lon_flip      = lonFlip(lon)
 var_time_flip = lonFlip(var_time)

;************************************************
; Yearly/seasonal averages or all months?
;************************************************

 nummonths = count_unique_values(MON)
 numyrs    = ((endi-begi)+1)/12

 if (SEASAVG .eq. "Yes") then

  ; Averages months to get yearly- or seasonal-averaged time series values

   var_resh_flip = reshape(var_time_flip, (/numyrs,nummonths,dimsizes(lat),dimsizes(lon)/))
   var_seas_flip = dim_avg_n_Wrap(var_resh_flip,1)

 else if (SEASAVG .eq. "No") then

   var_seas_flip = var_time_flip

 end if
 end if

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

   var_area_flip = wgt_areaave_Wrap(var_seas_flip(:,lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0)

 else if (Average .eq. "Point") then

   lat_point = min(ind(lat .ge. latpoint))
  if (lonpoint .gt. 180) then
   lon_point = min(ind(lon_flip .ge. lonpoint))
  else
   lon_point = max(ind(lon_flip .le. lonpoint))
  end if

   var_area_flip = var_seas_flip(:,lat_point,lon_point)

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
 printVarSummary(var_time)
 printVarSummary(var_time_flip)
 printVarSummary(var_area_flip)
 print("**************************")
 print("End loop for CASE"+i+"...")
 print("**************************")

;-----------------------------------------------------------
; Saved variables are of the following dimensions:
;
; var1_orig     -> (time,lat,lon) or (time,lev,lat,lon)
; var1_time     -> (time,lat,lon)
; var_time      -> (time,lat,lon)
; var_time_flip -> (time,lat,lon_flip)
; var_area_flip -> (time)
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
     var_time_case1      = var_time
     var_time_case1_flip = var_time_flip
     var_area_case1_flip = var_area_flip
   end if

   if (i .eq. 2) then
     var1_orig_case2 = var1_orig
     var1_time_case2 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case2 = var2_orig
     var2_time_case2 = var2_time
    end if
     var_time_case2      = var_time
     var_time_case2_flip = var_time_flip
     var_area_case2_flip = var_area_flip
   end if

   if (i .eq. 3) then
     var1_orig_case3 = var1_orig
     var1_time_case3 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case3 = var2_orig
     var2_time_case3 = var2_time
    end if
     var_time_case3      = var_time
     var_time_case3_flip = var_time_flip
     var_area_case3_flip = var_area_flip
   end if

   if (i .eq. 4) then
     var1_orig_case4 = var1_orig
     var1_time_case4 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case4 = var2_orig
     var2_time_case4 = var2_time
    end if
     var_time_case4      = var_time
     var_time_case4_flip = var_time_flip
     var_area_case4_flip = var_area_flip
   end if

   if (i .eq. 5) then
     var1_orig_case5 = var1_orig
     var1_time_case5 = var1_time
    if (VAR2 .ne. "") then
     var2_orig_case5 = var2_orig
     var2_time_case5 = var2_time
    end if
     var_time_case5      = var_time
     var_time_case5_flip = var_time_flip
     var_area_case5_flip = var_area_flip
   end if

; Now delete the unneeded variables

  delete([/fil,ins,var1,var1_orig,var1_time,var_time,var_time_flip,var_seas_flip,var_area_flip/])
 if (VAR2 .ne. "") then
  delete([/var2,var2_orig,var2_time/])
 end if
 if (LEVEL .ne. "") then
  delete([/numlevs_subone,hybm1,hyam1,P0,P0mb,ps1,intyp/])
 end if
 if (SEASAVG .eq. "Yes") then
  delete(var_resh_flip)
 end if

end do

;-------------------------------------------------*
; Loop is done.
;-------------------------------------------------*

;*****************************************************************
; Print values, lat/lon_flip, and region for ease of calculation
;*****************************************************************

if (Print_metadata .eq. "Yes") then

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

end if

if (Print_Values .eq. "Yes") then

  print(""+cases(0)+" values = "+var_area_case1_flip+"")
  print(""+cases(1)+" values = "+var_area_case2_flip+"")
  print(""+cases(2)+" values = "+var_area_case3_flip+"")
  print(""+cases(3)+" values = "+var_area_case4_flip+"")
  print(""+cases(4)+" values = "+var_area_case5_flip+"")

end if

;***************************************************
; Specifications for the plot are listed below
;***************************************************

; Define workstation

 wks = gsn_open_wks(file_type,outputfilename)

 res = True

;-----------------------------------------------------------
; XY axes specifications
;-----------------------------------------------------------

 ; X-axis limits
 if (ManLevX .eq. 1) then
   res@trXMinF = xmin
   res@trXMaxF = xmax
 end if

 ; Y-axis limits
 if (ManLevY .eq. 1) then
   res@trYMinF = ymin
   res@trYMaxF = ymax
 end if

; Reverse Y-axis to emulate atmosphere?
 res@trYReverse = trYReverse

;------------------------------------------------
; Titles and text on the plot
;------------------------------------------------

; Left string is in upper left corner
; Center string is in upper center
; Right string is in upper right corner

; Left, Center, and Right text strings

 res@gsnLeftString   = ""+LeftString+" "+AREA+""
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

; Axes text and tick spacing

 res@tmYUseLeft    = True           ; Uses left Y-axis for Y-axis string
 res@tiXAxisString = tiXAxisString  ; X-axis string
 res@tiXAxisFont   = 21             ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@tiYAxisString = tiYAxisString  ; Y-axis string
 res@tiYAxisFont   = 21             ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@tmYRMode      = "Automatic"    ; Tick spacing on right Y-axis: "Automatic", "Manual", "Explicit"
 res@tmYROn        = True           ; True turns on right tick marks, False turns them off
 res@tmXBMinorOn   = True           ; True turns on bottom X-axis minor ticks
 res@tmYLMinorOn   = True           ; True turns on left Y-axis minor ticks
 res@tmXBLabelFont = 21             ; Tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@tmYLLabelFont = 21             ; Tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

;-------------------
; Legend
;-------------------

 res@pmLegendDisplayMode  = "Always"  ; "Always" = draws legend; "Never" = legend not drawn; "NoCreate"= no legend (default)
 res@pmLegendSide         = "Top"     ; Where the legend is placed: "Top", "Bottom", "Right", "Left"
 res@lgPerimOn            = False     ; Draws a line around the legend, default=True
 res@pmLegendWidthF       = 0.3       ; Legend width, default=0.55 when vpWidthF=0.6
 res@pmLegendHeightF      = 0.18      ; Legend height, default=0.18 when vpHeightF=0.6
 res@lgBoxMinorExtentF    = 0.1       ; Distance between items in the legend, default=0.6
 res@lgLabelFontHeightF   = 0.015     ; Label font size, default=0.02
 res@lgLabelOffsetF       = 0.04      ; Offset between legend and labels, default=0.02

 ; These values are set here and can be modified in the invidual plot functions below

 pmLegendParallelPosF    = 0.60      ; Left/right movement of legend, default=0.5
 pmLegendOrthogonalPosF  = -0.30     ; Up/down movement of legend items, default=0.02

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
; Set X-axis "timeseries" variable
;------------------------------------------------

; "timeseries" has the same size as the time dimension of the final variables

 timedim    = dimsizes(var_area_case1_flip)
 timeseries = ispan(0,timedim(0)-1,1)

;------------------------------------------------
; Plot average of each case?
;------------------------------------------------

 if (PlotAvgValue .eq. "Yes") then

   var_area_avg_case1_flip = fspan(avg(var_area_case1_flip),avg(var_area_case1_flip),timedim(0))
   var_area_avg_case2_flip = fspan(avg(var_area_case2_flip),avg(var_area_case2_flip),timedim(0))
   var_area_avg_case3_flip = fspan(avg(var_area_case3_flip),avg(var_area_case3_flip),timedim(0))
   var_area_avg_case4_flip = fspan(avg(var_area_case4_flip),avg(var_area_case4_flip),timedim(0))
   var_area_avg_case5_flip = fspan(avg(var_area_case5_flip),avg(var_area_case5_flip),timedim(0))

 end if

;***********************************************************
; Make the plot
;***********************************************************

; Case 1
 res@xyExplicitLegendLabels = cases(0)
 res@xyLineColors           = xyLineColors(0)
 res@xyDashPatterns         = xyDashPatterns
 res@xyLineThicknessF       = xyLineThicknessF
 res@pmLegendParallelPosF   = pmLegendParallelPosF
 res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF
 plot1 = gsn_csm_xy(wks,timeseries,var_area_case1_flip,res)

 if (PlotAvgValue .eq. "Yes") then

  res@xyExplicitLegendLabels = (/""+cases(0)+"_avg"/)
  res@xyLineColors           = xyLineColors(0)
  res@xyDashPatterns         = 2
  res@xyLineThicknessF       = 1
  res@pmLegendParallelPosF   = pmLegendParallelPosF+0.24
  res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF
  plot10 = gsn_csm_xy(wks,timeseries,var_area_avg_case1_flip,res)

 end if

; Case 2
 res@xyExplicitLegendLabels = cases(1)
 res@xyLineColors           = xyLineColors(1)
 res@xyDashPatterns         = xyDashPatterns
 res@xyLineThicknessF       = xyLineThicknessF
 res@pmLegendParallelPosF   = pmLegendParallelPosF
 res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.04
 plot2 = gsn_csm_xy(wks,timeseries,var_area_case2_flip,res)

 if (PlotAvgValue .eq. "Yes") then

  res@xyExplicitLegendLabels = (/""+cases(1)+"_avg"/)
  res@xyLineColors           = xyLineColors(1)
  res@xyDashPatterns         = 2
  res@xyLineThicknessF       = 1
  res@pmLegendParallelPosF   = pmLegendParallelPosF+0.24
  res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.04
  plot20 = gsn_csm_xy(wks,timeseries,var_area_avg_case2_flip,res)

 end if

; Case 3
 res@xyExplicitLegendLabels = cases(2)
 res@xyLineColors           = xyLineColors(2)
 res@xyDashPatterns         = xyDashPatterns
 res@xyLineThicknessF       = xyLineThicknessF
 res@pmLegendParallelPosF   = pmLegendParallelPosF
 res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.08
 plot3 = gsn_csm_xy(wks,timeseries,var_area_case3_flip,res)

 if (PlotAvgValue .eq. "Yes") then

  res@xyExplicitLegendLabels = (/""+cases(2)+"_avg"/)
  res@xyLineColors           = xyLineColors(2)
  res@xyDashPatterns         = 2
  res@xyLineThicknessF       = 1
  res@pmLegendParallelPosF   = pmLegendParallelPosF+0.24
  res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.08
  plot30 = gsn_csm_xy(wks,timeseries,var_area_avg_case3_flip,res)

 end if

; Case 4
 res@xyExplicitLegendLabels = cases(3)
 res@xyLineColors           = xyLineColors(3)
 res@xyDashPatterns         = xyDashPatterns
 res@xyLineThicknessF       = xyLineThicknessF
 res@pmLegendParallelPosF   = pmLegendParallelPosF
 res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.12
 plot4 = gsn_csm_xy(wks,timeseries,var_area_case4_flip,res)

 if (PlotAvgValue .eq. "Yes") then

  res@xyExplicitLegendLabels = (/""+cases(3)+"_avg"/)
  res@xyLineColors           = xyLineColors(3)
  res@xyDashPatterns         = 2
  res@xyLineThicknessF       = 1
  res@pmLegendParallelPosF   = pmLegendParallelPosF+0.24
  res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.12
  plot40 = gsn_csm_xy(wks,timeseries,var_area_avg_case4_flip,res)

 end if

; Case 5
 res@xyExplicitLegendLabels = cases(4)
 res@xyLineColors           = xyLineColors(4)
 res@xyDashPatterns         = xyDashPatterns
 res@xyLineThicknessF       = xyLineThicknessF
 res@pmLegendParallelPosF   = pmLegendParallelPosF
 res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.16
 plot5 = gsn_csm_xy(wks,timeseries,var_area_case5_flip,res)

 if (PlotAvgValue .eq. "Yes") then

  res@xyExplicitLegendLabels = (/""+cases(4)+"_avg"/)
  res@xyLineColors           = xyLineColors(4)
  res@xyDashPatterns         = 2
  res@xyLineThicknessF       = 1
  res@pmLegendParallelPosF   = pmLegendParallelPosF+0.24
  res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.16
  plot50 = gsn_csm_xy(wks,timeseries,var_area_avg_case5_flip,res)

 end if

 if (PlotAvgValue .eq. "No") then

  overlay(plot1,plot2)
  overlay(plot1,plot3)
  overlay(plot1,plot4)
  overlay(plot1,plot5)
  draw(plot1)
  frame(wks)

 else if (PlotAvgValue .eq. "Yes") then

  overlay(plot1,plot2)
  overlay(plot1,plot3)
  overlay(plot1,plot4)
  overlay(plot1,plot5)
  overlay(plot1,plot10)
  overlay(plot1,plot20)
  overlay(plot1,plot30)
  overlay(plot1,plot40)
  overlay(plot1,plot50)
  draw(plot1)
  frame(wks)

 end if
 end if

end
