;-------------------------------------------------------------------------------------------------------------------------
; This script reads in isotopic variables from a climatology netCDF file and produces a seasonal cycle plot of each case's
; values (can include differences too) and map plots of each month. This script includes functionality for 
; calculating values from five (5) separate cases; however, it can be easily modified to increase/decrease this number.
;
; Author: Alex Thompson
; Date: 7/29/2022
;-------------------------------------------------------------------------------------------------------------------------

begin

;************************************************
;************************************************
; SET ALL VARIABLES IN THIS SECTION
;************************************************
;************************************************

;------------------------------------------------
; Which plots do you want to have?
;------------------------------------------------

 xyplots  = "Yes"
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

; Plot weighted or unweighted isotope values?
 WT = "wt"  ; "wt" or "" (blank)

; Which variable(s) to plot? Can perform math operations on these variables

 WTVAR = "PRECT" ; Special cases: "PRECT" and "H2OSOI"
 ISO   = "d18O"  ; "d18O", "dHDO", or "dexcess"
 Liso  = "precip"  ; Special cases: "precip" or "soil"
 Hiso  = "precip"  ; Else, input variable names here

 SOIL_LEV = 4

; What are the units of the variable?
 UNITS = "permil"
 ptiny = 1.E-18

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
; Do you want to overlay wind vectors?
;--------------------------------------------------------------

 OVERLAY_WIND = "Yes"

 WIND_LEVEL   = "850"                      ; Text string in hPa
 WIND_UNITS   = "m/s"                      ; Text string
 wind_lev_ind = ind(lev_p .eq. WIND_LEVEL) ; wind_lev_ind converts WIND_LEVEL to the corresponding index of lev_p

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = "pdfs/seasonalcycle_year"+YEARS+"_"+WTVAR+"-"+WT+"_"+ISO+""+Liso+"_"+LEVEL+"_xy"+xyplots+"_map"+mapplots+"_mapdiffs"+mapdiffs+"_winds"+WIND_LEVEL+""+OVERLAY_WIND+"_"+name+""

;------------------------------------------------
; Text strings for both plots
;------------------------------------------------

 LeftString     = "~F21~"+WTVAR+""+WT+"-"+ISO+"_"+Liso+" "+LEVEL+""
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

 latpoint = 16.0; 
 lonpoint = 270.0; 

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
 ManLevY = 1
 ymin    = -7.0
 ymax    = -1.0

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
 hival = 0.0
 loval = -10.0
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
  LatMin = -10; -40 ; negative values = °S
  LatMax = 40; 90   ; positive values = °N
  LonMin = -150 ; negative values = °W
  LonMax = -30; 60  ; positive values = °E
 end if

;-------------------------------------------------
; For mapplot, important plot specifications to set here
;-------------------------------------------------

 ColorTableName = "cmp_haxby";  "BlueYellowRed" ; "cmp_haxby" ; Take text from https://www.ncl.ucar.edu/Document/Graphics/color_table_gallery.shtml

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

; For seasonal cycle of isotopes, need to loop through each month

 ; First initialize variables

 delim           = ","
 numyrs          = ((endi-begi)+1)/12 
 nummonths       = count_unique_values(MON)
 dimfil          = CASES(i-1)
 dimins          = addfile(dimfil,"r")
 if (WTVAR .eq. "PRECT") then
  dimvar         = dimins->PRECC 
 else
  dimvar         = dimins->$WTVAR$
 end if
 if (LEVEL .ne. "") then
  lev = dimvar&lev
 end if
 lat             = dimvar&lat
 lon             = dimvar&lon
 iso_d18O_seasonal    = new((/12,dimsizes(lat),dimsizes(lon)/),float)
 iso_d18O_wt_seasonal = new((/12,dimsizes(lat),dimsizes(lon)/),float)
 iso_dHDO_seasonal    = new((/12,dimsizes(lat),dimsizes(lon)/),float)
 iso_dHDO_wt_seasonal = new((/12,dimsizes(lat),dimsizes(lon)/),float)

 ; Now loop through each month

 do k=0,11

 ; Initialize variables

  if (LEVEL .ne. "") then 
    wtvar           = new((/numyrs,dimsizes(lev),dimsizes(lat),dimsizes(lon)/),float)
    ps1             = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
    lightiso_d18O   = new((/numyrs,dimsizes(lev),dimsizes(lat),dimsizes(lon)/),float)
    heavyiso_d18O   = new((/numyrs,dimsizes(lev),dimsizes(lat),dimsizes(lon)/),float)
    lightiso_dHDO   = new((/numyrs,dimsizes(lev),dimsizes(lat),dimsizes(lon)/),float)
    heavyiso_dHDO   = new((/numyrs,dimsizes(lev),dimsizes(lat),dimsizes(lon)/),float)
  else
    wtvar           = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
    lightiso_d18O   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
    heavyiso_d18O   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
    lightiso_dHDO   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
    heavyiso_dHDO   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
  end if

 ; Create indexing array

  MONindex = ispan(k,numyrs*nummonths-1,12) 

 ; Read in variables and scale them

     fil = CASES(i-1)
     ins = addfile(fil,"r")

   ; Read in variable to weight isotopic values by

    if (WTVAR .eq. "PRECT") then
     wtvar = ins->PRECC(MONindex,:,:) + ins->PRECL(MONindex,:,:)
    else if (WTVAR .eq. "H2OSOI") then
     wtvar = ins->H2OSOI(MONindex,SOIL_LEV,:,:)
    else if (LEVEL .ne. "") then
     wtvar = ins->$WTVAR$(MONindex,:,:,:)
    else
     wtvar = ins->$WTVAR$(MONindex,:,:)
    end if
    end if
    end if

   ; Convert sigma to pressure levels if necessary

    if (LEVEL .ne. "") then

      lev            = wtvar&lev
      numlevs_subone = dimsizes(lev)-1
      hybm1          = ins->hybm(0:numlevs_subone) ; hybm is the 'sigma' coordinate
      hyam1          = ins->hyam(0:numlevs_subone) ; create a bogus hyam 1D array
      P0             = ins->P0(0)
      P0mb           = P0*0.01
      ps1            = ins->PS(MONindex,:,:)   ; these are in Pa
      intyp          = 1
      wtvar_lev = vinth2p(wtvar,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
      copy_VarAtts(wtvar,wtvar_lev)
      wtvar_time = wtvar_lev(:,lev_ind,:,:)

    else

      wtvar_time = wtvar

    end if

   ; Finish processing the variable to weight by

     wtvar_4d = reshape(wtvar_time, (/ numyrs, 1, dimsizes(lat), dimsizes(lon) /))

   ; Now read in isotopic values

    ; d18O
      if (Liso .eq. "precip") then
        lightiso_d18O = ins->PRECRC_H216Or(MONindex,:,:) + ins->PRECSC_H216Os(MONindex,:,:) + ins->PRECRL_H216OR(MONindex,:,:) + ins->PRECSL_H216OS(MONindex,:,:)
        heavyiso_d18O = ins->PRECRC_H218Or(MONindex,:,:) + ins->PRECSC_H218Os(MONindex,:,:) + ins->PRECRL_H218OR(MONindex,:,:) + ins->PRECSL_H218OS(MONindex,:,:)
      else if (Liso .eq. "soil") then
        lightiso_d18O = ins->H2OSOI_H2OTR(MONindex,SOIL_LEV,:,:)
        heavyiso_d18O = ins->H2OSOI_H218O(MONindex,SOIL_LEV,:,:)
      else if (LEVEL .ne. "") then
        lightiso_d18O = ins->$Liso$(MONindex,:,:,:)
        heavyiso_d18O = ins->$Hiso$(MONindex,:,:,:)
      else
        lightiso_d18O = ins->$Liso$(MONindex,:,:)
        heavyiso_d18O = ins->$Hiso$(MONindex,:,:)
      end if
      end if
      end if

    ; dHDO
      if (Liso .eq. "precip") then
        lightiso_dHDO = ins->PRECRC_H2Or(MONindex,:,:) + ins->PRECSC_H2Os(MONindex,:,:) + ins->PRECRL_H2OR(MONindex,:,:) + ins->PRECSL_H2OS(MONindex,:,:)
        heavyiso_dHDO = ins->PRECRC_HDOr(MONindex,:,:) + ins->PRECSC_HDOs(MONindex,:,:) + ins->PRECRL_HDOR(MONindex,:,:) + ins->PRECSL_HDOS(MONindex,:,:)
      else if (Liso .eq. "soil") then
        lightiso_dHDO = ins->H2OSOI_H2OTR(MONindex,SOIL_LEV,:,:)
        heavyiso_dHDO = ins->H2OSOI_HDO(MONindex,SOIL_LEV,:,:)
      else if (LEVEL .ne. "") then
        lightiso_dHDO = ins->$Liso$(MONindex,:,:,:)
        heavyiso_dHDO = ins->$Hiso$(MONindex,:,:,:)
      else
        lightiso_dHDO = ins->$Liso$(MONindex,:,:)
        heavyiso_dHDO = ins->$Hiso$(MONindex,:,:)
      end if
      end if
      end if

   ; Convert sigma to pressure levels if necessary

    if (LEVEL .ne. "") then

    ; d18O
     lightiso_d18O_lev = vinth2p(lightiso_d18O,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
     copy_VarAtts(lightiso_d18O,lightiso_d18O_lev)
     lightiso_d18O_time = lightiso_d18O_lev(:,lev_ind,:,:)

     heavyiso_d18O_lev = vinth2p(heavyiso_d18O,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
     copy_VarAtts(heavyiso_d18O,heavyiso_d18O_lev)
     heavyiso_d18O_time = heavyiso_d18O_lev(:,lev_ind,:,:)

    ; dHDO
     lightiso_dHDO_lev = vinth2p(lightiso_dHDO,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
     copy_VarAtts(lightiso_dHDO,lightiso_dHDO_lev)
     lightiso_dHDO_time = lightiso_dHDO_lev(:,lev_ind,:,:)

     heavyiso_dHDO_lev = vinth2p(heavyiso_dHDO,hyam1,hybm1,lev_p,ps1,intyp,P0mb,1,False)
     copy_VarAtts(heavyiso_dHDO,heavyiso_dHDO_lev)
     heavyiso_dHDO_time = heavyiso_dHDO_lev(:,lev_ind,:,:)

    else

    ; d18O
     lightiso_d18O_time = lightiso_d18O
     heavyiso_d18O_time = heavyiso_d18O

    ; dHDO
     lightiso_dHDO_time = lightiso_dHDO
     heavyiso_dHDO_time = heavyiso_dHDO

   end if

   ; Calculate delta values

   ; d18O
    lightiso_d18O_time = where(lightiso_d18O_time.lt.ptiny,ptiny,lightiso_d18O_time)
    pre_iso_d18O_wt    = (heavyiso_d18O_time/lightiso_d18O_time - 1.) * 1000.

   ; dHDO
    lightiso_dHDO_time = where(lightiso_dHDO_time.lt.ptiny,ptiny,lightiso_dHDO_time)
    pre_iso_dHDO_wt    = (heavyiso_dHDO_time/lightiso_dHDO_time - 1.) * 1000.

   ; Amount-weight the delta value

    wtvar_4d_fixed         = where(wtvar_4d .le. 0, wtvar_4d@_FillValue, wtvar_4d)

   ; d18O
    iso_d18O_4d                 = reshape(pre_iso_d18O_wt, (/ numyrs, 1, dimsizes(lat), dimsizes(lon) /))
    iso_d18O_wt_seasonal(k,:,:) = dim_avg_n_Wrap( dim_sum_n(wtvar_4d_fixed * iso_d18O_4d, 1) / dim_sum_n(wtvar_4d_fixed, 1) , 0)
    iso_d18O_seasonal(k,:,:)    = dim_avg_n_Wrap( pre_iso_d18O_wt , 0)

   ; dHDO
    iso_dHDO_4d                 = reshape(pre_iso_dHDO_wt, (/ numyrs, 1, dimsizes(lat), dimsizes(lon) /))
    iso_dHDO_wt_seasonal(k,:,:) = dim_avg_n_Wrap( dim_sum_n(wtvar_4d_fixed * iso_dHDO_4d, 1) / dim_sum_n(wtvar_4d_fixed, 1) , 0)
    iso_dHDO_seasonal(k,:,:)    = dim_avg_n_Wrap( pre_iso_dHDO_wt , 0)

  delete([/ins,wtvar,wtvar_time,wtvar_4d,lightiso_d18O,heavyiso_d18O,lightiso_d18O_time,heavyiso_d18O_time,pre_iso_d18O_wt,iso_d18O_4d,wtvar_4d_fixed,lightiso_dHDO,heavyiso_dHDO,lightiso_dHDO_time,heavyiso_dHDO_time,pre_iso_dHDO_wt,iso_dHDO_4d/]) ; not iso_seasonal or iso_wt_seasonal
  if (LEVEL .ne. "") then
   delete([/numlevs_subone,hybm1,hyam1,P0,P0mb,ps1,intyp,wtvar_lev,lightiso_d18O_lev,heavyiso_d18O_lev,lightiso_dHDO_lev,heavyiso_dHDO_lev/])
  end if

 end do

 ; Apply isotope type

    if (ISO .eq. "d18O") then
      iso_seasonal    = iso_d18O_seasonal
      iso_wt_seasonal = iso_d18O_wt_seasonal
    else if (ISO .eq. "dHDO") then
      iso_seasonal    = iso_dHDO_seasonal
      iso_wt_seasonal = iso_dHDO_wt_seasonal
    else if (ISO .eq. "dexcess") then
      iso_seasonal    = iso_dHDO_seasonal    - 8 * iso_d18O_seasonal
      iso_wt_seasonal = iso_dHDO_wt_seasonal - 8 * iso_d18O_wt_seasonal
    end if
    end if
    end if

;*********************************************************
; Define metadata for final variable and perform lonFlip
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

; Metadata

 iso_seasonal!0   = "time"
 iso_seasonal!1   = "lat"
 iso_seasonal!2   = "lon"
 iso_seasonal&lat = lat
 iso_seasonal&lon = lon

 iso_wt_seasonal!0   = "time"
 iso_wt_seasonal!1   = "lat"
 iso_wt_seasonal!2   = "lon"
 iso_wt_seasonal&lat = lat
 iso_wt_seasonal&lon = lon

; lonFlip

 lon_flip = lonFlip(lon)
 iso_seasonal_flip    = lonFlip(iso_seasonal)
 iso_wt_seasonal_flip = lonFlip(iso_wt_seasonal)

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

  if (WT .eq. "") then
   iso_seasonal_area_flip = wgt_areaave_Wrap(iso_seasonal_flip(:,lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0)
  else if (WT .eq. "wt") then
   iso_seasonal_area_flip = wgt_areaave_Wrap(iso_wt_seasonal_flip(:,lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0)
  end if
  end if 

 else if (Average .eq. "Point") then

   lat_point = min(ind(lat .ge. latpoint))
  if (lonpoint .gt. 180) then
   lon_point = min(ind(lon_flip .ge. lonpoint))
  else
   lon_point = max(ind(lon_flip .le. lonpoint))
  end if

  if (WT .eq. "") then
   iso_seasonal_area_flip = iso_seasonal_flip(:,lat_point,lon_point)
  else if (WT .eq. "wt") then
   iso_seasonal_area_flip = iso_wt_seasonal_flip(:,lat_point,lon_point)
  end if
  end if
 
 end if
 end if

;*********************************************************
; Read in wind vectors if necessary
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

if (OVERLAY_WIND .eq. "Yes") then

 filw = CASES(i-1)
 insw = addfile(filw,"r")

 ; Read in variables
 u_prelev = insw->U
 v_prelev = insw->V

 ; Convert from sigma to pressure
 if (WIND_LEVEL .ne. "")
  wlev            = u_prelev&lev
  wnumlevs_subone = dimsizes(wlev)-1
  whybm1          = insw->hybm(0:wnumlevs_subone) ; hybm is the 'sigma' coordinate
  whyam1          = insw->hyam(0:wnumlevs_subone) ; create a bogus hyam 1D array
  wP0             = insw->P0(0)
  wP0mb           = wP0*0.01
  wps1            = insw->PS   ; these are in Pa
  wintyp          = 1
  ulev = vinth2p(u_prelev,whyam1,whybm1,lev_p,wps1,wintyp,wP0mb,1,False)
  copy_VarAtts(u_prelev,ulev)
  vlev = vinth2p(v_prelev,whyam1,whybm1,lev_p,wps1,wintyp,wP0mb,1,False)
  copy_VarAtts(v_prelev,vlev)
 end if

 ; Take pressure level and average
 U_seasonal = clmMonTLL(ulev(begi:endi,wind_lev_ind,:,:))
 V_seasonal = clmMonTLL(vlev(begi:endi,wind_lev_ind,:,:))

 ; lonFlip
 U_seasonal_flip = lonFlip(U_seasonal)
 V_seasonal_flip = lonFlip(V_seasonal)

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
 printVarSummary(iso_seasonal)
 printVarSummary(iso_wt_seasonal)
 printVarSummary(iso_seasonal_flip)
 printVarSummary(iso_wt_seasonal_flip)
 printVarSummary(iso_seasonal_area_flip)
 if (OVERLAY_WIND .eq. "Yes") then
 printVarSummary(U_seasonal_flip)
 end if
 print("**************************")
 print("End loop for CASE"+i+"...")
 print("**************************")

;-----------------------------------------------------------
; Saved variables are of the following dimensions:
;
; iso_seasonal           -> (12 months,lat,lon)
; iso_wt_seasonal        -> (12 months,lat,lon)
; iso_seasonal_flip      -> (12 months,lat,lon_flip)
; iso_wt_seasonal_flip   -> (12 months,lat,lon_flip)
; iso_seasonal_area_flip -> (12 months)
; U/V_seasonal_flip      -> (12 months,lat,lon_flip) (if necessary) 
;
;-----------------------------------------------------------

 ; Save corresponding variables
   if (i .eq. 1) then
     iso_seasonal_case1           = iso_seasonal
     iso_wt_seasonal_case1        = iso_wt_seasonal
     iso_seasonal_case1_flip      = iso_seasonal_flip
     iso_wt_seasonal_case1_flip   = iso_wt_seasonal_flip
     iso_seasonal_area_case1_flip = iso_seasonal_area_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_seasonal_case1_flip        = U_seasonal_flip
     V_seasonal_case1_flip        = V_seasonal_flip
    end if
   end if

   if (i .eq. 2) then
     iso_seasonal_case2           = iso_seasonal
     iso_wt_seasonal_case2        = iso_wt_seasonal
     iso_seasonal_case2_flip      = iso_seasonal_flip
     iso_wt_seasonal_case2_flip   = iso_wt_seasonal_flip
     iso_seasonal_area_case2_flip = iso_seasonal_area_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_seasonal_case2_flip        = U_seasonal_flip
     V_seasonal_case2_flip        = V_seasonal_flip
    end if
   end if

   if (i .eq. 3) then
     iso_seasonal_case3           = iso_seasonal
     iso_wt_seasonal_case3        = iso_wt_seasonal
     iso_seasonal_case3_flip      = iso_seasonal_flip
     iso_wt_seasonal_case3_flip   = iso_wt_seasonal_flip
     iso_seasonal_area_case3_flip = iso_seasonal_area_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_seasonal_case3_flip        = U_seasonal_flip
     V_seasonal_case3_flip        = V_seasonal_flip
    end if
   end if

   if (i .eq. 4) then
     iso_seasonal_case4           = iso_seasonal
     iso_wt_seasonal_case4        = iso_wt_seasonal
     iso_seasonal_case4_flip      = iso_seasonal_flip
     iso_wt_seasonal_case4_flip   = iso_wt_seasonal_flip
     iso_seasonal_area_case4_flip = iso_seasonal_area_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_seasonal_case4_flip        = U_seasonal_flip
     V_seasonal_case4_flip        = V_seasonal_flip
    end if
   end if

   if (i .eq. 5) then
     iso_seasonal_case5           = iso_seasonal
     iso_wt_seasonal_case5        = iso_wt_seasonal
     iso_seasonal_case5_flip      = iso_seasonal_flip
     iso_wt_seasonal_case5_flip   = iso_wt_seasonal_flip
     iso_seasonal_area_case5_flip = iso_seasonal_area_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_seasonal_case5_flip        = U_seasonal_flip
     V_seasonal_case5_flip        = V_seasonal_flip
    end if
   end if

; If more than three cases, include another if/then here to accommodate...

; Now delete the unneeded variables

 delete([/delim,fil,dimfil,dimins,dimvar,iso_seasonal,iso_wt_seasonal,iso_seasonal_flip,iso_wt_seasonal_flip,iso_seasonal_area_flip/])
 if (OVERLAY_WIND .eq. "Yes") then
  delete([/u_prelev,v_prelev,wlev,wnumlevs_subone,whybm1,whyam1,wP0,wP0mb,wps1,wintyp,ulev,vlev,U_seasonal,V_seasonal,U_seasonal_flip,V_seasonal_flip/])
 end if

end do

;-------------------------------------------------*
; Loop is done.
;-------------------------------------------------*

;*****************************************************************
; Print values, lat/lon_flip, and region for ease of calculation
;*****************************************************************

 if (Average .eq. "Region") then

   print("Region = "+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+"-"+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+"-"+lon_e+")")
   AREA = (""+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+"-"+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+"-"+lon_e+")")

 else if (Average .eq. "Point") then

   print("Point = "+lat(lat_point)+","+lon_flip(lon_point)+"("+lat_point+","+lon_point+")")
   AREA = (""+lat(lat_point)+","+lon_flip(lon_point)+"("+lat_point+","+lon_point+")")

 end if
 end if

if (Print_values .eq. "Yes") then

  print(""+cases(0)+" values = "+iso_seasonal_area_case1_flip+"")
  print(""+cases(1)+" values = "+iso_seasonal_area_case2_flip+"")
  print(""+cases(2)+" values = "+iso_seasonal_area_case3_flip+"")
  print(""+cases(3)+" values = "+iso_seasonal_area_case4_flip+"")
  print(""+cases(4)+" values = "+iso_seasonal_area_case5_flip+"")

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

 pmLegendParallelPosF    = 0.22; 0.95      ; Left/right movement of legend, default=0.5
 pmLegendOrthogonalPosF  = -0.7; -0.30     ; Up/down movement of legend items, default=0.02

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
 plotxy1 = gsn_csm_xy(wks,tmXBValues,iso_seasonal_area_case1_flip,resxy)

;; Case 2
 resxy@xyExplicitLegendLabels = cases(1)
 resxy@xyLineColors           = xyLineColors(1)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.04
 plotxy2 = gsn_csm_xy(wks,tmXBValues,iso_seasonal_area_case2_flip,resxy)

; Case 3
 resxy@xyExplicitLegendLabels = cases(2)
 resxy@xyLineColors           = xyLineColors(2)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.08
 plotxy3 = gsn_csm_xy(wks,tmXBValues,iso_seasonal_area_case3_flip,resxy)

; Case 4
 resxy@xyExplicitLegendLabels = cases(3)
 resxy@xyLineColors           = xyLineColors(3)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.12
 plotxy4 = gsn_csm_xy(wks,tmXBValues,iso_seasonal_area_case4_flip,resxy)

; Case 5
 resxy@xyExplicitLegendLabels = cases(4)
 resxy@xyLineColors           = xyLineColors(4)
 resxy@xyDashPatterns         = xyDashPatterns
 resxy@xyLineThicknessF       = xyLineThicknessF
 resxy@pmLegendParallelPosF   = pmLegendParallelPosF
 resxy@pmLegendOrthogonalPosF = pmLegendOrthogonalPosF-0.16
 plotxy5 = gsn_csm_xy(wks,tmXBValues,iso_seasonal_area_case5_flip,resxy)

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
 resmap@cnLinesOn      = False       ; Contour lines?
 resmap@cnLineLabelsOn = False       ; Contour line labels?
 resmap@gsnAddCyclic   = True        ; Eliminates gap in longitudinal data

;------------------------------------------------
; Titles and text on the mapplot
;------------------------------------------------

; Left string is in upper left corner
; Center string is in upper center
; Right string is in upper right corner

; Left

 resmap@gsnLeftString   = LeftString 

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
 ReverseColorTable = False                  ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if
 resmap@lbLabelBarOn         = True             ; True turns on label bar
 resmap@gsnSpreadColors      = False            ; if True, reduces colors used from color table
 resmap@gsnSpreadColorStart  = 2; 20              ; Index to start with: default=2
 resmap@gsnSpreadColorEnd    = -2;-20              ; Index to end with: default=-1

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

;----------------------------------
; Wind vector specifications
;----------------------------------

if (OVERLAY_WIND .eq. "Yes") then

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

end if

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
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case1_flip(i,:,:),V_seasonal_case1_flip(i,:,:),iso_seasonal_case1_flip(i,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case1_flip(i,:,:),resmap)
    end if
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(1)+"-"+cases(0)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case2_flip(i,:,:)-U_seasonal_case1_flip(i,:,:),V_seasonal_case2_flip(i,:,:)-V_seasonal_case1_flip(i,:,:),iso_seasonal_case2_flip(i,:,:)-iso_seasonal_case1_flip(i,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case2_flip(i,:,:)-iso_seasonal_case1_flip(i,:,:),resmap)
    end if
   end if
   end if
   i=i+1
 end do

 i=12
 do while(i.le.23)
    resmap@gsnCenterString = date(i-12)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(1)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case2_flip(i-12,:,:),V_seasonal_case2_flip(i-12,:,:),iso_seasonal_case2_flip(i-12,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case2_flip(i-12,:,:),resmap)
    end if
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(2)+"-"+cases(0)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case3_flip(i-12,:,:)-U_seasonal_case1_flip(i-12,:,:),V_seasonal_case3_flip(i-12,:,:)-V_seasonal_case1_flip(i-12,:,:),iso_seasonal_case3_flip(i-12,:,:)-iso_seasonal_case1_flip(i-12,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case3_flip(i-12,:,:)-iso_seasonal_case1_flip(i-12,:,:),resmap)
    end if
   end if
   end if
   i=i+1
 end do

 i=24
 do while(i.le.35)
    resmap@gsnCenterString = date(i-24)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(2)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case3_flip(i-24,:,:),V_seasonal_case3_flip(i-24,:,:),iso_seasonal_case3_flip(i-24,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case3_flip(i-24,:,:),resmap)
    end if
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(2)+"-"+cases(0)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case3_flip(i-24,:,:)-U_seasonal_case1_flip(i-24,:,:),V_seasonal_case3_flip(i-24,:,:)-V_seasonal_case1_flip(i-24,:,:),iso_seasonal_case3_flip(i-24,:,:)-iso_seasonal_case1_flip(i-24,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case3_flip(i-24,:,:)-iso_seasonal_case1_flip(i-24,:,:),resmap)
    end if
   end if
   end if
   i=i+1
 end do

 i=36
 do while(i.le.47)
    resmap@gsnCenterString = date(i-36)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(3)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case4_flip(i-36,:,:),V_seasonal_case4_flip(i-36,:,:),iso_seasonal_case4_flip(i-36,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case4_flip(i-36,:,:),resmap)
    end if
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(3)+"-"+cases(0)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case4_flip(i-36,:,:)-U_seasonal_case1_flip(i-36,:,:),V_seasonal_case4_flip(i-36,:,:)-V_seasonal_case1_flip(i-36,:,:),iso_seasonal_case4_flip(i-36,:,:)-iso_seasonal_case1_flip(i-36,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case4_flip(i-36,:,:)-iso_seasonal_case1_flip(i-36,:,:),resmap)
    end if
   end if
   end if
   i=i+1
 end do

 i=48
 do while(i.le.59)
    resmap@gsnCenterString = date(i-48)
   if (mapdiffs .eq. "No") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(4)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case5_flip(i-48,:,:),V_seasonal_case5_flip(i-48,:,:),iso_seasonal_case5_flip(i-48,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case5_flip(i-48,:,:),resmap)
    end if
   else if (mapdiffs .eq. "Yes") then
    resmap@gsnLeftString   = ""+LeftString+" "+cases(4)+"-"+cases(0)+""
    if (OVERLAY_WIND .eq. "Yes") then
     plotmap(i) = gsn_csm_vector_scalar_map(wks,U_seasonal_case5_flip(i-48,:,:)-U_seasonal_case1_flip(i-48,:,:),V_seasonal_case5_flip(i-48,:,:)-V_seasonal_case1_flip(i-48,:,:),iso_seasonal_case5_flip(i-48,:,:)-iso_seasonal_case1_flip(i-48,:,:),resmap)
    else
     plotmap(i) = gsn_csm_contour_map_ce(wks,iso_seasonal_case5_flip(i-48,:,:)-iso_seasonal_case1_flip(i-48,:,:),resmap)
    end if
   end if
   end if
   i=i+1
 end do

end if

end
