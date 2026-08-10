import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

// The zxing -> ScanResult mapping itself lives in (and is tested by)
// `packages/qr_code_dart_decoder`. What matters here is the Flutter-side
// bridge and that the scanner API never mentions `zxing_lib`.
void main() {
  group('corners -> Offset bridge', () {
    test('toOffset maps x/y', () {
      expect(const Point<double>(10, 20).toOffset, const Offset(10, 20));
    });

    test('toOffsets keeps order', () {
      const corners = [Point<double>(1, 2), Point<double>(3, 4)];

      expect(corners.toOffsets, const [Offset(1, 2), Offset(3, 4)]);
    });

    test('an empty corner list maps to an empty offset list', () {
      expect(const <Point<double>>[].toOffsets, isEmpty);
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

  // Compile-time guard: this widget is built from the package barrel only.
  // If `zxing_lib` ever leaks back into the scanner API, these callbacks stop
  // type-checking without a `zxing_lib` import.
  testWidgets('the scanner API is expressible without zxing_lib', (_) async {
    QRCodeDartScanView(
      formats: const [BarcodeFormat.qrCode, BarcodeFormat.ean13],
      onCapture: (ScanResult result) {
        result.text;
        result.format;
        result.corners;
        result.rawBytes;
        result.timestamp;
      },
      onResultInterceptor: (ScanResult? oldResult, ScanResult newResult) {
        return oldResult?.text != newResult.text;
      },
    );
  });
}
