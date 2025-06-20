import 'package:flutter/foundation.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/decoder/global_functions.dart';

class IsolateDecoder {
  final List<BarcodeFormat> formats;
  final YuvPreProcessor? preYuvProcessor;

  late IsolateCameraDecode isolateController;

  IsolateDecoder({
    this.formats = QRCodeDartScanDecoder.acceptedFormats,
    required this.preYuvProcessor,
  }) {
    isolateController = IsolateCameraDecode();
  }

  Future<void> start() {
    return isolateController.start();
  }

  void dispose() {
    isolateController.terminate();
  }

  Future<Result?> decodeFileImage(XFile file, {CropRect? cropRect}) async {
    final bytes = await file.readAsBytes();
    final image = await myDecodeImageFromList(bytes);
    final event = FileDecodeEvent(
      image: (await image.toByteData())!.buffer.asUint8List(),
      width: image.width,
      height: image.height,
      formats: formats,
      cropRect: cropRect,
    );

    return compute(FileDecode.decode, event.toMap());
  }

  Future<Result?> decodeCameraImage(
    CameraImage image, {
    bool isInverted = false,
    ImageDecodeOrientation imageDecodeOrientation = ImageDecodeOrientation.original,
    CroppingStrategy? croppingStrategy,
  }) async {
    final isPortrait = image.height > image.width;
    final isLandscape = image.height < image.width;
    bool rotate = false;
    switch (imageDecodeOrientation) {
      case ImageDecodeOrientation.landscape:
        rotate = isPortrait;
        break;
      case ImageDecodeOrientation.portrait:
        rotate = isLandscape;
        break;
      case ImageDecodeOrientation.original:
        break;
    }

    List<Yuv420Planes> yuv420Planes = image.planes
        .map((e) => Yuv420Planes(
              bytes: e.bytes,
              bytesPerRow: e.bytesPerRow,
              bytesPerPixel: e.bytesPerPixel,
              width: e.width,
              height: e.height,
            ))
        .toList();

    try {
      final result = await isolateController.setYuv420Planess(
        yuv420Planes,
        rotation: rotate ? RotationType.clockwise : null,
        formats: formats,
        croppingStrategy: croppingStrategy,
      );
      if (result == null) {
        final processedYuv420Planes = preYuvProcessor?.process(yuv420Planes);
        if (processedYuv420Planes != null) {
          return isolateController.setYuv420Planess(
            processedYuv420Planes,
            rotation: rotate ? RotationType.clockwise : null,
            formats: formats,
          );
        }
      }
      return result;
    } catch (e) {
      return null;
    }
  }
}
