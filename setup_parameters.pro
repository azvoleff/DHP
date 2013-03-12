;+
; :Description:
;    Setup the parameters for pre-processing canopy photos for use in CAN-EYE.
;
; :Author: Alex Zvoleff
;
; :Date: March, 8, 2013
;-
PRO setup_parameters
  COMMON parameters, mask_path, band_number, iterations, min_classes, num_classes, $
    change_thresh, iso_merge_dist, iso_merge_pairs, iso_min_pixels, $
    iso_split_std, file_prefix, filename_regex, num_top_clusters, $
    default_folder_path, zip_path, output_folder, ignored_exposures
  
  compile_opt idl2, hidden
  
  ; Specifying a default output folder is optional. To disable output folder 
  ; and output files in input folder, uncomment the "output_folder = !NULL"
  ; line.
  ;output_folder = "C:\Users\azvoleff\Desktop\FNNR_Output"
  output_folder = "C:\Users\winroot\Desktop\FNNR_Output"
  ;output_folder = !NULL
  
  ; The below variable must be set to location on your system of the mask
  ; image (D7000_Sigma4.5_Mask.dat). The mask image will be used to mask areas
  ; of the photo that are outside the field of view of the 4.5mm Sigma
  ; fisheye lens. The full path to the mask image must be specified. To
  ; disable masking, uncomment the "mask_path = !NULL" line.
  ;mask_path = "C:\Users\azvoleff\Code\IDL\DHP\D7000_Sigma4.5_Mask.dat"
  mask_path = "C:\Users\winroot\Desktop\IDL_Processing_Code\D7000_Sigma4.5_Mask.dat"
  ;mask_path = !NULL

  ; Path to Info-Zip executable
  ;zip_path = "C:\Users\azvoleff\Code\IDL\DHP\zip300xn\zip.exe"
  zip_path = "C:\Users\winroot\Desktop\IDL_Processing_Code\zip.exe"

  ; default_folder_path specifies the default path to show in the file
  ; picker dialog. If an invalid path is specified, it will be ignored.
  ;default_folder_path = "M:\Data\China\FNNR\2012_DHP_Survey\TIFFs"
  default_folder_path = "\\vortex\an_research\Data_Store\DHP\FNNR\DHPphotos_FNNR\TIFFs"
  
  ; Exclude certain exposures from the layer stack. Specify as an array of band 
  ; numbers. The exposures, in order, are (relative to the metered exposure):
  ;   -4, -3, -2, -1, 0, +1
  ; So, for example, to ignore the 5th and 6th exposures you could specify:
  ;   ignored_exposures = [5, 6]
  ; and that would exclude the 0 and +1 exposures from the layer stack.
  ignored_exposures = [6]

  ; Choose the band number to use for the ISODATA layer stack. Set to 1 for
  ; red band, 2 for blue band, and 3 for green band.
  band_number = 1
  
  ; Below are the parameters for the ISODATA clustering
  iterations = 15 ; Default to 15 - most images take only 3-4 iterations
  ; min_classes specifies the minimum number of output classes
  min_classes = 10 ; Default to 10
  ; num_classes specifies the maximum number of output classes
  num_classes = 15 ; Default to 12
  ; change_thresh is used to end the iterative process when the number of
  ; pixels in each class changes by less than the threshold
  ; (which is specified as a percentage).
  change_thresh = .05 ; Default to 0-1.0
  ; iso_merge_dist sets the minimum distance between class means. If the
  ; distance between class means is less than the minimum value entered, then
  ; the classes will be merged.
  iso_merge_dist = 1000 ; Default to 2000
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
  iso_split_std = 5000 ; Default to 0
  
  ; num_top_clusters specifies how many of the brightest clusters should be
  ; combined and recoded as sky (default only 1, the brightest).
  num_top_clusters = 1
  
  ; The file_prefix is the prefix in front of each DHP tif file, including
  ; all text up until the plot and point ID number. For FNNR, set the
  ; file_prefix to "FNNR_DHP_Fall2012_". For Wolong, set it to
  ; "Wolong_DHP_Spring2012_".
  ;file_prefix = "Wolong_DHP_Spring2012_"
  file_prefix = "FNNR_DHP_Fall2012_"
  filename_regex = file_prefix + '[1-9]?[0-9]*-[1-9a-iA-I]_[0-9]*_[0-9]*(-[0-9])?.(TIF|tif)'

  ; Check that the specified paths are valid
  IF output_folder NE !NULL THEN $
    IF NOT FILE_TEST(output_folder, /DIRECTORY, /WRITE) THEN $
    MESSAGE, "Error: cannot write to " + output_folder
  IF mask_path NE !NULL THEN $
    IF NOT FILE_TEST(mask_path, /REGULAR, /READ) THEN $
    MESSAGE, "Error: cannot read mask from" + mask_path
  IF NOT FILE_TEST(zip_path, /REGULAR, /EXECUTABLE) THEN $
    MESSAGE, "Error: cannot execute " + zip_path
END
