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
PRO reclass_isodata_results, input_image, layer_stack_path, output_file, num_top_clusters
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
    
  ; Recode so the brightest class is set to 100 (for canopy) and all other
  ; classes are set to zero. Set invalid values (masked areas) to 255
  class_codes = SORT(means)
  num_codes = N_ELEMENTS(class_codes)
  sky_codes = class_codes[(num_codes - num_top_clusters):(num_codes -1)]
  masked_code = class_codes[1]
  
  image_data = ENVI_GET_DATA(DIMS=dims, FID=c_fid, POS=[0L])
  recoded_image_data = (image_data EQ masked_code) * 255
  FOR i=0L,(num_top_clusters-1) DO $
    recoded_image_data[WHERE(image_data EQ sky_codes[i])] = 100
    
  image_data_dims = SIZE(image_data, /DIMENSIONS)
  
  ENVI_WRITE_ENVI_FILE, recoded_image_data, OUT_DT=1, OUT_NAME=output_file, $
    NB=1, NS=image_data_dims[0], NL=image_data_dims[1]
END