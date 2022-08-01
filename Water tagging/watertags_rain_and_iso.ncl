;-------------------------------------------------------------------------------------------------------------------
; This script creates plots of rainfall percentage and isotopic values for a water tagged CESM simulation. It
; plots a map showing the rainfall percentages and isotopic values for each tagged region for land and ocean
; tags. It also plots isotopic and rainfall values for each individual tagged region. Functionality for weighting 
; by length of month and plotting region polymaker is included. This script includes functionality for calculating
; values from five (5) separate cases; however, it can be easily modified to increase/decrease this number.
;
; Author: Alex Thompson
; Date: 7/29/2022
;
; Example provided here includes different water tag regions from arond the world
;
;-------------------------------------------------------------------------------------------------------------------

begin

;------------------------------------------------
; Add filepaths for data here
;------------------------------------------------

; Read climatology files here

CASE1 = [/filepath/to/case1.nc] 
CASE2 = [/filepath/to/case2.nc]
CASE3 = [/filepath/to/case3.nc]
CASE4 = [/filepath/to/case4.nc]
CASE5 = [/filepath/to/case5.nc]

CASES = (/ CASE1, CASE2, CASE3, CASE4, CASE5 /)

cases1 = (/ "case1" /)
cases2 = (/ "case2" /)
cases3 = (/ "case3" /)
cases4 = (/ "case4" /)
cases5 = (/ "case5" /)

cases = (/ cases1, cases2, cases3, cases4, cases5 /)

; Define names of each region here

; tagnames = (/ "tag 1", "tag 2", ..., "tag n" /)

; Example of 40 tagged regions
tagnames = (/ "Antarctica","North America/Greenland","South America (-Amazon)","Eurasia","Africa (-Congo)","Sundaland NW","SundalandNE","Sundaland SW","Sundaland SE","Sahulland","Australia/Oceania","Amazon","Congo","North Pacific","North Atlantic","North Barents/Arctic Sea","Tropical Pacific NE","Caribbean","Tropical Atlantic NW","Tropical Atlantic NE","Mediterranean","Indian Ocean NW/Arabian Sea","Indian Ocean NE/Bay of Bengal","Sundaland NW ocean","Sundaland NE ocean/South China Sea","Sundaland SW ocean","Sundaland SE ocean","Tropical Pacific NW","Tropical Pacific North Central","Tropical Pacific SE","Tropical Atlantic SW","Tropical Atlantic SE","Tropical Indian SW","Tropical Indian South Central","Tropical Indian SE","Sahul region ocean","Tropical Pacific South Central","South Pacific","South Atlantic","South Indian" /)

numcases = 5

;------------------------------------------------
; Deal with seasonality here
;------------------------------------------------

; Indices to read in
 begi = 0
 endi = 11

; Season to plot from 0 to 11
 SEASON    = "ANN" 
  MON = (/ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 /)

; MON needs indices not actual months

 numyrs  = ((endi-begi)+1)/12
 nummonths = count_unique_values(MON)
 MONarray = new((/numyrs*nummonths/),integer)

; This loop calculates what MON should be! Do not modify
 i = 0
 do y=0,(numyrs*nummonths)-nummonths
   MONarray(y:y+nummonths-1) = MON + i*12
   y=y+nummonths-1
   i=i+1
 end do

;------------------------------------------------
; Specify the fields and properties here
;------------------------------------------------

; Which variable(s) to plot? Can perform math operations on these variables
 ISO = "d18O"   ; "d18O", "dHDO", or "dexcess"

; What are the units of the variable?
 UNITS = "permil"
 ptiny = 1.E-18

;------------------------------------------------------------------------------------------
; Define gridcell (or region) of interest for this calculation 
;------------------------------------------------------------------------------------------

GC_name = "Yucatan" ; Name of the region for calculation, will be used in output file name

GC = "Region"         ; "Point" or "Region"

; Region ; Example shown here calculates tagging for Yucatan region of Central America

 GC_slat = 13.0  ; N, limit -90
 GC_nlat = 22.0  ; N, limit 90
 GC_wlon = 267.5 ; W, limit 180
 GC_elon = 272.5 ; E, limit 177.5

; Point

 GC_lat = 32.0;    16.05
 GC_lon = 120.0;   270

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

if (dimsizes(MON) .eq. 1) then
  wgt_mon_1  = 1 
  wgt_mon_2  = 1
  wgt_mon_3  = 1
  wgt_mon_4  = 1
  wgt_mon_5  = 1
end if

;************************************************
;------------------------------------------------
;; Read in global variables first
;************************************************

 do i=1,numcases

print("*******************************")
print("**** Running "+cases(i-1)+" now ****")
print("*******************************")

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
 dimfil          = CASES(i-1)
 dimins          = addfile(dimfil,"r")
 dimvar          = dimins->PRECC
 lat             = dimvar&lat
 lon             = dimvar&lon
 lon_flip        = lonFlip(lon)
 iso_d18O_wt_seasonal = new((/12,dimsizes(lat),dimsizes(lon)/),float)
 iso_dHDO_wt_seasonal = new((/12,dimsizes(lat),dimsizes(lon)/),float)

 ; Now loop through each month

 do k=0,11

 ; Initialize variables
 
  wtvar           = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
  lightiso_d18O   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
  heavyiso_d18O   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
  lightiso_dHDO   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
  heavyiso_dHDO   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)

 ; Create indexing array

  MONindex = ispan(k,numyrs*nummonths-1,12)

 ; Read in variables and scale them

    fil = CASES(i-1)
    ins = addfile(fil,"r")

   ; Read in variable to weight isotopic values by

    wtvar      = ins->PRECC(MONindex,:,:) + ins->PRECL(MONindex,:,:)
    wtvar_time = wtvar

   ; Finish processing the variable to weight by

    wtvar_4d = reshape(wtvar_time, (/ numyrs, 1, dimsizes(lat), dimsizes(lon) /))

   ; Now read in isotopic values

    ; d18O
     lightiso_d18O = ins->PRECRC_H216Or(MONindex,:,:) + ins->PRECSC_H216Os(MONindex,:,:) + ins->PRECRL_H216OR(MONindex,:,:) + ins->PRECSL_H216OS(MONindex,:,:)
     heavyiso_d18O = ins->PRECRC_H218Or(MONindex,:,:) + ins->PRECSC_H218Os(MONindex,:,:) + ins->PRECRL_H218OR(MONindex,:,:) + ins->PRECSL_H218OS(MONindex,:,:)

    ; dHDO
     lightiso_dHDO = ins->PRECRC_H2Or(MONindex,:,:) + ins->PRECSC_H2Os(MONindex,:,:) + ins->PRECRL_H2OR(MONindex,:,:) + ins->PRECSL_H2OS(MONindex,:,:)
     heavyiso_dHDO = ins->PRECRC_HDOr(MONindex,:,:) + ins->PRECSC_HDOs(MONindex,:,:) + ins->PRECRL_HDOR(MONindex,:,:) + ins->PRECSL_HDOS(MONindex,:,:)

    ; d18O
     lightiso_d18O_time = lightiso_d18O
     heavyiso_d18O_time = heavyiso_d18O

    ; dHDO
     lightiso_dHDO_time = lightiso_dHDO
     heavyiso_dHDO_time = heavyiso_dHDO

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

   ; dHDO
    iso_dHDO_4d                 = reshape(pre_iso_dHDO_wt, (/ numyrs, 1, dimsizes(lat), dimsizes(lon) /))
    iso_dHDO_wt_seasonal(k,:,:) = dim_avg_n_Wrap( dim_sum_n(wtvar_4d_fixed * iso_dHDO_4d, 1) / dim_sum_n(wtvar_4d_fixed, 1) , 0)

  delete([/wtvar,wtvar_time,wtvar_4d,lightiso_d18O,heavyiso_d18O,lightiso_d18O_time,heavyiso_d18O_time,pre_iso_d18O_wt,iso_d18O_4d,wtvar_4d_fixed,lightiso_dHDO,heavyiso_dHDO,lightiso_dHDO_time,heavyiso_dHDO_time,pre_iso_dHDO_wt,iso_dHDO_4d/]) ; not iso_wt_seasonal

 end do

   ; Apply isotope type

    if (ISO .eq. "d18O") then
      iso_wt_time = iso_d18O_wt_seasonal
    else if (ISO .eq. "dHDO") then
      iso_wt_time = iso_dHDO_wt_seasonal
    else if (ISO .eq. "dexcess") then
      iso_wt_time = iso_dHDO_wt_seasonal - 8 * iso_d18O_wt_seasonal
    end if
    end if
    end if

   iso_wt_time!0   = "time"
   iso_wt_time!1   = "lat"
   iso_wt_time!2   = "lon"
   iso_wt_time&lat = lat
   iso_wt_time&lon = lon

  if (dimsizes(MON) .eq. 1) then
   iso_wt_global = iso_wt_time(MON,:,:)
  else
   iso_wt_global = dim_avg_wgt_n_Wrap(iso_wt_time(MON,:,:),wgt_mon,0,0)
  end if
   iso_wt_global_flip = lonFlip(iso_wt_global)

   printVarSummary(iso_wt_time)
   printVarSummary(iso_wt_global)

   ; Set precipitation variable

    PRECT_time = ins->PRECC(:,:,:) + ins->PRECL(:,:,:)
    prect_time = PRECT_time*86400000.0 ; m/s to mm/day

   prect_time!0   = "time"
   prect_time!1   = "lat"
   prect_time!2   = "lon"
   prect_time&lat = lat
   prect_time&lon = lon

   prect_months = clmMonTLL(prect_time)
  if (dimsizes(MON) .eq. 1) then
   prect_global = prect_months(MON,:,:)
  else
   prect_global = dim_avg_wgt_n_Wrap(prect_months(MON,:,:),wgt_mon,0,0)
  end if
   prect_global_flip = lonFlip(prect_global)

   printVarSummary(prect_months)
   printVarSummary(prect_global)

;*************************************************************************
; Now calculate water tags from regions
;*************************************************************************
; Equation
; d18Op@gc = d18Op_tag@gc * ( total16Op_tag@gc / prect_global@gc )

 numtags = 40

 d18Opsink_flip_by_tag = new((/numtags,dimsizes(lat),dimsizes(lon_flip)/),float)
 Pi_flip_by_tag        = new((/numtags,dimsizes(lat),dimsizes(lon_flip)/),float)

 do tag=1,numtags

;--------------------------
; Read in d18Opsink 
;--------------------------

; For seasonal cycle of isotopes, need to loop through each month

 ; First initialize variables

 delim            = ","
 dimfil           = CASES(i-1)
 dimins           = addfile(dimfil,"r")
 dimvar           = dimins->PRECC
 lat              = dimvar&lat
 lon              = dimvar&lon
 d18Opwt_tag_seas = new((/12,dimsizes(lat),dimsizes(lon)/),float)
 O16summed        = new((/12,dimsizes(lat),dimsizes(lon)/),float)

 ; Now loop through each month

 do k=0,11

 ; Initialize variables
  wtvar_tag           = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
  lightiso_d18O_tag   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)
  heavyiso_d18O_tag   = new((/numyrs,dimsizes(lat),dimsizes(lon)/),float)

 ; Create indexing array

  MONindex = ispan(k,numyrs*nummonths-1,12)

 ; Read in variables and scale them

    fil = CASES(i-1)
    ins = addfile(fil,"r")

   ; Now read in d18O isotopic values for each tag
   ; NOTE: Will need to modify the following if/then statements when changing the tagged regions

    if (tag .eq. 1) then
     lightiso_d18O_tag = ins->PRECRC_ANTAr(MONindex,:,:) + ins->PRECSC_ANTAs(MONindex,:,:) + ins->PRECRL_ANTAR(MONindex,:,:) + ins->PRECSL_ANTAS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_ANTA18Or(MONindex,:,:) + ins->PRECSC_ANTA18Os(MONindex,:,:) + ins->PRECRL_ANTA18OR(MONindex,:,:) + ins->PRECSL_ANTA18OS(MONindex,:,:)
    end if
    if (tag .eq. 2) then
     lightiso_d18O_tag = ins->PRECRC_NAMGr(MONindex,:,:) + ins->PRECSC_NAMGs(MONindex,:,:) + ins->PRECRL_NAMGR(MONindex,:,:) + ins->PRECSL_NAMGS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_NAMG18Or(MONindex,:,:) + ins->PRECSC_NAMG18Os(MONindex,:,:) + ins->PRECRL_NAMG18OR(MONindex,:,:) + ins->PRECSL_NAMG18OS(MONindex,:,:)
    end if
    if (tag .eq. 3) then
     lightiso_d18O_tag = ins->PRECRC_SAMEr(MONindex,:,:) + ins->PRECSC_SAMEs(MONindex,:,:) + ins->PRECRL_SAMER(MONindex,:,:) + ins->PRECSL_SAMES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SAME18Or(MONindex,:,:) + ins->PRECSC_SAME18Os(MONindex,:,:) + ins->PRECRL_SAME18OR(MONindex,:,:) + ins->PRECSL_SAME18OS(MONindex,:,:)
    end if
    if (tag .eq. 4) then
     lightiso_d18O_tag = ins->PRECRC_ERASr(MONindex,:,:) + ins->PRECSC_ERASs(MONindex,:,:) + ins->PRECRL_ERASR(MONindex,:,:) + ins->PRECSL_ERASS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_ERAS18Or(MONindex,:,:) + ins->PRECSC_ERAS18Os(MONindex,:,:) + ins->PRECRL_ERAS18OR(MONindex,:,:) + ins->PRECSL_ERAS18OS(MONindex,:,:)
    end if
    if (tag .eq. 5) then
     lightiso_d18O_tag = ins->PRECRC_AFRIr(MONindex,:,:) + ins->PRECSC_AFRIs(MONindex,:,:) + ins->PRECRL_AFRIR(MONindex,:,:) + ins->PRECSL_AFRIS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_AFRI18Or(MONindex,:,:) + ins->PRECSC_AFRI18Os(MONindex,:,:) + ins->PRECRL_AFRI18OR(MONindex,:,:) + ins->PRECSL_AFRI18OS(MONindex,:,:)
    end if
    if (tag .eq. 6) then
     lightiso_d18O_tag = ins->PRECRC_SLNWr(MONindex,:,:) + ins->PRECSC_SLNWs(MONindex,:,:) + ins->PRECRL_SLNWR(MONindex,:,:) + ins->PRECSL_SLNWS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SLNW18Or(MONindex,:,:) + ins->PRECSC_SLNW18Os(MONindex,:,:) + ins->PRECRL_SLNW18OR(MONindex,:,:) + ins->PRECSL_SLNW18OS(MONindex,:,:)
    end if
    if (tag .eq. 7) then
     lightiso_d18O_tag = ins->PRECRC_SLNEr(MONindex,:,:) + ins->PRECSC_SLNEs(MONindex,:,:) + ins->PRECRL_SLNER(MONindex,:,:) + ins->PRECSL_SLNES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SLNE18Or(MONindex,:,:) + ins->PRECSC_SLNE18Os(MONindex,:,:) + ins->PRECRL_SLNE18OR(MONindex,:,:) + ins->PRECSL_SLNE18OS(MONindex,:,:)
    end if
    if (tag .eq. 8) then
     lightiso_d18O_tag = ins->PRECRC_SLSWr(MONindex,:,:) + ins->PRECSC_SLSWs(MONindex,:,:) + ins->PRECRL_SLSWR(MONindex,:,:) + ins->PRECSL_SLSWS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SLSW18Or(MONindex,:,:) + ins->PRECSC_SLSW18Os(MONindex,:,:) + ins->PRECRL_SLSW18OR(MONindex,:,:) + ins->PRECSL_SLSW18OS(MONindex,:,:)
    end if
    if (tag .eq. 9) then
     lightiso_d18O_tag = ins->PRECRC_SLSEr(MONindex,:,:) + ins->PRECSC_SLSEs(MONindex,:,:) + ins->PRECRL_SLSER(MONindex,:,:) + ins->PRECSL_SLSES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SLSE18Or(MONindex,:,:) + ins->PRECSC_SLSE18Os(MONindex,:,:) + ins->PRECRL_SLSE18OR(MONindex,:,:) + ins->PRECSL_SLSE18OS(MONindex,:,:)
    end if
    if (tag .eq.10) then
     lightiso_d18O_tag = ins->PRECRC_SAHLr(MONindex,:,:) + ins->PRECSC_SAHLs(MONindex,:,:) + ins->PRECRL_SAHLR(MONindex,:,:) + ins->PRECSL_SAHLS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SAHL18Or(MONindex,:,:) + ins->PRECSC_SAHL18Os(MONindex,:,:) + ins->PRECRL_SAHL18OR(MONindex,:,:) + ins->PRECSL_SAHL18OS(MONindex,:,:)
    end if
    if (tag .eq.11) then
     lightiso_d18O_tag = ins->PRECRC_AUSTr(MONindex,:,:) + ins->PRECSC_AUSTs(MONindex,:,:) + ins->PRECRL_AUSTR(MONindex,:,:) + ins->PRECSL_AUSTS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_AUST18Or(MONindex,:,:) + ins->PRECSC_AUST18Os(MONindex,:,:) + ins->PRECRL_AUST18OR(MONindex,:,:) + ins->PRECSL_AUST18OS(MONindex,:,:)
    end if
    if (tag .eq.12) then
     lightiso_d18O_tag = ins->PRECRC_AMAZr(MONindex,:,:) + ins->PRECSC_AMAZs(MONindex,:,:) + ins->PRECRL_AMAZR(MONindex,:,:) + ins->PRECSL_AMAZS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_AMAZ18Or(MONindex,:,:) + ins->PRECSC_AMAZ18Os(MONindex,:,:) + ins->PRECRL_AMAZ18OR(MONindex,:,:) + ins->PRECSL_AMAZ18OS(MONindex,:,:)
    end if
    if (tag .eq.13) then
     lightiso_d18O_tag = ins->PRECRC_CONGr(MONindex,:,:) + ins->PRECSC_CONGs(MONindex,:,:) + ins->PRECRL_CONGR(MONindex,:,:) + ins->PRECSL_CONGS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_CONG18Or(MONindex,:,:) + ins->PRECSC_CONG18Os(MONindex,:,:) + ins->PRECRL_CONG18OR(MONindex,:,:) + ins->PRECSL_CONG18OS(MONindex,:,:)
    end if
    if (tag .eq.14) then
     lightiso_d18O_tag = ins->PRECRC_NPACr(MONindex,:,:) + ins->PRECSC_NPACs(MONindex,:,:) + ins->PRECRL_NPACR(MONindex,:,:) + ins->PRECSL_NPACS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_NPAC18Or(MONindex,:,:) + ins->PRECSC_NPAC18Os(MONindex,:,:) + ins->PRECRL_NPAC18OR(MONindex,:,:) + ins->PRECSL_NPAC18OS(MONindex,:,:)
    end if
    if (tag .eq.15) then
     lightiso_d18O_tag = ins->PRECRC_NATLr(MONindex,:,:) + ins->PRECSC_NATLs(MONindex,:,:) + ins->PRECRL_NATLR(MONindex,:,:) + ins->PRECSL_NATLS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_NATL18Or(MONindex,:,:) + ins->PRECSC_NATL18Os(MONindex,:,:) + ins->PRECRL_NATL18OR(MONindex,:,:) + ins->PRECSL_NATL18OS(MONindex,:,:)
    end if
    if (tag .eq.16) then
     lightiso_d18O_tag = ins->PRECRC_ARCTr(MONindex,:,:) + ins->PRECSC_ARCTs(MONindex,:,:) + ins->PRECRL_ARCTR(MONindex,:,:) + ins->PRECSL_ARCTS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_ARCT18Or(MONindex,:,:) + ins->PRECSC_ARCT18Os(MONindex,:,:) + ins->PRECRL_ARCT18OR(MONindex,:,:) + ins->PRECSL_ARCT18OS(MONindex,:,:)
    end if
    if (tag .eq.17) then
     lightiso_d18O_tag = ins->PRECRC_TPNEr(MONindex,:,:) + ins->PRECSC_TPNEs(MONindex,:,:) + ins->PRECRL_TPNER(MONindex,:,:) + ins->PRECSL_TPNES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TPNE18Or(MONindex,:,:) + ins->PRECSC_TPNE18Os(MONindex,:,:) + ins->PRECRL_TPNE18OR(MONindex,:,:) + ins->PRECSL_TPNE18OS(MONindex,:,:)
    end if
    if (tag .eq.18) then
     lightiso_d18O_tag = ins->PRECRC_CARBr(MONindex,:,:) + ins->PRECSC_CARBs(MONindex,:,:) + ins->PRECRL_CARBR(MONindex,:,:) + ins->PRECSL_CARBS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_CARB18Or(MONindex,:,:) + ins->PRECSC_CARB18Os(MONindex,:,:) + ins->PRECRL_CARB18OR(MONindex,:,:) + ins->PRECSL_CARB18OS(MONindex,:,:)
    end if
    if (tag .eq.19) then
     lightiso_d18O_tag = ins->PRECRC_TANWr(MONindex,:,:) + ins->PRECSC_TANWs(MONindex,:,:) + ins->PRECRL_TANWR(MONindex,:,:) + ins->PRECSL_TANWS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TANW18Or(MONindex,:,:) + ins->PRECSC_TANW18Os(MONindex,:,:) + ins->PRECRL_TANW18OR(MONindex,:,:) + ins->PRECSL_TANW18OS(MONindex,:,:)
    end if
    if (tag .eq.20) then
     lightiso_d18O_tag = ins->PRECRC_TANEr(MONindex,:,:) + ins->PRECSC_TANEs(MONindex,:,:) + ins->PRECRL_TANER(MONindex,:,:) + ins->PRECSL_TANES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TANE18Or(MONindex,:,:) + ins->PRECSC_TANE18Os(MONindex,:,:) + ins->PRECRL_TANE18OR(MONindex,:,:) + ins->PRECSL_TANE18OS(MONindex,:,:)
    end if
    if (tag .eq.21) then
     lightiso_d18O_tag = ins->PRECRC_MEDIr(MONindex,:,:) + ins->PRECSC_MEDIs(MONindex,:,:) + ins->PRECRL_MEDIR(MONindex,:,:) + ins->PRECSL_MEDIS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_MEDI18Or(MONindex,:,:) + ins->PRECSC_MEDI18Os(MONindex,:,:) + ins->PRECRL_MEDI18OR(MONindex,:,:) + ins->PRECSL_MEDI18OS(MONindex,:,:)
    end if
    if (tag .eq.22) then
     lightiso_d18O_tag = ins->PRECRC_ARABr(MONindex,:,:) + ins->PRECSC_ARABs(MONindex,:,:) + ins->PRECRL_ARABR(MONindex,:,:) + ins->PRECSL_ARABS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_ARAB18Or(MONindex,:,:) + ins->PRECSC_ARAB18Os(MONindex,:,:) + ins->PRECRL_ARAB18OR(MONindex,:,:) + ins->PRECSL_ARAB18OS(MONindex,:,:)
    end if
    if (tag .eq.23) then
     lightiso_d18O_tag = ins->PRECRC_BOFBr(MONindex,:,:) + ins->PRECSC_BOFBs(MONindex,:,:) + ins->PRECRL_BOFBR(MONindex,:,:) + ins->PRECSL_BOFBS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_BOFB18Or(MONindex,:,:) + ins->PRECSC_BOFB18Os(MONindex,:,:) + ins->PRECRL_BOFB18OR(MONindex,:,:) + ins->PRECSL_BOFB18OS(MONindex,:,:)
    end if
    if (tag .eq.24) then
     lightiso_d18O_tag = ins->PRECRC_SONWr(MONindex,:,:) + ins->PRECSC_SONWs(MONindex,:,:) + ins->PRECRL_SONWR(MONindex,:,:) + ins->PRECSL_SONWS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SONW18Or(MONindex,:,:) + ins->PRECSC_SONW18Os(MONindex,:,:) + ins->PRECRL_SONW18OR(MONindex,:,:) + ins->PRECSL_SONW18OS(MONindex,:,:)
    end if
    if (tag .eq.25) then
     lightiso_d18O_tag = ins->PRECRC_SONEr(MONindex,:,:) + ins->PRECSC_SONEs(MONindex,:,:) + ins->PRECRL_SONER(MONindex,:,:) + ins->PRECSL_SONES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SONE18Or(MONindex,:,:) + ins->PRECSC_SONE18Os(MONindex,:,:) + ins->PRECRL_SONE18OR(MONindex,:,:) + ins->PRECSL_SONE18OS(MONindex,:,:)
    end if
    if (tag .eq.26) then
     lightiso_d18O_tag = ins->PRECRC_SOSWr(MONindex,:,:) + ins->PRECSC_SOSWs(MONindex,:,:) + ins->PRECRL_SOSWR(MONindex,:,:) + ins->PRECSL_SOSWS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SOSW18Or(MONindex,:,:) + ins->PRECSC_SOSW18Os(MONindex,:,:) + ins->PRECRL_SOSW18OR(MONindex,:,:) + ins->PRECSL_SOSW18OS(MONindex,:,:)
    end if
    if (tag .eq.27) then
     lightiso_d18O_tag = ins->PRECRC_SOSEr(MONindex,:,:) + ins->PRECSC_SOSEs(MONindex,:,:) + ins->PRECRL_SOSER(MONindex,:,:) + ins->PRECSL_SOSES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SOSE18Or(MONindex,:,:) + ins->PRECSC_SOSE18Os(MONindex,:,:) + ins->PRECRL_SOSE18OR(MONindex,:,:) + ins->PRECSL_SOSE18OS(MONindex,:,:)
    end if
    if (tag .eq.28) then
     lightiso_d18O_tag = ins->PRECRC_TPNWr(MONindex,:,:) + ins->PRECSC_TPNWs(MONindex,:,:) + ins->PRECRL_TPNWR(MONindex,:,:) + ins->PRECSL_TPNWS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TPNW18Or(MONindex,:,:) + ins->PRECSC_TPNW18Os(MONindex,:,:) + ins->PRECRL_TPNW18OR(MONindex,:,:) + ins->PRECSL_TPNW18OS(MONindex,:,:)
    end if
    if (tag .eq.29) then
     lightiso_d18O_tag = ins->PRECRC_TPNCr(MONindex,:,:) + ins->PRECSC_TPNCs(MONindex,:,:) + ins->PRECRL_TPNCR(MONindex,:,:) + ins->PRECSL_TPNCS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TPNC18Or(MONindex,:,:) + ins->PRECSC_TPNC18Os(MONindex,:,:) + ins->PRECRL_TPNC18OR(MONindex,:,:) + ins->PRECSL_TPNC18OS(MONindex,:,:)
    end if
    if (tag .eq.30) then
     lightiso_d18O_tag = ins->PRECRC_TPSEr(MONindex,:,:) + ins->PRECSC_TPSEs(MONindex,:,:) + ins->PRECRL_TPSER(MONindex,:,:) + ins->PRECSL_TPSES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TPSE18Or(MONindex,:,:) + ins->PRECSC_TPSE18Os(MONindex,:,:) + ins->PRECRL_TPSE18OR(MONindex,:,:) + ins->PRECSL_TPSE18OS(MONindex,:,:)
    end if
    if (tag .eq.31) then
     lightiso_d18O_tag = ins->PRECRC_TASWr(MONindex,:,:) + ins->PRECSC_TASWs(MONindex,:,:) + ins->PRECRL_TASWR(MONindex,:,:) + ins->PRECSL_TASWS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TASW18Or(MONindex,:,:) + ins->PRECSC_TASW18Os(MONindex,:,:) + ins->PRECRL_TASW18OR(MONindex,:,:) + ins->PRECSL_TASW18OS(MONindex,:,:)
    end if
    if (tag .eq.32) then
     lightiso_d18O_tag = ins->PRECRC_TASEr(MONindex,:,:) + ins->PRECSC_TASEs(MONindex,:,:) + ins->PRECRL_TASER(MONindex,:,:) + ins->PRECSL_TASES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TASE18Or(MONindex,:,:) + ins->PRECSC_TASE18Os(MONindex,:,:) + ins->PRECRL_TASE18OR(MONindex,:,:) + ins->PRECSL_TASE18OS(MONindex,:,:)
    end if
    if (tag .eq.33) then
     lightiso_d18O_tag = ins->PRECRC_TISWr(MONindex,:,:) + ins->PRECSC_TISWs(MONindex,:,:) + ins->PRECRL_TISWR(MONindex,:,:) + ins->PRECSL_TISWS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TISW18Or(MONindex,:,:) + ins->PRECSC_TISW18Os(MONindex,:,:) + ins->PRECRL_TISW18OR(MONindex,:,:) + ins->PRECSL_TISW18OS(MONindex,:,:)
    end if
    if (tag .eq.34) then
     lightiso_d18O_tag = ins->PRECRC_TISCr(MONindex,:,:) + ins->PRECSC_TISCs(MONindex,:,:) + ins->PRECRL_TISCR(MONindex,:,:) + ins->PRECSL_TISCS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TISC18Or(MONindex,:,:) + ins->PRECSC_TISC18Os(MONindex,:,:) + ins->PRECRL_TISC18OR(MONindex,:,:) + ins->PRECSL_TISC18OS(MONindex,:,:)
    end if
    if (tag .eq.35) then
     lightiso_d18O_tag = ins->PRECRC_TISEr(MONindex,:,:) + ins->PRECSC_TISEs(MONindex,:,:) + ins->PRECRL_TISER(MONindex,:,:) + ins->PRECSL_TISES(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TISE18Or(MONindex,:,:) + ins->PRECSC_TISE18Os(MONindex,:,:) + ins->PRECRL_TISE18OR(MONindex,:,:) + ins->PRECSL_TISE18OS(MONindex,:,:)
    end if
    if (tag .eq.36) then
     lightiso_d18O_tag = ins->PRECRC_SAHOr(MONindex,:,:) + ins->PRECSC_SAHOs(MONindex,:,:) + ins->PRECRL_SAHOR(MONindex,:,:) + ins->PRECSL_SAHOS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SAHO18Or(MONindex,:,:) + ins->PRECSC_SAHO18Os(MONindex,:,:) + ins->PRECRL_SAHO18OR(MONindex,:,:) + ins->PRECSL_SAHO18OS(MONindex,:,:)
    end if
    if (tag .eq.37) then
     lightiso_d18O_tag = ins->PRECRC_TPSCr(MONindex,:,:) + ins->PRECSC_TPSCs(MONindex,:,:) + ins->PRECRL_TPSCR(MONindex,:,:) + ins->PRECSL_TPSCS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_TPSC18Or(MONindex,:,:) + ins->PRECSC_TPSC18Os(MONindex,:,:) + ins->PRECRL_TPSC18OR(MONindex,:,:) + ins->PRECSL_TPSC18OS(MONindex,:,:)
    end if
    if (tag .eq.38) then
     lightiso_d18O_tag = ins->PRECRC_SPACr(MONindex,:,:) + ins->PRECSC_SPACs(MONindex,:,:) + ins->PRECRL_SPACR(MONindex,:,:) + ins->PRECSL_SPACS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SPAC18Or(MONindex,:,:) + ins->PRECSC_SPAC18Os(MONindex,:,:) + ins->PRECRL_SPAC18OR(MONindex,:,:) + ins->PRECSL_SPAC18OS(MONindex,:,:)
    end if
    if (tag .eq.39) then
     lightiso_d18O_tag = ins->PRECRC_SATLr(MONindex,:,:) + ins->PRECSC_SATLs(MONindex,:,:) + ins->PRECRL_SATLR(MONindex,:,:) + ins->PRECSL_SATLS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SATL18Or(MONindex,:,:) + ins->PRECSC_SATL18Os(MONindex,:,:) + ins->PRECRL_SATL18OR(MONindex,:,:) + ins->PRECSL_SATL18OS(MONindex,:,:)
    end if
    if (tag .eq.40) then
     lightiso_d18O_tag = ins->PRECRC_SINDr(MONindex,:,:) + ins->PRECSC_SINDs(MONindex,:,:) + ins->PRECRL_SINDR(MONindex,:,:) + ins->PRECSL_SINDS(MONindex,:,:)
     heavyiso_d18O_tag = ins->PRECRC_SIND18Or(MONindex,:,:) + ins->PRECSC_SIND18Os(MONindex,:,:) + ins->PRECRL_SIND18OR(MONindex,:,:) + ins->PRECSL_SIND18OS(MONindex,:,:)
    end if

    ; d18O
     lightiso_d18O_tag_time = lightiso_d18O_tag
     heavyiso_d18O_tag_time = heavyiso_d18O_tag

   ; Calculate delta values

   ; d18O
    lightiso_d18O_tag_time = where(lightiso_d18O_tag_time.lt.ptiny,ptiny,lightiso_d18O_tag_time)
    pre_iso_d18O_wt_tag    = (heavyiso_d18O_tag_time/lightiso_d18O_tag_time - 1.) * 1000.

   ; Use lightiso as the precipitation weighting variable, determine cutoff value for influence from tagged region 

    lightiso_d18O_tag_time_4d  = reshape(lightiso_d18O_tag_time, (/ numyrs, 1, dimsizes(lat), dimsizes(lon) /))*86400000
    lightiso_d18O_tag_4d_fixed = where(lightiso_d18O_tag_time_4d .le. 0.00000001, lightiso_d18O_tag_time_4d@_FillValue, lightiso_d18O_tag_time_4d)

   ; Amount-weight the delta value
   ; d18O
    iso_d18O_tag_4d         = reshape(pre_iso_d18O_wt_tag, (/ numyrs, 1, dimsizes(lat), dimsizes(lon) /))
    d18Opwt_tag_seas(k,:,:) = dim_avg_n_Wrap( dim_sum_n(lightiso_d18O_tag_4d_fixed * iso_d18O_tag_4d, 1) / dim_sum_n(lightiso_d18O_tag_4d_fixed, 1) , 0)
    O16summed(k,:,:)        = lightiso_d18O_tag*86400000.0 ; m/s to mm/day

  delete([/lightiso_d18O_tag,heavyiso_d18O_tag,lightiso_d18O_tag_time,heavyiso_d18O_tag_time,pre_iso_d18O_wt_tag,iso_d18O_tag_4d/]) ; not d18Opwt_tag_seas

 end do ; k

 d18Opwt_tag_seas!0   = "time"
 d18Opwt_tag_seas!1   = "lat"
 d18Opwt_tag_seas!2   = "lon"
 d18Opwt_tag_seas&lat = lat
 d18Opwt_tag_seas&lon = lon
 
 O16summed!0   = "time"
 O16summed!1   = "lat"
 O16summed!2   = "lon"
 O16summed&lat = lat
 O16summed&lon = lon

 if (dimsizes(MON) .eq. 1) then 
  d18Opsink = d18Opwt_tag_seas(MON,:,:)
 else
  d18Opsink = dim_avg_wgt_n_Wrap(d18Opwt_tag_seas(MON,:,:),wgt_mon,0,0)
 end if
  d18Opsink_flip = lonFlip(d18Opsink) 

 if (dimsizes(MON) .eq. 1) then
  Pi = O16summed(MON,:,:)
 else
  Pi = dim_avg_wgt_n_Wrap(O16summed(MON,:,:),wgt_mon,0,0)
 end if
  Pi_flip = lonFlip(Pi)

 d18Opsink_flip_by_tag(tag-1,:,:) = d18Opsink_flip(:,:)
 Pi_flip_by_tag(tag-1,:,:)        = Pi_flip(:,:)

 delete([/d18Opsink_flip,Pi_flip/])

 end do ; tag

 printVarSummary(d18Opsink_flip_by_tag)

;*****************************************
; Do the calculation here!
;*****************************************

 d18Op = new((/numtags/),float)
 prect = new((/numtags/),float)
 rad = 4.0*atan(1.0)/180.0
 gw  = (cos(lat*rad))/2

if (GC .eq. "Region") then

 lat_s = min(ind(lat .ge. GC_slat))
 lat_n = max(ind(lat .le. GC_nlat))  

 if (GC_wlon .ge. 180.0) then
  lon_w = min(ind(lon_flip .ge. GC_wlon))
 else if (GC_wlon .lt. 180) then
  lon_w = max(ind(lon_flip .le. GC_wlon))
 end if
 end if

 if (GC_elon .ge. 180.0) then
  lon_e = min(ind(lon_flip .ge. GC_elon))
 else if (GC_elon .lt. 180.0) then
  lon_e = max(ind(lon_flip .le. GC_elon))
 end if
 end if

 if (GC_wlon .ge. 180.0) then
  print(lon_flip)
  print(GC_wlon)
  print(lon_w)
  lon1 = lon_flip(lon_w);-360
  lon2 = lon_flip(lon_e);-360
 else
  lon1 = lon_flip(lon_w)
  lon2 = lon_flip(lon_e)
 end if
 print("*******************************")
 print("**** "+SEASON+" Values for "+cases(i-1)+" ****")
 print("*******************************")
 print("******************************************************")
 print(""+GC+" = "+lat(lat_s)+"-"+lat(lat_n)+"°N,"+lon1+"-"+lon2+"°E")
 print("******************************************************")
 print(""+GC+" d18Op value (permil) = "+wgt_areaave_Wrap(iso_wt_global_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print(""+GC+" prect value (mm/day) = "+wgt_areaave_Wrap(prect_global_flip(lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0))
 print("**************************************************")

do tag=1,numtags
 d18Op_reg = new((/numtags,dimsizes(lat(:)),dimsizes(lon_flip(:))/),float)
 d18Op_reg(tag-1,:,:) = d18Opsink_flip_by_tag(tag-1,:,:) * ( Pi_flip_by_tag(tag-1,:,:) / prect_global_flip(:,:) )
 d18Op(tag-1) = wgt_areaave_Wrap(d18Op_reg(tag-1,lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0)
 prect(tag-1) = wgt_areaave_Wrap(Pi_flip_by_tag(tag-1,lat_s:lat_n,lon_w:lon_e),gw(lat_s:lat_n),1.0,0) 
end do

else if (GC .eq. "Point") then

 latp = min(ind(lat .ge. GC_lat))
 if (GC_lon .gt. 180) then
  lonp = min(ind(lon_flip .ge. GC_lon))
 else
  lonp = max(ind(lon_flip .le. GC_lon))
 end if

 print("*******************************")
 print("**** Values for "+cases(i-1)+" ****")
 print("*******************************")
 
 print("******************************************************")
 print(""+GC+" = "+lat(latp)+"°N,"+lon_flip(lonp)+"°E") 
 print("******************************************************")

 print(""+GC+" d18Op value (permil) = "+iso_wt_global_flip(latp,lonp))
 print(""+GC+" prect value (mm/day) = "+prect_global_flip(latp,lonp))
 print("**************************************************")

do tag=1,numtags
 d18Op(tag-1) = d18Opsink_flip_by_tag(tag-1,latp,lonp) * ( Pi_flip_by_tag(tag-1,latp,lonp) / prect_global_flip(latp,lonp) )
 prect(tag-1) = Pi_flip_by_tag(tag-1,latp,lonp)
end do

end if
end if

; Print d18Op and precip values by region

 print("******** d18Op values by tagged region ***********")
 print(" Tagged region sum = "+sum(d18Op))
 print("**************************************************")
do tag=1,numtags
 print(""+tagnames(tag-1)+" = "+d18Op(tag-1))
end do
 print("**************************************************")

 print("******** Precip values by tagged region **********")
 print(" Tagged region sum = "+sum(prect))
 print("**************************************************")
do tag=1,numtags
 print(""+tagnames(tag-1)+" = "+prect(tag-1))
end do
 print("**************************************************")

; Write case's isotopic and rainfall values to csv

printout = new((/2,numtags/),float)
printout(0,:) = d18Op
printout(1,:) = prect

alist = [/tagnames,d18Op,prect/]
write_table("[/filepath/to/csv/file/]"+SEASON+"_"+cases(i-1)+".csv","w",alist,"%s,%f,%f")

; Column 1 = tagged region names
; Column 2 = tagged region isotopic value (units = per mil)
; Column 3 = tagged region rainfall value (units = mm/day)

;********************************************************************
;********************************************************************
; Plot land tags
;********************************************************************
;********************************************************************

; Make dummy variable

in = addfile("[/filepath/to/file/that/contains/variable/LANDFRAC.nc]","r")
dum = in->LANDFRAC(0,:,:)

dum = where(dum .gt. 0.5, 1.0, 0.0) ; where greater than 50% land, set as 100% land for visualization

;********************************************************************
; Make a plot
;********************************************************************

; Define workstation

 wks = gsn_open_wks("pdf","pdfs/watertagging_"+SEASON+"_"+cases(i-1)+"_"+GC_name)

 res = True

;-------------------------------------------------
; Contour specifications
;-------------------------------------------------

 gsn_define_colormap(wks,"MPL_gist_earth")
 res@gsnSpreadColors = True
 res@gsnSpreadColorEnd = 10
 gsn_reverse_colormap(wks)
 res@cnFillOn       = True
 res@cnFillMode     = "RasterFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 res@cnLinesOn      = False       ; Contour lines?
 res@cnLineLabelsOn = False       ; Contour line labels?
 res@gsnAddCyclic   = True        ; Eliminates gap in longitudinal data

;------------------------------------------------
; Titles and text on the plot
;------------------------------------------------

; Axes text size and stride

 res@tmXBLabelFontHeightF = 0.014  ; X-axis font height, default=0.02
 res@tmYLLabelFontHeightF = 0.014  ; Y-axis font height, default=0.02
 res@gsnMajorLatSpacing   = 20     ; Latitude stride
 res@gsnMajorLonSpacing   = 30     ; Longitude stride

 res@gsnLeftString = ""+cases(i-1)+" land tags"
 res@gsnCenterString = ""

;------------------------------------------------
; Color and label bar specifications
;------------------------------------------------

 res@lbLabelBarOn         = False            ; True turns on label bar

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
; Remove rectangle stating all contours are zero
;------------------------------------------------

 res@cnConstFLabelFontHeightF = 0.0

;------------------------------------------------
; Make plot
;------------------------------------------------

landplot = new(2, graphic)

do m=0,1

;------------------------------------------------
; Specify polygon features
;------------------------------------------------

 polyres = True
 polyres@gsLineColor        = "black"
 polyres@gsLineThicknessF   = 2.0
 polyres@gsLineDashPattern  = 0

;------------------------------------------------
; Contour plot 
;------------------------------------------------

 res@gsnDraw  = False
 res@gsnFrame = False
 if (m .eq. 0) then
  res@gsnRightString = "% precip"
 else 
  res@gsnRightString = "per mil"
 end if
 landplot(m) = gsn_csm_contour_map_ce(wks,dum,res)

;-------------------------------------------------------------------
; Draw polygons, NOTE: need to change if changing tagged regions
;-------------------------------------------------------------------

do tags=1,13

 if (tags .eq. 1) then ; Antarctica
  lats = -90
  latn = -60
  lonw = -180
  lone = 180
  polygon1 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 2) then ; North America
  lats = 15
  latn = 90
  lonw = -180
  lone = -18
  polygon2 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 3) then ; South America
  lats = -60
  latn = 15
  lonw = -180
  lone = -18
  polygon3 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 4) then ; Eurasia, adding lines only
  polygon40 = gsn_add_polyline(wks,landplot(m),(/-18,-18/),(/37,90/),polyres) ; Eurasia, adding lines only
 end if
 
 if (tags .eq. 5) then ; Africa
  lats = -60
  latn = 37
  lonw = -18
  lone = 52
  polygon5 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 6) then ; Sundaland NW
  lats = 4
  latn = 17
  lonw = 95
  lone = 108
  polygon6 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 7) then ; Sundaland NE
  lats = 4
  latn = 17
  lonw = 108
  lone = 119
  polygon7 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 8) then ; Sundaland SW
  lats = -10
  latn = 4
  lonw = 95
  lone = 105
  polygon8 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 9) then ; Sundaland SE
  lats = -10
  latn = 4
  lonw = 105
  lone = 119
  polygon9 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 10) then ; Sahulland
  lats = -19
  latn = 4
  lonw = 119
  lone = 150
  polygon10 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 11) then ; Australia and Oceania
  lats = -60
  latn = 4
  lonw = 52
  lone = 180
  polygon11 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 12) then ; Amazon
  lats = -10
  latn = 10
  lonw = -70
  lone = -45
  polyres@gsLineDashPattern = 1
  polygon12 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 13) then ; Congo
  lats = -10
  latn = 10
  lonw = 10
  lone = 35
  polygon13 = gsn_add_polyline(wks,landplot(m),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

end do

;----------------
; Determine text to plot
;----------------

 tres = True
 tres@txFontHeightF    = 0.015
 tres@txFontColor = "black"

 if (m .eq. 0) then
  textvar = decimalPlaces((prect/sum(prect))*100.,1,True)
 else if (m .eq. 1) then
  textvar = decimalPlaces(d18Op,2,True)
 end if
 end if

;-----------------------------------
; Specifiy locations of text for plot
;-----------------------------------

landlon = (/   0, 260, 302, 55,  2, 99, 113, 99, 113, 135, 135, 299, 22 /)
landlat = (/ -81,  38, -20, 58, 22, 11,  11, -2,  -2,  -7, -26,   0,  5 /)

;----------------
; Draw point/region
;----------------

Area = "Region"

if (Area .eq. "Region") then
 polyres@gsLineColor = "red"
 polyres@gsLineDashPattern = 0
 lonw_reg = GC_wlon ; -92.5; -97.5
 lone_reg = GC_elon ; -87.5; -85.0
 lats_reg = GC_slat ; 14.2; 8.5
 latn_reg = GC_nlat ; 21.8; 23.7
 polygon_region = gsn_add_polyline(wks,landplot(m),(/lonw_reg,lonw_reg,lone_reg,lone_reg,lonw_reg/),(/lats_reg,latn_reg,latn_reg,lats_reg,lats_reg/),polyres)

 textl = new(13,graphic)

 do l=0,12 ; 13 land tags
  pre = ""
  if (m .eq. 1) then ; d18Op
   if (textvar(l) .gt. 0.) then
    tres@txFontColor = "red"
    pre = "+"
   else if (textvar(l) .lt. 0.) then
    tres@txFontColor = "blue"
   else
    tres@txFontColor = "black"
   end if
   end if
  end if

  textl(l) = gsn_add_text(wks,landplot(m),""+pre+textvar(l),landlon(l),landlat(l),tres)
 
  delete(pre) 
 end do

 draw(landplot(m))
 frame(wks)

else if (Area .eq. "Point") then

 draw(landplot(m))
 polyres@gsMarkerColor = "red"
 polyres@gsMarkerSizeF = 8.0
 polyres@gsMarkerIndex = 16
 lon_point = GC_lon ; -90.0
 lat_point = GC_lat ; 16.1
 gsn_polymarker(wks,landplot(m),lon_point,lat_point,polyres)
 frame(wks)

end if
end if

end do

;********************************************************************
;********************************************************************
; Plot ocean tags
;********************************************************************
;********************************************************************

; Make dummy variable

in = addfile("[/filepath/to/file/that/contains/variable/LANDFRAC.nc]","r")
dum = in->LANDFRAC(0,:,:)

dum = where(dum .lt. 0.5, 1.0, 0.0) ; where greater than 50% ocean, set as 100% ocean for visualization

;-------------------------------------------------
; Contour specifications
;-------------------------------------------------

 gsn_define_colormap(wks,"WhiteBlue")
 res@gsnSpreadColors = True
 res@gsnSpreadColorEnd = 105
 res@cnFillOn       = True
 res@cnFillMode     = "RasterFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 res@cnLinesOn      = False       ; Contour lines?
 res@cnLineLabelsOn = False       ; Contour line labels?
 res@gsnAddCyclic   = True        ; Eliminates gap in longitudinal data

;------------------------------------------------
; Titles and text on the plot
;------------------------------------------------

; Axes text size and stride

 res@tmXBLabelFontHeightF = 0.014  ; X-axis font height, default=0.02
 res@tmYLLabelFontHeightF = 0.014  ; Y-axis font height, default=0.02
 res@gsnMajorLatSpacing   = 20     ; Latitude stride
 res@gsnMajorLonSpacing   = 30     ; Longitude stride

 res@gsnLeftString = ""+cases(i-1)+ " ocean tags"

;------------------------------------------------
; Color and label bar specifications
;------------------------------------------------

 res@lbLabelBarOn         = False            ; True turns on label bar

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
; Remove rectangle stating all contours are zero
;------------------------------------------------

 res@cnConstFLabelFontHeightF = 0.0

;------------------------------------------------
; Make plot
;------------------------------------------------

 oceanplot = new(2, graphic)

do n=0,1

;------------------------------------------------
; Specify polygon features
;------------------------------------------------

 polyres = True
 polyres@gsLineColor        = "black"
 polyres@gsLineThicknessF   = 2.0
 polyres@gsLineDashPattern  = 0

;------------------------------------------------
; Specify polygon features
;------------------------------------------------

 res@gsnDraw  = False
 res@gsnFrame = False
 if (n .eq. 0) then
  res@gsnRightString = "% precip"
 else
  res@gsnRightString = "per mil"
 end if
 oceanplot(n) = gsn_csm_contour_map_ce(wks,dum,res)

;------------------------------------------------
; Draw polygons
;------------------------------------------------

do tags=1,31

 if (tags .eq. 1) then ; North Pacific
  lats = 25
  latn = 90
  lonw = 118
  lone = -100
  polygon1 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 2) then ; North Atlantic, polylines only
  polygon20 = gsn_add_polyline(wks,oceanplot(n),(/-100,-100/),(/25,90/),polyres)
  polygon21 = gsn_add_polyline(wks,oceanplot(n),(/20,20/),(/48,90/),polyres)
  polygon22 = gsn_add_polyline(wks,oceanplot(n),(/20,20/),(/25,30/),polyres)
 end if

 if (tags .eq. 3) then ; North Barents/Arctic Sea
  lats = 48
  latn = 90
  lonw = 20
  lone = 118
  polygon3 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 4) then ; Tropical Pacific NE, polylines only
  polygon40 = gsn_add_polyline(wks,oceanplot(n),(/-150,-100/),(/25,25/),polyres) ; Tropical Atlantic NE
  polygon41 = gsn_add_polyline(wks,oceanplot(n),(/-100,-100/),(/18,25/),polyres)
  polygon42 = gsn_add_polyline(wks,oceanplot(n),(/-100,-92/),(/18,18/),polyres)
  polygon43 = gsn_add_polyline(wks,oceanplot(n),(/-92,-92/),(/15,18/),polyres)
  polygon44 = gsn_add_polyline(wks,oceanplot(n),(/-92,-84/),(/15,15/),polyres)
  polygon45 = gsn_add_polyline(wks,oceanplot(n),(/-84,-84/),(/8,15/),polyres)
  polygon46 = gsn_add_polyline(wks,oceanplot(n),(/-84,-75/),(/8,8/),polyres)
  polygon47 = gsn_add_polyline(wks,oceanplot(n),(/-75,-75/),(/0,8/),polyres)
 end if

 if (tags .eq. 7) then ; Caribbean, polylines only
  polygon50 = gsn_add_polyline(wks,oceanplot(n),(/-100,-100/),(/25,48/),polyres) ; Caribbean
  polygon51 = gsn_add_polyline(wks,oceanplot(n),(/-100,-75/),(/48,48/),polyres) ; Caribbean
  polygon52 = gsn_add_polyline(wks,oceanplot(n),(/-75,-75/),(/8,48/),polyres) ; Caribbean
 end if

 if (tags .eq. 10) then ; Tropical Atlantic NW
  lats = 0
  latn = 25
  lonw = -75
  lone = -30
  polygon10 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 11) then ; Tropical Atlantic NE
  lats = 0
  latn = 25
  lonw = -30
  lone = 20
  polygon11 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 12) then ; Mediterranean
  lats = 30
  latn = 48
  lonw = 0
  lone = 45
  polygon12 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 13) then ; Indian Ocean NW/Arabian Sea
  lats = 4
  latn = 30
  lonw = 30
  lone = 75
  polygon13 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 14) then ; Indian Ocean NE/Bay of Bengal
  lats = 4
  latn = 30
  lonw = 75
  lone = 95
  polygon14 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 15) then ; Sundaland NW ocean
  lats = 4
  latn = 17
  lonw = 95
  lone = 108
  polygon15 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 16) then ; Sundaland NE ocean/South China Sea
  lats = 4
  latn = 17
  lonw = 108
  lone = 119
  polygon16 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 17) then ; Sundaland SW ocean
  lats = -10
  latn = 4
  lonw = 95
  lone = 105
  polygon17 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 18) then ; Sundaland SE ocean
  lats = -10
  latn = 4
  lonw = 105
  lone = 119
  polygon18 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 19) then ; Tropical Pacific NW
  lats = 4
  latn = 25
  lonw = 95
  lone = 150
  polygon19 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 20) then ; Tropical Pacific north central
  lats = 0
  latn = 25
  lonw = 150
  lone = -150
  polygon20 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 21) then ; Tropical Pacific SE
  lats = -25
  latn = 0
  lonw = -150
  lone = -60
  polygon21 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 22) then ; Tropical Atlantic SW
  lats = -25
  latn = 0
  lonw = -60
  lone = -10
  polygon22 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 23) then ; Tropical Atlantic SE
  lats = -25
  latn = 0
  lonw = -10
  lone = 20
  polygon23 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 24) then ; Tropical Indian Ocean SW
  lats = -25
  latn = 4
  lonw = 30
  lone = 70
  polygon24 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 25) then ; Tropical Indian Ocean south central
  lats = -25
  latn = 4
  lonw = 70
  lone = 95
  polygon25 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 26) then ; Tropical Indian Ocean SE
  lats = -25
  latn = -10
  lonw = 95
  lone = 119
  polygon26 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 27) then ; Sahul region ocean
  lats = -25
  latn = 4
  lonw = 119
  lone = 150
  polygon27 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 28) then ; Tropical Pacific south central, polyline only
  polygon280 = gsn_add_polyline(wks,oceanplot(n),(/150,179/),(/0,0/),polyres)
 end if

 if (tags .eq. 29) then ; South Pacific
  lats = -90
  latn = -25
  lonw = 140
  lone = -70
  polygon29 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 30) then ; South Atlantic
  lats = -90
  latn = -25
  lonw = -70
  lone = 25
  polygon30 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

 if (tags .eq. 31) then ; South Indian Ocean
  lats = -90
  latn = -25
  lonw = 25
  lone = 140
  polygon31 = gsn_add_polyline(wks,oceanplot(n),(/lonw,lonw,lone,lone,lonw/),(/lats,latn,latn,lats,lats/),polyres)
  delete([/lats,latn,lonw,lone/])
 end if

end do

;----------------
; Determine text to plot
;----------------

 tres = True
 tres@txFontHeightF = 0.015
 tres@txFontColor   = "black"

 if (n .eq. 0) then
  textvar = decimalPlaces((prect/sum(prect))*100.,1,True)
 else if (n .eq. 1) then
  textvar = decimalPlaces(d18Op,2,True)
 end if
 end if

;-----------------------------------
; Specifiy locations of text for plot
;-----------------------------------

oceanlon = (/ 210,310,50,240,272,315, 0,22,63,85,100,113,100,113,138,195,240,335,  1,57, 83,107,134,195,225,345, 90 /) 
oceanlat = (/  36, 36,58,  8, 37, 18,18,44,10,25, 11, 11, -2, -2, 18,  8, -8,-13,-13,-5,-10,-17,-20, -8,-40,-40,-40 /)

;----------------
; Draw point/region
;----------------

Area = "Region"

if (Area .eq. "Region") then
 polyres@gsLineColor = "red"
 polyres@gsLineDashPattern = 0
 polygon_region = gsn_add_polyline(wks,oceanplot(n),(/lonw_reg,lonw_reg,lone_reg,lone_reg,lonw_reg/),(/lats_reg,latn_reg,latn_reg,lats_reg,lats_reg/),polyres)

 texto = new(27,graphic)

 do o=13,39 ; 27 land tags
  pre = ""
  if (n .eq. 1) then ; d18Op
   if (textvar(o) .gt. 0.) then
    tres@txFontColor = "red"
    pre = "+"
   else if (textvar(o) .lt. 0.) then
    tres@txFontColor = "blue"
   else
    tres@txFontColor = "black"
   end if
   end if
  end if

  texto(o-13) = gsn_add_text(wks,oceanplot(n),""+pre+textvar(o),oceanlon(o-13),oceanlat(o-13),tres)

  delete(pre)
 end do 

 draw(oceanplot(n))
 frame(wks)

else if (Area .eq. "Point") then

 draw(oceanplot(n))
 polyres@gsMarkerColor = "red"
 polyres@gsMarkerSizeF = 8.0
 polyres@gsMarkerIndex = 16
 gsn_polymarker(wks,oceanplot(n),lon_point,lat_point,polyres)
 frame(wks)

end if
end if

end do

;********************************************************************
;********************************************************************
; Make the auxiliary plots for each tagged region
;********************************************************************
;********************************************************************

;-------------------------------------------------
; Contour specifications
;-------------------------------------------------

 res@cnFillOn       = True        ; Fill in contours?
 res@cnFillMode     = "RasterFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
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

 res@gsnLeftString   = "" 
 res@gsnCenterString = "" 
if (GC .eq. "Region") then
 res@gsnRightString  = ""+lat(lat_s)+"-"+lat(lat_n)+"~S~o~N~N,"+lon1+"-"+lon2+"~S~o~N~E" 
else if (GC .eq. "Point") then
 res@gsnRightString = ""+lat(latp)+"~S~o~N~N,"+lon_flip(lonp)+"~S~o~N~E"
end if
end if

; Text positions

 res@gsnLeftStringOrthogonalPosF   = 0.05  ; Left string up/down position
 res@gsnCenterStringOrthogonalPosF = 0.1; 0.05  ; Center string up/down position
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

 gsn_define_colormap(wks,"cmp_haxby")  ; Set at beginning of script by ColorTable
 ReverseColorTable = False       ; Reverse color table order?
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

 res@lbLabelFontHeightF = 0.01   ; Size of label font, default=0.02
 res@lbLabelAngleF      = 0      ; Angle of the label text, default=0.0
 res@lbLabelFont        = 21     ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

; Label Bar Title Text - displays units

 res@lbTitleString      = "~F21~" ; Label bar title text string
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
; Map plots
;----------------------------------------

 CUTOFF_VAL = 0.001 ; only show values in gridcells where rainfall (mm/day) is higher than this value

 polyres = True
 polyres@gsLineColor        = "black"
 polyres@gsMarkerColor      = "black"
 polyres@gsMarkerSizeF      = 5.0 
 polyres@gsLineThicknessF   = 1.0
 polyres@gsMarkerThicknessF = 1.0
 polyres@gsMarkerIndex      = 16       
 polyres@gsLineDashPattern  = 0

 res@gsnLeftString = cases(i-1)
 res@gsnDraw = False
 res@gsnFrame = False

; Plot d18Opsink

; First, remove areas where there is no rainfall
do lati=0,dimsizes(lat)-1
 do loni=0,dimsizes(lon)-1
  do tagind=1,numtags
   if (Pi_flip_by_tag(tagind-1,lati,loni) .lt. CUTOFF_VAL) then
    d18Opsink_flip_by_tag(tagind-1,lati,loni) = d18Opsink_flip_by_tag@_FillValue
   end if
  end do 
 end do
end do

 plotmap_18 = new(numtags, graphic)

 res@cnLevelSelectionMode = "ManualLevels"
 res@cnMaxLevelValF       =  10.0
 res@cnMinLevelValF       =  -60.0
 res@cnLevelSpacingF      =  5.0
 res@lbTitleString      = "~F21~per mil where precip > "+CUTOFF_VAL+" mm/day" ; Label bar title text string

 do tag=1,numtags
  res@gsnCenterString = ""+tag+": "+tagnames(tag-1)
  plotmap_18(tag-1) = gsn_csm_contour_map_ce(wks,d18Opsink_flip_by_tag(tag-1,:,:),res)
  if (GC .eq. "Region") then
   polygonr = gsn_add_polyline(wks,plotmap_18(tag-1),(/lon_flip(lon_w),lon_flip(lon_w),lon_flip(lon_e),lon_flip(lon_e),lon_flip(lon_w)/),(/lat(lat_s),lat(lat_n),lat(lat_n),lat(lat_s),lat(lat_s)/),polyres)
   draw(plotmap_18(tag-1))
  else if (GC .eq. "Point") then
   draw(plotmap_18(tag-1))
   gsn_polymarker(wks,plotmap_18(tag-1),lon_flip(lonp),lat(latp),polyres)
  end if
  end if
  frame(wks)
 end do

; Plot Pi

 plotmap_Pi = new(numtags, graphic)

 gsn_reverse_colormap(wks) 
 res@lbBoxEndCapStyle = "TriangleHighEnd"
; res@cnLevelSelectionMode = "ManualLevels"  ; If not wanting to use custom contour levels,
; res@cnMaxLevelValF       =  2.0            ; Uncomment these lines of code
; res@cnMinLevelValF       =  0.0            ; And comment out the one below
; res@cnLevelSpacingF      =  0.1            ; that says "res@cnLevels"
 res@cnLevelSelectionMode  = "ExplicitLevels"
 res@cnLevels              = (/ CUTOFF_VAL,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,2.0/) 
 res@lbTitleString         = "~F21~mm/day" ; Label bar title text string

 do tag=1,numtags
  res@gsnCenterString = ""+tag+": "+tagnames(tag-1)
  plotmap_Pi(tag-1) = gsn_csm_contour_map_ce(wks,Pi_flip_by_tag(tag-1,:,:),res)
  if (GC .eq. "Region") then
   polygonr = gsn_add_polyline(wks,plotmap_Pi(tag-1),(/lon_flip(lon_w),lon_flip(lon_w),lon_flip(lon_e),lon_flip(lon_e),lon_flip(lon_w)/),(/lat(lat_s),lat(lat_n),lat(lat_n),lat(lat_s),lat(lat_s)/),polyres)
   draw(plotmap_Pi(tag-1))
  else if (GC .eq. "Point") then
   draw(plotmap_Pi(tag-1))
   gsn_polymarker(wks,plotmap_Pi(tag-1),lon_flip(lonp),lat(latp),polyres)
  end if
  end if
  frame(wks)
 end do

delete(res)

end do ; i

end
