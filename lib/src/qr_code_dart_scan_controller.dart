import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/util/extensions.dart';

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

class PreviewState extends Equatable {
  final Result? result;
  final bool processing;
  final bool initialized;
  final TypeScan typeScan;
  final TypeCamera typeCamera;
  final DeviceOrientation? lockCaptureOrientation;

  const PreviewState({
    this.result,
    this.processing = false,
    this.initialized = false,
    this.typeScan = TypeScan.live,
    this.typeCamera = TypeCamera.back,
    this.lockCaptureOrientation,
  });

  PreviewState copyWith({
    Result? result,
    bool? processing,
    bool? initialized,
    TypeScan? typeScan,
    TypeCamera? typeCamera,
  }) {
    return PreviewState(
      result: result,
      processing: processing ?? this.processing,
      initialized: initialized ?? this.initialized,
      typeScan: typeScan ?? this.typeScan,
      typeCamera: typeCamera ?? this.typeCamera,
    );
  }

  @override
  List<Object?> get props => [
        result,
        processing,
        initialized,
        typeScan,
        typeCamera,
      ];
}

class QRCodeDartScanController {
  final ValueNotifier<PreviewState> state = ValueNotifier(const PreviewState());
  CameraController? cameraController;
  QRCodeDartScanDecoder? _codeDartScanDecoder;
  QRCodeDartScanResolutionPreset _resolutionPreset =
      QRCodeDartScanResolutionPreset.medium;
  bool scanEnabled = true;
  bool _scanInvertedQRCode = false;
  Duration _intervalScan = const Duration(seconds: 1);
  _LastScan? _lastScan;
  DeviceOrientation? _lockCaptureOrientation;

  Future<void> config(
    List<BarcodeFormat> formats,
    TypeCamera typeCamera,
    TypeScan typeScan,
    bool scanInvertedQRCode,
    QRCodeDartScanResolutionPreset resolutionPreset,
    Duration intervalScan,
    OnResultInterceptorCallback? onResultInterceptor,
    DeviceOrientation? lockCaptureOrientation,
  ) async {
    _scanInvertedQRCode = scanInvertedQRCode;
    state.value = state.value.copyWith(
      typeScan: typeScan,
    );
    _intervalScan = intervalScan;
    _codeDartScanDecoder = QRCodeDartScanDecoder(
      formats: formats,
      usePoolIsolate: true,
    );
    _resolutionPreset = resolutionPreset;
    _lastScan = _LastScan(
      date: DateTime.now()
        ..subtract(
          const Duration(days: 1),
        ),
      onResultInterceptor: onResultInterceptor,
    );
    if (lockCaptureOrientation != null) {
      _lockCaptureOrientation = lockCaptureOrientation;
    }
    await _initController(typeCamera);
  }

  Future<void> _initController(TypeCamera typeCamera) async {
    state.value = state.value.copyWith(
      initialized: false,
      typeCamera: typeCamera,
    );
    final camera = await _getCamera(typeCamera);
    cameraController = CameraController(
      camera,
      _resolutionPreset.toResolutionPreset(),
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await cameraController?.initialize();

    if (_lockCaptureOrientation != null) {
      cameraController?.lockCaptureOrientation(_lockCaptureOrientation!);
    }

    if (state.value.typeScan == TypeScan.live) {
      cameraController?.startImageStream(_imageStream);
    }
    state.value = state.value.copyWith(
      initialized: true,
    );
  }

  Future<CameraDescription> _getCamera(TypeCamera typeCamera) async {
    final CameraLensDirection lensDirection;
    switch (typeCamera) {
      case TypeCamera.back:
        lensDirection = CameraLensDirection.back;
        break;
      case TypeCamera.front:
        lensDirection = CameraLensDirection.front;
        break;
    }

    final cameras = await availableCameras();
    return cameras.firstWhere(
      (camera) => camera.lensDirection == lensDirection,
      orElse: () => cameras.first,
    );
  }

  void _imageStream(CameraImage image) async {
    if (!scanEnabled) return;
    if (state.value.processing) return;
    state.value = state.value.copyWith(
      processing: true,
    );
    _processImage(image);
  }

  void _processImage(CameraImage image) async {
    final decoded = await _codeDartScanDecoder?.decodeCameraImage(
      image,
      scanInverted: _scanInvertedQRCode,
    );

    if (decoded != null) {
      if (_lastScan?.checkTime(_intervalScan, decoded) == true) {
        _lastScan = _lastScan!.updateResult(decoded);
        state.value = state.value.copyWith(
          result: decoded,
        );
      }
    }
    state.value = state.value.copyWith(
      processing: false,
    );
  }

  Future<void> changeTypeScan(TypeScan type) async {
    if (state.value.typeScan == type) {
      return;
    }
    if (type == TypeScan.live) {
      cameraController?.startImageStream(_imageStream);
    } else {
      await cameraController?.stopImageStream();
    }
    state.value = state.value.copyWith(
      processing: false,
      typeScan: type,
    );
  }

  Future<void> takePictureAndDecode() async {
    if (state.value.processing) return;
    state.value = state.value.copyWith(
      processing: true,
    );
    final xFile = await cameraController?.takePicture();

    if (xFile != null) {
      final decoded = await _codeDartScanDecoder?.decodeFile(
        xFile,
        scanInverted: _scanInvertedQRCode,
      );
      state.value = state.value.copyWith(
        result: decoded,
      );
    }

    state.value = state.value.copyWith(
      processing: false,
    );
  }

  Future<void> changeCamera(TypeCamera typeCamera) async {
    await _disposeController();
    await _initController(typeCamera);
  }

  Future<void> dispose() async {
    _codeDartScanDecoder?.dispose();
    return _disposeController();
  }

  Future<void> _disposeController() async {
    if (state.value.typeScan == TypeScan.live) {
      await cameraController?.stopImageStream();
    }
    return cameraController?.dispose();
  }
}

class _LastScan {
  final Result? data;
  final DateTime date;
  final OnResultInterceptorCallback? onResultInterceptor;

  _LastScan({
    this.data,
    required this.date,
    this.onResultInterceptor,
  });

  _LastScan updateResult(Result data) {
    return _LastScan(
      data: data,
      date: DateTime.now(),
      onResultInterceptor: onResultInterceptor,
    );
  }

  bool checkTime(Duration intervalScan, Result newResult) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMilliseconds < intervalScan.inMilliseconds) {
      return false;
    }
    return onResultInterceptor?.call(data, newResult) ?? true;
  }
}
