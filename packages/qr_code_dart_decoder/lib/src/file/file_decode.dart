import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/file/file_decode_event.dart';
import 'package:qr_code_dart_decoder/src/util/liminance_mapper.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

abstract class FileDecode {
  static Future<Result?> decode(Map<dynamic, dynamic> map) async {
    final FileDecodeEvent event = FileDecodeEvent.fromMap(map);

    final imageBytes = Uint8List.view(event.image.buffer);

    LuminanceSource source = LiminanceMapper.toLuminanceSourceFromBytes(
      imageBytes,
      event.width,
      event.height,
      rotationType: event.rotation,
      cropRect: event.cropRect,
    );

    final bitmap = BinaryBitmap(
      HybridBinarizer(source),
    );

    final reader = MultiFormatReader();

    try {
      return reader.decode(
        bitmap,
        DecodeHint(
          possibleFormats: event.formats,
          alsoInverted: false,
          tryHarder: false,
        ),
      );
    } on NotFoundException catch (_) {
      try {
        return reader.decode(
          bitmap,
          DecodeHint(
            possibleFormats: event.formats,
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
