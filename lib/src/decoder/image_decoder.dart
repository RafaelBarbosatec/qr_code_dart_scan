import 'package:flutter/foundation.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/decoder/decode_event.dart';
import 'package:qr_code_dart_scan/src/decoder/global_functions.dart';
import 'package:qr_code_dart_scan/src/decoder/qr_code_dart_scan_multi_reader.dart';
import 'package:zxing_lib/common.dart';

class ImageDecoder {
  static Result? decodePlanes(Map<dynamic, dynamic> msg) {
    try {
      DecodeCameraImageEvent event = DecodeCameraImageEvent.fromMap(msg);

      LuminanceSource source = transformToLuminanceSource(
        event.cameraImage.planes,
        forceReadPortrait: event.forceReadPortrait,
      );

      if (event.rotate && source.isRotateSupported) {
        source = source.rotateCounterClockwise();
      }

      if (event.invert) {
        source = source.invert();
      }

      var bitmap = BinaryBitmap(
        HybridBinarizer(source),
      );

      final reader = QRCodeDartScanMultiReader(event.formats);

      return reader.decode(bitmap);
    } catch (_) {
      return null;
    }
  }

  static Future<Result?> decodeImage(Map<dynamic, dynamic> map) async {
    try {
      final DecodeImageEvent event = DecodeImageEvent.fromMap(map);
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
