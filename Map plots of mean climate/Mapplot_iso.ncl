;------------------------------------------------------------------------------------------------------------------------
; This script reads in isotopic variables from a climatology netCDF file and produces a map plot of each case's average
; values and differences between cases. Functionality for weighting by length of month is included. 
; This script includes functionality for calculating values from five (5) separate cases; however, it can be easily 
; modified to increase/decrease this number.
;
; Author: Alex Thompson
; Date: 7/29/2022
;------------------------------------------------------------------------------------------------------------------------

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

; Climatology
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

 numyears  = ((endi-begi)+1)/12 
 nummonths = count_unique_values(MON) 
 MONarray = new((/numyears*nummonths/),integer)

; This loop calculates what MON should be! Do not modify
 i = 0
 do y=0,(numyears*nummonths)-nummonths
   MONarray(y:y+nummonths-1) = MON + i*12
   y=y+nummonths-1
   i=i+1
 end do  

;------------------------------------------------
; Specify the fields and properties here
;------------------------------------------------ 

; Plot weighted or unweighted isotope values?
 WT = "wt"  ; "wt" or "" (blank)

; Which variable(s) to plot? Can perform math operations on these variables 

 WTVAR = "PRECT" ; Special cases: "PRECT" and "H2OSOI", Q for vapor
 ISO   = "d18O"   ; "d18O", "dHDO", or "dexcess"
 Liso  = "precip"  ; Special cases: "precip" or "soil"
 Hiso  = "precip"  ; Else, input variable names here (H216OV, H218OV, H2OV, HDOV)

; If plotting soil isotopic values, define level here
 SOIL_LEV = 3

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

 southlat = 14.0
 northlat = 23.0
 westlon  = 267.5
 eastlon  = 272.5

; Do you want an average at a specific grid point?
 Point = "Yes"

 latpoint = 20.0
 lonpoint = 10.0

;------------------------------------------------
; What to name the output plot file?
;------------------------------------------------

 file_type  = "pdf"    ; "x11" or "pdf"

 ; If second variables exists, this is used for file name
 outputfilename = "pdfs/"+SEASON+"_year"+YEARS+"_"+WTVAR+"-"+WT+"_"+ISO+""+Liso+"_"+LEVEL+"_winds"+OVERLAY_WIND+""+WIND_LEVEL+"_"+name+""

;-----------------------------------------------------------
; Specify contour levels for absolute and difference values
;-----------------------------------------------------------

; Manual Levels for absolute contour plotting (1=ON, 0=OFF) 
 ManLevAbs = 1      
 abs_hival = 0.0
 abs_loval = -15.0
 abs_spval = 0.5

; Manual Levels for difference contour plotting (1=ON, 0=OFF)
 ManLevDif = 1
 dif_hival = 2.5
 dif_loval = -2.5
 dif_spval = 0.25

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
  LatMin = -40  ; negative values = °S
  LatMax = 90   ; positive values = °N
  LonMin = -150 ; negative values = °W
  LonMax = 60   ; positive values = °E
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
 LeftString     = "~F21~"+SEASON+" "+WTVAR+""+WT+"-"+ISO+"_"+Liso+" "+LEVEL+""
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

  delete([/wtvar,wtvar_time,wtvar_4d,lightiso_d18O,heavyiso_d18O,lightiso_d18O_time,heavyiso_d18O_time,pre_iso_d18O_wt,iso_d18O_4d,wtvar_4d_fixed,lightiso_dHDO,heavyiso_dHDO,lightiso_dHDO_time,heavyiso_dHDO_time,pre_iso_dHDO_wt,iso_dHDO_4d/]) ; not iso_seasonal or iso_wt_seasonal
  if (LEVEL .ne. "") then
   delete([/numlevs_subone,hybm1,hyam1,P0,P0mb,ps1,intyp,wtvar_lev,lightiso_d18O_lev,heavyiso_d18O_lev,lightiso_dHDO_lev,heavyiso_dHDO_lev/])
  end if

 end do

   ; Apply isotope type

    if (ISO .eq. "d18O") then
      iso    = iso_d18O_seasonal
      iso_wt = iso_d18O_wt_seasonal
    else if (ISO .eq. "dHDO") then
      iso    = iso_dHDO_seasonal
      iso_wt = iso_dHDO_wt_seasonal
    else if (ISO .eq. "dexcess") then
      iso    = iso_dHDO_seasonal    - 8 * iso_d18O_seasonal
      iso_wt = iso_dHDO_wt_seasonal - 8 * iso_d18O_wt_seasonal 
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

if (WTVAR .eq. "PRECT") then
 dmvar = ins->PRECC
 lat    = dmvar&lat
 lon    = dmvar&lon
else
 wtvar = ins->$WTVAR$
 lat = wtvar&lat
 lon = wtvar&lon
 delete(wtvar)
end if

; Variable metadata set here

   iso!0   = "time"
   iso!1   = "lat"
   iso!2   = "lon"
   iso&lat = lat
   iso&lon = lon

   iso_wt!0   = "time"
   iso_wt!1   = "lat"
   iso_wt!2   = "lon"
   iso_wt&lat = lat
   iso_wt&lon = lon

;************************************************
; Average over entire time series
;-----------------------------------------------*
; Loop continues here...
;-----------------------------------------------*
;************************************************

; Select months for average
 iso_avg    = dim_avg_wgt_n_Wrap(iso(MON,:,:),wgt_mon,0,0)
 iso_wt_avg = dim_avg_wgt_n_Wrap(iso_wt(MON,:,:),wgt_mon,0,0)

;*********************************************************
; Define metadata for final variable and perform lonFlip
;--------------------------------------------------------*
; Loop continues here...
;--------------------------------------------------------*
;*********************************************************

; Metadata

 iso_avg!0   = "lat"
 iso_avg!1   = "lon"
 iso_avg&lat = lat
 iso_avg&lon = lon

 iso_wt_avg!0   = "lat"
 iso_wt_avg!1   = "lon"
 iso_wt_avg&lat = lat
 iso_wt_avg&lon = lon

; lonFlip

 lon_flip       = lonFlip(lon)
 iso_avg_flip = lonFlip(iso_avg)
 iso_wt_avg_flip = lonFlip(iso_wt_avg)

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
 printVarSummary(iso)
 printVarSummary(iso_wt)
 printVarSummary(iso_avg)
 printVarSummary(iso_wt_avg)
 printVarSummary(iso_wt_avg_flip)
 printVarSummary(iso_avg_flip)
 if (OVERLAY_WIND .eq. "Yes") then
 printVarSummary(U_flip)
 end if
 print("**************************")
 print("End loop for CASE"+i+"...")
 print("**************************")

;-----------------------------------------------------------
; Saved variables are of the following dimensions:
;
; iso             -> (time[yr&mon],lat,lon) 
; iso_wt          -> (time[yr],lat,lon)
; iso_avg         -> (lat,lon)
; iso_wt_avg      -> (lat,lon)
; iso_avg_flip    -> (lat,lon_flip)
; iso_wt_avg_flip -> (lat,lon_flip)
; U/V_flip       -> (lat,lon_flip) (if necessary)
;
;-----------------------------------------------------------

 ; Save corresponding variables
   if (i .eq. 1) then
     iso_case1             = iso
     iso_wt_case1          = iso_wt
     iso_avg_case1         = iso_avg
     iso_wt_avg_case1      = iso_wt_avg
     iso_avg_case1_flip    = iso_avg_flip
     iso_wt_avg_case1_flip = iso_wt_avg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case1      = U
     V_case1      = V
     U_case1_flip = U_flip
     V_case1_flip = V_flip
    end if
   end if

   if (i .eq. 2) then
     iso_case2             = iso
     iso_wt_case2          = iso_wt
     iso_avg_case2         = iso_avg
     iso_wt_avg_case2      = iso_wt_avg
     iso_avg_case2_flip    = iso_avg_flip
     iso_wt_avg_case2_flip = iso_wt_avg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case2      = U
     V_case2      = V
     U_case2_flip = U_flip
     V_case2_flip = V_flip
    end if
   end if

   if (i .eq. 3) then
     iso_case3             = iso
     iso_wt_case3          = iso_wt
     iso_avg_case3         = iso_avg
     iso_wt_avg_case3      = iso_wt_avg
     iso_avg_case3_flip    = iso_avg_flip
     iso_wt_avg_case3_flip = iso_wt_avg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case3      = U
     V_case3      = V
     U_case3_flip = U_flip
     V_case3_flip = V_flip
    end if
   end if

   if (i .eq. 4) then
     iso_case4             = iso
     iso_wt_case4          = iso_wt
     iso_avg_case4         = iso_avg
     iso_wt_avg_case4      = iso_wt_avg
     iso_avg_case4_flip    = iso_avg_flip
     iso_wt_avg_case4_flip = iso_wt_avg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case4      = U
     V_case4      = V
     U_case4_flip = U_flip
     V_case4_flip = V_flip
    end if
   end if

   if (i .eq. 5) then
     iso_case5             = iso
     iso_wt_case5          = iso_wt
     iso_avg_case5         = iso_avg
     iso_wt_avg_case5      = iso_wt_avg
     iso_avg_case5_flip    = iso_avg_flip
     iso_wt_avg_case5_flip = iso_wt_avg_flip
     if (OVERLAY_WIND .eq. "Yes") then
     U_case5      = U
     V_case5      = V
     U_case5_flip = U_flip
     V_case5_flip = V_flip
    end if
   end if

; If more than three cases, include another if/then here to accommodate...

; Now delete the unneeded variables

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

;-----------
; Global
;-----------

if (Global .eq. "Yes") then
 
  print("Global average "+cases(0)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_case1_flip,gw,1.0,0)+"")
  print("Global average "+cases(1)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_case2_flip,gw,1.0,0)+"")
  print("Global average "+cases(2)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_case3_flip,gw,1.0,0)+"")
  print("Global average "+cases(3)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_case4_flip,gw,1.0,0)+"")
  print("Global average "+cases(4)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" = "+wgt_areaave_Wrap(iso_wt_avg_case5_flip,gw,1.0,0)+"")

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

 print(""+cases(0)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_case1_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0)) 
 print(""+cases(1)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_case2_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0)) 
 print(""+cases(2)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_case3_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(3)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_case4_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+cases(4)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" ("+lat(lat_s)+"-"+lat(lat_n)+"("+lat_s+","+lat_n+"),"+lon_flip(lon_w)+"-"+lon_flip(lon_e)+"("+lon_w+","+lon_e+") = "+wgt_areaave_Wrap(iso_wt_avg_case5_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))

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

 print(""+cases(0)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_case1_flip(lat_point,lon_point)))
 print(""+cases(1)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_case2_flip(lat_point,lon_point)))
 print(""+cases(2)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_case3_flip(lat_point,lon_point)))
 print(""+cases(3)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_case4_flip(lat_point,lon_point)))
 print(""+cases(4)+" "+WTVAR+"wt-"+ISO+"_"+Liso+" "+UNITS+" "+lat(lat_point)+"("+lat_point+"),"+lon_flip(lon_point)+"("+lon_point+") = "+avg(iso_wt_avg_case5_flip(lat_point,lon_point)))

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

 res@cnFillOn            = True        ; Fill in contours?
 res@cnFillMode          = "RasterFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 res@cnRasterSmoothingOn = True
 res@cnLinesOn           = False       ; Contour lines?
 res@cnLineLabelsOn      = False       ; Contour line labels?
 res@gsnAddCyclic        = True        ; Eliminates gap in longitudinal data

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
 ReverseColorTable = False                  ; Reverse color table order?
 if (ReverseColorTable .eq. True) then
   gsn_reverse_colormap(wks)
 end if
 res@lbLabelBarOn         = True             ; True turns on label bar            
 res@gsnSpreadColors      = False            ; if True, reduces colors used from color table
 res@gsnSpreadColorStart  = 2              ; Index to start with: default=2
 res@gsnSpreadColorEnd    = -2              ; Index to end with: default=-1

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

;*************************************************************
; Make the plot 
;*************************************************************

;----------------------------------------
; Absolute value map plots
;----------------------------------------

if (OVERLAY_WIND .eq. "No") then

 res@gsnCenterString = cases(0)
 plot1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case1_flip,res)

 res@gsnCenterString = cases(1)
 plot2 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case2_flip,res)

 res@gsnCenterString = cases(2)
 plot3 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case3_flip,res)

 res@gsnCenterString = cases(3)
 plot4 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case4_flip,res)

 res@gsnCenterString = cases(4)
 plot5 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case5_flip,res)

else

 res@gsnCenterString = cases(0)
 plot1 = gsn_csm_vector_scalar_map(wks,U_case1_flip,V_case1_flip,iso_wt_avg_case1_flip,res)

 res@gsnCenterString = cases(1)
 plot2 = gsn_csm_vector_scalar_map(wks,U_case2_flip,V_case2_flip,iso_wt_avg_case2_flip,res)

 res@gsnCenterString = cases(2)
 plot3 = gsn_csm_vector_scalar_map(wks,U_case3_flip,V_case3_flip,iso_wt_avg_case3_flip,res)

 res@gsnCenterString = cases(3)
 plot4 = gsn_csm_vector_scalar_map(wks,U_case4_flip,V_case4_flip,iso_wt_avg_case4_flip,res)

 res@gsnCenterString = cases(4)
 plot5 = gsn_csm_vector_scalar_map(wks,U_case5_flip,V_case5_flip,iso_wt_avg_case5_flip,res)

end if

;------------------------------------
; Difference plots
;------------------------------------

; Set the difference contour levels

 gsn_define_colormap(wks,""+ColorTableNameDif+"")
 ReverseColorTable = False                 ; Reverse color table order?
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
  diff_2_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case2_flip-iso_wt_avg_case1_flip,res)

  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case3_flip-iso_wt_avg_case1_flip,res)

  res@gsnCenterString = ""+cases(3)+"-"+cases(0)+""
  diff_4_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case4_flip-iso_wt_avg_case1_flip,res)

  res@gsnCenterString = ""+cases(4)+"-"+cases(0)+""
  diff_5_1 = gsn_csm_contour_map_ce(wks,iso_wt_avg_case5_flip-iso_wt_avg_case1_flip,res)

else

  res@gsnCenterString = ""+cases(1)+"-"+cases(0)+""
  diff_2_1 = gsn_csm_vector_scalar_map(wks,U_case2_flip-U_case1_flip,V_case2_flip-V_case1_flip,iso_wt_avg_case2_flip-iso_wt_avg_case1_flip,res)

  res@gsnCenterString = ""+cases(2)+"-"+cases(0)+""
  diff_3_1 = gsn_csm_vector_scalar_map(wks,U_case3_flip-U_case1_flip,V_case3_flip-V_case1_flip,iso_wt_avg_case3_flip-iso_wt_avg_case1_flip,res)

  res@gsnCenterString = ""+cases(3)+"-"+cases(0)+""
  diff_4_1 = gsn_csm_vector_scalar_map(wks,U_case4_flip-U_case1_flip,V_case4_flip-V_case1_flip,iso_wt_avg_case4_flip-iso_wt_avg_case1_flip,res)

  res@gsnCenterString = ""+cases(4)+"-"+cases(0)+""
  diff_5_1 = gsn_csm_vector_scalar_map(wks,U_case5_flip-U_case1_flip,V_case5_flip-V_case1_flip,iso_wt_avg_case5_flip-iso_wt_avg_case1_flip,res)

end if

end
