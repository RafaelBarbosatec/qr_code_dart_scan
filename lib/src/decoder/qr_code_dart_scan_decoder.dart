import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:zxing_lib/zxing.dart';

import 'decode_event.dart';
import 'global_functions.dart';

///
/// Created by
///
/// ─▄▀─▄▀
/// ──▀──▀
/// █▀▀▀▀▀█▄
/// █░░░░░█─█
/// ▀▄▄▄▄▄▀▀
///
/// Rafaelbarbosatec
/// on 12/08/21

class QRCodeDartScanDecoder {
  static const acceptedFormats = [
    BarcodeFormat.QR_CODE,
    BarcodeFormat.AZTEC,
    BarcodeFormat.DATA_MATRIX,
    BarcodeFormat.PDF_417,
    BarcodeFormat.CODE_39,
    BarcodeFormat.CODE_93,
    BarcodeFormat.CODE_128,
    BarcodeFormat.EAN_8,
    BarcodeFormat.EAN_13,
  ];
  final List<BarcodeFormat> formats;

  QRCodeDartScanDecoder({required this.formats}) {
    for (var format in formats) {
      if (!acceptedFormats.contains(format)) {
        throw Exception('$format format not supported in the moment');
      }
    }
  }

  Future<Result?> decodeCameraImage(
    CameraImage image, {
    bool scanInverted = false,
  }) async {
    final event = DecodeCameraImageEvent(
      cameraImage: image,
      formats: formats,
    );
    Result? decoded = await compute(
      decode,
      event.toMap(),
    );

    if (scanInverted && decoded == null) {
      decoded = await compute(
        decode,
        event.copyWith(invert: true).toMap(),
      );
    }

    return decoded;
  }

  Future<Result?> decodeFile(
    XFile file, {
    bool scanInverted = false,
  }) async {
    final bytes = await file.readAsBytes();

    final image = await decodeImageFromList(bytes);
    final event = DecodeImageEvent(
      image: (await image.toByteData())!.buffer.asUint8List(),
      width: image.width,
      height: image.height,
      formats: formats,
    );
    Result? decoded = await compute(
      decodeImage,
      event.toMap(),
    );

    if (scanInverted && decoded == null) {
      decoded = await compute(
        decodeImage,
        event.copyWith(invert: true).toMap(),
      );
    }

    return decoded;
  }
}
