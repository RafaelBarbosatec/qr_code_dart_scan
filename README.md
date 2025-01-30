[![pub package](https://img.shields.io/pub/v/qr_code_dart_scan.svg)](https://pub.dev/packages/qr_code_dart_scan)

# QRCodeDartScan

A QR code scanner that works on both iOS and Android using [dart decoder](https://github.com/shirne/zxing-dart).

Scanning normal Qr code             |  Scanning invert Qr code 
:-------------------------:|:-------------------------:
![](https://raw.githubusercontent.com/RafaelBarbosatec/qr_code_dart_scan/main/img/normal.jpg)  |  ![](https://raw.githubusercontent.com/RafaelBarbosatec/qr_code_dart_scan/main/img/inverted.jpg)

[APK DEMO](https://github.com/RafaelBarbosatec/qr_code_dart_scan/raw/main/apk/demo.apk)

## Features

- Camera scan preview in a widget
- Scan QRCode
- Scan invert QRCode

## Supported platforms

This package is limited per `camera` pluggin support.

Platform            |  Scan live   | Scan take picture
:-------------------------:|:-------------------------:|:-------------------------:
Android  |  :white_check_mark:  |  :white_check_mark: |
IOS  |  :white_check_mark:  |  :white_check_mark: |
WEB  |    |  :white_check_mark: |
Windows  |    |   |
MacOS  |    | |
Linux |    | |

## Supported Formats

- QR_CODE
- AZTEC
- DATA_MATRIX
- PDF_417
- CODE_39
- CODE_93
- CODE_128
- EAN_8
- EAN_13

## Installation

First, add `qr_code_dart_scan` as a [dependency in your pubspec.yaml file](https://flutter.dev/using-packages/).

### iOS

iOS 10.0 of higher is needed to use the camera plugin. If compiling for any version lower than 10.0 make sure to check the iOS version before using the camera plugin. For example, using the [device_info](https://pub.dev/packages/device_info) plugin.

Add two rows to the `ios/Runner/Info.plist`:

* one with the key `Privacy - Camera Usage Description` and a usage description.
* and one with the key `Privacy - Microphone Usage Description` and a usage description.

Or in text format add the key:

```xml
<key>NSCameraUsageDescription</key>
<string>Can I use the camera please?</string>
<key>NSMicrophoneUsageDescription</key>
<string>Can I use the mic please?</string>
```

### Android

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

```
minSdkVersion 21
```

It's important to note that the `MediaRecorder` class is not working properly on emulators, as stated in the documentation: https://developer.android.com/reference/android/media/MediaRecorder. Specifically, when recording a video with sound enabled and trying to play it back, the duration won't be correct and you will only see the first frame.

```
dependency_overrides:
  camera_android_camerax: 0.6.10+3
```

### Using

```dart

    return Scaffold(
      body: QRCodeDartScanView(
        scanInvertedQRCode: true, // enable scan invert qr code ( default = false)
        onCameraError: (String error) {
          debugPrint('Error: $error');
        },
        // forceReadPortrait: false, // if true will force read portrait image (default = false)
        typeScan: TypeScan.live, // if TypeScan.takePicture will try decode when click to take a picture(default TypeScan.live)
        // intervalScan: const Duration(seconds:1)
        // onResultInterceptor: (old,new){
        //  do any rule to controll onCapture.
        // }
        // takePictureButtonBuilder: (context,controller,isLoading){ // if typeScan == TypeScan.takePicture you can customize the button.
        //    if(loading) return CircularProgressIndicator();
        //    return ElevatedButton(
        //       onPressed:controller.takePictureAndDecode,
        //       child:Text('Take a picture'),
        //    );
        // }
        // resolutionPreset: = QrCodeDartScanResolutionPreset.high,
        // formats: [ // You can restrict specific formats.
        //  BarcodeFormat.qrCode,
        //  BarcodeFormat.aztec,
        //  BarcodeFormat.dataMatrix,
        //  BarcodeFormat.pdf417,
        //  BarcodeFormat.code39,
        //  BarcodeFormat.code93,
        //  BarcodeFormat.code128,
        //  BarcodeFormat.ean8,
        //  BarcodeFormat.ean13,
        // ],
        onCapture: (Result result) {
          // do anything with result
          // result.text
          // result.rawBytes
          // result.resultPoints
          // result.format
          // result.numBits
          // result.resultMetadata
          // result.time
        },
      ),
    );
    
```

### Decoder

You may use only the our decoder if you want:

``` dart

  final decoder = QRCodeDartScanDecoder(
    // formats: [ // You can restrict specific formats.
    //  BarcodeFormat.qrCode,
    //  BarcodeFormat.aztec,
    //  BarcodeFormat.dataMatrix,
    //  BarcodeFormat.pdf417,
    //  BarcodeFormat.code39,
    //  BarcodeFormat.code93,
    //  BarcodeFormat.code128,
    //  BarcodeFormat.ean8,
    //  BarcodeFormat.ean13,
    // ],
  );

  Result? result = await decoder.decodeCameraImage(CameraImage());

  // or

  Result? result = await decoder.decodeFile(XFile());

```
