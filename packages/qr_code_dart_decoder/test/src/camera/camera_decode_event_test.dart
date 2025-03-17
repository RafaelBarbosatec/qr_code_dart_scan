import 'dart:typed_data';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:test/test.dart';

void main() {
  final testYuv420Planes = [
    Yuv420Planes(
      width: 100,
      height: 100,
      bytes: Uint8List.fromList(List.filled(100 * 100, 0)),
      bytesPerRow: 100,
    ),
  ];

  group('CameraDecodeEvent', () {
    test('constructor creates instance with correct values', () {
      final event = CameraDecodeEvent(
        yuv420Planes: testYuv420Planes,
        invert: true,
        rotation: RotationType.counterClockwise,
        formats: [BarcodeFormat.qrCode],
      );

      expect(event.yuv420Planes, equals(testYuv420Planes));
      expect(event.invert, isTrue);
      expect(event.rotation, equals(RotationType.counterClockwise));
      expect(event.formats, equals([BarcodeFormat.qrCode]));
    });

    test('constructor uses default values when not specified', () {
      final event = CameraDecodeEvent(yuv420Planes: testYuv420Planes);

      expect(event.yuv420Planes, equals(testYuv420Planes));
      expect(event.invert, isFalse);
      expect(event.rotation, isNull);
      expect(event.formats, isEmpty);
    });

    test('copyWith returns new instance with updated values', () {
      final event = CameraDecodeEvent(yuv420Planes: testYuv420Planes);
      final newYuv420Planes = [
        Yuv420Planes(
          width: 200,
          height: 200,
          bytes: Uint8List.fromList(List.filled(200 * 200, 0)),
          bytesPerRow: 200,
        ),
      ];

      final updatedEvent = event.copyWith(
        invert: true,
        rotationType: RotationType.counterClockwise,
        yuv420Planes: newYuv420Planes,
        formats: [BarcodeFormat.qrCode, BarcodeFormat.aztec],
      );

      expect(updatedEvent.invert, isTrue);
      expect(updatedEvent.rotation, equals(RotationType.counterClockwise));
      expect(updatedEvent.yuv420Planes, equals(newYuv420Planes));
      expect(updatedEvent.formats, equals([BarcodeFormat.qrCode, BarcodeFormat.aztec]));

      // Original should remain unchanged
      expect(event.invert, isFalse);
      expect(event.rotation, isNull);
      expect(event.yuv420Planes, equals(testYuv420Planes));
      expect(event.formats, isEmpty);
    });

    test('copyWith keeps original values when parameters are null', () {
      final event = CameraDecodeEvent(
        yuv420Planes: testYuv420Planes,
        invert: true,
        rotation: RotationType.counterClockwise,
        formats: [BarcodeFormat.qrCode],
      );

      final updatedEvent = event.copyWith();

      expect(updatedEvent.invert, isTrue);
      expect(updatedEvent.rotation, equals(RotationType.counterClockwise));
      expect(updatedEvent.yuv420Planes, equals(testYuv420Planes));
      expect(updatedEvent.formats, equals([BarcodeFormat.qrCode]));
    });

    test('toMap converts instance to map correctly', () {
      final event = CameraDecodeEvent(
        yuv420Planes: testYuv420Planes,
        invert: true,
        rotation: RotationType.counterClockwise,
        cropRect: const CropRect.fromLTRB(10, 10, 10, 10),
      );

      final map = event.toMap();

      expect(map['invert'], isTrue);
      expect(map['rotation'], equals(RotationType.counterClockwise.name));
      expect(map['yuv420Planes'], isA<List>());
      expect(map['yuv420Planes'].length, equals(1));
      expect(map['cropRect'], isA<Map>());
      expect(map['cropRect']['left'], equals(10));
      expect(map['cropRect']['top'], equals(10));
      expect(map['cropRect']['right'], equals(10));
      expect(map['cropRect']['bottom'], equals(10));
    });

    test('fromMap creates instance from map correctly', () {
      final originalEvent = CameraDecodeEvent(
        yuv420Planes: testYuv420Planes,
        invert: true,
        rotation: RotationType.counterClockwise,
      );

      final map = originalEvent.toMap();
      final recreatedEvent = CameraDecodeEvent.fromMap(map);

      expect(recreatedEvent.invert, isTrue);
      expect(recreatedEvent.rotation, equals(RotationType.counterClockwise));
      expect(recreatedEvent.yuv420Planes.length, equals(1));

      // Note: formats is missing in fromMap implementation
      expect(recreatedEvent.formats, isEmpty);
    });
  });
}
