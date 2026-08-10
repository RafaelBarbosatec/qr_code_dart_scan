## 0.14.0

### Breaking: the models moved to `qr_code_dart_decoder`

`ScanResult` and `BarcodeFormat` are now owned by `qr_code_dart_decoder` (0.3.0) and re-exported here, so both packages speak the same types and `zxing_lib` is gone from this package's dependencies. Importing from `package:qr_code_dart_scan/qr_code_dart_scan.dart` keeps working unchanged.

- **`ScanResult.corners` is now `List<Point<double>>`** (`dart:math`) instead of `List<Offset>`. The decoder is a pure Dart package and cannot depend on `dart:ui`. New `toOffset`/`toOffsets` extensions bridge them:

  ```dart
  // before
  CustomPaint(painter: MyPainter(result.corners));            // List<Offset>

  // now
  CustomPaint(painter: MyPainter(result.corners.toOffsets));  // List<Offset>
  ```

- **`QRCodeDartScanDecoder` no longer speaks `zxing_lib`.** `decodeCameraImage` and `decodeFile` return `ScanResult?` instead of `Result?`, completing the migration started in 0.13.0.

### Bug fix (from `qr_code_dart_decoder` 0.3.0)

- Camera decoding now honours the `formats` you pass to `QRCodeDartScanView`/`QRCodeDartScanDecoder`. The format list was accepted but never reached the reader, so live scanning could return a barcode in a format you had not asked for. If you were relying on that leak, widen `formats` explicitly.

## 0.13.0

### Breaking: `zxing_lib` no longer leaks into the scanner API

`onCapture`, `onResultInterceptor` and `formats` now use the package's own types, so apps do not need a `zxing_lib` dependency to consume them.

| before (`zxing_lib`) | now |
| --- | --- |
| `Result` | `ScanResult` |
| `BarcodeFormat` | `BarcodeFormat` (own enum, only the 10 supported formats) |
| `result.barcodeFormat` | `result.format` |
| `result.resultPoints` (`List<ResultPoint?>?`) | `result.corners` (`List<Offset>`, never null) |
| `result.timestamp` (`int` millis) | `result.timestamp` (`DateTime`) |
| `result.rawBytes` (`List<int>?`) | `result.rawBytes` (`Uint8List?`) |

- `result.numBits` and `result.resultMetadata` were dropped; nothing in the package used them.
- Passing an unsupported format is now a compile error instead of a runtime `Exception`.
- `ScanResult` keeps identity equality on purpose, so scanning the same code twice still notifies.
- The low-level `QRCodeDartScanDecoder` still speaks `zxing_lib` types; only the scanner layer was migrated.

## 0.12.2
- **Lifecycle race fix**: Fixed `CameraException(Disposed CameraController, startImageStream() was called on a disposed CameraController.)` raised when the app was paused/resumed (or the scanner was popped) while the camera initialization was still in flight.
  - Camera setup/teardown is now serialized and guarded by a generation token: an initialization that gets invalidated aborts at its next `await` and disposes the camera it created, instead of continuing against a dead controller.
  - `CameraController.value.isInitialized` stays `true` after `dispose()`, so the package now tracks the disposed state itself rather than relying on that flag.
- **Camera leak fix**: An aborted or replaced initialization no longer leaves a native camera session open (also fixes leaks on `changeCamera`).
- **Paused scan is preserved across the app lifecycle**: if `stopScan()` was called and the user minimizes and reopens the app, the camera preview is restored but the image stream is *not* restarted. Use `startScan()` (or `changeTypeScan(TypeScan.live)`) to resume, and the new `isScanPaused` getter to query it. Mounting the view again resets it, so a reused controller never comes back mute; `config()` takes a new `keepScanPaused` flag for the lifecycle case.
- `QRCodeDartScanController.cameraController` now returns `null` instead of a disposed instance, and a new `isInitialized` getter was added.
- The controller can be safely reused after `dispose()`: calling `config()` again re-arms it.
- The view now registers its state listener only once instead of on every resume, and no longer calls `setState` after being unmounted.
- Fixed `changeTypeScan(TypeScan.live)` never restarting the image stream.
- Errors from `availableCameras()`, `takePicture()` and `setFocusPoint()` are now caught and reported through `onCameraError` instead of escaping to the zone. `startImageStream()` failures are the deliberate exception: they are reported through `onCameraError` **and** re-surfaced to the zone, so they keep reaching crash reporting.

## 0.12.1
- **Result points accuracy**: Fixed `resultPoints` coordinates to accurately match the QR code position in the camera preview.
- **Dynamic rotation handling**: Automatically detects camera orientation (landscape/portrait) and applies the correct transformation.
- **Bounding box generation**: Result points now always form a perfect quadrilateral (4 corners) regardless of the number of points detected.
- **Example enhancement**: Added visual overlay in the example app to display detected QR code boundaries with lines and points.

## 0.12.0
- **Performance improvements**: Reduced scan interval default from 1s to 200ms (5x faster detection).
- **Memory optimization**: Update `qr_code_dart_decoder` to `0.2.0` with major performance improvements:
  - Zero-copy data transfer between isolates (~4MB saved per frame)
  - Y plane only processing (~1.5MB saved per frame)
  - Memory leak fix in results list
  - Block-wise image rotation (30-40% faster)
  - Blur detection to skip unprocessable frames (20-30% CPU savings)
- **Detection speed**: Average detection time reduced from 2-3s to ~0.4-0.6s (5-7x faster).
- **Decode optimization**: Changed to `tryHarder: true` on first attempt for better success rate.

## 0.11.5
- Add image stream watchdog to detect and handle native camera errors when stream stops responding.
- Add `imageStreamTimeout` parameter to configure watchdog timeout (default 2 seconds).

## 0.11.4
- Fix issue `CameraException(Disposed CameraController, buildPreview() was called on a disposed CameraController.)`

## 0.11.3
- Adds `focusPoint` in `QRCodeDartScanView` to set the focus point for the camera preview.

## 0.11.2
- Performance improvements.

## 0.11.1
- Update `qr_code_dart_decoder` to `0.1.2`.

## 0.11.0
- Adds `croppingStrategy` in `QRCodeDartScanView` to crop the image before decode.
- Update `qr_code_dart_decoder` to `0.1.1`.
- remove `scanInvertedQRCode` in `QRCodeDartScanView`. Now it is always true.

## 0.10.1
- Little improvements in `QRCodeDartScanView`.
- Increment some dependencies

## 0.10.0
- Adds `lockCaptureOrientation` default to `DeviceOrientation.portraitUp` in `QRCodeDartScanView`.
- Decode improvements. Now it use package `qr_code_dart_decoder`.
- Adds `cropRect` in `QRCodeDartScanView` to crop the image before decode.

## 0.9.11
- Fix exception: CameraException(Uninitialized CameraController, startImageStream() was called on an uninitialized CameraController.);

## 0.9.10
- Adds `videoBitrate` and `fps` in `QRCodeDartScanView`.

## 0.9.9+1
- update README.md

## 0.9.9
- Adds `imageDecodeOrientation` in `QRCodeDartScanView` to force read image in landscape or portrait orientation.

## 0.9.8
- Rename param `forceReadPortrait` to `forceReadLandscape`. Read image portrait by default. If `forceReadLandscape` is true, the image will be read in landscape mode, helpful to read itf code.
- Fix IOS camera orientation.

## 0.9.7
- Adds `onCameraError` in `QRCodeDartScanView`.

## 0.9.6
- Update dependencies.

## 0.9.5
- Fix issue [#30](https://github.com/RafaelBarbosatec/qr_code_dart_scan/issues/30). Adds `forceReadPortrait` in `QRCodeDartScanView` to force read portrait image.

## 0.9.4
- adds methods `toggleFlash`,`setFlash`,`setFlashAuto` in QRCodeDartScanController.

## 0.9.3
- Fix `stopImageStream` exception.

## 0.9.2
- Adds method `stopScan` and `startScan` in `QRCodeDartScanController`.
- Adds get `isLiveScan`.
- Fix `changeCamera` exception.

## 0.9.1
- Fix issue [#28](https://github.com/RafaelBarbosatec/qr_code_dart_scan/issues/28)
- Fix issue [#29](https://github.com/RafaelBarbosatec/qr_code_dart_scan/issues/29)

## 0.9.0
- Camera key improvments
- Update camera pluggin to `0.11.0`
- Performance improvements. Now using pool of isolates to process in live.
- Adds support to `itf`.

## 0.8.3
- Fix camera preview scale.

## 0.8.2
- Remove debug prints

## 0.8.1
- fix app life circle issue [26](https://github.com/RafaelBarbosatec/qr_code_dart_scan/pull/26). Thanks [Ömral Cörüt](https://github.com/omralcrt) !

## 0.8.0
- `QRCodeDartScanController` Improvements
- Adds `Future<void> changeCamera(TypeCamera typeCamera)` method in `QRCodeDartScanController`.
- Adds `intervalScan` param in `QRCodeDartScanView`.
- Adds `onResultInterceptor` param in `QRCodeDartScanView`.

## 0.7.7
- Fix issue [#18](https://github.com/RafaelBarbosatec/qr_code_dart_scan/issues/18). Thanks [MateusLucasDaSilva](https://github.com/MateusLucasDaSilva)!

## 0.7.6
- Handle with `didChangeAppLifecycleState`.
- Fix issue [#15](https://github.com/RafaelBarbosatec/qr_code_dart_scan/issues/15). Thanks [thierrylee](https://github.com/thierrylee)!

## 0.7.5
- Update dependencies.
- Adds the method `dispose` in `QRCodeDartScanController`

## 0.7.4
- Fix issue [#11](https://github.com/RafaelBarbosatec/qr_code_dart_scan/issues/11)
- Fix AspectRatio
- Update dependencies.

## 0.7.3
- Fix issue [#9](https://github.com/RafaelBarbosatec/qr_code_dart_scan/issues/9)

## 0.7.2
- Fix issue [#7](https://github.com/RafaelBarbosatec/qr_code_dart_scan/issues/7). Thanks so much [philseeley](https://github.com/philseeley)!

## 0.7.1
- return `resolutionPreset` default to `QRCodeDartScanResolutionPreset.medium`
- removre debug prints.

## 0.7.0
- Update dependencies.

## 0.6.0
- Adds scan by picture
- Export decoder
- Improvements in `QRCodeDartScanController`
- Improvements in project structure

## 0.5.1
- fix problem camera dispose.

## 0.5.0
- update `camera`.
- update `zxing_lib`.
- update `image`.

## 0.4.1
- update `camera`
- Adds param `resolutionPreset` and `child` in `QRCodeDartScanView`.

## 0.4.0
- update `camera`, `zxing_lib` and `image`

## 0.3.0
- update `camera` to 0.9.4+5

## 0.2.1

- downgrade `camera`. Awaiting fix issue [#90070](https://github.com/flutter/flutter/issues/90070).

## 0.2.0

- update `camera`
- update `image`.

## 0.1.1

- rename `scanQRCodeInverted` to `scanInvertedQRCode`
- improvements aspectRatio.

## 0.1.0

* add `setScanEnabled` in controller.
* add other formats: `QR_CODE`,`AZTEC`,`DATA_MATRIX`,`PDF_417`,`CODE_39`,`CODE_93`,`CODE_128`,`EAN_8`,`EAN_13`.

## 0.0.2

* Improvements performance

## 0.0.1+1

* Update README

## 0.0.1

* First version
