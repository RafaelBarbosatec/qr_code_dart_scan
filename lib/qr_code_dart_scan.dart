library qr_code_dart_scan;

export 'package:camera/camera.dart';
export 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart' show CroppingStrategy;
export 'package:zxing_lib/zxing.dart' show BarcodeFormat, Result;

export 'src/decoder/qr_code_dart_scan_decoder.dart';
export 'src/qr_code_dart_scan_controller.dart';
export 'src/qr_code_dart_scan_view.dart';
export 'src/util/image_decode_orientation.dart';
export 'src/util/qr_code_dart_scan_resolution_preset.dart';
