import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/util/extensions.dart';

import 'util/qr_code_dart_scan_config.dart';

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
  final ScanResult? result;
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
    ScanResult? result,
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

/// Owns a single [CameraController] and keeps track of whether it was already
/// disposed.
///
/// [CameraController] exposes no public `isDisposed` flag and keeps
/// `value.isInitialized == true` after being disposed, so checking
/// `value.isInitialized` is not enough to know if it is safe to call
/// `startImageStream()`/`stopImageStream()` on it.
class _CameraSession {
  _CameraSession(this.controller);

  final CameraController controller;

  bool _disposed = false;
  bool _streaming = false;

  bool get isDisposed => _disposed;

  /// Safe to call platform methods on.
  bool get isUsable => !_disposed && controller.value.isInitialized;

  bool get isStreaming => _streaming && !_disposed;

  Future<void> startStream(void Function(CameraImage image) onImage) async {
    if (!isUsable || _streaming) return;
    await controller.startImageStream(onImage);
    _streaming = true;
  }

  Future<void> stopStream() async {
    if (!_streaming) return;
    _streaming = false;
    if (_disposed) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error stop image stream: $e');
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await stopStream();
    // Flag before awaiting dispose so any concurrent caller bails out.
    _disposed = true;
    try {
      await controller.dispose();
    } catch (e) {
      debugPrint('Error dispose camera controller: $e');
    }
  }
}

class QRCodeDartScanController {
  final ValueNotifier<PreviewState> state = ValueNotifier(const PreviewState());

  _CameraSession? _session;
  QRCodeDartScanDecoder? _codeDartScanDecoder;

  /// Whether the image stream is currently running.
  bool _scanEnabled = false;

  /// User intent: [stopScan] was called and [startScan] has not been called
  /// since.
  ///
  /// Unlike [_scanEnabled] this survives [dispose]/[config], so restarting the
  /// camera after an app background round trip restores the preview without
  /// silently resuming the decoding the user had paused.
  bool _scanPaused = false;

  bool get isLiveScan => state.value.typeScan == TypeScan.live && _scanEnabled;

  /// Whether scanning is paused by [stopScan].
  ///
  /// A paused controller still shows the camera preview (and restores it after
  /// the app is minimized and reopened), it just does not decode frames.
  bool get isScanPaused => _scanPaused;

  _LastScan? _lastScan;
  QRCodeDartScanConfig? _config;
  ScanResult? _lastResult;
  Timer? _imageStreamWatchdog;
  DateTime? _lastImageStreamCall;

  /// Bumped on every [config]/[changeCamera]/[dispose] call. Any async work
  /// started under an older generation must abort at its next await boundary
  /// instead of touching a camera that no longer belongs to it.
  int _generation = 0;

  /// Serializes camera setup/teardown so an init and a dispose can never be
  /// in flight at the same time.
  Future<void> _queue = Future<void>.value();

  /// The camera controller currently in use, or `null` when the camera is not
  /// running. Never returns a disposed instance.
  CameraController? get cameraController {
    final session = _session;
    if (session == null || session.isDisposed) return null;
    return session.controller;
  }

  /// Whether the camera is initialized and safe to interact with.
  bool get isInitialized => _session?.isUsable == true;

  void _enqueue(Future<void> Function() operation) {
    _queue = _queue.then((_) => operation()).catchError((Object error) {
      debugPrint('QRCodeDartScanController error: $error');
    });
  }

  /// Configures the controller and starts the camera.
  ///
  /// [keepScanPaused] preserves a previous [stopScan] across the call. It is
  /// used by [QRCodeDartScanView] when it re-arms the camera after an app
  /// lifecycle pause; a fresh setup resets the paused state.
  Future<void> config(
    QRCodeDartScanConfig config, {
    bool keepScanPaused = false,
  }) {
    final generation = ++_generation;
    _enqueue(() async {
      if (generation != _generation) return;
      if (!keepScanPaused) {
        _scanPaused = false;
      }
      _config = config;
      _lastResult = null;
      state.value = state.value.copyWith(
        typeScan: config.typeScan,
      );
      _codeDartScanDecoder?.dispose();
      _codeDartScanDecoder = QRCodeDartScanDecoder(
        formats: config.formats,
      );
      _lastScan = _LastScan(
        date: DateTime.now().subtract(
          const Duration(days: 1),
        ),
      );
      await _initController(config.typeCamera, generation);
    });
    return _queue;
  }

  Future<void> _initController(TypeCamera typeCamera, int generation) async {
    // Never leave a previous session behind: it would keep the native camera
    // busy and could later be reused as if it were alive.
    await _disposeSession();
    if (generation != _generation) return;

    final config = _config;
    if (config == null) return;

    state.value = state.value.copyWith(
      initialized: false,
      typeCamera: typeCamera,
    );

    final camera = await _getCamera(typeCamera);
    if (generation != _generation) return;
    if (camera == null) {
      config.onCameraError?.call('camera_not_found ($typeCamera)');
      return;
    }

    final session = _CameraSession(
      CameraController(
        camera,
        config.resolutionPreset.toResolutionPreset(),
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
        fps: config.fps,
        videoBitrate: config.videoBitrate,
      ),
    );

    try {
      await session.controller.initialize();
      if (generation != _generation) return await session.dispose();

      if (config.focusPoint != null) {
        await session.controller.setFocusMode(FocusMode.locked);
        await session.controller.setFocusPoint(config.focusPoint!);
        if (generation != _generation) return await session.dispose();
      }
      if (config.lockCaptureOrientation != null) {
        await session.controller.lockCaptureOrientation(
          config.lockCaptureOrientation!,
        );
        if (generation != _generation) return await session.dispose();
      }
    } catch (e) {
      await session.dispose();
      if (generation != _generation) return;
      config.onCameraError?.call(e is CameraException ? e.code : e.toString());
      return;
    }

    _session = session;

    await _startScan(session, generation);
    if (generation != _generation) return;

    state.value = state.value.copyWith(
      initialized: true,
    );
  }

  Future<CameraDescription?> _getCamera(TypeCamera typeCamera) async {
    final CameraLensDirection lensDirection;
    switch (typeCamera) {
      case TypeCamera.back:
        lensDirection = CameraLensDirection.back;
        break;
      case TypeCamera.front:
        lensDirection = CameraLensDirection.front;
        break;
    }

    try {
      final cameras = await availableCameras();
      return cameras.firstWhere(
        (camera) => camera.lensDirection == lensDirection,
      );
    } catch (e) {
      debugPrint('Error getting camera ($typeCamera): $e');
      return null;
    }
  }

  void _imageStream(CameraImage image) {
    // Frames already buffered by the platform can still arrive after we asked
    // the stream to stop.
    if (!_scanEnabled) return;
    _lastImageStreamCall = DateTime.now();
    if (state.value.processing) return;
    state.value = state.value.copyWith(
      processing: true,
    );
    _processImage(image, _generation);
  }

  Future<void> _processImage(CameraImage image, int generation) async {
    try {
      if (_lastScan?.checkTime(_config?.intervalScan) == true) {
        final decoded = await _codeDartScanDecoder?.decodeCameraImage(
          image,
          imageDecodeOrientation:
              _config?.imageDecodeOrientation ?? ImageDecodeOrientation.original,
          croppingStrategy: _config?.croppingStrategy,
        );
        if (generation != _generation) return;
        final result = decoded;
        if (result != null) {
          final canNotify = _config?.onResultInterceptor?.call(_lastResult, result) ?? true;
          if (canNotify == true) {
            _lastResult = result;
            state.value = state.value.copyWith(
              result: result,
            );
          }
        }
      }
    } catch (e) {
      // Log error but continue processing
      debugPrint('Error processing image: $e');
    } finally {
      // Sempre marca como não processando, desde que o controller ainda seja
      // o mesmo que iniciou o processamento.
      if (generation == _generation) {
        state.value = state.value.copyWith(
          processing: false,
        );
      }
    }
  }

  Future<void> changeTypeScan(TypeScan type) {
    _enqueue(() async {
      if (state.value.typeScan == type) return;
      // Set the state first: _startScan only starts when typeScan is live.
      state.value = state.value.copyWith(
        processing: false,
        typeScan: type,
      );
      if (type == TypeScan.live) {
        // Explicitly asking for live scan clears a previous stopScan().
        _scanPaused = false;
        final session = _session;
        if (session != null) {
          await _startScan(session, _generation);
        }
      } else {
        await _stopScan();
      }
    });
    return _queue;
  }

  /// Pauses the decoding while keeping the camera preview running.
  ///
  /// The paused state is remembered across an app background round trip: when
  /// the camera is restarted the preview comes back but the image stream is
  /// not started until [startScan] is called.
  Future<void> stopScan() {
    _scanPaused = true;
    _enqueue(_stopScan);
    return _queue;
  }

  Future<void> startScan() {
    _scanPaused = false;
    _enqueue(() async {
      final session = _session;
      if (session == null) return;
      await _startScan(session, _generation);
    });
    return _queue;
  }

  Future<void> _stopScan() async {
    _scanEnabled = false;
    _stopImageStreamWatchdog();
    await _session?.stopStream();
  }

  Future<void> _startScan(_CameraSession session, int generation) async {
    if (generation != _generation) return;
    if (!session.isUsable) return;
    // Restarting the camera (e.g. after the app was minimized) must not resume
    // a scan the user had explicitly paused.
    if (_scanPaused) return;
    if (state.value.typeScan != TypeScan.live || _scanEnabled) return;

    try {
      await session.startStream(_imageStream);
    } catch (e, stackTrace) {
      debugPrint('Error start image stream: $e');
      _config?.onCameraError?.call(e is CameraException ? e.code : e.toString());
      // Deliberately surfaced to the zone (and therefore to crash reporting)
      // instead of being swallowed: the disposal guards are supposed to make
      // this unreachable, so if it ever fires again we want to hear about it.
      // Reported out of band so it does not abort the setup flow.
      Zone.current.handleUncaughtError(e, stackTrace);
      return;
    }

    // The session may have been disposed while the stream was starting up.
    if (generation != _generation || session.isDisposed) {
      await session.stopStream();
      return;
    }

    _scanEnabled = true;
    _startImageStreamWatchdog();
  }

  Future<void> takePictureAndDecode() async {
    final session = _session;
    if (session == null || !session.isUsable) return;
    if (state.value.processing) return;

    final generation = _generation;
    state.value = state.value.copyWith(
      processing: true,
    );

    try {
      final xFile = await session.controller.takePicture();
      if (generation != _generation) return;

      final result = await _codeDartScanDecoder?.decodeFile(xFile);
      if (generation != _generation) return;

      _lastResult = result;
      state.value = state.value.copyWith(
        result: result,
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (generation == _generation) {
        _config?.onCameraError?.call(e is CameraException ? e.code : e.toString());
      }
    } finally {
      if (generation == _generation) {
        state.value = state.value.copyWith(
          processing: false,
        );
      }
    }
  }

  Future<void> changeCamera(TypeCamera typeCamera) {
    final generation = ++_generation;
    _enqueue(() async {
      if (generation != _generation) return;
      _lastResult = null;
      state.value = PreviewState(
        typeScan: state.value.typeScan,
        typeCamera: typeCamera,
      );
      await _initController(typeCamera, generation);
    });
    return _queue;
  }

  /// Releases the camera resources.
  ///
  /// The controller can be reused afterwards: calling [config] again re-arms
  /// it with a fresh camera session.
  Future<void> dispose() {
    // Bump synchronously so any init already in flight aborts at its next
    // await instead of running to completion against a dead camera.
    _generation++;
    _scanEnabled = false;
    _stopImageStreamWatchdog();
    _enqueue(() async {
      _codeDartScanDecoder?.dispose();
      _codeDartScanDecoder = null;
      _lastResult = null;
      state.value = const PreviewState();
      await _disposeSession();
    });
    return _queue;
  }

  Future<void> _disposeSession() async {
    final session = _session;
    _session = null;
    _scanEnabled = false;
    _stopImageStreamWatchdog();
    await session?.dispose();
  }

  Future<void> setFlashAuto() async {
    final camera = cameraController;
    if (camera == null || !camera.value.isInitialized) {
      return;
    }
    try {
      await camera.setFlashMode(
        FlashMode.auto,
      );
    } catch (e) {
      debugPrint('Error setFlashAuto flash: $e');
    }
  }

  Future<void> setFlash(bool on) async {
    final camera = cameraController;
    if (camera == null || !camera.value.isInitialized) {
      return;
    }
    try {
      await camera.setFlashMode(
        on ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint('Error setFlash = $on flash: $e');
    }
  }

  bool get isFlashOn => cameraController?.value.flashMode == FlashMode.torch;

  Future<void> toggleFlash() async {
    final camera = cameraController;
    if (camera == null || !camera.value.isInitialized) {
      return;
    }
    await setFlash(!isFlashOn);
  }

  Future<void> setFocusPoint(Offset? point) async {
    final camera = cameraController;
    if (camera == null || !camera.value.isInitialized) {
      return;
    }
    try {
      if (point == null) {
        await camera.setFocusMode(FocusMode.auto);
        return;
      }
      await camera.setFocusMode(FocusMode.locked);
      await camera.setFocusPoint(point);
    } catch (e) {
      debugPrint('Error setFocusPoint: $e');
    }
  }

  void _startImageStreamWatchdog() {
    _lastImageStreamCall = DateTime.now();
    _imageStreamWatchdog?.cancel();
    _imageStreamWatchdog = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (!_scanEnabled) {
          _stopImageStreamWatchdog();
          return;
        }
        final lastCall = _lastImageStreamCall;
        if (lastCall == null) return;

        final timeout = _config?.imageStreamTimeout;
        if (timeout == null) return;

        final now = DateTime.now();
        final timeSinceLastCall = now.difference(lastCall);
        // Se passou mais tempo que o timeout sem receber frames, considera como erro
        if (timeSinceLastCall.inMilliseconds > timeout.inMilliseconds) {
          final errorMessage =
              'image_stream_timeout: No frames received for ${timeSinceLastCall.inSeconds} seconds';
          debugPrint(errorMessage);
          _config?.onCameraError?.call(
            errorMessage,
          );
          _stopImageStreamWatchdog();
        }
      },
    );
  }

  void _stopImageStreamWatchdog() {
    _imageStreamWatchdog?.cancel();
    _imageStreamWatchdog = null;
    _lastImageStreamCall = null;
  }
}

class _LastScan {
  DateTime date;

  _LastScan({
    required this.date,
  });

  bool checkTime(Duration? intervalScan) {
    if (intervalScan == null) return false;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMilliseconds < intervalScan.inMilliseconds) {
      return false;
    }
    date = DateTime.now();
    return true;
  }
}
