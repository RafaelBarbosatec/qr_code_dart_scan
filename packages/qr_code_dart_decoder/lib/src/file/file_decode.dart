import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/file/file_decode_event.dart';
import 'package:qr_code_dart_decoder/src/util/liminance_mapper.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

abstract class FileDecode {
  static Future<Result?> decode(Map<dynamic, dynamic> map) async {
    try {
      final FileDecodeEvent event = FileDecodeEvent.fromMap(map);
      final int pixelCount = event.width * event.height;
      final pixels = Uint8List(pixelCount);
      final imageBytes = Uint8List.view(event.image.buffer);

      for (int i = 0, j = 0; i < pixelCount; i++, j += 4) {
        pixels[i] = LiminanceMapper.getLuminanceSourcePixel(imageBytes, j);
      }

      LuminanceSource source = RGBLuminanceSource.orig(
        event.width,
        event.height,
        pixels,
      );

      if (event.rotate) {
        source = source.rotateCounterClockwise();
      }

      final bitmap = BinaryBitmap(
        HybridBinarizer(source),
      );

      final reader = MultiFormatReader();

      return reader.decode(
        bitmap,
        DecodeHint(
          possibleFormats: event.formats,
          alsoInverted: event.invert,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
