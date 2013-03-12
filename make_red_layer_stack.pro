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
  filename_regex, mask_path, ignored_exposures
  
  COMPILE_OPT idl2, hidden
  
  IF(N_ELEMENTS(mask_path) EQ 0) THEN mask_path=!NULL
  
  IF mask_path NE !NULL THEN BEGIN
    PRINT, "Reading mask from " + mask_path
    mask = read_binary(mask_path, DATA_DIMS=[4928, 3264])
  ENDIF
  
  PRINT, "Making layer stack..."
  
  files = FILE_SEARCH(input_folder + PATH_SEP() + "*")
  tiff_list = STREGEX(files, filename_regex, /extract, /fold_case)
  tiff_list = STRSPLIT(tiff_list, '[[:space:]]', /extract, /regex)
  ; Remove empty entries
  non_empties = where(tiff_list NE '')
  if N_ELEMENTS(non_empties) EQ 1 && non_empties EQ -1 THEN $
    MESSAGE, 'No tiffs found in ' + input_folder + $
    ' (using regular expression "' + filename_regex + '")'
  tiff_list = tiff_list[non_empties]
  IF ignored_exposures NE [] THEN BEGIN
    IF MAX(ignored_exposures) GT N_ELEMENTS(tiff_list) THEN $
      MESSAGE, "Error: cannot exclude exposures", + $
      strtrim(ignored_exposures, 2) + "when only" + $
      strtim(N_ELEMENTS(tiff_list), 2) + "exposures were taken"
    IF MIN(ignored_exposures) LT 1 THEN $
      MESSAGE, "Error: ignored exposures cannot be less than 1"
    print, "Exposures excluded from layer stack:", strtrim(ignored_exposures, 2)
    included_tiffs = MAKE_ARRAY(N_ELEMENTS(tiff_list),1, /INTEGER, VALUE=1)
    ; Subtract one from below due to zero indexing
    included_tiffs[ignored_exposures-1] = 0
    tiff_list = tiff_list[where(included_tiffs, /NULL)]
  ENDIF
  num_tiffs = N_ELEMENTS(tiff_list)
  IF num_tiffs LT 1 THEN MESSAGE, "Error: all tiffs excluded"
    
  FOR i=0L,(num_tiffs-1) DO BEGIN
    PRINT, "Reading band " + STRTRIM(band_num,2) + " from " + tiff_list[i]
    image_data = READ_TIFF(input_folder + PATH_SEP() + tiff_list[i], $
      CHANNELS=band_num)
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