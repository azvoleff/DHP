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
; :Date: March, 8, 2013
;-
PRO process_single_point
  COMMON parameters, mask_path, band_number, iterations, min_classes, num_classes, $
  change_thresh, iso_merge_dist, iso_merge_pairs, iso_min_pixels, $
  iso_split_std, file_prefix, filename_regex, num_top_clusters, $
  default_folder_path, zip_path, output_folder
  
  compile_opt idl2, hidden
  
  ; Load the parameters from the setup file.
  setup_parameters
  
  ; Below date code adapted from cgtimestamp.pro from idlcoyote.com, Copyright
  ; (c) 2013, by Fanning Software Consulting, Inc. All rights reserved.     
  time = Systime(UTC=Keyword_Set(utc))
  day = Strmid(time, 0, 3)
  date = String(StrMid(time, 8, 2), Format='(I2.2)')
  month = Strmid(time, 4, 3)
  year = Strmid(time, 20, 4)
  hour = Strmid(time, 11, 2)
  min = Strmid(time, 14, 2)
  sec = Strmid(time, 17, 2)
  months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']
  m = (Where(months EQ StrUpCase(month))) + 1
  timestamp = year + String(m, FORMAT='(I2.2)') + date + '-' + hour + min + sec
  
  ; Select the folder where the input data is located. Either use the
  ; code to have a GUI dialog presented, or uncomment the line below the GUI
  ; code and hard hardcode the path to the input data.
  point_folder = DIALOG_PICKFILE(/DIRECTORY, $
    TITLE="Choose a folder to process", PATH=default_folder_path)
  ; Path to input data (comment out above two lines if you hardcode the input
  ; data path).
  ;point_folder = "M:\Data\China\FNNR\2012_DHP_Survey\TIFFs\1\A"
  
  ENVI, /restore_base_save_files
  ENVI_BATCH_INIT, log_file='batch.txt'
  
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
  PRINT, "************************************************************"
  ; First save the processing parameters so they can be recovered later
  SAVE, FILENAME=parameter_file, layer_stack_file, isodata_file, reclass_file, $
    reclass_cie_file, reclass_cie_zipfile, iterations, change_thresh, $
    iso_merge_dist, iso_merge_pairs, iso_min_pixels, iso_split_std, $
    min_classes, num_classes, mask_path, point_folder, band_number, $
    file_prefix, filename_regex
  
  make_red_layer_stack, point_folder, band_number, layer_stack_file, $
    filename_regex, mask_path
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
  
  ENVI_BATCH_EXIT
  PRINT, "************************************************************"
  PRINT, "             Completed CAN-EYE pre-processing."
  PRINT, "************************************************************"
END
