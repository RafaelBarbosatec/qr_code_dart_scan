library qr_code_dart_decoder;

import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:qr_code_dart_decoder/src/camera/camera_decode.dart';
import 'package:qr_code_dart_decoder/src/camera/camera_decode_event.dart';
import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:qr_code_dart_decoder/src/file/file_decode.dart';
import 'package:qr_code_dart_decoder/src/file/file_decode_event.dart';
import 'package:qr_code_dart_decoder/src/util/crop_rect.dart';
import 'package:qr_code_dart_decoder/src/util/rotation_type.dart';
import 'package:zxing_lib/zxing.dart';

import 'src/util/pre_image_processor.dart';
import 'src/util/pre_yuv_processor.dart';

export 'package:qr_code_dart_decoder/src/camera/camera_decode.dart';
export 'package:qr_code_dart_decoder/src/camera/camera_decode_event.dart';
export 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
export 'package:qr_code_dart_decoder/src/file/file_decode.dart';
export 'package:qr_code_dart_decoder/src/file/file_decode_event.dart';
export 'package:qr_code_dart_decoder/src/util/crop_background_yuv.dart';
export 'package:qr_code_dart_decoder/src/util/crop_rect.dart';
export 'package:qr_code_dart_decoder/src/util/rotation_type.dart';
export 'package:zxing_lib/zxing.dart' show BarcodeFormat, Result;

/// A Calculator.
class QrCodeDartDecoder {
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

  QrCodeDartDecoder({
    this.formats = acceptedFormats,
  });

  Future<Result?> decodeFile(
    Uint8List bytes, {
    bool isInverted = false,
    RotationType? rotate,
    CropRect? cropRect,
    PreImageProcessor? preImageProcessor,
  }) async {
    var image = decodeImage(bytes);
    if (image == null) {
      return null;
    }

    final event = FileDecodeEvent(
      image: image.buffer.asUint8List(),
      invert: isInverted,
      formats: formats,
      width: image.width,
      height: image.height,
      rotation: rotate,
      cropRect: cropRect,
    );
    final result = await FileDecode.decode(event.toMap());
    if (result == null) {
      return _tryUsingImageProcessor(
        image,
        event,
        preImageProcessor ?? CropBackgroundProcessor(debug: true),
      );
    }
    return result;
  }

  Future<Result?> decodeCameraImage(
    List<Yuv420Planes> yuv420Planes, {
    bool isInverted = false,
    RotationType? rotate,
    CropRect? cropRect,
    PreYuvProcessor? preYuvProcessor,
  }) async {
    final event = CameraDecodeEvent(
      yuv420Planes: yuv420Planes,
      invert: isInverted,
      formats: formats,
      rotation: rotate,
      cropRect: cropRect,
    );
    final result = CameraDecode.decode(event.toMap());
    if (result == null) {
      return _tryUsingYuvProcessor(
        yuv420Planes,
        event,
        preYuvProcessor ?? CropBackgroundYuvProcessor(debug: true),
      );
    }
    return result;
  }

  Future<Result?> _tryUsingImageProcessor(
    Image i,
    FileDecodeEvent e,
    PreImageProcessor preImageProcessor,
  ) async {
    var image = preImageProcessor.process(i);
    if (image == null) {
      return null;
    }
    final event = FileDecodeEvent(
      image: image.buffer.asUint8List(),
      invert: e.invert,
      formats: formats,
      width: image.width,
      height: image.height,
      rotation: e.rotation,
      cropRect: e.cropRect,
    );
    return FileDecode.decode(event.toMap());
  }

  Future<Result?> _tryUsingYuvProcessor(
    List<Yuv420Planes> yuv420planes,
    CameraDecodeEvent e,
    PreYuvProcessor preYuvProcessor,
  ) async {
    var yuv420PlanesP = preYuvProcessor.process(yuv420planes);
    if (yuv420PlanesP == null) {
      return null;
    }
    final event = CameraDecodeEvent(
      yuv420Planes: yuv420PlanesP,
      invert: e.invert,
      formats: e.formats,
      rotation: e.rotation,
      cropRect: e.cropRect,
    );
    return CameraDecode.decode(event.toMap());
  }
}
