// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:qr_code_dart_decoder/src/util/crop_rect.dart';
import 'package:qr_code_dart_decoder/src/util/rotation_type.dart';
import 'package:zxing_lib/zxing.dart';

class CameraDecodeEvent {
  final bool invert;
  final RotationType? rotation;
  final List<Yuv420Planes> yuv420Planes;
  final List<BarcodeFormat> formats;
  final CropRect? cropRect;

  CameraDecodeEvent({
    required this.yuv420Planes,
    this.invert = false,
    this.rotation,
    this.formats = const [],
    this.cropRect,
  });

  CameraDecodeEvent copyWith({
    bool? invert,
    RotationType? rotationType,
    List<Yuv420Planes>? yuv420Planes,
    List<BarcodeFormat>? formats,
    CropRect? cropRect,
  }) {
    return CameraDecodeEvent(
      invert: invert ?? this.invert,
      rotation: rotationType ?? rotation,
      yuv420Planes: yuv420Planes ?? this.yuv420Planes,
      formats: formats ?? this.formats,
      cropRect: cropRect ?? this.cropRect,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'invert': invert,
      'rotation': rotation?.name,
      'yuv420Planes': yuv420Planes.map((e) => e.toMap()).toList(),
      'formats': formats.map((e) => e.name).toList(),
      'cropRect': cropRect?.toMap(),
    };
  }

  factory CameraDecodeEvent.fromMap(Map<String, dynamic> map) {
    return CameraDecodeEvent(
      invert: map['invert'] as bool,
      rotation: map['rotation'] != null ? RotationType.values.byName(map['rotation']) : null,
      yuv420Planes: (map['yuv420Planes'] as List)
          .map((e) => Yuv420Planes.fromMap((e as Map).cast()))
          .toList(),
      formats: (map['formats'] as List).map((e) => BarcodeFormat.values.byName(e)).toList(),
      cropRect: map['cropRect'] != null ? CropRect.fromMap((map['cropRect'] as Map).cast()) : null,
    );
  }
}
