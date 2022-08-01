;-------------------------------------------------------------------------------------------------------------------
; This script reads in variables from an fsurdat file for the Community Land Model (CLM) and checks if the sum
; of all land surface percentage variables (i.e., %PFT, %glacier, %wetland, %lake, %urban) is 100%.
;
; Author: Alex Thompson
; Date: 7/29/2022
;-------------------------------------------------------------------------------------------------------------------

begin

;**************************************
; Read in fsurdat file
;**************************************

 filename = "[/filepath/to/fsurdat/file.nc]"

;**************************************
; Read in variables
;**************************************

 in = addfile(filename,"r")

; Lat/Lon
 lat1     = in->LATIXY
 lon1     = in->LONGXY
 lat      = lat1(:,0)
 lon      = lon1(0,:)
 lon_flip = lonFlip(lon)
 ;print(lat)
 ;print(lon_flip)

; Dimensions for modifications
 latdim = dimsizes(lat)
 londim = dimsizes(lon)

; Variables to be modified

; PFT (pft,lat,lon)
 pct_pft = in->PCT_PFT

; GLACIER (lat,lon)
 pct_glc = in->PCT_GLACIER

; WETLAND (lat,lon)
 pct_wet = in->PCT_WETLAND

; LAKE (lat,lon)
 pct_lak = in->PCT_LAKE

; URBAN (lat,lon)
 pct_urb = in->PCT_URBAN

;*************************************************************
; Calculate sum of all variables
;*************************************************************

; Sum land surface variables into one variable to ensure it reaches 100%

 SumLand = pct_pft(0,:,:)+pct_pft(1,:,:)+pct_pft(2,:,:)+pct_pft(3,:,:)+pct_pft(4,:,:)+pct_pft(5,:,:)+pct_pft(6,:,:)+pct_pft(7,:,:)+pct_pft(8,:,:)+pct_pft(9,:,:)+pct_pft(10,:,:)+pct_pft(11,:,:)+pct_pft(12,:,:)+pct_pft(13,:,:)+pct_pft(14,:,:)+pct_pft(15,:,:)+pct_pft(16,:,:)+pct_glc(:,:)+pct_wet(:,:)+pct_lak(:,:)+pct_urb(:,:)

;******************
; Is sum 100%?
;******************

 Sum_100 = dimsizes(lat)*dimsizes(lon)*100.
 SumFile = sum(SumLand)

 DIFF = Sum_100 - SumFile

 if (DIFF .eq. 0.0000000000) then        ; Accuracy to 10^10 to catch miniscule errors

  print("*****************************")
  print("**** SUM .eq. 100% !!!!!!****")
  print("*****************************")

 else

  print("-----------------------------")
  print("-- ERROR ERROR ERROR ERROR --")
  print("-- SUM DOES NOT EQUAL 100% --")
  print("-- ERROR ERROR ERROR ERROR --")
  print("-----------------------------")

  ; Plot DIFF to see where errors are

   wks = gsn_open_wks("x11","file")
   res = True
   res@cnFillOn = True
   plot1 = gsn_csm_contour_map_ce(wks,SumLand,res)

 end if

end
