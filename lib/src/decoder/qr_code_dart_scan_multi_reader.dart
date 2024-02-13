import 'package:flutter/foundation.dart';
import 'package:zxing_lib/aztec.dart';
import 'package:zxing_lib/datamatrix.dart';
import 'package:zxing_lib/maxicode.dart';
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/pdf417.dart';
import 'package:zxing_lib/qrcode.dart';
// ignore: implementation_imports
import 'package:zxing_lib/src/result.dart' as other_result;
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
/// on 16/08/21
class QRCodeDartScanMultiReader {
  final List<BarcodeFormat> formats;

  final List<Reader> _readers = [];

  QRCodeDartScanMultiReader(this.formats) {
    for (var format in formats) {
      switch (format) {
        case BarcodeFormat.aztec:
          _readers.add(AztecReader());
          break;
        case BarcodeFormat.codabar:
          _readers.add(CodaBarReader());
          break;
        case BarcodeFormat.code39:
          _readers.add(Code39Reader());
          break;
        case BarcodeFormat.code93:
          _readers.add(Code93Reader());
          break;
        case BarcodeFormat.code128:
          _readers.add(Code128Reader());
          break;
        case BarcodeFormat.dataMatrix:
          _readers.add(DataMatrixReader());
          break;
        case BarcodeFormat.ean8:
          _readers.add(EAN8Reader());
          break;
        case BarcodeFormat.ean13:
          _readers.add(EAN13Reader());
          break;
        case BarcodeFormat.itf:
          _readers.add(ITFReader());
          break;
        case BarcodeFormat.maxicode:
          _readers.add(MaxiCodeReader());
          break;
        case BarcodeFormat.pdf417:
          _readers.add(PDF417Reader());
          break;
        case BarcodeFormat.qrCode:
          _readers.add(QRCodeReader());
          break;
        case BarcodeFormat.rss14:
          _readers.add(RSS14Reader());
          break;
        case BarcodeFormat.rssExpanded:
          _readers.add(RSSExpandedReader());
          break;
        default:
      }
    }
  }

  other_result.Result? decode(BinaryBitmap image) {
    for (final reader in _readers) {
      try {
        return reader.decode(image);
        // ignore: empty_catches
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
    return null;
  }
}
