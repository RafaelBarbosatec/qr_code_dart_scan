// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:zxing_lib/zxing.dart';

class CameraDecodeEvent {
  final bool invert;
  final bool rotate;
  final List<Yuv420Planes> yuv420Planes;
  final List<BarcodeFormat> formats;

  CameraDecodeEvent({
    required this.yuv420Planes,
    this.invert = false,
    this.rotate = false,
    this.formats = const [],
  });

  CameraDecodeEvent copyWith({
    bool? invert,
    bool? rotate,
    List<Yuv420Planes>? yuv420Planes,
    List<BarcodeFormat>? formats,
  }) {
    return CameraDecodeEvent(
      invert: invert ?? this.invert,
      rotate: rotate ?? this.rotate,
      yuv420Planes: yuv420Planes ?? this.yuv420Planes,
      formats: formats ?? this.formats,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'invert': invert,
      'rotate': rotate,
      'yuv420Planes': yuv420Planes.map((e) => e.toMap()).toList(),
      'formats': formats.map((e) => e.name).toList(),
    };
  }

  factory CameraDecodeEvent.fromMap(Map<String, dynamic> map) {
    return CameraDecodeEvent(
      invert: map['invert'] as bool,
      rotate: map['rotate'] as bool,
      yuv420Planes: (map['yuv420Planes'] as List)
          .map((e) => Yuv420Planes.fromMap((e as Map).cast()))
          .toList(),
      formats: (map['formats'] as List).map((e) => BarcodeFormat.values.byName(e)).toList(),
    );
  }
}
