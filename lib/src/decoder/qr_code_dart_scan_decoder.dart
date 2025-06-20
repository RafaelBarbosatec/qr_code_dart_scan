import 'package:camera/camera.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:qr_code_dart_scan/src/util/image_decode_orientation.dart';

import 'isolate_decoder.dart';

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
    BarcodeFormat.itf,
  ];

  final List<BarcodeFormat> formats;
  late IsolateDecoder _isolateDecoder;

  QRCodeDartScanDecoder({
    required this.formats,
  }) {
    for (var format in formats) {
      if (!acceptedFormats.contains(format)) {
        throw Exception('$format format not supported in the moment');
      }
    }
    _isolateDecoder = IsolateDecoder(
      formats: formats,
      preYuvProcessor: CropBackgroundYuvProcessor(),
    )..start();
  }

  Future<Result?> decodeCameraImage(
    CameraImage image, {
    bool scanInverted = false,
    ImageDecodeOrientation imageDecodeOrientation = ImageDecodeOrientation.original,
    CroppingStrategy? croppingStrategy,
  }) async {
    return _isolateDecoder.decodeCameraImage(
      image,
      isInverted: scanInverted,
      imageDecodeOrientation: imageDecodeOrientation,
      croppingStrategy: croppingStrategy,
    );
  }

  Future<Result?> decodeFile(
    XFile file, {
    bool scanInverted = false,
    CropRect? cropRect,
  }) async {
    return _isolateDecoder.decodeFileImage(
      file,
      isInverted: scanInverted,
      cropRect: cropRect,
    );
  }

  void dispose() {
    _isolateDecoder.dispose();
  }
}
