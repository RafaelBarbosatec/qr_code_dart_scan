import 'dart:developer';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:qr_code_dart_decoder/src/util/liminance_mapper.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

abstract class CameraDecode {
  /// Flag para habilitar/desabilitar detecção de blur
  /// Pode ser desabilitado se causar falsos negativos em certos ambientes
  static bool enableBlurDetection = false;

  static Result? decode(
    List<Yuv420Planes> yuv420Planess, {
    RotationType? rotation,
    List<BarcodeFormat>? formats,
    CroppingStrategy? croppingStrategy,
  }) {
    // Otimização: Skip de frames borrados (economia de CPU)
    if (enableBlurDetection && !BlurDetector.isSharpFast(yuv420Planess)) {
      return null;
    }

    if (croppingStrategy != null) {
      try {
        double width = yuv420Planess.first.bytesPerRow.toDouble();
        double height =
            (yuv420Planess.first.bytes.length / width).round().toDouble();
        yuv420Planess = CropYuv.cropYuv(
          yuv420Planess,
          croppingStrategy.getCropRect(width, height),
        );
      } catch (_) {
        log('Error cropping yuv420Planess: $_');
      }
    }

    LuminanceSource source = LiminanceMapper.toLuminanceSource(
      yuv420Planess,
      rotationType: rotation,
    );

    var bitmap = BinaryBitmap(
      HybridBinarizer(source),
    );

    final reader = MultiFormatReader();

    Result? result;

    result = _try(
      reader,
      bitmap,
      alsoInverted: false,
      tryHarder: true,
    );

    result ??= _try(
      reader,
      bitmap,
      alsoInverted: true,
      tryHarder: true,
    );

    return result;
  }

  static Result? _try(
    MultiFormatReader reader,
    BinaryBitmap bitmap, {
    List<BarcodeFormat>? formats,
    bool alsoInverted = false,
    bool tryHarder = false,
  }) {
    try {
      return reader.decode(
        bitmap,
        DecodeHint(
          possibleFormats: formats,
          alsoInverted: alsoInverted,
          tryHarder: tryHarder,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // Método desabilitado por questões de performance (muito caro)
  // Descomente se necessário para QR codes muito difíceis de detectar
  // ignore: unused_element
  static Result? _tryUsingCropBackground(
    List<Yuv420Planes> yuv420Planess,
    MultiFormatReader reader,
    List<BarcodeFormat>? formats,
    RotationType? rotation,
  ) {
    final processor = CropBackgroundYuvProcessor();
    final processed = processor.process(yuv420Planess);
    if (processed == null) {
      return null;
    }

    LuminanceSource source = LiminanceMapper.toLuminanceSource(
      processed,
      rotationType: rotation,
    );

    var bitmap = BinaryBitmap(
      HybridBinarizer(source),
    );

    try {
      return reader.decode(
        bitmap,
        DecodeHint(
          possibleFormats: formats,
          alsoInverted: true,
          tryHarder: true,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
