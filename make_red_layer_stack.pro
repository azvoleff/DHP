;+
; :Description:
;    Describe the procedure.
;
; :Params:
;    input_folder
;    band_num
;    output_file
;    filename_format
;    mask_path
;
; :Author: Alex Zvoleff
; 
; :Date: March, 8, 2013
;-
PRO make_red_layer_stack, input_folder, band_num, output_file, $
  filename_format, mask_path
  
  COMPILE_OPT idl2, hidden
  
  IF(N_ELEMENTS(mask_path) EQ 0) THEN mask_path=!NULL
  
  IF mask_path NE !NULL THEN BEGIN
    PRINT, "Reading mask from " + mask_path
    mask = read_binary(mask_path, DATA_DIMS=[4928, 3264])
  ENDIF
  
  PRINT, "Making layer stack..."
  tiff_list = FILE_SEARCH(input_folder + PATH_SEP() + $
    filename_format, count=count)
    
  FOR i=0L,(count-1) DO BEGIN
    PRINT, "Reading band " + STRTRIM(band_num,2) + " from " + tiff_list[i]
    image_data = READ_TIFF(tiff_list[i], CHANNELS=band_num)
    IF MASK_PATH NE !NULL THEN BEGIN
      image_data = image_data * mask
    ENDIF
    image_data = REFORM(image_data,[1, SIZE(image_data,/dimensions)])
    IF (i EQ 0L) THEN BEGIN
      layers = image_data
    ENDIF ELSE BEGIN
      layers = [layers, image_data]
    ENDELSE
  ENDFOR
  
  PRINT, "Writing layer stack to " + output_file
  WRITE_TIFF, output_file, layers, /SHORT
END