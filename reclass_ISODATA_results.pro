;+
; :Description:
;    Describe the procedure.
;
; :Params:
;    input_image
;    layer_stack_path
;    output_file
;    num_top_clusters
;
; :Author: Alex Zvoleff
;
; :Date: March, 8, 2013
;-

PRO reclass_isodata_results, input_image, layer_stack_path, output_file, $
  mask_path, mask_dims, num_top_clusters
    
  COMPILE_OPT idl2, hidden
    
  PRINT, "Reclassifying ISODATA results..."
  ENVI_OPEN_FILE, input_image, R_FID=c_fid
  ENVI_FILE_QUERY, c_fid, DIMS=dims, NB=nb, CLASS_NAMES=class_names, $
    NUM_CLASSES=num_classes
    
  ENVI_OPEN_FILE, layer_stack_path, R_FID=l_fid
  ENVI_FILE_QUERY, l_fid, DIMS=l_dims, NB=l_nb
  ; Calculate stats on the brightness of the band closest to the middle of the
  ; layer stack.
  pos = ROUND(l_nb/2.)
  
  class_ptr=LINDGEN(num_classes)
  
  ENVI_DOIT, 'CLASS_STATS_DOIT', CLASS_DIMS=dims, CLASS_FID=c_fid, $
    FID=l_fid, CLASS_PTR=class_ptr, POS=pos, COMP_FLAG=0, mean=means
    
  ; Recode so the brightest class is set to 100 (for sky) and all other
  ; classes are set to zero (canopy). Set invalid values (masked areas) to 255
  class_codes = SORT(means)
  num_codes = N_ELEMENTS(class_codes)
  canopy_codes = class_codes[(num_codes - num_top_clusters):(num_codes - 1)]
    
  image_data = ENVI_GET_DATA(DIMS=dims, FID=c_fid, POS=[0L])
  
  IF(N_ELEMENTS(mask_path) EQ 0) THEN mask_path=!NULL
  IF mask_path NE !NULL THEN BEGIN
    PRINT, "Reading mask from " + mask_path
    mask = read_binary(mask_path, DATA_DIMS=mask_dims)
    ; End result of below line is masked areas equal 255, not masked areas equal
    ; zero. Note that we need to invert the mask.
    recoded_image_data = (mask-1) * (-1) * 255
  ENDIF ELSE BEGIN
    recoded_image_data = image_data * 0
  ENDELSE
  
  ; Now set the canopy clusters to 100
  FOR i=0L,(num_top_clusters-1) DO $
    recoded_image_data[WHERE(image_data EQ canopy_codes[i])] = 100
    
  image_data_dims = SIZE(image_data, /DIMENSIONS)
  
  ENVI_WRITE_ENVI_FILE, recoded_image_data, OUT_DT=1, OUT_NAME=output_file, $
    NB=1, NS=image_data_dims[0], NL=image_data_dims[1]
END
