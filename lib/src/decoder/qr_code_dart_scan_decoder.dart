import 'package:camera/camera.dart';
import 'package:qr_code_dart_scan/src/decoder/isolate_decoder.dart';
import 'package:zxing_lib/zxing.dart';

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
    BarcodeFormat.qrCode,
    BarcodeFormat.aztec,
    BarcodeFormat.dataMatrix,
    BarcodeFormat.pdf417,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.code128,
    BarcodeFormat.ean8,
    BarcodeFormat.ean13,
  ];
  final List<BarcodeFormat> formats;
  late IsolateDecoder _isolateDecoder;

  QRCodeDartScanDecoder({required this.formats}) {
    for (var format in formats) {
      if (!acceptedFormats.contains(format)) {
        throw Exception('$format format not supported in the moment');
      }
    }
    _isolateDecoder = IsolateDecoder(formats: formats);
  }

  Future<Result?> decodeCameraImage(
    CameraImage image, {
    bool scanInverted = false,
  }) async {
    Result? decoded = await _isolateDecoder.decodeCameraImage(image);

    if (scanInverted && decoded == null) {
      decoded = await _isolateDecoder.decodeCameraImage(
        image,
        insverted: scanInverted,
      );
    }

    return decoded;
  }

  Future<Result?> decodeFile(
    XFile file, {
    bool scanInverted = false,
  }) async {
    Result? decoded = await _isolateDecoder.decodeFileImage(file);

    if (scanInverted && decoded == null) {
      decoded = await _isolateDecoder.decodeFileImage(file, insverted: true);
    }

    return decoded;
  }
}
