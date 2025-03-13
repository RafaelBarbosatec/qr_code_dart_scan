import 'package:flutter/foundation.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/decoder/global_functions.dart';
import 'package:qr_code_dart_scan/src/util/isolate_pool.dart';

class IsolateDecoder {
  final List<BarcodeFormat> formats;
  final int countIsolates;
  IsolatePool? pool;

  IsolateDecoder({
    this.formats = QRCodeDartScanDecoder.acceptedFormats,
    this.countIsolates = 1,
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
    final event = FileDecodeEvent(
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

    return compute(FileDecode.decode, map);
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

    List<Yuv420Planes> yuv420Planes = image.planes
        .map((e) => Yuv420Planes(
              bytes: e.bytes,
              bytesPerRow: e.bytesPerRow,
              bytesPerPixel: e.bytesPerPixel,
              width: e.width,
              height: e.height,
            ))
        .toList();

    final event = CameraDecodeEvent(
      yuv420Planes: yuv420Planes,
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

    return compute(CameraDecode.decode, map);
  }
}
