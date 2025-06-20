// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:zxing_lib/grayscale.dart';

abstract class ImagePreProcessor {
  Image? process(Image image) {
    return image;
  }
}

class CropBackgroundProcessor extends ImagePreProcessor {
  final bool debug;
  CropBackgroundProcessor({this.debug = false});

  @override
  Image? process(Image image) {
    Dispatch? dispatcher = CropBackground(tolerance: 0.8);

    final origData = Uint8List.fromList(
      image.map<int>((e) => (e.luminanceNormalized * 255).round()).toList(),
    );

    Uint8List data;
    int width = image.width;
    int height = image.height;
    data = dispatcher.dispatch(origData, width, height);
    final rect = dispatcher.cropRect;

    if (rect != null) {
      final result = copyCrop(
        image,
        x: rect.left,
        y: rect.top,
        width: rect.width,
        height: rect.height,
      );

      if (debug) {
        print('original image: ${image.width}x${image.height}');
        print('croped image: ${rect.width}x${rect.height}');
        try {
          const filename = 'cropped_image.png';
          final pngBytes = encodePng(result);
          final file = File(filename);
          file.writeAsBytes(pngBytes);
          print('Processed image saved to $filename');
        } catch (e) {
          print('Failed to save processed image: $e');
        }
      }
      return result;
    }

    return Image.fromBytes(
      width: width,
      height: height,
      bytes: data.buffer,
      order: ChannelOrder.red,
    );
  }
}
