import 'package:qr_code_dart_decoder/src/camera/camera_decode_event.dart';
import 'package:qr_code_dart_decoder/src/util/liminance_mapper.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

abstract class CameraDecode {
  static Result? decode(Map<dynamic, dynamic> msg) {
    try {
      CameraDecodeEvent event = CameraDecodeEvent.fromMap(msg.cast());
      LuminanceSource source = LiminanceMapper.toLuminanceSource(
        event.yuv420Planes,
        rotationType: event.rotation,
        cropRect: event.cropRect,
      );

      var bitmap = BinaryBitmap(
        HybridBinarizer(source),
      );

      final reader = MultiFormatReader();

      return reader.decode(
        bitmap,
        DecodeHint(
          possibleFormats: event.formats,
          alsoInverted: event.invert,
          tryHarder: true,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
