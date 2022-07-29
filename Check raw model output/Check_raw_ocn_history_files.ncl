begin

;-------------------------------------------------------------------------------------------------------------------------------
; This script looks at time series data of raw ocean model output in the form of monthly files and plots it as a time series
;
; Author: Alex Thompson
; Date: 7/29/2022
;
; Example case used here is: b.e12.B1850C5.f19_g16.i06ka.07 {years 01-10 in monthly output}
;-------------------------------------------------------------------------------------------------------------------------------

; Load this file for remapping ocean grid
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"

;************************************************
;************************************************
; MODIFY THIS SECTION
;************************************************
;************************************************

;------------------------------------------------
; Specify POP scratch path
;------------------------------------------------

 CASE = "[/filepath/to/case/]b.e12.B1850C5.f19_g16.i06ka.07.pop.h."

 case = "i06ka.07"

; "surface" or "bottom" of the ocean?
 LEV = "surface"

 L1  = "{"                                       ; one year: ""  multiple years: "{"
 R1  = "}"                                       ; one year: ""  multiple years: "}"
 
 YR  = "0001,0002,0003,0004,0005,0006,0007,0008,0009,0010"
 
 L2  = "{"                                       ; one month/day: ""  multiple months/days: "{"
 R2  = "}"                                       ; one month/day: ""  multiple months/days: "}"
 MON = "01,02,03,04,05,06,07,08,09,10,11,12"    ; monthly: 01,02,etc. daily: 01-01,01-06,etc.
 END = ".nc"                                    ; monthly: .nc        daily: -21600.nc

 YEARS   = "01-10"
 SEASON  = "ANN"
 SEASAVG = "Yes"

 Print_metadata = "Yes"
 Print_Values   = "Yes"
 PlotAvgValue   = "Yes"

;------------------------------------------------
; Which variable(s) to plot and their units
;------------------------------------------------

 VAR = "TEMP"  ; "TEMP" or "SALT"

 UNITS = "degC" ; units of the variable

;------------------------------------------------
; Contour and zooming specifications
;------------------------------------------------

; Manual range for xy plotting (1=ON, 0=OFF)
 ManLevX = 0
 xmax = 40
 xmin = 0

 ManLevY = 0
 ymax = 20
 ymin = -20

 trYReverse = False

;------------------------------------------------
; Region/Point to Average Over
;------------------------------------------------

 Averaging = "Region"   ; "Region" or "Point"

 southlat = -90                  ; global
 northlat = 90
 westlon  = 0
 eastlon  = 360

;------------------------------------------------
; Line properties
;------------------------------------------------

 xyLineColors     = "black"
 xyLineThicknessF = 5.0
 xyDashPatterns   = 0

;------------------------------------------------
; File specifications
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

; ; If no second variable, this is used for file name
  outputfilename = ""+SEASON+"_year"+YEARS+"_"+VAR+"_timeseries_"+case+""

;------------------------------------------------
; Text strings and specifications on the plot
;------------------------------------------------

; Do you want to make a custom string for left or center title?
; Yes = 1, No = 0

 LeftString  = "~F21~"+SEASON+" "+LEV+" "+VAR+" avg("+southlat+","+northlat+";"+westlon+","+eastlon+")"
 RightString = ""

 tiXAxisString = "Year"
 tiYAxisString = ""+VAR+" ("+UNITS+")" ; Left Y axis string text

;************************************************
; This section is where the code is
;************************************************
;************************************************

;************************************************
; Read in CASE
;************************************************

; Read in VAR1 from CASE file
 fils_CASE = systemfunc("ls "+CASE+""+L1+""+YR+""+R1+"-"+L2+""+MON+""+R2+""+END+"")
 ins_CASE  = addfiles(fils_CASE,"r")
 ListSetType(ins_CASE,"cat")

; -----------------------------------
; ONLY OCCURS FOR CASE
; Coordinates

; lat = ins_CASE[0]->TLAT
; lon = ins_CASE[0]->TLONG
 lat = fspan(-90,90,96)     ; NOTE: Need to modify these lines if running a different ocean grid resolution
 lon = fspan(0,360,144)     ; NOTE: Need to modify these lines if running a different ocean grid resolution

; -----------------------------------
; Read in variable, limit levels to run faster

  delim = ","
  nummonths = str_fields_count(MON,delim)
  if (LEV.eq."surface") then
    var_CASE = ins_CASE[:]->$VAR$(:,0,:,:)
  elseif (LEV.eq."bottom") then
    var_CASE1 = ins_CASE[:]->$VAR$(:,51,:,:)
  end if

;********************************************************
; Convert POP grid to lat/lon grid
;********************************************************

  var_CASE_remap = PopLatLon(var_CASE,"gx1LPIA4ig","fv19_25","bilin","da","180811")
  printVarSummary(var_CASE_remap)

;************************************************
; Yearly/seasonal averages or all months?
;************************************************

 delim = ","
 nummonths = str_fields_count(MON,delim)
 numyrs    = str_fields_count(YR,delim)

 if (SEASAVG .eq. "Yes") then

  ; Averages months to get yearly- or seasonal-averaged time series values

   var_resh = reshape(var_CASE_remap, (/numyrs,nummonths,dimsizes(lat),dimsizes(lon)/))
   var_seas = dim_avg_n_Wrap(var_resh,1)

 else if (SEASAVG .eq. "No") then

   var_seas = var_CASE_remap

 end if
 end if

;********************************************************
; Average values over a certain region for time series
;********************************************************

  rad = 4.0*atan(1.0)/180.0
  clat  = cos(lat*rad)

  lat_s = min(ind(lat .ge. southlat))
  lat_n = max(ind(lat .le. northlat))
  lon_w = min(ind(lon .ge. westlon))
  lon_e = max(ind(lon .le. eastlon))

  var_wgt = wgt_areaave(var_seas(:,lat_s:lat_n,lon_w:lon_e),clat(lat_s:lat_n),1.0,0)

  printVarSummary(var_wgt)

  print("Region = "+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_w+"-"+lon_e+"("+lon_w+","+lon_e+")")

  timedim    = dimsizes(var_wgt)
  timeseries = ispan(0,timedim(0)-1,1)

 if (PlotAvgValue .eq. "Yes") then

   var_avg_wgt = fspan(avg(var_wgt),avg(var_wgt),timedim(0))

   if (Print_Values .eq. "Yes") then

     print(var_avg_wgt(0))

   end if

 end if

;************************************************
; Make the plot
;************************************************

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

 res@gsnLeftString   = LeftString
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

;***********************************************************
; Make the plot
;***********************************************************

 res@xyExplicitLegendLabels = case
 res@xyLineColors           = xyLineColors(0)
 res@xyDashPatterns         = xyDashPatterns
 res@xyLineThicknessF       = xyLineThicknessF
 res@pmLegendParallelPosF   = pmLegendParallelPosF
 res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF
 plot1 = gsn_csm_xy(wks,timeseries,var_wgt,res)

 if (PlotAvgValue .eq. "Yes") then

  res@xyExplicitLegendLabels = (/""+case+"_avg"/)
  res@xyLineColors           = xyLineColors(0)
  res@xyDashPatterns         = 2
  res@xyLineThicknessF       = 1
  res@pmLegendParallelPosF   = pmLegendParallelPosF+0.24
  res@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF
  plot10 = gsn_csm_xy(wks,timeseries,var_avg_wgt,res)

  overlay(plot1,plot10)
  draw(plot1)
  frame(wks)

 end if

 res@cnFillOn       = True        ; Fill in contours?
 res@cnFillMode     = "AreaFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 res@cnLinesOn      = False       ; Contour lines?
 res@cnLineLabelsOn = False       ; Contour line labels?
 res@gsnAddCyclic   = True        ; Eliminates gap in longitudinal data

 plot11 = gsn_csm_contour_map_ce(wks,dim_avg_n_Wrap(var_seas,0),res)

end
