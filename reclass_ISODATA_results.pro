PRO reclass_ISODATA_results, input_image, layer_stack_path, num_top_clusters, output_file=output_file
    COMPILE_OPT idl2, hidden
    
    PRINT,"Loading ENVI to reclassify ISODATA results"
    ENVI, /restore_base_save_files
    ENVI_BATCH_INIT, log_file='batch.txt'
    
    IF(N_ELEMENTS(num_top_clusters) EQ 0) THEN num_top_clusters=1
      
    IF(N_ELEMENTS(output_file) EQ 0) THEN BEGIN
      pos = STREGEX(input_image, 'Band_[1-3]_Stack_FNNR_2012_DHP_[0-9]{1,2}-[ABCDEabcde]_ISODATA', length=len)
      plot_ID = STRMID(input_image, pos, len)
      output_path = FILE_DIRNAME(input_image) + PATH_SEP() + plot_ID + $
        "_reclassed.dat"
      cie_file_output_path = FILE_DIRNAME(input_image) + PATH_SEP() + $
        plot_ID + "_reclassed.cie"
      cie_zipfile_output_path = FILE_DIRNAME(input_image) + PATH_SEP() + $
        plot_ID + "_reclassed.zip"
    ENDIF
    
    PRINT, "Reclassifying ISODATA results..."
    ENVI_OPEN_FILE, input_image, R_FID=c_fid
    ENVI_FILE_QUERY, c_fid, DIMS=dims, NB=nb, CLASS_NAMES=class_names, $
      NUM_CLASSES=num_classes
        
    ENVI_OPEN_FILE, layer_stack_path, R_FID=l_fid
    pos = [3L]
        
    class_ptr=LINDGEN(num_classes)
        
    ENVI_DOIT, 'CLASS_STATS_DOIT', CLASS_DIMS=dims, CLASS_FID=c_fid, $
      FID=l_fid, CLASS_PTR=class_ptr, POS=pos, COMP_FLAG=0, mean=means
    
    ; Recode so the brightest class is set to 100 (for canopy) and all other
    ; classes are set to zero.    
    max_brightness = MAX(means, max_class_index)
    max_class_name = class_names[max_class_index]
    image_data=ENVI_GET_DATA(DIMS=dims,FID=c_fid,POS=[0L])
    image_data = (image_data EQ max_class_index) * 100
    
    ENVI_WRITE_ENVI_FILE, image_data, OUT_DT=1, OUT_NAME=output_path
    
    ; Copy the 8 bit unsigned int binary format file to another file with a
    ; .cie extension for use in CAN-EYE 
    FILE_COPY,output_path,cie_file_output_path
    
    ; Note that the below is a temporary fix for cross-platform file compression
    ; in IDL. IDL version 8.2.3 or 8.3 is supposed to have built in support
    ; for file compression (https://groups.google.com/forum/?fromgroups=#!topic/comp.lang.idl-pvwave/VvxNmj0lBvQ" 
    void = {IDLitWriteKML}  ; just get the code compiled
    void = IDLKML_SaveKMZ(cie_zipfile_output_path, cie_file_output_path)
END