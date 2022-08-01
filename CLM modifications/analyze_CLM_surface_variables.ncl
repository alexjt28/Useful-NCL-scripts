;-------------------------------------------------------------------------------------------------------------------
; This script reads in variables from an fsurdat file for the Community Land Model (CLM) and displays map plots of
; the percentage of surface variables (individual PFTs, glacier, lake, wetland, and urban). This script calculates
; the percentages from an individual case's fsurdat file or the differences in percentages from a difference file
; (ex. diff case1_fsurdat.nc case2_fsurdat.nc case1_case2_diff.nc).
;
; Author: Alex Thompson
; Date: 7/29/2022
;-------------------------------------------------------------------------------------------------------------------

begin

;****************************
; Specify fsurdat file paths
;****************************

; Case name for output file

NAME = "[case name]"

; Filepath to fsurdat file

filename = "[/filepath/to/fsurdat/file.nc]" ; or "[/filepath/to/fsurdat/diff/file.nc]"

; Is the fsurdat file a difference file?

filediff = "No"   ; "Yes" or "No"

;*********************************
; Read in the variables
;*********************************

in = addfile(filename,"r")

pct_pft = in->PCT_PFT
pct_pft_flip = lonFlip(pct_pft)
pct_pft_flip@_FillValue = -999

pct_glac = in->PCT_GLACIER
pct_glac_flip = lonFlip(pct_glac)
pct_glac_flip@_FillValue = -999

pct_lake = in->PCT_LAKE
pct_lake_flip = lonFlip(pct_lake)
pct_lake_flip@_FillValue = -999

pct_wetl = in->PCT_WETLAND
pct_wetl_flip = lonFlip(pct_wetl)
pct_wetl_flip@_FillValue = -999

pct_urba = in->PCT_URBAN
pct_urba_flip = lonFlip(pct_urba)
pct_urba_flip@_FillValue = -999

PFT_names = (/ "0  = bare","1  = needleleaf evergreen temperate tree","2  = needleleaf evergreen boreal tree","3  = needleleaf deciduous boreal tree","4  = broadleaf evergreen tropical tree","5  = broadleaf evergreen temperate tree","6  = broadleaf deciduous tropical tree","7  = broadleaf deciduous temperate tree","8  = broadleaf deciduous boreal tree","9  = broadleaf evergreen temperate shrub","10 = broadleaf deciduous temperate shrub","11 = broadleaf deciduous boreal shrub","12 = arctic c3 grass","13 = cool c3 grass","14 = warm c4 grass","15 = crop 1","16 = crop 2" /)

; Useful guide for CLM4.0 pft indices
print("0  = bare")
print("1  = needleleaf evergreen temperate tree")
print("2  = needleleaf evergreen boreal tree")
print("3  = needleleaf deciduous boreal tree")
print("4  = broadleaf evergreen tropical tree")
print("5  = broadleaf evergreen temperate tree")
print("6  = broadleaf deciduous tropical tree")
print("7  = broadleaf deciduous temperate tree")
print("8  = broadleaf deciduous boreal tree")
print("9  = broadleaf evergreen temperate shrub")
print("10 = broadleaf deciduous temperate shrub")
print("11 = broadleaf deciduous boreal shrub")
print("12 = arctic c3 grass")
print("13 = cool c3 grass")
print("14 = warm c4 grass")
print("15 = crop 1")
print("16 = crop 2")

;**********************
; Apply PFT data mask
;**********************

mask_in = addfile("[/filepath/with/PFTDATA_MASK]","r")  ; may be same as filepath above

pftmask = lonFlip(mask_in->PFTDATA_MASK)
dims_pft = dimsizes(pct_pft_flip)

do i=0,dims_pft(1)-1
 do j=0,dims_pft(2)-1
   if (pftmask(i,j) .eq. 0.) then
     pct_pft_flip(:,i,j) = pct_pft_flip@_FillValue
     pct_glac_flip(i,j) = pct_glac_flip@_FillValue
     pct_lake_flip(i,j) = pct_lake_flip@_FillValue
     pct_wetl_flip(i,j) = pct_wetl_flip@_FillValue
     pct_urba_flip(i,j) = pct_urba_flip@_FillValue
   end if
 end do
end do

;****************************************
; Make the plot
;****************************************

 file_type  = "pdf"    ; "x11" or "pdf"

 outputfilename = "pdfs/CLM_surface_variables_for_"+filename+""

 wks = gsn_open_wks(file_type,outputfilename)

 res = True

;---------------------------------------------
; Zoom into any world region in particular?
;---------------------------------------------

 res@mpMinLatF = -90
 res@mpMaxLatF = 90
 res@mpMinLonF = -180
 res@mpMaxLonF = 180

;-------------------------------------------------
; Contour specifications
;-------------------------------------------------

 res@cnFillOn       = True        ; Fill in contours?
 res@cnFillMode     = "AreaFill"  ; What type of contour fill? "RasterFill" or "AreaFill"
 res@cnLinesOn      = False      ; Contour lines?
 res@cnLineLabelsOn = False      ; Contour line labels?
 res@gsnAddCyclic   = True        ; Eliminates gap in longitudinal data

;------------------------------------------------
; Color and label bar specifications
;------------------------------------------------

; Colors

 if (filediff .eq. "No") then
  gsn_define_colormap(wks,"MPL_gist_earth") ; Setting ColorTable
  gsn_reverse_colormap(wks)
 else if (filediff .eq. "Yes") then
  gsn_define_colormap(wks,"BlueYellowred")  ; Setting ColorTable
 end if
 end if

 res@lbLabelBarOn         = True             ; True turns on label bar
 res@gsnSpreadColors      = False             ; if True, reduces colors used from color table
 res@gsnSpreadColorStart  = 2; 20              ; Index to start with: default=2
 res@gsnSpreadColorEnd    = -2;-20              ; Index to end with: default=-1

; Label Bar Style

 res@pmLabelBarOrthogonalPosF = 0.08               ; Up and down position of label bar, default=0.02
 res@lbOrientation            = "horizontal"       ; Orientation of label bar: "horizontal" or "vertical"
 res@lbLabelStride            = 2                  ; How many labels to skip

; Label Text

 res@lbLabelFontHeightF = 0.01   ; Size of label font, default=0.02
 res@lbLabelAngleF      = 0      ; Angle of the label text, default=0.0
 res@lbLabelFont        = 21     ; Label font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml

; Label Bar Title Text - displays units

 res@lbTitleString      = "~F21~%" ; Label bar title text string
 res@lbTitlePosition    = "Right"          ; Where to place label bar title text string
                                       ; "Top","Bottom","Left","Right"
 res@lbTitleDirection   = "Across"         ; Direction of title text: "Across" or "Down"
 res@lbTitleFont        = 21               ; Title font index from https://www.ncl.ucar.edu/Document/Graphics/font_tables.shtml
 res@lbTitleFontHeightF = 0.012            ; Title font size, default=0.025

;--------------------------------------------------------------------------------
; Specify contour levels for values, sets explicit values for individual case
;--------------------------------------------------------------------------------

if (filediff .eq. "No") then
 CONTOURS = "Explicit"
else if (filediff .eq. "Yes") then
 CONTOURS = "Manual"
end if
end if

if (CONTOURS .eq. "Manual") then
 res@cnLevelSelectionMode = "ManualLevels"
 res@cnMaxLevelValF       = 20.0
 res@cnMinLevelValF       = -20.0
 res@cnLevelSpacingF      = 1.0

else if (CONTOURS .eq. "Explicit") then
 res@cnLevelSelectionMode = "ExplicitLevels"
 res@cnLevels             = (/ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,50,60,70,80,90 /)

end if
end if

;-----------------------
; Multiple plots
;-----------------------

res@gsnRightString = NAME

plot = new(21,graphic)

i=0
do while(i.le.dimsizes(PFT_names)-1)
 res@gsnLeftString = PFT_names(i)
 plot(i) = gsn_csm_contour_map_ce(wks,pct_pft_flip(i,:,:),res)
 i = i+1
end do

 res@gsnLeftString = "% Glacier"
 plot(i) = gsn_csm_contour_map_ce(wks,pct_glac_flip,res)

 res@gsnLeftString = "% Lake"
 plot(i+1) = gsn_csm_contour_map_ce(wks,pct_lake_flip,res)

 res@gsnLeftString = "% Wetland"
 plot(i+2) = gsn_csm_contour_map_ce(wks,pct_wetl_flip,res)

 res@gsnLeftString = "% Urban"
 plot(i+3) = gsn_csm_contour_map_ce(wks,pct_urba_flip,res)

end
