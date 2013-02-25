PRO run_ISODATA, input_image, method, output_file=output_file
    COMPILE_OPT idl2, hidden
    
    IF(N_ELEMENTS(output_file) EQ 0) THEN BEGIN
        pos = STREGEX(input_image, 'Band_[1-3]_Stack_FNNR_2012_DHP_[0-9]{1,2}-[ABCDEabcde]', length=len)
        plot_ID = STRMID(input_image, pos, len)
        output_file = file_dirname(input_image) + path_sep() + plot_ID + $
          "_ISODATA.dat"
    ENDIF
    
    IF(N_ELEMENTS(method) EQ 0) THEN method=4
    
    PRINT, "Loading ENVI to run ISODATA"                
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, log_file='batch.txt'

    iterations=100
    change_thresh=.5
    iso_merge_dist=5
    iso_merge_pairs=2
    iso_min_pixels=20
    iso_split_std=0
    min_classes=2
    num_classes=10

    ENVI_OPEN_FILE, input_image, R_FID=fid

    ; Validate that the raster was successfully opened by ENVI
    ; and use error reporting.
    IF (fid EQ -1) THEN BEGIN
        errMsg = 'Error: Failed to open input: ' + input_image
        ENVI_REPORT_ERROR, errMsg
        RETURN
    ENDIF

    ; Get the dimensions and # bands for the input file. 
    ENVI_FILE_QUERY, fid, dims=dims, nb=nb
    ; Initialize a POS variable for all bands in the file. 
    pos = LINDGEN(nb)

    PRINT, "Running ISODATA"
    ; Call the ENVI ISODATA doit routine and return a File ID (outFid) to the 
    ; new raster file.
    ENVI_DOIT, 'CLASS_DOIT', FID=fid, OUT_NAME=output_file, $ 
        METHOD=method, R_FID=outFid, POS=pos, DIMS=dims, $
        ITERATIONS=iterations, CHANGE_THRESH=change_thresh, $
        ISO_MERGE_DIST=iso_merge_dist, ISO_MERGE_PAIRS=iso_merge_pairs, $
        ISO_MIN_PIXELS=iso_min_pixels, ISO_SPLIT_SMULT=iso_split_smult, $
        ISO_SPLIT_STD=iso_split_std, MIN_CLASSES=min_classes, $
        NUM_CLASSES=num_classes

    ENVI_BATCH_EXIT
END
