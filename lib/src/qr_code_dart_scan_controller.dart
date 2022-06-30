import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:qr_code_dart_scan/src/qr_code_dart_scan_view.dart';

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

abstract class DartScanInterface {
  TypeScan typeScan = TypeScan.live;
  Future<void> takePictureAndDecode();
  Future<void> changeTypeScan(TypeScan type);
}

class QRCodeDartScanController {
  bool _scanEnabled = true;
  CameraController? _cameraController;
  DartScanInterface? _dartScanInterface;

  void configure(
    CameraController cameraController,
    DartScanInterface dartScanInterface,
  ) {
    _cameraController = cameraController;
    _dartScanInterface = dartScanInterface;
  }

  Future<void>? setFlashMode(FlashMode mode) {
    return _cameraController?.setFlashMode(mode);
  }

  Future<void>? setZoomLevel(double zoom) {
    return _cameraController?.setZoomLevel(zoom);
  }

  Future<void>? setFocusMode(FocusMode mode) {
    return _cameraController?.setFocusMode(mode);
  }

  Future<void>? setFocusPoint(Offset? point) {
    return _cameraController?.setFocusPoint(point);
  }

  Future<double>? getExposureOffsetStepSize() {
    return _cameraController?.getExposureOffsetStepSize();
  }

  Future<double>? getMaxExposureOffset() {
    return _cameraController?.getMaxExposureOffset();
  }

  Future<double>? getMaxZoomLevel() {
    return _cameraController?.getMaxZoomLevel();
  }

  Future<double>? getMinExposureOffset() {
    return _cameraController?.getMinExposureOffset();
  }

  Future<double>? getMinZoomLevel() {
    return _cameraController?.getMinZoomLevel();
  }

  void setScanEnabled(bool enable) {
    _scanEnabled = enable;
  }

  Future<void>? takePictureAndDecode() {
    return _dartScanInterface?.takePictureAndDecode();
  }

  Future<void>? changeTypeScan(TypeScan type) {
    return _dartScanInterface?.changeTypeScan(type);
  }

  bool get scanEnabled => _scanEnabled;
  TypeScan? get typeScan => _dartScanInterface?.typeScan;
}
