import 'package:flutter/foundation.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/decoder/decode_event.dart';
import 'package:qr_code_dart_scan/src/decoder/global_functions.dart';
import 'package:qr_code_dart_scan/src/util/isolate_pool.dart';

import 'image_decoder.dart';

class IsolateDecoder {
  final List<BarcodeFormat> formats;
  final int countIsolates;
  IsolatePool? pool;

  IsolateDecoder({
    this.formats = QRCodeDartScanDecoder.acceptedFormats,
    this.countIsolates = 2,
  });

  Future<void> start() {
    pool = IsolatePool(countIsolates);
    return pool!.start();
  }

  void dispose() {
    pool?.dispose();
  }

  Future<Result?> decodeFileImage(XFile file, {bool isInverted = false}) async {
    final bytes = await file.readAsBytes();

    final image = await myDecodeImageFromList(bytes);

    final event = DecodeImageEvent(
      image: (await image.toByteData())!.buffer.asUint8List(),
      width: image.width,
      height: image.height,
      formats: formats,
      invert: isInverted,
    );

    var map = event.toMap();

    if (pool != null) {
      map['type'] = IsolateTaskType.image;
      final result = await pool!.runTask(map);
      return result;
    }

    return compute(ImageDecoder.decodeImage, map);
  }

  Future<Result?> decodeCameraImage(
    CameraImage image, {
    bool isInverted = false,
    ImageDecodeOrientation imageDecodeOrientation = ImageDecodeOrientation.original,
  }) async {
    final isPortrait = image.height > image.width;
    final isLandscape = image.height < image.width;
    bool rotate = false;
    switch (imageDecodeOrientation) {
      case ImageDecodeOrientation.landscape:
        rotate = isPortrait;
        break;
      case ImageDecodeOrientation.portrait:
        rotate = isLandscape;
        break;
      case ImageDecodeOrientation.original:
        break;
    }

    final event = DecodeCameraImageEvent(
      cameraImage: image,
      formats: formats,
      invert: isInverted,
      rotate: rotate,
    );

    var map = event.toMap();

    if (pool != null) {
      map['type'] = IsolateTaskType.planes;
      final result = await pool!.runTask(map);
      return result;
    }

    return compute(ImageDecoder.decodePlanes, map);
  }
}
