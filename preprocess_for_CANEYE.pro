PRO preprocess_for_CANEYE
    ; The below variable must be set to location on your system of the mask
    ; image (D7000_Sigma4.5_Mask.dat). The mask image will be used to mask areas
    ; of the photo that are outside the field of view of the 4.5mm Sigma
    ; fisheye lens. The full path to the mask image must be specified.
    mask_path = "C:\Users\azvoleff\Code\IDL\DHP\D7000_Sigma4.5_Mask.dat"
    
    ; First select the folder where the input data is located. Either use the
    ; code to have a GUI dialog presented, or uncomment the line below the GUI
    ; code and hard hardcode the path to the input data.
    ;input_path = DIALOG_PICKFILE(/DIRECTORY, $
    ;    TITLE="Choose a folder to process")
    ; Path to input data (comment out above two lines if you hardcode the input
    ; data path).
    input_path = "M:\Data\China\FNNR\2012_DHP_Survey\TIFFs\1"
    
    ; Choose the band number to use for the ISODATA layer stack. Set to 1 for
    ; red band, 2 for blue band, and 3 for green band.
    band_number = 1
    
    ; Below are the parameters for the ISODATA clustering
    iterations = 15 ; Default to 15 - most images take only 3 iterations
    change_thresh = .5 ; Default to .5
    iso_merge_dist = 5 ; Default to 5 
    iso_merge_pairs = 2 ; Default to 2
    iso_min_pixels = 20 ; Default to 20
    iso_split_std = 0 ; Default to 0
    min_classes = 2 ; Default to 2
    num_classes = 10 ; Default to 10
    
    ; The file_prefix is the prefix in front of each DHP tif file, including 
    ; all text up until the plot and point ID number. For FNNR, set the
    ; file_prefix to "FNNR_DHP_Fall2012_". For Wolong, set it to
    ; "Wolong_DHP_Spring2012_".
    file_prefix = "FNNR_DHP_Fall2012_"
    filename_format = file_prefix + '*-*_*.{TIF}'
    
    ; *************************************************************************
    ; Do not modify code below this line.
    ; *************************************************************************
           
    point_folder_list = FILE_SEARCH(input_path + PATH_SEP() + $
      '[1-6a-eA-E]', count=count, /TEST_DIRECTORY, /TEST_READ)
    IF COUNT EQ 0 THEN BEGIN
        MESSAGE, "No point folders found in " + input_path
    ENDIF ELSE BEGIN
        PRINT, "Found " + STRTRIM(count, 2) + " point folders:"
        FOR i=0, count-1 DO PRINT, "    " + point_folder_list[i]
    ENDELSE
    
    ENVI, /restore_base_save_files
    ENVI_BATCH_INIT, log_file='batch.txt'
    
    FOR i=0, count-1 DO BEGIN
        point_folder = point_folder_list[i]
        pos = STREGEX(point_folder, '[0-9]{1,2}[\\]{1,2}[a-iA-I1-9]$', length=len)
        split_point_folder = strsplit(point_folder, "\/", /EXTRACT, count=num_strs)
        plot_ID = split_point_folder[num_strs-2]
        point_ID = split_point_folder[num_strs-1]
        full_point_ID = plot_ID + '-' + point_ID
        
        ; Setup filenames for input/output files
        output_file_prefix = file_prefix + full_point_ID + "_Band_" + $
            strtrim(band_number, 2)
        layer_stack_file = point_folder + PATH_SEP() + output_file_prefix + $
            "_Stack.dat"
        isodata_file = point_folder + PATH_SEP() + ouput_file_prefix + $
            "_Stack_ISODATA.dat"
        reclass_file = point_folder + PATH_SEP() + output_file_prefix + $
            "_Stack_ISODATA_reclass.dat"
        reclass_cie_file = point_folder + PATH_SEP() + output_file_prefix + $
            "_Stack_ISODATA_reclass.cie"
        reclass_cie_zipfile = input_path + PATH_SEP() + "CIE_" + $
          output_file_prefix + "_Stack_ISODATA_reclass.zip"
        
        PRINT, "************************************************************"
        PRINT, "Processing " + point_folder
        PRINT, "************************************************************"
        make_red_layer_stack, point_folder, band_number, layer_stack_file, $
            filename_format, mask_path
        run_ISODATA, layer_stack_file, isodata_file, iterations, $
            change_thresh, iso_merge_dist, iso_merge_pairs, iso_min_pixels, $
            iso_split_std, min_classes, num_classes
        reclass_ISODATA_results, isodata_file, layer_stack_file, reclass_file
                
        ; Now save the reclass file as an 8 bit binary format file with a cie
        ; extension, then compress it into a zipfile for CAN-EYE.
        PRINT, "Compressing CIE file for CAN-EYE..."
        FILE_COPY, reclass_file, reclass_cie_file
        SPAWN, "zip -m -j " + reclass_cie_zipfile + " " + reclass_cie_file, results
        PRINT, results
    ENDFOR
    
    ENVI_BATCH_EXIT
    PRINT, "************************************************************"
    PRINT, "             Completed CAN-EYE pre-processing."
    PRINT, "************************************************************"
END