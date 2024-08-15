import 'package:flutter/foundation.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/decoder/decode_event.dart';
import 'package:qr_code_dart_scan/src/decoder/global_functions.dart';
import 'package:qr_code_dart_scan/src/util/isolate_pool.dart';

import 'image_decoder.dart';

class IsolateDecoder {
  final List<BarcodeFormat> formats;

  IsolatePool? pool;

  IsolateDecoder({this.formats = QRCodeDartScanDecoder.acceptedFormats});

  Future start() {
    pool = IsolatePool(2);
    return pool!.start();
  }

  void dispose() {
    pool?.dispose();
  }

  Future<Result?> decodeFileImage(XFile file, {bool insverted = false}) async {
    final bytes = await file.readAsBytes();

    final image = await myDecodeImageFromList(bytes);

    final event = DecodeImageEvent(
      image: (await image.toByteData())!.buffer.asUint8List(),
      width: image.width,
      height: image.height,
      formats: formats,
      invert: insverted,
    );

    return compute(ImageDecoder.decodeImage, event.toMap());
  }

  Future<Result?> decodeCameraImage(
    CameraImage image, {
    bool insverted = false,
  }) async {
    if (pool == null) {
      throw Exception('Should call start method before');
    }
    final event = DecodeCameraImageEvent(
      cameraImage: image,
      formats: formats,
      invert: insverted,
    );

    final result = await pool!.runTask(event.toMap());
    return result;
  }
}
