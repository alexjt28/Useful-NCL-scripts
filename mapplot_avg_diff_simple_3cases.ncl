begin

;-------------------------------------------------------------------------------------------------------------------
; This script takes a time series from climate model output as netCDF files and plots the average spatial difference
; It is optimized to only include the simplest parts needed to run with three separate cases. 
;
; Author: Alex Thompson
; Date: 7/2/2019
; File name: mapplot_avg_diff_simple_3cases.ncl 
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

 ; Add file paths

 CASES = (/ "[example... path 1 goes here]", "[example... path 2 goes here]", "[example... path 3 goes here]" /)

 cases = (/ "[example name 1]","[example name 2]","[example name 3]"/)

; Is there a special name for these cases to include in the output file name?
 name = "[example description here]"

 numcases = 3
 monthly  = "Yes"

;-------------------------------------------------------
; Are the netCDF files a list of separate monthly files?
;-------------------------------------------------------

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
 outputfilename = "/pdfs/"+SEASON+"_year"+YEARS+"_"+VAR1+""+MATH+""+VAR2+"_"+LEVEL+"_"+name+""

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
; Important plot specifications to set here
;-------------------------------------------------

 ColorTableName = "BlAqGrYeOrReVi200"
 LeftString     = "~F21~"+SEASON+" "+VAR1+""+MATH+""+VAR2+""
 CenterString   = ""
 RightString    = ""

 Panelplot = "Yes"

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

 res@lbLabelBarOn        = True
 res@ColorTable          = ColorTableName       ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 res@ReverseColorTable   = False                ; Reverse color table order?
 res@gsnSpreadColors     = True                 ; if True, reduces colors used from color table
 res@gsnSpreadColorStart =  20                  ; Index to start with: default=2
 res@gsnSpreadColorEnd   = -20                  ; Index to end with: default=-1

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

;***********************************************************
; Make the plot
;***********************************************************

;----------------------------------------
; Absolute value map plots
;----------------------------------------

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

  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_contour_map_ce(wks,var_averg_case2_flip-var_averg_case1_flip,res)

  res@gsnCenterString = ""+cases(2)+"-"+cases(1)+""
  diff_3_2 = gsn_csm_contour_map_ce(wks,var_averg_case3_flip-var_averg_case2_flip,res)

  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_contour_map_ce(wks,var_averg_case3_flip-var_averg_case1_flip,res)

;-----------------------
; Panel plot
;-----------------------

if (Panelplot .eq. "Yes") then

   gsn_panel(wks,(/plot1,plot2,plot3,diff_2_1,diff_3_2,diff_3_1/),(/2,3/),res)

end if

end
