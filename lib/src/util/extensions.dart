import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:qr_code_dart_scan/src/util/qr_code_dart_scan_resolution_preset.dart';

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
/// on 12/08/21
extension QrCodeDartScanResolutionPresetExtension on QRCodeDartScanResolutionPreset {
  ResolutionPreset toResolutionPreset() {
    switch (this) {
      case QRCodeDartScanResolutionPreset.low:
        return ResolutionPreset.low;
      case QRCodeDartScanResolutionPreset.medium:
        return ResolutionPreset.medium;
      case QRCodeDartScanResolutionPreset.high:
        return ResolutionPreset.high;
      case QRCodeDartScanResolutionPreset.veryHigh:
        return ResolutionPreset.veryHigh;
      case QRCodeDartScanResolutionPreset.ultraHigh:
        return ResolutionPreset.ultraHigh;
      case QRCodeDartScanResolutionPreset.max:
        return ResolutionPreset.max;
    }
  }
}

extension StateExt on State {
  void postFrame(VoidCallback execute) {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        execute();
      }
    });
  }
}
