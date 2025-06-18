import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:qr_code_dart_decoder/src/util/crop_rect.dart';

class CropBackgroundYuv {
  final double tolerance;
  final double purity;
  final int wrapper;

  CropBackgroundYuv({
    this.tolerance = 0.05,
    this.purity = 0.99,
    this.wrapper = 255,
  });

  int? lastColor;

  CropRect? _cropRect;

  CropRect? get cropRect => _cropRect;

  bool checkLine(List<int> line) {
    final groups = <int, int>{};
    // 统计颜色
    for (var i in line) {
      if (lastColor != null) {
        if (i == lastColor || (i - lastColor!).abs() / 255 < tolerance) {
          groups[lastColor!] = (groups[lastColor] ?? 0) + 1;
        }
      } else {
        if (groups.containsKey(i)) {
          groups[i] = groups[i]! + 1;
        } else {
          groups[i] = 1;
        }
      }
    }

    if (groups.isEmpty) return false;

    // 尝试合并颜色
    if (groups.length > 1) {
      final sorted = groups.entries.toList()..sort((e, e2) => e.value - e2.value);
      final first = sorted.removeAt(0);
      if (first.value < purity * line.length) {
        if (tolerance == 0) {
          return false;
        }
        int count = first.value;
        for (var e in sorted) {
          if ((e.key - first.key).abs() / 255 <= tolerance) {
            count += e.value;
          }
        }
        final passed = count / line.length > purity;
        if (passed && lastColor == null) {
          lastColor = first.key;
        }
        return passed;
      }
    }
    if (lastColor == null) {
      lastColor ??= groups.keys.first;
      return true;
    } else {
      return groups.values.first / line.length > purity;
    }
  }

  /// Converts YUV420 planes to grayscale data similar to LiminanceMapper
  Uint8List _convertYuv420ToGrayscale(List<Yuv420Planes> planes) {
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

    return data;
  }

  /// Get width and height from YUV420 planes
  Map<String, int> _getDimensionsFromPlanes(List<Yuv420Planes> planes) {
    final e = planes.first;
    int width = e.bytesPerRow;
    int height = (e.bytes.length / width).round();
    return {'width': width, 'height': height};
  }

  List<Yuv420Planes> dispatch(
    List<Yuv420Planes> yuv420Planes, [
    CropRect? rect,
  ]) {
    if (rect == null) {
      return dispatchFull(yuv420Planes);
    }
    return dispatchRect(yuv420Planes, rect);
  }

  List<Yuv420Planes> dispatchFull(List<Yuv420Planes> yuv420Planes) {
    // Convert YUV420 to grayscale data for processing
    final data = _convertYuv420ToGrayscale(yuv420Planes);
    final dimensions = _getDimensionsFromPlanes(yuv420Planes);
    final width = dimensions['width']!;
    final height = dimensions['height']!;

    int cropTop = 0, cropLeft = 0, cropRight = 0, cropBottom = 0;
    const minSize = 10;

    // 垂直裁剪
    for (int i = 0; i < height - minSize; i++) {
      if (checkLine(data.getRange(i * width, (i + 1) * width).toList())) {
        cropTop++;
      } else {
        break;
      }
    }
    for (int i = height - 1; i > cropTop + minSize; i--) {
      if (checkLine(data.getRange(i * width, (i + 1) * width).toList())) {
        cropBottom++;
      } else {
        break;
      }
    }
    final newHeight = height - cropBottom - cropTop;

    // 横向裁剪
    for (int i = 0; i < width - minSize; i++) {
      if (checkLine(
        List.generate(newHeight, (l) => data[(l + cropTop) * width + i]),
      )) {
        cropLeft++;
      } else {
        break;
      }
    }
    for (int i = width - 1; i > cropLeft + minSize; i--) {
      if (checkLine(
        List.generate(newHeight, (l) => data[(l + cropTop) * width + i]),
      )) {
        cropRight++;
      } else {
        break;
      }
    }

    if (cropTop > 0 || cropLeft > 0 || cropRight > 0 || cropBottom > 0) {
      _cropRect = CropRect.fromLTRB(cropLeft.toDouble(), cropTop.toDouble(),
          (width - cropRight).toDouble(), (height - cropBottom).toDouble());

      final newWidth = _cropRect!.width.toInt();
      final newHeight = _cropRect!.height.toInt();

      // Create cropped planes
      List<Yuv420Planes> croppedPlanes = [];
      for (var plane in yuv420Planes) {
        // Calculate the crop region for this plane
        final planeWidth = plane.width ?? plane.bytesPerRow;
        final planeHeight = plane.height ?? (plane.bytes.length / planeWidth).round();

        // Calculate scaling factors if this plane is a different size (e.g., UV planes in YUV420)
        final scaleX = planeWidth / width;
        final scaleY = planeHeight / height;

        final planeCropLeft = (cropLeft * scaleX).toInt();
        final planeCropTop = (cropTop * scaleY).toInt();
        final planeCropWidth = (newWidth * scaleX).toInt();
        final planeCropHeight = (newHeight * scaleY).toInt();

        // Create cropped plane data
        final croppedBytes = Uint8List(planeCropWidth * planeCropHeight);

        for (int y = 0; y < planeCropHeight; y++) {
          final sourceY = planeCropTop + y;
          final sourceStart = sourceY * planeWidth + planeCropLeft;
          final destStart = y * planeCropWidth;

          // Ensure we don't exceed source bounds
          final sourceEnd = sourceStart + planeCropWidth;
          final maxSourceEnd = plane.bytes.length;

          if (sourceStart < maxSourceEnd && sourceEnd <= maxSourceEnd) {
            List.copyRange(
              croppedBytes,
              destStart,
              plane.bytes,
              sourceStart,
              sourceEnd,
            );
          } else {
            // If bounds are invalid, copy what we can
            final validEnd = sourceStart < maxSourceEnd
                ? (sourceEnd > maxSourceEnd ? maxSourceEnd : sourceEnd)
                : sourceStart;

            if (sourceStart < validEnd) {
              List.copyRange(
                croppedBytes,
                destStart,
                plane.bytes,
                sourceStart,
                validEnd,
              );
            }
          }
        }

        croppedPlanes.add(Yuv420Planes(
          bytes: croppedBytes,
          bytesPerRow: planeCropWidth,
          bytesPerPixel: plane.bytesPerPixel,
          width: planeCropWidth,
          height: planeCropHeight,
        ));
      }

      lastColor = null;
      return croppedPlanes;
    }

    return yuv420Planes;
  }

  List<Yuv420Planes> dispatchRect(List<Yuv420Planes> yuv420Planes, CropRect rect) {
    // For rect dispatch, we could implement specific rectangle cropping
    // For now, return the original planes
    return yuv420Planes;
  }
}
