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
  ; The below variable must be set to location on your system of the mask
  ; image (D7000_Sigma4.5_Mask.dat). The mask image will be used to mask areas
  ; of the photo that are outside the field of view of the 4.5mm Sigma
  ; fisheye lens. The full path to the mask image must be specified.
  mask_path = "C:\Users\azvoleff\Code\IDL\DHP\D7000_Sigma4.5_Mask.dat"
  mask_path = !NULL
  
  ; First select the folder where the input data is located. Either use the
  ; code to have a GUI dialog presented, or uncomment the line below the GUI
  ; code and hard hardcode the path to the input data.
  ;point_folder = DIALOG_PICKFILE(/DIRECTORY, $
  ;    TITLE="Choose a folder to process")
  ; Path to input data (comment out above two lines if you hardcode the input
  ; data path).
  point_folder = "M:\Data\China\FNNR\2012_DHP_Survey\TIFFs\1\A"
  ;point_folder = "M:\Data\China\FNNR\2012_DHP_Survey\TIFFs\99\A"
  
  ; Choose the band number to use for the ISODATA layer stack. Set to 1 for
  ; red band, 2 for blue band, and 3 for green band.
  band_number = 1
  
  ; Below are the parameters for the ISODATA clustering
  iterations = 15 ; Default to 15 - most images take only 3-4 iterations
  ; min_classes specifies the minimum number of output classes
  min_classes = 8 ; Default to 10
  ; num_classes specifies the maximum number of output classes
  num_classes = 12 ; Default to 20
  ; change_thresh is used to end the iterative process when the number of
  ; pixels in each class changes by less than the threshold
  ; (which is specified as a percentage).
  change_thresh = .05 ; Default to 0-1.0
  ; iso_merge_dist sets the minimum distance between class means. If the
  ; distance between class means is less than the minimum value entered, then
  ; the classes will be merged.
  iso_merge_dist = 2000 ; Default to 2000
  ; iso_merge_pairs sets the maximum number of class pairs to merge in a
  ; single iteration
  iso_merge_pairs = 4 ; Default to 4
  ; iso_min_pixels sets the minimum number of pixels in a class. If there are
  ; fewer than this number of pixels in a class, the class will be deleted and
  ; the pixels placed in the classes nearest to them threshold then the class
  ; is split into two classes.
  iso_min_pixels = 1000 ; Default to 1000
  ; iso_split_std sets the maximum standard deviation of a class. If a class
  ; has a standard deviation  is larger than this threshold then the class is
  ; split into two classes. If set to zero this type of split is disabled.
  iso_split_std = 0 ; Default to 0
  
  ; The file_prefix is the prefix in front of each DHP tif file, including
  ; all text up until the plot and point ID number. For FNNR, set the
  ; file_prefix to "FNNR_DHP_Fall2012_". For Wolong, set it to
  ; "Wolong_DHP_Spring2012_".
  file_prefix = "FNNR_DHP_Fall2012_"
  filename_regex = file_prefix + '[1-9]?[0-9]*-[1-6a-iA-I]_[0-9]*_[0-9]*(-[0-9])?.(TIF|tif)'
  
  ; *************************************************************************
  ; Do not modify code below this line.
  ; *************************************************************************
  
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
  reclass_cie_zipfile = point_folder + PATH_SEP() + "CIE_" + $
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
  reclass_isodata_results, isodata_file, layer_stack_file, reclass_file
  
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
