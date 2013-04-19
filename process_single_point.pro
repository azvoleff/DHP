;+
; :Description:
;    Layer stack a set of canopy photos from a single point, and then run ISODATA
;    on the layer stack to classify 10 different clusters. Finally, reclassify
;    the ISODATA output so that the cluster with the highest brightness is
;    assigned a value of 100 (for sky), while pixels from all other clusters are
;    set to 0 (for canopy). Unknown or masked pixels are set to 255.
;
;    The photos must all be located in the same folder, with a the folder name
;    set to the plot ID. Sets of exposures from the same point must be within
;    subfolders under the plot ID. For example, the photos from points A for
;    plot 1 might be organized as follows:
;
;      D:\Data\FNNR_DHP\1\A
;
;    There are several variables than can be set to control the ISODATA
;    clustering, and the reclassification. See the code below for more details
;    on these variables.
;
; :Author: Alex Zvoleff
;
; :Date: April, 18, 2013
;-
PRO process_single_point, point_folder
  COMMON parameters, mask_path, band_number, iterations, min_classes, num_classes, $
    change_thresh, iso_merge_dist, iso_merge_pairs, iso_min_pixels, $
    iso_split_std, file_prefix, filename_regex, num_top_clusters, $
    default_folder_path, zip_path, output_folder, ignored_exposures
    
  COMPILE_OPT idl2, hidden
  
  point_time = SYSTIME(1)
  
  e = ENVI(/HEADLESS)
  ENVI_BATCH_STATUS_WINDOW, /ON
  
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
  ; code to have a GUI dialog presented, or use the value of the point folder
  ; input parameter.
  IF point_folder EQ !NULL THEN BEGIN
    point_folder = DIALOG_PICKFILE(/DIRECTORY, $
      TITLE="Choose a folder to process", PATH=default_folder_path)
  END
  
  pos = STREGEX(point_folder, '[0-9]{1,2}[\\]{1,2}[a-iA-I1-9]$', length=len)
    split_point_folder = strsplit(point_folder, "\/", /EXTRACT, count=num_strs)
  plot_ID = split_point_folder[num_strs-2]
  point_ID = split_point_folder[num_strs-1]
  full_point_ID = plot_ID + '-' + point_ID
  
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
    
  PRINT, "************************************************************"
  PRINT, "Processing " + point_folder
  
  ; First save the processing parameters so they can be recovered later
  SAVE, FILENAME=parameter_file, layer_stack_file, isodata_file, reclass_file, $
    reclass_cie_file, reclass_cie_zipfile, iterations, change_thresh, $
    iso_merge_dist, iso_merge_pairs, iso_min_pixels, iso_split_std, $
    min_classes, num_classes, mask_path, point_folder, band_number, $
    file_prefix, filename_regex, ignored_exposures
    
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
  
  PRINT, "Finished processing " + point_folder
  PRINT, "Point processing time: ", STRTRIM((ROUND(SYSTIME(1) - point_time)/60.), 2), $
    " minutes"
  PRINT, "************************************************************"
END