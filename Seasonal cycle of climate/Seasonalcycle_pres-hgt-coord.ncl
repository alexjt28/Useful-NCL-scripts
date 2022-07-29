;-------------------------------------------------------------------------------------------------------------------
; This script reads in variables from a climatology netCDF file and produces a seasonal cycle plot of each case's
; values (can include differences too) and plots of each month. This script produces a zonal/meridional average of
; the variable produced. This script includes functionality for calculating values from five (5) separate cases; 
; however, it can be easily modified to increase/decrease this number.
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

 mapdiffs = "Yes"

;------------------------------------------------
; Add filepaths for time series data here
;------------------------------------------------

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
  MON = (/ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 /) ; leave as is
; MON needs indices not actual months

;------------------------------------------------
; Specify the fields and properties here
;------------------------------------------------ 

; Which variable(s) to plot? Can perform math operations on these variables 

 VAR1 = "T" 
 VAR2 = ""

; What are the units of the variable?
 UNITS = "K"                    

; Which Math operation to perform if there are two variables? 
 MATH = ""   ; options:  "add"->VAR1+VAR2, "sub"->VAR1-VAR2, "mul"->VAR1*VAR2, "div"->VAR1/VAR2

; Plot at a specific atmospheric pressure level? Specify value in hPa (ex. "850") or leave blank ("")

 ; Define pressure levels with this array
  lev_p = ispan(0,1000,50)  ; ex. Pressure array goes from 0 hPa to 1000 hPa by 50 hPa
  lev_p!0         = "lev_p"                  ; variable/dim name
  lev_p&lev_p     =  lev_p                   ; create coordinate variable
  lev_p@long_name = "pressure"               ; attach some attributes
  lev_p@units     = "hPa"
  lev_p@positive  = "down"

; Do you want to scale the variables by a certain factor?
 MULT = 1.0  ; this factor turns m/s into mm/day

;--------------------------------------------------------------
; Coordinate averages and XY axes 
;--------------------------------------------------------------

; Which coordinate do you want to remain after averaging (lat or lon)?

 CoordAvg = "lon"

; Axes strings

 tiXAxisString = ""       ; X-axis string
 tiYAxisString = "Pressure (hPa)"  ; Y-axis string

; Manual Levels for X-axis coordinates (1=ON, 0=OFF)
 ManLevX = 1      ; 0 for global, 1 for zoom
 xmin    = -180.0;        -180.0; -120.0; -180.0 ; LAT: (-°S, +°N), LON: (-°W, +°E),
 xmax    = 177.5; 180.0 ;        180.0;  60.0; 180.0  ; LAT: (-°S, +°N), LON: (-°W, +°E)

; If not plotting full atmospheric column, specify here
 ManLevY = 1
 ymin    = 100
 ymax    = 1000

; Spacing between coordinate ticks
 gsnMajorSpacing = 5    ; Degrees of spacing b/w ticks, ex. 30 leads to 30°N,60°N,90°N ticks

; Limit zonal/meridional region of averaging?
; Latitude: 0 to +90 = north, -90 to 0 = south
; Longitude: 0-177.5=E, 180-360=W (when indexing using lon_flip)
; Global: westlon=180.0, eastlon=177.5

 southlat = -60.0
 northlat = 60.0
 westlon  = 280.0
 eastlon  = 290.0

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
 outputfilename = "pdfs/seasonalcycle_year"+YEARS+"_"+VAR1+""+MATH+""+VAR2+"_preshgt_"+CoordAvg+"_"+coordname+"_"+name+""

;-----------------------------------------------------------
; Specify contour levels for absolute and difference values
;-----------------------------------------------------------

; Manual Levels for absolute contour plotting (1=ON, 0=OFF) 
 ManLevAbs = 0      
 abs_hival = 14.0
 abs_loval = -14.0
 abs_spval =  1.0

; Manual Levels for difference contour plotting (1=ON, 0=OFF)
 ManLevDif = 0
 dif_hival =  5.0
 dif_loval =  -5.0
 dif_spval =  0.5

;-------------------------------------------------
; Important plot specifications to set here
;-------------------------------------------------

 ColorTableName1 = "cmp_haxby" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 ColorTableName2 = "BlueYellowRed" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml
 LeftString     = "~F21~"+VAR1+""+MATH+""+VAR2+""
 CenterString   = ""
 RightString    = coordname

 Panelplot = "No"

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

       var1_time = vinth2p(var1_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var1_orig,var1_time)
      if (VAR2 .ne. "") then 
       var2_time = vinth2p(var2_orig,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
       copy_VarAtts(var2_orig,var2_time)
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

   var1_time!0     = "time"
   var1_time!1     = "lev_p"
   var1_time!2     = "lat"
   var1_time!3     = "lon"
   var1_time&lev_p = lev_p
   var1_time&lat   = lat
   var1_time&lon   = lon
  if (VAR2 .ne. "") then
   var2_time!0     = "time"
   var2_time!1     = "lev_p"
   var2_time!2     = "lat"
   var2_time!3     = "lon"
   var2_time&lev_p = lev_p
   var2_time&lat   = lat
   var2_time&lon   = lon
  end if

;************************************************
; Perform math operator if necessary
;-----------------------------------------------*
; Loop continues here...
;-----------------------------------------------*
;************************************************

if (VAR2 .ne. "") then

 ; Eliminate division by zero
 var2_time = where(var2_time .eq. 0, var2_time@_FillValue, var2_time)

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

; Convert to climatology
 var_months = clmMonTLLL(var_time)

; Select months for average
  var_lev = var_months ;  dim_avg_wgt_n_Wrap(var_months(MON,:,:,:),wgt_mon,0,0)

;*********************************************************
; Define metadata for final variable and perform lonFlip
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

; Metadata

 var_lev!0     = "time"
 var_lev!1     = "lev_p"
 var_lev!2     = "lat"
 var_lev!3     = "lon"
 var_lev&lev_p = lev_p
 var_lev&lat   = lat
 var_lev&lon   = lon

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

  var_avg = dim_avg_n_Wrap(var_lev_flip(:,:,:,lon_w:lon_e),3)

  var_avg!0   = "time"
  var_avg!1   = "lev"
  var_avg!2   = "lat"
  var_avg&lev = lev_p
  var_avg&lat = lat

  print("-------------------------------------------------")
  print("Lon averaged over "+lon_flip(lon_w)+" to "+lon_flip(lon_e)+"")
  print("-------------------------------------------------")

 else if (CoordAvg .eq. "lon") then

  rad = 4.0*atan(1.0)/180.0
  gw  = (cos(lat*rad))/2

  lat_s = min(ind(lat .ge. southlat))
  lat_n = max(ind(lat .le. northlat))

  ; Weighted-average when averaging over latitude

  vardims = dimsizes(var_lev(:,:,lat_s:lat_n,:))
  congw = conform_dims((/vardims(0),vardims(1),vardims(2),vardims(3)/),gw(lat_s:lat_n),2)
  var_avg = dim_sum_n(var_lev(:,:,lat_s:lat_n,:)*congw,2)/dim_sum_n(congw,2)

  var_avg!0   = "time"
  var_avg!1   = "lev"
  var_avg!2   = "lon"
  var_avg&lev = lev_p
  var_avg&lon = lon

  var_avg = lonFlip(var_avg)

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

; If more than three cases, include another if/then here to accommodate...

; Now delete the unneeded variables

  delete([/fil,ins,var1,var1_orig,numlevs_subone,hybm1,hyam1,P0,P0mb,ps1,intyp,var1_time,var_time,var_lev,var_avg/])
 if (VAR2 .ne. "") then
  delete([/var2,var2_orig,var2_time/])
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

;-------------------------------------------------
; Contour specifications
;-------------------------------------------------

 res@cnFillOn            = True        ; Fill in contours?
 res@cnFillMode          = "RasterFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 res@cnRasterSmoothingOn = True
 res@cnLinesOn           = False       ; Contour lines?
 res@cnLineLabelsOn      = False       ; Contour line labels?

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

 ; Axes text and tick spacing

 res@tmYUseLeft           = True             ; Uses left Y-axis for Y-axis string
 res@tiXAxisString        = tiXAxisString    ; X-axis string
 res@tiXAxisFont          = 21               ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@tiXAxisFontHeightF   = 0.022; 0.02             ; X-axis string font height, default=0.025 
 res@tiXAxisOffsetYF      = 0.22             ; Moves the X-axis label up/down, default=0.0
 res@tiYAxisString        = tiYAxisString    ; Y-axis string
 res@tiYAxisFont          = 21               ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@tiYAxisFontHeightF   = 0.022; 0.02             ; Y-axis string font height, default=0.025 
 res@tmYRMode             = "Automatic"      ; Tick spacing on right Y-axis: "Automatic", "Manual", "Explicit"
 res@tmYROn               = True             ; True turns on right tick marks, False turns them off
 res@tmXBLabelFontHeightF = 0.02; 0.014            ; X-axis font height, default=0.02
 res@tmYLLabelFontHeightF = 0.02; 0.014            ; Y-axis font height, default=0.02
 res@gsnMajorLatSpacing   = gsnMajorSpacing  ; Latitude stride
 res@gsnMajorLonSpacing   = gsnMajorSpacing  ; Longitude stride

;------------------------------------------------
; Color and label bar specifications
;------------------------------------------------

; Colors

 gsn_define_colormap(wks,""+ColorTableName1+"")  ; Set at beginning of script by ColorTable
 ReverseColorTable = False                  ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if
 res@lbLabelBarOn         = True             ; True turns on label bar
 res@gsnSpreadColors      = True             ; if True, reduces colors used from color table
 res@gsnSpreadColorStart  = 2; 20              ; Index to start with: default=2
 res@gsnSpreadColorEnd    = -2;-20              ; Index to end with: default=-1

; Label Bar Style

 res@pmLabelBarOrthogonalPosF = 0.08               ; Up and down position of label bar, default=0.02
 res@lbOrientation            = "horizontal"       ; Orientation of label bar: "horizontal" or "vertical"
 res@lbLabelStride            = 2                  ; How many labels to skip
 res@lbBoxEndCapStyle         = "TriangleBothEnds" ; What shape to have at the ends of the label bar, options are:
                                               ; "TriangleBothEnds", "TriangleLowEnd", "TriangleHighEnd", "RectangleEnds"
; Label Text

 res@lbLabelFontHeightF = 0.015; 0.01   ; Size of label font, default=0.02
 res@lbLabelAngleF      = 0      ; Angle of the label text, default=0.0
 res@lbLabelFont        = 21     ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

; Label Bar Title Text - displays units

 res@lbTitleString      = "~F21~"+UNITS+"" ; Label bar title text string
 res@lbTitlePosition    = "Right"          ; Where to place label bar title text string
                                       ; "Top","Bottom","Left","Right"
 res@lbTitleDirection   = "Across"         ; Direction of title text: "Across" or "Down"
 res@lbTitleFont        = 21               ; Title font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@lbTitleFontHeightF = 0.015            ; Title font size, default=0.025

;------------------------------------------------
; Plot tick marks
;------------------------------------------------

 res@tmXBLabelFont = 21  ; X-axis tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@tmYLLabelFont = 21  ; Y-axis tick font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

 res@tmXBMinorOn = True  ; Draws X-axis minor ticks
 res@tmYLMinorOn = True  ; Draws Y-axis minor ticks

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
; Monthly plot center strings
;------------------------------------------------

 date = (/"~F22~Jan","~F22~Feb","~F22~Mar","~F22~Apr","~F22~May","~F22~Jun","~F22~Jul","~F22~Aug","~F22~Sep","~F22~Oct","~F22~Nov","~F22~Dec"/)

;***********************************************************
; Make the plot
;***********************************************************

; Need to apply metadata for these plots

 diff_case2_case1 = var_avg_case2 - var_avg_case1
 copy_VarCoords(var_avg_case1,diff_case2_case1)
 diff_case3_case1 = var_avg_case3 - var_avg_case1 
 copy_VarCoords(var_avg_case1,diff_case3_case1)
 diff_case4_case1 = var_avg_case4 - var_avg_case1 
 copy_VarCoords(var_avg_case1,diff_case4_case1)
 diff_case5_case1 = var_avg_case5 - var_avg_case1 
 copy_VarCoords(var_avg_case1,diff_case5_case1)

 printVarSummary(diff_case2_case1)

;----------------------------------------
; Absolute value map plots
;----------------------------------------

 plotmap = new(60, graphic) ; 5 cases x 12 months each

 i=0
 do while(i.le.11)
   res@gsnLeftString = ""+LeftString+" "+cases(0)
   res@gsnCenterString = date(i)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,var_avg_case1(i,:,:),res)
 i=i+1
 end do

 i=12
 do while(i.le.23)
   res@gsnLeftString = ""+LeftString+" "+cases(1)
   res@gsnCenterString = date(i-12)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,var_avg_case2(i-12,:,:),res)
 i=i+1
 end do

 i=24
 do while(i.le.35)
   res@gsnLeftString = ""+LeftString+" "+cases(2)
   res@gsnCenterString = date(i-24)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,var_avg_case3(i-24,:,:),res)
 i=i+1
 end do

 i=36
 do while(i.le.47)
   res@gsnLeftString = ""+LeftString+" "+cases(3)
   res@gsnCenterString = date(i-36)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,var_avg_case4(i-36,:,:),res)
 i=i+1
 end do

 i=48
 do while(i.le.59)
   res@gsnLeftString = ""+LeftString+" "+cases(4)
   res@gsnCenterString = date(i-48)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,var_avg_case5(i-48,:,:),res)
 i=i+1
 end do

if (mapdiffs .eq. "Yes") then

 gsn_define_colormap(wks,""+ColorTableName2+"")  ; Set at beginning of script by ColorTable
 ReverseColorTable = False                  ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if

; Set the difference contour levels

 if (ManLevDif .eq. 1) then
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMaxLevelValF       =  dif_hival
   res@cnMinLevelValF       =  dif_loval
   res@cnLevelSpacingF      =  dif_spval
 end if

 i=0
 do while(i.le.11)
   res@gsnLeftString = ""+LeftString+" "+cases(1)+"-"+cases(0)
   res@gsnCenterString = date(i)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,diff_case2_case1(i,:,:),res)
 i=i+1
 end do

 i=12
 do while(i.le.23)
   res@gsnLeftString = ""+LeftString+" "+cases(2)+"-"+cases(0)
   res@gsnCenterString = date(i-12)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,diff_case3_case1(i-12,:,:),res)
 i=i+1
 end do

 i=24
 do while(i.le.35)
   res@gsnLeftString = ""+LeftString+" "+cases(3)+"-"+cases(0)
   res@gsnCenterString = date(i-24)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,diff_case4_case1(i-24,:,:),res)
 i=i+1
 end do

 i=36
 do while(i.le.47)
   res@gsnLeftString = ""+LeftString+" "+cases(4)+"-"+cases(0)
   res@gsnCenterString = date(i-36)
   res@gsnRightString = coordname
   plotmap(i) = gsn_csm_pres_hgt(wks,diff_case5_case1(i-36,:,:),res)
 i=i+1
 end do

end if

end
