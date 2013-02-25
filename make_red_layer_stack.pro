pro make_red_layer_stack, input_folder, band_num, mask_path, output_file=output_file
    COMPILE_OPT idl2, hidden

    IF(N_ELEMENTS(mask_path) EQ 0) THEN mask_path=!NULL
        
    IF mask_path ne !NULL THEN BEGIN
        print, "Reading mask from " + mask_path
        mask=read_binary(mask_path, DATA_DIMS=[4928,3264])
    ENDIF
    
    tiff_list = FILE_SEARCH(input_folder + PATH_SEP() + $
      'FNNR_2012_DHP_*-*_*.{TIF}', count=count)

    FOR i=0L,(count-1) DO BEGIN
        PRINT, "Reading band " + STRTRIM(band_num,2) + " from " + tiff_list[i]
        image_data = READ_TIFF(tiff_list[i], CHANNELS=band_num)
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

    IF(N_ELEMENTS(output_file) EQ 0) THEN BEGIN
        ; Extract plot ID from filename of the first tiff image
        pos = STREGEX(tiff_list[1], 'FNNR_2012_DHP_[0-9]{1,2}-[ABCDEabcde]', $
          length=len)
        plot_ID = STRMID(tiff_list[1], pos, len)
        output_file = input_folder + PATH_SEP() + "Band_" + $
          STRTRIM(band_num,2) + "_Stack_" + plot_ID + ".tif"
    ENDIF
    PRINT, "Writing " + output_file
    WRITE_TIFF, output_file, layers, /SHORT
end
