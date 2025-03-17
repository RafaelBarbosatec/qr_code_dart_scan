import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:qr_code_dart_decoder/src/util/rotation_type.dart';
import 'package:zxing_lib/zxing.dart';

import 'crop_rect.dart';

abstract class LiminanceMapper {
  static LuminanceSource toLuminanceSource(
    List<Yuv420Planes> planes, {
    RotationType? rotationType,
    CropRect? cropRect,
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

    if (rotationType != null) {
      switch (rotationType) {
        case RotationType.clockwise:
          Uint8List rotatedData = _rotateClockWise(width, height, data, multiplier: total);
          final temp = width;
          width = height;
          height = temp;
          data = rotatedData;
          break;
        case RotationType.counterClockwise:
          Uint8List rotatedData = _rotateCounterClockWise(width, height, data, multiplier: total);
          final temp = width;
          width = height;
          height = temp;
          data = rotatedData;
          break;
      }
    }

    LuminanceSource luminanceSource = RGBLuminanceSource.orig(
      width,
      height,
      data,
    );

    if (cropRect != null) {
      luminanceSource = luminanceSource.crop(
        cropRect.left.round(),
        cropRect.top.round(),
        cropRect.width.round(),
        cropRect.height.round(),
      );
    }

    return luminanceSource;
  }

  static Uint8List _rotateCounterClockWise(
    int width,
    int height,
    Uint8List data, {
    int multiplier = 1,
  }) {
    final rotatedData = Uint8List(width * height * multiplier);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        rotatedData[x * height + height - y - 1] = data[y * width + x];
      }
    }
    return rotatedData;
  }

  static Uint8List _rotateClockWise(
    int width,
    int height,
    Uint8List data, {
    int multiplier = 1,
  }) {
    final rotatedData = Uint8List(width * height * multiplier);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        rotatedData[(width - x - 1) * height + y] = data[y * width + x];
      }
    }
    return rotatedData;
  }

  static LuminanceSource toLuminanceSourceFromBytes(
    Uint8List imageBytes,
    int width,
    int height, {
    RotationType? rotationType,
    CropRect? cropRect,
  }) {
    final int pixelCount = width * height;
    Uint8List pixels = Uint8List(pixelCount);

    for (int i = 0, j = 0; i < pixelCount; i++, j += 4) {
      pixels[i] = _getLuminanceSourcePixel(imageBytes, j);
    }

    if (rotationType != null) {
      switch (rotationType) {
        case RotationType.clockwise:
          Uint8List rotatedData = _rotateClockWise(width, height, pixels);
          final temp = width;
          width = height;
          height = temp;
          pixels = rotatedData;
          break;
        case RotationType.counterClockwise:
          Uint8List rotatedData = _rotateCounterClockWise(width, height, pixels);
          final temp = width;
          width = height;
          height = temp;
          pixels = rotatedData;
          break;
      }
    }

    LuminanceSource luminanceSource = RGBLuminanceSource.orig(
      width,
      height,
      pixels,
    );

    if (cropRect != null) {
      luminanceSource = luminanceSource.crop(
        cropRect.left.round(),
        cropRect.top.round(),
        cropRect.width.round(),
        cropRect.height.round(),
      );
    }

    return luminanceSource;
  }

  static int _getLuminanceSourcePixel(
    List<int> byte,
    int index,
  ) {
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
