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
  ; Remove empty entries
  non_empties = where(tiff_list NE '')
  if N_ELEMENTS(non_empties) EQ 1 && non_empties EQ -1 THEN $
    MESSAGE, 'No tiffs found in ' + input_folder + $
    ' (using regular expression "' + filename_regex + '")'
  tiff_list = tiff_list[non_empties]
  ; Now grep for EV values
  EV_strings = STREGEX(tiff_list, "_[-]?[0-4] EV", /extract, /fold_case)
  EV_values = LONG(STREGEX(EV_strings, "[-]?[0-4]", /extract, /fold_case))
  ; Sort tiff list in order by EV value
  tiff_list = tiff_list[sort(EV_values)]
  ; Now sort EV value list for use in excluding exposures
  EV_values = EV_values[sort(EV_values)]
  included_exposures = MAKE_ARRAY(N_ELEMENTS(tiff_list),1, /INTEGER, VALUE=1)
  IF ignored_exposures NE [] THEN BEGIN
    FOR i=0, (N_ELEMENTS(ignored_exposures)-1) DO BEGIN
      loc = where(EV_values EQ ignored_exposures[i], /NULL)
      IF loc EQ !NULL THEN MESSAGE, "Error: cannot exclude exposure " + $
        STRTRIM(ignored_exposures[i], 2) + " - check if file exists"
      included_exposures[loc] = 0
    ENDFOR
    tiff_list = tiff_list[where(included_exposures, /NULL)]
    incuded_indices = where(included_exposures, complement=excluded_indices, /NULL)
    print, ["Excluded exposures (in EV):", STRTRIM(EV_values[excluded_indices], 2)]
  ENDIF
  num_tiffs = N_ELEMENTS(tiff_list)
  IF num_tiffs LT 1 THEN MESSAGE, "Error: all tiffs excluded"
  print, ["Included exposures (in EV):", STRTRIM(EV_values[where(included_exposures, /NULL)], 2)]
    
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