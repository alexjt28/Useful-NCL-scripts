;-------------------------------------------------------------------------------------------------------------------
; This script reads in rainfall from monthly netCDF files of climate model output and determines the northernmost
; latitudes reached each month/year by the West African monsoon. 
; 
; To define the northern limit of the West African Monsoon (WAM), we use a threshold of 2 mm/day, 
; adapted from 60 mm/month, averaged over the zonal region 15°W–20°E (Pausata et al., 2016). 
; With monthly model output, we calculate the northernmost latitude that exceeds
; 2 mm/day for each month over the zonal region. We find the northernmost latitude for each year, 
; taken as the maximum of the year’s monthly values, and create a distribution of northernmost latitudes 
; by year for each simulation. The median of this distribution is calculated and printed at the end. 
;
; Author: Alex Thompson
; Date: 7/29/2022
;
; Example shown here is for 50 years of monthly files from a case named "b.e12.B1850C5.f19_g16.i09ka.04"
;-------------------------------------------------------------------------------------------------------------------

begin

;*****************************************************************
; Specify model, output file, variable, and months to average over
;*****************************************************************

 PATH = "[/filepath/to/case/]b.e12.B1850C5.f19_g16.i09ka.04.cam.h0.02"   ; Will be reading in years 0201-0250
 
 L1  = "{"                                       ; one year: ""  multiple years: "{"
 R1  = "}"                                       ; one year: ""  multiple years: "}"
 YR  = "01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50" ; years to use
 L2  = "{"                                       ; one month/day: ""  multiple months/days: "{"
 R2  = "}"                                       ; one month/day: ""  multiple months/days: "}"
 MON = "01,02,03,04,05,06,07,08,09,10,11,12"    ; monthly: 01,02,etc. daily: 01-01,01-06,etc.
 END = ".nc"

 VAR1 = "PRECC" ; convective rainfall
 VAR2 = "PRECL" ; stratiform rainfall

 UNITS = "mm/day"
 MULT  = 86400000.0 ; If the default precipitation units are m/s, use the following conversion coefficients: 86400000.0 (mm/day), 2592000000.0 (mm/month), 31536000000.0 (mm/year)

;************************************************
; Case to identify
;************************************************

 fils = systemfunc("ls "+PATH+""+L1+""+YR+""+R1+"-"+L2+""+MON+""+R2+""+END+"")
 ins  = addfiles(fils,"r")
 ListSetType(ins,"cat")
 var1_preflip = ins[:]->$VAR1$
 var2_preflip = ins[:]->$VAR2$
 precc_preflip = var1_preflip*MULT
 precl_preflip = var2_preflip*MULT
 lat = var1_preflip&lat
 lon = var1_preflip&lon

 prect_preflip = precc_preflip + precl_preflip
 prect_preflip!0 = "time"
 prect_preflip!1 = "lat"
 prect_preflip!2 = "lon"
 prect_preflip&lat = lat
 prect_preflip&lon = lon
 printVarSummary(prect_preflip)

;************************************************
; Quantify northward extent of monsoon 
;************************************************

 ; Before applying coordinate indexing, use lonFlip

  lon_flip   = lonFlip(lon)
  prect_flip = lonFlip(prect_preflip) 

 ; Define zonal averaging region

  ;print(lat)
  ;print(lon_flip)

  lon_w = min(ind(lon_flip .ge. 345.0))  ; finding index of lon=15°W
  lon_e = max(ind(lon_flip .le. 20.0))   ; finding index of lon=20°E
  print("index = "+lon_w+" and coord = "+lon_flip(lon_w)+"°")
  print("index = "+lon_e+" and coord = "+lon_flip(lon_e)+"°")

 ; Define bounded region of latitude to calculate over
 ; This keeps the calculation short and centered on the region of importance 
 
  lat_s = min(ind(lat .ge. 10.0))   ; lowest latitude for calculation is ~10°N
  lat_n = max(ind(lat .le. 36.0))   ; highest latitude for calculation is ~36°N
  print("index = "+lat_s+" and coord = "+lat(lat_s)+"°")
  print("index = "+lat_n+" and coord = "+lat(lat_n)+"°")

 ; Perform zonal average (time,lat_s:lat_n)

  apply_coord_indices = prect_flip(:,lat_s:lat_n,lon_w:lon_e)
  monsoonvar          = dim_avg_n_Wrap(apply_coord_indices,2)
  printVarSummary(monsoonvar)

 ; Create variables for # of years and latitude cells

  times     = dimsizes(monsoonvar(:,0))
  numlats   = dimsizes(monsoonvar(0,:))
  latcoords = lat(lat_s-1:lat_n) 
  print(latcoords) 

 ; Initialize variables to run with loop, start northward_lat at 0 so it can climb 

  rain_per_lat = new((/numlats/),double)
  northward_lat = new((/times/),integer)
  northward_lat = 0 ; sets all values as 0

 ; Run a loop to determine highest latitude reaching a specified rainfall limit

  max_rain = 2.0 ; mm/day

  do n=0,times-1
    do i=0,numlats-1
      rain_per_lat(:) = monsoonvar(n,:)
      if (rain_per_lat(i) .ge. max_rain) then
        northward_lat(n) = northward_lat(n)+1 ; counts how many latitude bands (s->n) exceed max_rain
      end if
    end do
  end do  
  
  ; Northward lat now contains an index value for every month of the farthest north the max_rain value reached

 ; Calculate number of months in string MON and store in variable "timeperiod" 

  delim = ","
  timeperiod = str_fields_count(MON,delim)

 ; Find max latitude that reached max_rain for each time period (intervals of dimsizes(MON))
 
  numgroups = times / timeperiod
  northlat_per_timegroup = new((/numgroups/),integer)  

  do p = 1,numgroups
     b = (p*timeperiod)-1
     a = b - (timeperiod-1)
     northlat_per_timegroup(p-1) = max(northward_lat(a:b))
  end do

 ; Convert indices into latitude coordinates

  northlat_vals = new((/numgroups/),double)

  do c = 0,dimsizes(northlat_per_timegroup)-1
    northlat_vals(c) = latcoords(northlat_per_timegroup(c))
  end do

  print(northlat_vals)

 ; Calculate single maximum value

  MEDIAN_MAXLAT = dim_median(northlat_vals)
  print(MEDIAN_MAXLAT)

end
