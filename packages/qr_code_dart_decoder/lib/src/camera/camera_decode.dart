import 'package:qr_code_dart_decoder/src/camera/camera_decode_event.dart';
import 'package:qr_code_dart_decoder/src/multi_reader.dart';
import 'package:qr_code_dart_decoder/src/util/liminance_mapper.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

abstract class CameraDecode {
  static Result? decode(Map<dynamic, dynamic> msg) {
    try {
      CameraDecodeEvent event = CameraDecodeEvent.fromMap(msg.cast());

      LuminanceSource source = LiminanceMapper.toLuminanceSource(
        event.yuv420Planes,
        rotateCounterClockwise: event.rotate,
      );

      if (event.invert) {
        source = source.invert();
      }

      var bitmap = BinaryBitmap(
        HybridBinarizer(source),
      );

      final reader = MultiReader(event.formats);

      return reader.decode(bitmap);
    } catch (_) {
      return null;
    }
  }
}
