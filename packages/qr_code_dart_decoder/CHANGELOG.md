## 0.3.0

### Breaking Changes

* `zxing_lib` is no longer part of the public API. The package now owns its models, so consuming apps never need a `zxing_lib` dependency:
  * `decodeFile` and `decodeCameraImage` return `ScanResult?` instead of `zxing_lib`'s `Result?`.
  * `BarcodeFormat` is now this package's own enum, exposing only the formats that are actually supported (`aztec`, `code39`, `code93`, `code128`, `dataMatrix`, `ean8`, `ean13`, `itf`, `pdf417`, `qrCode`). Unsupported formats are a compile error instead of a runtime exception.
  * `export 'package:zxing_lib/zxing.dart' show BarcodeFormat, Result` was removed from the barrel.
* `FileDecode.decode`, `CameraDecode.decode` and `IsolateCameraDecode.setYuv420Planess` return `ScanResult?`; `FileDecodeEvent.formats` and `IsolateCameraDecode.currentResults` use the new types as well.

### Features

* Added `ScanResult` with `text`, `format`, `timestamp`, `rawBytes` and `corners`.
  * `corners` is a `List<Point<double>>` (`dart:math`), keeping the package pure Dart. Flutter apps can bridge it to `Offset` with `toOffset`/`toOffsets` from `package:qr_code_dart_scan`.
  * `ScanResult` keeps identity equality on purpose, so repeated scans of the same barcode still notify.

### Bug Fixes

* `CameraDecode.decode` now honours the `formats` it is given. It accepted the argument but never forwarded it to the reader, so camera decoding was unrestricted and could return a barcode in a format the caller had not asked for.

### Migration

```dart
// Before
final Result? result = await decoder.decodeFile(bytes);
result?.barcodeFormat; // zxing_lib BarcodeFormat
result?.resultPoints;  // List<ResultPoint?>?

// After
final ScanResult? result = await decoder.decodeFile(bytes);
result?.format;  // qr_code_dart_decoder BarcodeFormat
result?.corners; // List<Point<double>>, never null
```

## 0.2.0

### Performance Improvements

* **Memory optimization**: Implemented TransferableTypedData for zero-copy data transfer between isolates (~4MB saved per frame).
* **YUV processing optimization**: Use only Y plane for luminance extraction, eliminating unnecessary U/V plane allocation (~1.5MB saved per frame).
* **Memory leak fix**: Added bounded buffer (limit of 10) to results list to prevent unbounded growth.
* **Rotation optimization**: Implemented block-wise image rotation (32x32 blocks) for better cache locality (30-40% faster).
* **Blur detection**: Added motion and out-of-focus frame detection to skip unprocessable frames (20-30% CPU savings).
* **Decode optimization**: Changed default to `tryHarder: true` on first attempt for better success rate.
* **Crop background disabled**: Disabled expensive crop background fallback by default for better performance.

### Features

* Added `BlurDetector` class with `isSharp()` and `isSharpFast()` methods for blur detection.
* Added `TransferableYuv420Planes` class for efficient isolate communication.
* Added `CameraDecode.enableBlurDetection` flag to toggle blur detection (default: false).

### Breaking Changes

* Crop background processing is now disabled by default in `CameraDecode` (can be re-enabled by uncommenting).

## 0.1.2

* Move crop background to FileDecode.
* Move crop background to CameraDecode.

## 0.1.1

* Adds rotation to decode event.
* Remove invert from decode event.
* Adds CroppingStrategy to decode event.
* Adds CropBackgroundYuvProcessor.

## 0.0.5

* Adds cropRect.

## 0.0.4

* Adds tryHarder=true in decode.
* FileDecode improvements


## 0.0.3

* Adds rotate

## 0.0.2

* Update MultiFormatReader.

## 0.0.1

* Initial version
