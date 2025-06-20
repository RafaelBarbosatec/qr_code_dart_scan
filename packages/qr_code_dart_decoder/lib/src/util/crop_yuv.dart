import 'dart:typed_data';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';

abstract class CropYuv {
  static List<Yuv420Planes> cropYuv(List<Yuv420Planes> yuv420planes, CropRect rect) {
    final newPlanes = <Yuv420Planes>[];
    for (var i = 0; i < yuv420planes.length; i++) {
      final plane = yuv420planes[i];
      final bytesPerPixel = plane.bytesPerPixel ?? 1;

      // given crop rect is for full size image.
      // y plane is full size, u and v are half size.
      final cropX = (i == 0 ? rect.left : rect.left / 2).floor();
      final cropY = (i == 0 ? rect.top : rect.top / 2).floor();
      final cropWidth = (i == 0 ? rect.width : rect.width / 2).floor();
      final cropHeight = (i == 0 ? rect.height : rect.height / 2).floor();

      final newBytesPerRow = cropWidth * bytesPerPixel;
      final newBytes = Uint8List(newBytesPerRow * cropHeight);

      for (var y = 0; y < cropHeight; y++) {
        final srcOffset = (cropY + y) * plane.bytesPerRow + cropX * bytesPerPixel;
        final dstOffset = y * newBytesPerRow;
        newBytes.setRange(
          dstOffset,
          dstOffset + newBytesPerRow,
          plane.bytes.getRange(srcOffset, srcOffset + newBytesPerRow),
        );
      }

      newPlanes.add(
        Yuv420Planes(
          bytes: newBytes,
          bytesPerRow: newBytesPerRow,
          bytesPerPixel: plane.bytesPerPixel,
          height: cropHeight,
          width: cropWidth,
        ),
      );
    }

    return newPlanes;
  }
}
