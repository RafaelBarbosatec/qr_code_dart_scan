import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/file/file_decode_event.dart';
import 'package:qr_code_dart_decoder/src/qr_code_dart_scan_multi_reader.dart';
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
        pixels[i] = _getLuminanceSourcePixel(imageBytes, j);
      }

      final source = RGBLuminanceSource.orig(
        event.width,
        event.height,
        pixels,
      );
      final bitmap = BinaryBitmap(
        HybridBinarizer(event.invert ? source.invert() : source),
      );
      final reader = QRCodeDartScanMultiReader(event.formats);

      return reader.decode(bitmap);
    } catch (e) {
      return null;
    }
  }

  static int _getLuminanceSourcePixel(List<int> byte, int index) {
    if (byte.length <= index + 3) {
      return 0xff;
    }
    final r = byte[index] & 0xff; // red
    final g2 = (byte[index + 1] << 1) & 0x1fe; // 2 * green
    final b = byte[index + 2]; // blue
    // Calculate green-favouring average cheaply
    return ((r + g2 + b) ~/ 4);
  }
}
