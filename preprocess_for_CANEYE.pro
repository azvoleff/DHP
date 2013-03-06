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
    
    file_prefix = "FNNR_DHP_Fall2012_"
    filename_format = file_prefix + '*-*_*.{TIF}'
    band_number = 1
    
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
        layer_stack_file = point_folder + PATH_SEP() + file_prefix + $
          full_point_ID + "_Band_" + strtrim(band_number, 2) + "_Stack.dat"
        isodata_file = point_folder + PATH_SEP() + file_prefix + $
          full_point_ID + "_Band_" + strtrim(band_number, 2) + $
          "_Stack_ISODATA.dat"
        reclass_file = point_folder + PATH_SEP() + file_prefix + $
          full_point_ID + "_Band_" + strtrim(band_number, 2) + $
          "_Stack_ISODATA_reclass.dat"
        reclass_cie_file = point_folder + PATH_SEP() + file_prefix + $
          full_point_ID + "_Band_" + strtrim(band_number, 2) + $
          "_Stack_ISODATA_reclass.cie"
        reclass_cie_zipfile = input_path + PATH_SEP() + "CIE_" + file_prefix + $
          full_point_ID + "_Band_" + strtrim(band_number, 2) + $
          "_Stack_ISODATA_reclass.zip"
        
        PRINT, "************************************************************"
        PRINT, "Processing " + point_folder
        PRINT, "************************************************************"
        make_red_layer_stack, point_folder, band_number, layer_stack_file, $
          filename_format, mask_path
        run_ISODATA, layer_stack_file, isodata_file
        reclass_ISODATA_results, isodata_file, layer_stack_file, reclass_file
                
        ; Now save the reclass file as an 8 bit binary format file with a cie
        ; extension, then compress it into a zipfile for CAN-EYE.
        PRINT, "Compressing CIE file for CAN-EYE..."
        FILE_COPY, reclass_file, reclass_cie_file
        SPAWN, "zip -m " + reclass_cie_zipfile + " " + reclass_cie_file, results
        PRINT, results
    ENDFOR
    
    ENVI_BATCH_EXIT
    PRINT, "************************************************************"
    PRINT, "             Completed CAN-EYE pre-processing."
    PRINT, "************************************************************"
END