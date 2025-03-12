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

    if (rotateCounterClockwise) {
      // rotaciona a imagem 90 graus
      final rotatedData = Uint8List(width * height * total);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          rotatedData[x * height + height - y - 1] = data[y * width + x];
        }
      }
      width = height;
      height = width;
      data = rotatedData;
    }

    return PlanarYUVLuminanceSource(
      data,
      width,
      height,
    );
  }
}
