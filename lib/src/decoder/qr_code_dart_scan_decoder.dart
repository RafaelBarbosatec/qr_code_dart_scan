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

  QRCodeDartScanDecoder({List<BarcodeFormat>? formats})
      : formats = formats ?? acceptedFormats {
    formats?.forEach((element) {
      if (!acceptedFormats.contains(element)) {
        throw Exception('$element format not supported in the moment');
      }
    });
  }

  Future<Result?> decodeCameraImage(
    CameraImage image, {
    bool scanInvertedQRCode = false,
  }) async {
    final event = DecodeCameraImageEvent(
      cameraImage: image,
      formats: formats,
    );
    Result? decoded = await compute(
      decode,
      event.toMap(),
    );

    if (scanInvertedQRCode && decoded == null) {
      decoded = await compute(
        decode,
        event.copyWith(invert: true).toMap(),
      );
    }

    return decoded;
  }

  Future<Result?> decodeFile(
    XFile file, {
    bool scanInvertedQRCode = false,
  }) async {
    final bytes = await file.readAsBytes();
    final event = DecodeImageEvent(
      image: bytes,
      formats: formats,
    );
    Result? decoded = await compute(
      decodeImage,
      event.toMap(),
    );

    if (scanInvertedQRCode && decoded == null) {
      decoded = await compute(
        decodeImage,
        event.copyWith(invert: true).toMap(),
      );
    }

    return decoded;
  }
}
