import 'dart:developer';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:qr_code_dart_decoder/src/util/liminance_mapper.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

abstract class CameraDecode {
  static Result? decode(
    List<Yuv420Planes> yuv420Planess, {
    RotationType? rotation,
    List<BarcodeFormat>? formats,
    CroppingStrategy? croppingStrategy,
  }) {
    if (croppingStrategy != null) {
      try {
        double width = yuv420Planess.first.bytesPerRow.toDouble();
        double height = (yuv420Planess.first.bytes.length / width).round().toDouble();
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

    try {
      return reader.decode(
        bitmap,
        DecodeHint(
          possibleFormats: formats,
          alsoInverted: false,
          tryHarder: false,
        ),
      );
    } catch (_) {
      try {
        return reader.decode(
          bitmap,
          DecodeHint(
            possibleFormats: formats,
            alsoInverted: true,
            tryHarder: true,
          ),
        );
      } catch (_) {
        return _tryUsingCropBackground(
          yuv420Planess,
          reader,
          formats,
          rotation,
        );
      }
    }
  }

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
