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
  QRCodeDartScanResolutionPreset _resolutionPreset = QRCodeDartScanResolutionPreset.medium;
  bool _scanEnabled = false;
  bool get isLiveScan => state.value.typeScan == TypeScan.live && _scanEnabled;
  bool _scanInvertedQRCode = false;
  ImageDecodeOrientation _imageDecodeOrientation = ImageDecodeOrientation.original;
  Duration _intervalScan = const Duration(seconds: 1);
  _LastScan? _lastScan;
  DeviceOrientation? _lockCaptureOrientation;
  ValueChanged<String>? _onCameraError;
  int? _fps;
  int? _videoBitrate;

  Future<void> config(
    List<BarcodeFormat> formats,
    TypeCamera typeCamera,
    TypeScan typeScan,
    bool scanInvertedQRCode,
    ImageDecodeOrientation imageDecodeOrientation,
    QRCodeDartScanResolutionPreset resolutionPreset,
    Duration intervalScan,
    OnResultInterceptorCallback? onResultInterceptor,
    DeviceOrientation? lockCaptureOrientation,
    ValueChanged<String>? onCameraError,
    int? fps,
    int? videoBitrate,
  ) async {
    _fps = fps;
    _videoBitrate = videoBitrate;
    _scanInvertedQRCode = scanInvertedQRCode;
    _imageDecodeOrientation = imageDecodeOrientation;
    _onCameraError = onCameraError;
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
      fps: _fps,
      videoBitrate: _videoBitrate,
    );

    try {
      await cameraController?.initialize();
    } catch (e) {
      if (e is CameraException) {
        _onCameraError?.call(e.code);
      }
      return;
    }

    if (_lockCaptureOrientation != null) {
      cameraController?.lockCaptureOrientation(_lockCaptureOrientation!);
    }

    await startScan();

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
      imageDecodeOrientation: _imageDecodeOrientation,
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
      await startScan();
    } else {
      await stopScan();
    }
    state.value = state.value.copyWith(
      processing: false,
      typeScan: type,
    );
  }

  Future<void> stopScan() async {
    if (isLiveScan) {
      await stopImageStream();
      _scanEnabled = false;
    }
  }

  Future<void> startScan() async {
    if (state.value.typeScan == TypeScan.live && !_scanEnabled) {
      await cameraController?.startImageStream(_imageStream);
      _scanEnabled = true;
    }
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
    state.value = const PreviewState();
    await _disposeController();
    await _initController(typeCamera);
  }

  Future<void> dispose() async {
    _codeDartScanDecoder?.dispose();
    state.value = const PreviewState();
    return _disposeController();
  }

  Future<void> _disposeController() async {
    if (state.value.typeScan == TypeScan.live) {
      await stopImageStream();
    }
    return cameraController?.dispose();
  }

  Future<void> stopImageStream() async {
    if (cameraController?.value.isStreamingImages == true) {
      await cameraController?.stopImageStream();
    }
  }

  Future<void> setFlashAuto() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    try {
      await cameraController?.setFlashMode(
        FlashMode.auto,
      );
    } catch (e) {
      debugPrint('Error setFlashAuto flash: $e');
    }
  }

  Future<void> setFlash(bool on) async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    try {
      await cameraController?.setFlashMode(
        on ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint('Error setFlash = $on flash: $e');
    }
  }

  bool get isFlashOn => cameraController!.value.flashMode == FlashMode.torch;

  Future<void> toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    await setFlash(!isFlashOn);
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
