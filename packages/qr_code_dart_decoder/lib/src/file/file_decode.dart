import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/file/file_decode_event.dart';
import 'package:qr_code_dart_decoder/src/models/scan_result.dart';
import 'package:qr_code_dart_decoder/src/models/zxing_mapping.dart';
import 'package:qr_code_dart_decoder/src/util/liminance_mapper.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart' hide BarcodeFormat;

abstract class FileDecode {
  static Future<ScanResult?> decode(Map<dynamic, dynamic> map) async {
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

    final possibleFormats = event.formats.toZxing;

    try {
      return reader
          .decode(
            bitmap,
            DecodeHint(
              possibleFormats: possibleFormats,
              alsoInverted: false,
              tryHarder: false,
            ),
          )
          .toScanResult;
    } on NotFoundException catch (_) {
      try {
        return reader
            .decode(
              bitmap,
              DecodeHint(
                possibleFormats: possibleFormats,
                alsoInverted: true,
                tryHarder: true,
              ),
            )
            .toScanResult;
      } catch (_) {
        return null;
      }
    }
  }
}
