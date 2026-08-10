/// Barcode formats that this package is able to decode.
///
/// This mirrors only the formats that are actually supported, so an
/// unsupported format is a compile error instead of a runtime exception.
enum BarcodeFormat {
  /// Aztec 2D barcode format.
  aztec,

  /// Code 39 1D format.
  code39,

  /// Code 93 1D format.
  code93,

  /// Code 128 1D format.
  code128,

  /// Data Matrix 2D barcode format.
  dataMatrix,

  /// EAN-8 1D format.
  ean8,

  /// EAN-13 1D format.
  ean13,

  /// ITF (Interleaved Two of Five) 1D format.
  itf,

  /// PDF417 format.
  pdf417,

  /// QR Code 2D barcode format.
  qrCode,
}
