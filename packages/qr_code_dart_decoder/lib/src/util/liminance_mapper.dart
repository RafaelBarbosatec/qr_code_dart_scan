import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:zxing_lib/zxing.dart';

abstract class LiminanceMapper {
  static LuminanceSource toLuminanceSource(
    List<Yuv420Planes> planes, {
    bool rotateCounterClockwise = false,
  }) {
    final e = planes.first;
    int width = e.bytesPerRow;
    int height = (e.bytes.length / width).round();
    final total = planes
        .map<double>((p) => (p.bytesPerPixel ?? 1).toDouble())
        .reduce((value, element) => value + 1 / element)
        .toInt();
    Uint8List data = Uint8List(width * height * total);
    int startIndex = 0;
    for (var p in planes) {
      List.copyRange(data, startIndex, p.bytes);
      startIndex += width * height ~/ (p.bytesPerPixel ?? 1);
    }

    return PlanarYUVLuminanceSource(
      data,
      width,
      height,
    );
  }

  static int getLuminanceSourcePixel(List<int> byte, int index) {
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
