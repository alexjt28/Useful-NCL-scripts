;----------------------------------------------------------------------------------------------------------------------
; This script transforms a given array of latitude and longitude values and transforms them to conform to a given
; model's lat/lon grid. For example, on f19_g16 grid resolution, lat=11.9°N and lon=78.7°W becomes 12.3 and 282.5.
; Model grid cell indices are also provided.
;
; Author: Alex Thompson
; Date: 7/29/2022
;----------------------------------------------------------------------------------------------------------------------

begin

;*************************************
; Read in variables from netCDF file
;*************************************

; NOTE: netCDF file must contain 2d lat and lon variables, such as LATIXY and LONGXY

coords_in = addfile("[/filepath/to/file/containing/2dlatlonvalues/ex.LATIXYandLONGXY.nc]","r")
lat2d     = coords_in->LATIXY
lon2d     = coords_in->LONGXY

; Print lat and lon for easy viewing
lat = lat2d(:,0)
lon = lon2d(0,:)
print(lat)
print(lon)

;***************************************************************
; Specify lat and lon arrays to convert to model grid values
;***************************************************************

; Example arrays provided below

latval = (/ -7.4, -3.6, -3.7, -9, -4.6, 2.5, 8.5, 5.7, -3.6, 24.4, 22.9, -13.1, 33, 37.6, 29, -37, 2.5, 6.5, 36.1, -40, 8.8, 8.7, -5.2, -4.7, 3.6, 7.9, 7.9, 32, 33, 0, 20.8, -16.6, 36, 12.8, 40.4, 10.7, -4.5, -6.5, 37.8, 2.3, 0.5, 36.2, -3.1, 11.3, 11.9 /)

lonval = (/ 115.2, 119.4, -81.1, 120, -36.6, 9.4, 112.3, 110.7, 119.4, -83.2, -109.5, 121.8, -120, -10.1, -87.1, 137.4, 9.4, 126.5, -2.6, 178, 121.3, 109.9, 117.5, 117.9, 118.7, -83.6, -83.6, -118, -120, -86.5, -18.6, 146.3, -2, -78.8, 143.5, -65.9, 145.7, 103.8, -10.2, -91, -92.4, -4.3, 142.7, -66.6, -78.7 /)

;*************************************
; Convert lat and lon values
;*************************************

nm = getind_latlon2d(lat2d,lon2d,latval,lonval)

;**************************************************
; Determine lat/lon values and indices for model grid
;**************************************************

lats_index = nm(:,0)
lons_index = nm(:,1)

; Determine lat/lon value from indices

lats_value = new((/ dimsizes(lats_index) /),double)
do lats=0,dimsizes(lats_index)-1
  lats_value(lats) = lat(lats_index(lats))
end do

lons_value = new((/ dimsizes(lons_index) /),double)
do lons=0,dimsizes(lons_index)-1
  lons_value(lons) = lon(lons_index(lons))
end do

;*****************************
; Print values and indices
;*****************************

print(lats_value)
print(lons_value)

print(lats_index)
print(lons_index)

end
