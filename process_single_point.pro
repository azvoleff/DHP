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
  COMMON mask_path, band_number, iterations, min_classes, num_classes, $
  change_thresh, iso_merge_dist, iso_merge_pairs, iso_min_pixels, $
  iso_split_std, file_prefix, filename_regex, num_top_clusters, $
  default_folder_path
  
  ; Load the parameters from the setup file.
  setup_parameters
  
  ; Select the folder where the input data is located. Either use the
  ; code to have a GUI dialog presented, or uncomment the line below the GUI
  ; code and hard hardcode the path to the input data.
  point_folder = DIALOG_PICKFILE(/DIRECTORY, $
    TITLE="Choose a folder to process")
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
  
  ; Setup filenames for input/output files
  output_file_prefix = file_prefix + full_point_ID + "_Band_" + $
    STRTRIM(band_number, 2)
  layer_stack_file = point_folder + PATH_SEP() + output_file_prefix + $
    "_Stack.tif"
  isodata_file = point_folder + PATH_SEP() + output_file_prefix + $
    "_Stack_ISODATA.dat"
  reclass_file = point_folder + PATH_SEP() + output_file_prefix + $
    "_Stack_ISODATA_reclass.dat"
  reclass_cie_file = point_folder + PATH_SEP() + output_file_prefix + $
    "_Stack_ISODATA_reclass.cie"
  reclass_cie_zipfile = point_folder + PATH_SEP() + "..\"+ "CIE_" + $
    output_file_prefix + "_Stack_ISODATA_reclass.zip"
  parameter_file = point_folder + PATH_SEP() + output_file_prefix + $
    "_Processing_Parameters.sav"
    
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
  SPAWN, "zip -m -j " + reclass_cie_zipfile + " " + reclass_cie_file, results
  PRINT, results
  
  ENVI_BATCH_EXIT
  PRINT, "************************************************************"
  PRINT, "             Completed CAN-EYE pre-processing."
  PRINT, "************************************************************"
END
