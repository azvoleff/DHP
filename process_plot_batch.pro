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
; :Date: April, 18, 2013
;-
PRO process_plot_batch
  COMMON parameters, mask_path, band_number, iterations, min_classes, num_classes, $
    change_thresh, iso_merge_dist, iso_merge_pairs, iso_min_pixels, $
    iso_split_std, file_prefix, filename_regex, num_top_clusters, $
    default_folder_path, zip_path, output_folder, ignored_exposures
    
  COMPILE_OPT idl2, hidden
    
  plot_time = SYSTIME(1)
  
  e = ENVI(/HEADLESS)
  ENVI_BATCH_STATUS_WINDOW, /ON
  
  ; Load the parameters from the setup file.
  setup_parameters
  
  ; Select the folder where the input data is located. Either use the
  ; code to have a GUI dialog presented, or uncomment the line below the GUI
  ; code and hard hardcode the path to the input data.
  input_folder = DIALOG_PICKFILE(/DIRECTORY, $
    TITLE="Choose a folder of plot folders to process", PATH=default_folder_path)
    
  PRINT, "************************************************************"
  PRINT, "Processing " + input_folder
  
  ; Below regex will work find plot folders numbered 000-999. Change as
  ; necessary.
  plot_folder_list = FILE_SEARCH(input_folder + PATH_SEP() + "*", count=count, /TEST_DIRECTORY)
  IF count EQ 0 THEN BEGIN
    MESSAGE, 'No plot folders found in ' + input_folder
  END
  
  PRINT, "Found " + STRTRIM(count, 2) + " plot folders"
  
  FOR i=0, count-1 DO BEGIN
    plot_folder = plot_folder_list[i]
    
    IF NOT FILE_TEST(plot_folder, /DIRECTORY, /READ) THEN $
      MESSAGE, "Error: cannot read from " + plot_folder
      
    process_plot, plot_folder
    
  ENDFOR
    
  PRINT, "Finished processing " + input_folder
  PRINT, "Folder processing time: ", STRTRIM(ROUND((SYSTIME(1) - plot_time)/60.) ,2), $
    " minutes"
  PRINT, "************************************************************"
END