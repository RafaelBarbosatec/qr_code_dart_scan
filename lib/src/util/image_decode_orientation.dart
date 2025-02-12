enum ImageDecodeOrientation {
  /// Force image to be read in landscape orientation
  landscape,

  /// Force image to be read in portrait orientation
  portrait,

  /// The original orientation of the image provided by the camera
  /// Some devices provide images in landscape orientation like Android, and IOS sometimes provide images in portrait orientation sometimes in landscape orientation
  original,
}
