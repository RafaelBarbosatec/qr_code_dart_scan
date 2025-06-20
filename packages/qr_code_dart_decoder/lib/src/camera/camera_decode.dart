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
      double width = yuv420Planess.first.bytesPerRow.toDouble();
      double height = (yuv420Planess.first.bytes.length / width).round().toDouble();
      yuv420Planess = CropYuv.cropYuv(
        yuv420Planess,
        croppingStrategy.getCropRect(width, height),
      );
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
    } on NotFoundException catch (_) {
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
        return null;
      }
    }
  }
}
