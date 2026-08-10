import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart' show CroppingStrategy;
import 'package:qr_code_dart_scan/src/models/barcode_format.dart';
import 'package:qr_code_dart_scan/src/models/scan_result.dart';
import 'package:qr_code_dart_scan/src/qr_code_dart_scan_controller.dart';
import 'package:qr_code_dart_scan/src/util/extensions.dart';
import 'package:qr_code_dart_scan/src/util/image_decode_orientation.dart';
import 'package:qr_code_dart_scan/src/util/qr_code_dart_scan_resolution_preset.dart';

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

enum TypeCamera { back, front }

enum TypeScan { live, takePicture }

typedef TakePictureButtonBuilder = Widget Function(
  BuildContext context,
  QRCodeDartScanController controller,
  bool loading,
);

class QRCodeDartScanView extends StatefulWidget {
  final TypeCamera typeCamera;
  final TypeScan typeScan;
  final ValueChanged<ScanResult>? onCapture;

  /// Barcode formats to scan for. Defaults to every supported format.
  ///
  /// Narrowing this down makes decoding faster.
  final List<BarcodeFormat> formats;

  /// Controller to manage the QR code scanning functionality
  final QRCodeDartScanController? controller;

  /// Resolution preset for the camera preview
  final QRCodeDartScanResolutionPreset resolutionPreset;

  /// Optional child widget to overlay on top of the camera preview
  final Widget? child;

  /// Width of the camera preview
  final double? widthPreview;

  /// Height of the camera preview
  final double? heightPreview;

  /// Builder for customizing the take picture button
  final TakePictureButtonBuilder? takePictureButtonBuilder;

  /// Minimum duration between scans of the same QR code
  final Duration intervalScan;

  /// Callback to intercept and decide if the result should be returned
  final OnResultInterceptorCallback? onResultInterceptor;

  /// Forces a specific device orientation for capturing
  final DeviceOrientation? lockCaptureOrientation;

  /// Controls how the image is oriented during decoding
  final ImageDecodeOrientation imageDecodeOrientation;

  /// Callback when camera errors occur
  final ValueChanged<String>? onCameraError;

  /// Frames per second for the camera preview
  final int? fps;

  /// Video bitrate for the camera preview
  final int? videoBitrate;

  /// Strategy to crop the camera image before decoding
  final CroppingStrategy? croppingStrategy;

  /// Focus point for the camera preview
  final Offset? focusPoint;

  /// Timeout for the image stream
  final Duration imageStreamTimeout;

  const QRCodeDartScanView({
    Key? key,
    this.typeCamera = TypeCamera.back,
    this.typeScan = TypeScan.live,
    this.onCapture,
    this.resolutionPreset = QRCodeDartScanResolutionPreset.medium,
    this.controller,
    this.formats = BarcodeFormat.values,
    this.child,
    this.takePictureButtonBuilder,
    this.widthPreview,
    this.heightPreview,
    this.intervalScan = const Duration(milliseconds: 500),
    this.onResultInterceptor,
    this.lockCaptureOrientation = DeviceOrientation.portraitUp,
    this.imageDecodeOrientation = ImageDecodeOrientation.original,
    this.onCameraError,
    this.fps,
    this.videoBitrate,
    this.croppingStrategy,
    this.focusPoint,
    this.imageStreamTimeout = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  QRCodeDartScanViewState createState() => QRCodeDartScanViewState();
}

class QRCodeDartScanViewState extends State<QRCodeDartScanView>
    with WidgetsBindingObserver {
  late final QRCodeDartScanController controller;
  bool initialized = false;

  /// Whether the camera *should* be running. Kept separate from [initialized]
  /// (which only reflects the controller state) so that a start/stop pair that
  /// happens faster than the async camera setup does not leave the camera on.
  bool _cameraRunning = false;

  /// Whether the camera has yet to be started for the first time by this state.
  bool _firstStart = true;

  Key _cameraKey = UniqueKey();
  double _scale = 1.0;
  Size _previewSize = Size.zero;
  Size _cameraSize = Size.zero;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      startCamera();
    } else if (state == AppLifecycleState.inactive) {
      stopCamera();
    }
  }

  void stopCamera() {
    if (!_cameraRunning) {
      return;
    }
    _cameraRunning = false;
    if (mounted) {
      setState(() {
        initialized = false;
      });
    } else {
      initialized = false;
    }
    controller.dispose();
  }

  void startCamera() {
    if (_cameraRunning) {
      return;
    }
    _cameraRunning = true;
    _initController();
  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? QRCodeDartScanController();
    controller.state.addListener(_onStateListener);
    WidgetsBinding.instance.addObserver(this);
    startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.state.removeListener(_onStateListener);
    _cameraRunning = false;
    initialized = false;
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: initialized ? _getCameraWidget(context) : widget.child,
    );
  }

  Future<void> _initController() async {
    // The widget may have been unmounted (or paused again) while the previous
    // teardown was still running.
    if (!mounted || !_cameraRunning) return;
    // A fresh mount starts a new scanning session, so a `stopScan()` left over
    // on an app-owned controller must not survive it. Later restarts (app
    // lifecycle, startCamera/stopCamera) do preserve it.
    final keepScanPaused = !_firstStart;
    _firstStart = false;
    try {
      await controller.config(
        QRCodeDartScanConfig(
          formats: widget.formats,
          typeCamera: widget.typeCamera,
          typeScan: widget.typeScan,
          imageDecodeOrientation: widget.imageDecodeOrientation,
          resolutionPreset: widget.resolutionPreset,
          intervalScan: widget.intervalScan,
          onResultInterceptor: widget.onResultInterceptor,
          lockCaptureOrientation: widget.lockCaptureOrientation,
          onCameraError: widget.onCameraError,
          fps: widget.fps,
          videoBitrate: widget.videoBitrate,
          croppingStrategy: widget.croppingStrategy,
          focusPoint: widget.focusPoint,
          imageStreamTimeout: widget.imageStreamTimeout,
        ),
        keepScanPaused: keepScanPaused,
      );
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (!mounted) return;
      widget.onCameraError?.call(e is CameraException ? e.code : e.toString());
    }
  }

  Widget _buildButton() {
    return ValueListenableBuilder<PreviewState>(
      valueListenable: controller.state,
      builder: (context, value, child) {
        return widget.takePictureButtonBuilder?.call(
              context,
              controller,
              value.processing,
            ) ??
            _ButtonTakePicture(
              onTakePicture: controller.takePictureAndDecode,
              isLoading: value.processing,
            );
      },
    );
  }

  Widget _getCameraWidget(BuildContext context) {
    final cameraController = controller.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return widget.child ?? const SizedBox.shrink();
    }

    var camera = cameraController.value;
    // fetch screen size
    final size = MediaQuery.of(context).size;

    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    Size sizePreview = size;
    if (widget.widthPreview != null && widget.heightPreview != null) {
      sizePreview = Size(widget.widthPreview!, widget.heightPreview!);
    }

    var scale = sizePreview.aspectRatio * camera.aspectRatio;

    // // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    // Store values for result points transformation
    _scale = scale;
    _previewSize = sizePreview;
    _cameraSize = Size(
      camera.previewSize!.height,
      camera.previewSize!.width,
    );

    return ClipRRect(
      child: SizedBox(
        key: _cameraKey,
        width: widget.widthPreview,
        height: widget.heightPreview,
        child: Stack(
          children: [
            Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(
                  cameraController,
                ),
              ),
            ),
            if (controller.state.value.typeScan == TypeScan.takePicture)
              _buildButton(),
            widget.child ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  void _onStateListener() {
    if (!mounted) return;
    final state = controller.state.value;
    if (state.initialized != initialized) {
      postFrame(() {
        final shouldBeInitialized =
            _cameraRunning && controller.state.value.initialized;
        if (shouldBeInitialized == initialized) return;
        setState(() {
          _cameraKey = Key(controller.state.value.typeCamera.toString());
          initialized = shouldBeInitialized;
        });
      });
    }
    final result = state.result;
    if (result != null) {
      widget.onCapture?.call(
        result.copyWith(corners: _fixCorners(result.corners)),
      );
    }
  }

  /// Maps decoder corners (camera image space) to preview widget space.
  List<Offset> _fixCorners(List<Offset> corners) {
    if (corners.isEmpty) {
      return corners;
    }

    if (_cameraSize == Size.zero || _previewSize == Size.zero) {
      return corners;
    }

    final cameraController = controller.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return corners;
    }

    // Tamanho da câmera conforme reportado pelo hardware
    final originalPreviewSize = cameraController.value.previewSize!;
    final cameraWidth = originalPreviewSize.width;
    final cameraHeight = originalPreviewSize.height;

    // Detectar orientação da câmera e do preview
    final cameraIsLandscape = cameraWidth > cameraHeight;
    final previewIsLandscape = _previewSize.width > _previewSize.height;

    // Precisamos rotacionar se as orientações são diferentes
    final needsRotation = cameraIsLandscape != previewIsLandscape;

    // Dimensões finais da imagem após rotação (se necessário)
    double finalImageWidth, finalImageHeight;
    if (needsRotation) {
      // Após rotação 90°, largura e altura são invertidas
      finalImageWidth = cameraHeight;
      finalImageHeight = cameraWidth;
    } else {
      finalImageWidth = cameraWidth;
      finalImageHeight = cameraHeight;
    }

    // Aplicar a mesma escala uniforme que é aplicada ao CameraPreview
    final scaledImageWidth = finalImageWidth * _scale;
    final scaledImageHeight = finalImageHeight * _scale;

    // Calcular crop (parte que fica fora do preview)
    final cropX = (scaledImageWidth - _previewSize.width) / 2;
    final cropY = (scaledImageHeight - _previewSize.height) / 2;

    // Transformar todos os pontos
    final transformedPoints = <Offset>[];
    for (final point in corners) {
      double transformedX, transformedY;

      if (needsRotation) {
        // Rotação 90° horário: (x, y) → (height - y, x)
        transformedX = cameraHeight - point.dy;
        transformedY = point.dx;
      } else {
        // Sem rotação, usar coordenadas originais
        transformedX = point.dx;
        transformedY = point.dy;
      }

      // Aplicar escala uniforme e remover crop
      final fixedX = (transformedX * _scale) - cropX;
      final fixedY = (transformedY * _scale) - cropY;

      transformedPoints.add(Offset(fixedX, fixedY));
    }

    if (transformedPoints.isEmpty) {
      return corners;
    }

    // Calcular bounding box
    double minX = transformedPoints.first.dx;
    double maxX = transformedPoints.first.dx;
    double minY = transformedPoints.first.dy;
    double maxY = transformedPoints.first.dy;

    for (final point in transformedPoints) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }

    // Retornar os 4 cantos do quadrilátero (bounding box)
    return [
      Offset(minX, minY), // Top-left
      Offset(maxX, minY), // Top-right
      Offset(maxX, maxY), // Bottom-right
      Offset(minX, maxY), // Bottom-left
    ];
  }
}

class _ButtonTakePicture extends StatelessWidget {
  static const buttonContainerHeight = 150.0;
  static const buttonSize = 80.0;
  static const progressSize = 40.0;
  final VoidCallback onTakePicture;
  final bool isLoading;
  const _ButtonTakePicture({
    Key? key,
    required this.onTakePicture,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: buttonContainerHeight,
        color: Colors.black,
        child: Center(
          child: InkWell(
            onTap: onTakePicture,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: progressSize,
                          height: progressSize,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// If return true the newResult is passed in 'onCapture'
typedef OnResultInterceptorCallback = bool Function(
  ScanResult? oldResult,
  ScanResult newResult,
);
