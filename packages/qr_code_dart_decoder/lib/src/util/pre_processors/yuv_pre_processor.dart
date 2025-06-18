// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';

abstract class YuvPreProcessor {
  List<Yuv420Planes>? process(List<Yuv420Planes> image) {
    return image;
  }
}

class CropBackgroundYuvProcessor extends YuvPreProcessor {
  final bool debug;
  CropBackgroundYuvProcessor({this.debug = false});

  @override
  List<Yuv420Planes>? process(List<Yuv420Planes> image) {
    CropBackgroundYuv dispatcher = CropBackgroundYuv(tolerance: 0.5);

    // Process the planes to crop background
    final result = dispatcher.dispatch(image);
    final rect = dispatcher.cropRect;

    if (debug) {
      // Get dimensions from the first plane
      final firstPlane = image.first;
      final originalWidth = firstPlane.width ?? firstPlane.bytesPerRow;
      final originalHeight = firstPlane.height ?? (firstPlane.bytes.length / originalWidth).round();

      print('original YUV planes: ${originalWidth}x$originalHeight');
      if (rect != null) {
        print('cropped region: ${rect.width.toInt()}x${rect.height.toInt()}');
      } else {
        print('No background cropping was applied');
      }
      saveDebugImage(result, 'cropped_image.png');
      saveDebugImage(image, 'original_image.png');
    }

    return result;
  }

  static void saveDebugImage(
    List<Yuv420Planes> result,
    String filename,
  ) {
    try {
      // Convert first plane (Y plane) to grayscale image for debugging
      final resultPlane = result.first;
      final resultWidth = resultPlane.width ?? resultPlane.bytesPerRow;
      final resultHeight = resultPlane.height ?? (resultPlane.bytes.length / resultWidth).round();

      final debugImage = Image(
        width: resultWidth,
        height: resultHeight,
        numChannels: 1,
      );

      // Copy Y plane data to image
      for (int y = 0; y < resultHeight; y++) {
        for (int x = 0; x < resultWidth; x++) {
          final index = y * resultWidth + x;
          if (index < resultPlane.bytes.length) {
            final value = resultPlane.bytes[index];
            debugImage.setPixelRgb(x, y, value, value, value);
          }
        }
      }

      final pngBytes = encodePng(debugImage);
      final file = File(filename);
      file.writeAsBytes(pngBytes);
      print('Processed YUV image saved to $filename');
    } catch (e) {
      print('Failed to save processed YUV image');
    }
  }
}
