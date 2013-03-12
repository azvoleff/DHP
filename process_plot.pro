;+
; :Description:
;    For each point in a plot, layer stack the canopy photos, and then run ISODATA
;    on the layer stack to classify 10 different clusters. Finally, reclassify
;    the ISODATA output so that the cluster with the highest brightness is
;    assigned a value of 100 (for sky), while pixels from all other clusters are
;    set to 0 (for canopy). Unknown or masked pixels are set to 255.
;
;    The photos must all be located in the same folder, with a the folder name
;    set to the plot ID. Sets of exposures from the same point must be within
;    subfolders under the plot ID. For example, the photos from points A-E for
;    plot 1 might be organized as follows:
;
;      D:\Data\FNNR_DHP\1\A
;      D:\Data\FNNR_DHP\1\B
;      D:\Data\FNNR_DHP\1\C
;      D:\Data\FNNR_DHP\1\D
;      D:\Data\FNNR_DHP\1\E
;
;    There are several variables than can be set to control the ISODATA
;    clustering, and the reclassification. See the code below for more details
;    on these variables.
;
; :Author: Alex Zvoleff
;
; :Date: March, 8, 2013
;-
PRO process_plot
  COMMON parameters, mask_path, band_number, iterations, min_classes, num_classes, $
  change_thresh, iso_merge_dist, iso_merge_pairs, iso_min_pixels, $
  iso_split_std, file_prefix, filename_regex, num_top_clusters, $
  default_folder_path, zip_path, output_folder, ignored_exposures
  
  compile_opt idl2, hidden
  
  ; Load the parameters from the setup file.
  setup_parameters
  
  ; Below date code adapted from cgtimestamp.pro from idlcoyote.com, Copyright
  ; (c) 2013, by Fanning Software Consulting, Inc. All rights reserved.
  time = SYSTIME(UTC=KEYWORD_SET(utc))
  day = STRMID(time, 0, 3)
  date = STRING(STRMID(time, 8, 2), Format='(I2.2)')
  month = STRMID(time, 4, 3)
  year = STRMID(time, 20, 4)
  hour = STRMID(time, 11, 2)
  min = STRMID(time, 14, 2)
  sec = STRMID(time, 17, 2)
  months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']
  m = (WHERE(months EQ STRUPCASE(month))) + 1
  timestamp = year + STRING(m, FORMAT='(I2.2)') + date + '-' + hour + min + sec
  
  ; Select the folder where the input data is located. Either use the
  ; code to have a GUI dialog presented, or uncomment the line below the GUI
  ; code and hard hardcode the path to the input data.
  input_path = DIALOG_PICKFILE(/DIRECTORY, $
    TITLE="Choose a folder to process", PATH=default_folder_path)
  ; Path to input data (comment out above two lines if you hardcode the input
  ; data path).
  ;input_path = "M:\Data\China\FNNR\2012_DHP_Survey\TIFFs\1"
  
  TIC
  
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
    
    clock = TIC('Plot ' + full_point_ID) 
    
    ; If an output folder was specified, check that it exists. If it doesn't,
    ; raise an error. If none was specified, output to the input folder.
    IF output_folder EQ !NULL THEN output_folder = point_folder 
    IF NOT FILE_TEST(point_folder, /DIRECTORY, /READ) THEN $
      MESSAGE, "Error: cannot read from " + point_folder
    
    ; Setup filenames for input/output files
    output_file_prefix = file_prefix + full_point_ID + "_Band_" + $
      STRTRIM(band_number, 2)
    layer_stack_file = output_folder + PATH_SEP() + output_file_prefix + $
      "_Stack_" + timestamp + ".tif"
    isodata_file = output_folder + PATH_SEP() + output_file_prefix + $
      "_Stack_ISODATA_" + timestamp + ".dat"
    reclass_file = output_folder + PATH_SEP() + output_file_prefix + $
      "_Stack_ISODATA_reclass_" + timestamp + ".dat"
    reclass_cie_file = output_folder + PATH_SEP() + output_file_prefix + $
      "_Stack_ISODATA_reclass_" + timestamp + ".cie"
    reclass_cie_zipfile = output_folder + PATH_SEP() + "CIE_" + $
      output_file_prefix + "_Stack_ISODATA_reclass_" + timestamp + ".zip"
    parameter_file = output_folder + PATH_SEP() + output_file_prefix + $
      "_Processing_Parameters_" + timestamp + ".sav"
      
    ; Save the processing parameters so they can be recovered later
    SAVE, FILENAME=parameter_file, layer_stack_file, isodata_file, reclass_file, $
      reclass_cie_file, reclass_cie_zipfile, iterations, change_thresh, $
      iso_merge_dist, iso_merge_pairs, iso_min_pixels, iso_split_std, $
      min_classes, num_classes, mask_path, input_path, point_folder, $
      band_number, file_prefix, filename_regex, plot_ID, point_ID, $
      full_point_ID, ignored_exposures
      
    PRINT, "************************************************************"
    PRINT, "Processing " + point_folder
    PRINT, "************************************************************"
    make_red_layer_stack, point_folder, band_number, layer_stack_file, $
      filename_regex, mask_path, ignored_exposures
    run_isodata, layer_stack_file, isodata_file, iterations, $
      change_thresh, iso_merge_dist, iso_merge_pairs, iso_min_pixels, $
      iso_split_std, min_classes, num_classes
    reclass_isodata_results, isodata_file, layer_stack_file, reclass_file, $
      num_top_clusters
    
    ; Now save the reclass file as an 8 bit binary format file with a cie
    ; extension, then compress it into a zipfile for CAN-EYE.
    PRINT, "Compressing CIE file for CAN-EYE..."
    FILE_COPY, reclass_file, reclass_cie_file
    SPAWN, zip_path + " -m -j " + reclass_cie_zipfile + " " + reclass_cie_file, results
    PRINT, results
    TOC, clock
  ENDFOR
    
  ENVI_BATCH_EXIT
  PRINT, "************************************************************"
  PRINT, "             Completed CAN-EYE pre-processing."
  PRINT, "************************************************************"
  TOC
END
