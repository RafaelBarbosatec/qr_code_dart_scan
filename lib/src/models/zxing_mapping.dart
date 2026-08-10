import 'dart:typed_data';
import 'dart:ui';

import 'package:zxing_lib/zxing.dart' as zxing;

import 'barcode_format.dart';
import 'scan_result.dart';

/// Conversions between the package's public models and `zxing_lib`.
///
/// This file is deliberately not exported: `zxing_lib` is an implementation
/// detail and must not appear in the public API.

extension BarcodeFormatMapping on BarcodeFormat {
  zxing.BarcodeFormat get toZxing {
    switch (this) {
      case BarcodeFormat.aztec:
        return zxing.BarcodeFormat.aztec;
      case BarcodeFormat.code39:
        return zxing.BarcodeFormat.code39;
      case BarcodeFormat.code93:
        return zxing.BarcodeFormat.code93;
      case BarcodeFormat.code128:
        return zxing.BarcodeFormat.code128;
      case BarcodeFormat.dataMatrix:
        return zxing.BarcodeFormat.dataMatrix;
      case BarcodeFormat.ean8:
        return zxing.BarcodeFormat.ean8;
      case BarcodeFormat.ean13:
        return zxing.BarcodeFormat.ean13;
      case BarcodeFormat.itf:
        return zxing.BarcodeFormat.itf;
      case BarcodeFormat.pdf417:
        return zxing.BarcodeFormat.pdf417;
      case BarcodeFormat.qrCode:
        return zxing.BarcodeFormat.qrCode;
    }
  }
}

extension BarcodeFormatListMapping on List<BarcodeFormat> {
  List<zxing.BarcodeFormat> get toZxing =>
      map((format) => format.toZxing).toList();
}

extension ZxingBarcodeFormatMapping on zxing.BarcodeFormat {
  /// `null` for formats this package does not expose.
  ///
  /// Decoding is always restricted to the requested formats, so in practice
  /// this never returns `null`; it exists so an unexpected value degrades to
  /// "no result" instead of throwing on a camera frame.
  BarcodeFormat? get toScanFormat {
    switch (this) {
      case zxing.BarcodeFormat.aztec:
        return BarcodeFormat.aztec;
      case zxing.BarcodeFormat.code39:
        return BarcodeFormat.code39;
      case zxing.BarcodeFormat.code93:
        return BarcodeFormat.code93;
      case zxing.BarcodeFormat.code128:
        return BarcodeFormat.code128;
      case zxing.BarcodeFormat.dataMatrix:
        return BarcodeFormat.dataMatrix;
      case zxing.BarcodeFormat.ean8:
        return BarcodeFormat.ean8;
      case zxing.BarcodeFormat.ean13:
        return BarcodeFormat.ean13;
      case zxing.BarcodeFormat.itf:
        return BarcodeFormat.itf;
      case zxing.BarcodeFormat.pdf417:
        return BarcodeFormat.pdf417;
      case zxing.BarcodeFormat.qrCode:
        return BarcodeFormat.qrCode;
      case zxing.BarcodeFormat.codabar:
      case zxing.BarcodeFormat.maxicode:
      case zxing.BarcodeFormat.rss14:
      case zxing.BarcodeFormat.rssExpanded:
      case zxing.BarcodeFormat.upcA:
      case zxing.BarcodeFormat.upcE:
      case zxing.BarcodeFormat.upcEanExtension:
        return null;
    }
  }
}

extension ZxingResultMapping on zxing.Result {
  /// `null` when the decoded format is not exposed by this package.
  ScanResult? get toScanResult {
    final format = barcodeFormat.toScanFormat;
    if (format == null) return null;

    final bytes = rawBytes;
    return ScanResult(
      text: text,
      format: format,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      rawBytes: bytes == null ? null : Uint8List.fromList(bytes),
      corners: _cornersOf(resultPoints),
    );
  }

  static List<Offset> _cornersOf(List<zxing.ResultPoint?>? points) {
    if (points == null || points.isEmpty) return const <Offset>[];
    final corners = <Offset>[];
    for (final point in points) {
      if (point == null) continue;
      corners.add(Offset(point.x, point.y));
    }
    return corners;
  }
}
