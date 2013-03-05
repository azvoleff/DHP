PRO preprocess_for_CANEYE
    ; The below variable must be set to location on your system of the mask
    ; image (D7000_Sigma4.5_Mask.dat). The mask image will be used to mask areas
    ; of the photo that are outside the field of view of the 4.5mm Sigma
    ; fisheye lens. If the image is in the same folder as the code, the image
    ; name alone can be given. Otherwise the full path must be specified
    mask_path = "D7000_Sigma4.5_Mask.dat"
    
    input_folder = DIALOG_PICKFILE(/DIRECTORY, $
        TITLE="Choose a plot directory containing a set of point folders to process")
    
    make_red_layer_stack, input_folder, 1, mask_path, output_file=layer_stack_file
    run_ISODATA, layer_stack_file, output_file=isodata_results
    reclass_ISODATA_results, isodata_results, layer_stack_file
    
    PRINT, "Completed processing."
END