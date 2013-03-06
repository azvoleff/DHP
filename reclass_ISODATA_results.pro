PRO reclass_ISODATA_results, input_image, layer_stack_path, output_file, num_top_clusters
    COMPILE_OPT idl2, hidden
    
    ; num_top_clusters specifies how many of the brightest clusters should be 
    ; combined and recoded as sky
    IF(N_ELEMENTS(num_top_clusters) EQ 0) THEN num_top_clusters=1
      
    PRINT, "Reclassifying ISODATA results..."
    ENVI_OPEN_FILE, input_image, R_FID=c_fid
    ENVI_FILE_QUERY, c_fid, DIMS=dims, NB=nb, CLASS_NAMES=class_names, $
      NUM_CLASSES=num_classes
        
    ENVI_OPEN_FILE, layer_stack_path, R_FID=l_fid
    ; The pos=3 below indicates that we will calculate stats on the brightness
    ; values from the 3rd layer in the layer stack only when we are trying to
    ; decide which class has the highest mean brightness.
    pos = [3L]
        
    class_ptr=LINDGEN(num_classes)
        
    ENVI_DOIT, 'CLASS_STATS_DOIT', CLASS_DIMS=dims, CLASS_FID=c_fid, $
      FID=l_fid, CLASS_PTR=class_ptr, POS=pos, COMP_FLAG=0, mean=means
    
    ; Recode so the brightest class is set to 100 (for canopy) and all other
    ; classes are set to zero. Set invalid values (masked areas) to 255
    class_codes = sort(means)
    num_codes = N_Elements(class_codes)
    sky_codes = class_codes[(num_codes - num_top_clusters):(num_codes -1)]
    masked_code = class_codes[1]
    
    image_data = ENVI_GET_DATA(DIMS=dims, FID=c_fid, POS=[0L])
    recoded_image_data = (image_data EQ masked_code) * 255
    FOR i=0L,(num_top_clusters-1) DO $
      recoded_image_data[WHERE(image_data EQ sky_codes[i])] = 100 
        
    ENVI_WRITE_ENVI_FILE, recoded_image_data, OUT_DT=1, OUT_NAME=output_file
END