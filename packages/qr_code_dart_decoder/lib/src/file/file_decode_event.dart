import 'dart:typed_data';

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
class FileDecodeEvent {
  final bool invert;
  final Uint8List image;
  final int width;
  final int height;
  final List<BarcodeFormat> formats;
  final bool rotate;

  FileDecodeEvent({
    required this.image,
    this.invert = false,
    this.formats = const [],
    this.width = 0,
    this.height = 0,
    this.rotate = false,
  });

  FileDecodeEvent.fromMap(Map map)
      : invert = map['invert'] as bool,
        image = Uint8List.fromList((map['image'] as List).cast<int>()),
        width = map['width'] as int,
        height = map['height'] as int,
        formats = map['formats'].map<BarcodeFormat>((f) => BarcodeFormat.values[f]).toList(),
        rotate = map['rotate'] as bool;

  Map toMap() {
    return {
      'invert': invert,
      'image': image.toList(),
      'width': width,
      'height': height,
      'formats': formats.map((e) => e.index).toList(),
      'rotate': rotate,
    };
  }

  FileDecodeEvent copyWith({
    bool? invert,
    Uint8List? image,
    int? width,
    int? height,
    List<BarcodeFormat>? formats,
    bool? rotate,
  }) {
    return FileDecodeEvent(
      invert: invert ?? this.invert,
      image: image ?? this.image,
      formats: formats ?? this.formats,
      width: width ?? this.width,
      height: height ?? this.height,
      rotate: rotate ?? this.rotate,
    );
  }
}
