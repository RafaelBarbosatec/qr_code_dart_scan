import 'dart:math';
import 'dart:typed_data';

import 'barcode_format.dart';

/// The outcome of decoding a barcode.
///
/// This is the package's own type on purpose: nothing about the underlying
/// decoder leaks into the public API, so consuming apps never need a
/// dependency on `zxing_lib`.
class ScanResult {
  const ScanResult({
    required this.text,
    required this.format,
    required this.timestamp,
    this.rawBytes,
    this.corners = const <Point<double>>[],
  });

  /// Text encoded in the barcode.
  final String text;

  /// Format of the barcode that was decoded.
  final BarcodeFormat format;

  /// When the barcode was decoded.
  final DateTime timestamp;

  /// Raw bytes encoded by the barcode, when the format provides them.
  final Uint8List? rawBytes;

  /// Corners of the barcode in the decoded image coordinate space.
  ///
  /// When not empty this is the bounding quadrilateral of the barcode, in
  /// order: top-left, top-right, bottom-right, bottom-left.
  ///
  /// This package is pure Dart, so these are `dart:math` points; Flutter apps
  /// get `toOffset`/`toOffsets` from `package:qr_code_dart_scan`.
  ///
  /// Empty when the decoder did not report any point.
  final List<Point<double>> corners;

  ScanResult copyWith({
    String? text,
    BarcodeFormat? format,
    DateTime? timestamp,
    Uint8List? rawBytes,
    List<Point<double>>? corners,
  }) {
    return ScanResult(
      text: text ?? this.text,
      format: format ?? this.format,
      timestamp: timestamp ?? this.timestamp,
      rawBytes: rawBytes ?? this.rawBytes,
      corners: corners ?? this.corners,
    );
  }

  // Intentionally not a value type: identity equality is what makes every
  // decode notify listeners, even when the same barcode is read twice with
  // identical content. Use `onResultInterceptor` to deduplicate.

  @override
  String toString() => 'ScanResult(text: $text, format: $format)';
}
