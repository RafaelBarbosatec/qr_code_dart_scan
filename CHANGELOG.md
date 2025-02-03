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
