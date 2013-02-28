PRO preprocess_for_CANEYE
    input_folder = DIALOG_PICKFILE(/DIRECTORY, $
        TITLE="Choose directory containing the .tif files to process")
        
    mask_path = "C:\Users\azvoleff\Code\IDL\DHP\D7000_Sigma4.5_Mask.dat"

    make_red_layer_stack, input_folder, 1, mask_path, output_file=layer_stack_file
    run_ISODATA, layer_stack_file, output_file=isodata_results
    reclass_ISODATA_results, isodata_results, layer_stack_file
    
    PRINT, "Completed processing."
END