import 'package:flutter/services.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class QRCodeDartScanConfig {
  final List<BarcodeFormat> formats;
  final TypeCamera typeCamera;
  final TypeScan typeScan;
  final ImageDecodeOrientation imageDecodeOrientation;
  final QRCodeDartScanResolutionPreset resolutionPreset;
  final Duration intervalScan;
  final OnResultInterceptorCallback? onResultInterceptor;
  final DeviceOrientation? lockCaptureOrientation;
  final ValueChanged<String>? onCameraError;
  final int? fps;
  final int? videoBitrate;
  final CroppingStrategy? croppingStrategy;

  QRCodeDartScanConfig({
    required this.formats,
    required this.typeCamera,
    required this.typeScan,
    this.imageDecodeOrientation = ImageDecodeOrientation.original,
    this.resolutionPreset = QRCodeDartScanResolutionPreset.medium,
    this.intervalScan = const Duration(seconds: 1),
    this.onResultInterceptor,
    this.lockCaptureOrientation,
    this.onCameraError,
    this.fps,
    this.videoBitrate,
    this.croppingStrategy,
  });
}
