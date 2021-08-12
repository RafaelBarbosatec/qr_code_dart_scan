import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

///
/// Created by
///
/// ─▄▀─▄▀
/// ──▀──▀
/// █▀▀▀▀▀█▄
/// █░░░░░█─█
/// ▀▄▄▄▄▄▀▀
///
/// Rafaelbarbosatec
/// on 12/08/21
extension CameraImageExtension on CameraImage {
  Map toPlatformData() {
    return <dynamic, dynamic>{
      'height': height,
      'width': width,
      'format': _getFormat(),
      'planes': _getPlanes(),
    };
  }

  int _getFormat() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      switch (format.group) {
        // android.graphics.ImageFormat.YUV_420_888
        case ImageFormatGroup.yuv420:
          return 35;
        // android.graphics.ImageFormat.JPEG
        case ImageFormatGroup.jpeg:
          return 256;
        case ImageFormatGroup.unknown:
        case ImageFormatGroup.bgra8888:
      }
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      switch (format.group) {
        // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        case ImageFormatGroup.yuv420:
          return 875704438;
        // kCVPixelFormatType_32BGRA
        case ImageFormatGroup.bgra8888:
          return 1111970369;
        case ImageFormatGroup.unknown:
          break;
        case ImageFormatGroup.jpeg:
          break;
      }
    }
    return 0;
  }

  List<Map<dynamic, dynamic>> _getPlanes() {
    return planes.map((e) {
      return <dynamic, dynamic>{
        'bytes': e.bytes,
        'bytesPerPixel': e.bytesPerPixel,
        'bytesPerRow': e.bytesPerRow,
        'height': e.height,
        'width': e.width,
      };
    }).toList();
  }
}
