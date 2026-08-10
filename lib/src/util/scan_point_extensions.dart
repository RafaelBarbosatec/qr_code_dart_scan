import 'dart:math';
import 'dart:ui';

/// Bridges the decoder's pure-Dart points to Flutter's [Offset].
///
/// `qr_code_dart_decoder` has no Flutter dependency, so `ScanResult.corners`
/// is a list of `dart:math` points. Use these to paint them.
extension ScanPointOffset on Point<double> {
  Offset get toOffset => Offset(x, y);
}

extension ScanPointListOffset on List<Point<double>> {
  List<Offset> get toOffsets => map((point) => point.toOffset).toList();
}
