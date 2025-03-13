# QR Code Dart Decoder

A Flutter/Dart package for decoding QR codes and other barcode formats from images and camera streams. Built on top of the ZXing library, this package provides a simple API for barcode recognition in Dart applications.

## Features

- Decode QR codes and multiple barcode formats from image files
- Process camera streams for real-time barcode detection
- Support for various barcode formats including:
  - QR Code
  - Aztec
  - Data Matrix
  - PDF417
  - Code 39
  - Code 93
  - Code 128
  - EAN-8
  - EAN-13
  - ITF

## Getting started

Add the package to your `pubspec.yaml`:


## Usage

```dart
import 'dart:typed_data';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';

Future<void> decodeQrFromImage(Uint8List imageBytes) async {
  // Create decoder instance
  final decoder = QrCodeDartDecoder(
    formats: [BarcodeFormat.qrCode],
  );
  
  // Decode the image
  final result = await decoder.decodeFile(imageBytes);
  if (result != null) {
    print('Decoded text: ${result.text}');
  } else {
    print('No QR code found');
  }
}

Future<void> decodeQrFromCamera(CamperaImage image) async {
  // Create decoder instance
  final decoder = QrCodeDartDecoder(
    formats: [BarcodeFormat.qrCode],
  );

  List<Yuv420Planes> yuv420Planes = image.planes
        .map((e) => Yuv420Planes(
              bytes: e.bytes,
              bytesPerRow: e.bytesPerRow,
              bytesPerPixel: e.bytesPerPixel,
              width: e.width,
              height: e.height,
            ))
        .toList();
  
  // Decode the image
  final result = await decoder.decodeCameraImage(yuv420Planes);
  if (result != null) {
    print('Decoded text: ${result.text}');
  } else {
    print('No QR code found');
  }
}
```

## Camera Stream Processing

For real-time barcode detection from camera streams, the package provides:

