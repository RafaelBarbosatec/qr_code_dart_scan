import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:qr_code_dart_scan/src/util/extensions.dart';
import 'package:zxing_lib/zxing.dart';

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
/// on 28/06/22
class DecodeImageEvent {
  final bool invert;
  final Uint8List image;
  final List<BarcodeFormat> formats;

  DecodeImageEvent({
    required this.image,
    this.invert = false,
    this.formats = const [],
  });

  DecodeImageEvent.fromMap(Map map)
      : invert = map['invert'] as bool,
        image = map['image'] as Uint8List,
        formats = map['formats']
            .map<BarcodeFormat>((f) => BarcodeFormat.values[f])
            .toList();

  Map toMap() {
    return {
      'invert': invert,
      'image': image,
      'formats': formats.map((e) => e.index).toList(),
    };
  }

  DecodeImageEvent copyWith({
    bool? invert,
    Uint8List? image,
    List<BarcodeFormat>? formats,
  }) {
    return DecodeImageEvent(
      invert: invert ?? this.invert,
      image: image ?? this.image,
      formats: formats ?? this.formats,
    );
  }
}

class DecodeCameraImageEvent {
  final bool invert;
  final CameraImage cameraImage;
  final List<BarcodeFormat> formats;

  DecodeCameraImageEvent({
    required this.cameraImage,
    this.invert = false,
    this.formats = const [],
  });

  DecodeCameraImageEvent.fromMap(Map map)
      : invert = map['invert'] as bool,
        cameraImage = CameraImage.fromPlatformData(
          map['image'] as Map<dynamic, dynamic>,
        ),
        formats = map['formats']
            .map<BarcodeFormat>((f) => BarcodeFormat.values[f])
            .toList();

  Map toMap() {
    return {
      'invert': invert,
      'image': cameraImage.toPlatformData(),
      'formats': formats.map((e) => e.index).toList(),
    };
  }

  DecodeCameraImageEvent copyWith({
    bool? invert,
    CameraImage? cameraImage,
    List<BarcodeFormat>? formats,
  }) {
    return DecodeCameraImageEvent(
      invert: invert ?? this.invert,
      cameraImage: cameraImage ?? this.cameraImage,
      formats: formats ?? this.formats,
    );
  }
}
