import 'dart:math';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:qr_code_dart_decoder/src/models/zxing_mapping.dart';
import 'package:test/test.dart';
import 'package:zxing_lib/zxing.dart' as zxing;

void main() {
  group('zxing -> ScanResult mapping', () {
    test('maps text, format, bytes, timestamp and corners', () {
      final decoded = zxing.Result(
        'hello',
        [1, 2, 3],
        [zxing.ResultPoint(10, 20), zxing.ResultPoint(30, 40)],
        zxing.BarcodeFormat.qrCode,
        1700000000000,
      );

      final result = decoded.toScanResult!;

      expect(result.text, 'hello');
      expect(result.format, BarcodeFormat.qrCode);
      expect(result.rawBytes, [1, 2, 3]);
      expect(
        result.timestamp,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(
        result.corners,
        const [Point<double>(10, 20), Point<double>(30, 40)],
      );
    });

    test('drops null points instead of exposing a nullable list', () {
      final decoded = zxing.Result(
        'hello',
        null,
        [zxing.ResultPoint(1, 2), null],
        zxing.BarcodeFormat.ean13,
      );

      final result = decoded.toScanResult!;

      expect(result.rawBytes, isNull);
      expect(result.corners, const [Point<double>(1, 2)]);
    });

    test('no corners becomes an empty list, never null', () {
      final decoded = zxing.Result(
        'hello',
        null,
        null,
        zxing.BarcodeFormat.code128,
      );

      expect(decoded.toScanResult!.corners, isEmpty);
    });

    test('a format the package does not expose maps to null', () {
      final decoded = zxing.Result(
        'hello',
        null,
        null,
        zxing.BarcodeFormat.upcA,
      );

      expect(decoded.toScanResult, isNull);
    });

    test('every public BarcodeFormat round-trips through zxing', () {
      for (final format in BarcodeFormat.values) {
        expect(format.toZxing.toScanFormat, format, reason: '$format');
      }
    });
  });

  group('ScanResult', () {
    test('keeps identity equality so repeated scans still notify', () {
      final a = ScanResult(
        text: 'same',
        format: BarcodeFormat.qrCode,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final b = ScanResult(
        text: 'same',
        format: BarcodeFormat.qrCode,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(a, isNot(equals(b)));
      expect(a, equals(a));
    });

    test('copyWith replaces corners only', () {
      final result = ScanResult(
        text: 'x',
        format: BarcodeFormat.aztec,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );

      final moved = result.copyWith(corners: const [Point<double>(1, 1)]);

      expect(moved.text, 'x');
      expect(moved.format, BarcodeFormat.aztec);
      expect(moved.corners, const [Point<double>(1, 1)]);
    });
  });
}
