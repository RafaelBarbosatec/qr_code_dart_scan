import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/src/qr_code_dart_scan_controller.dart';
import 'package:qr_code_dart_scan/src/util/extensions.dart';
import 'package:qr_code_dart_scan/src/util/qr_code_dart_scan_resolution_preset.dart';
import 'package:zxing_lib/zxing.dart';

import 'decoder/qr_code_dart_scan_decoder.dart';

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
  final ValueChanged<Result>? onCapture;
  final bool scanInvertedQRCode;

  /// Use to limit a specific format
  /// If null use all accepted formats
  final List<BarcodeFormat>? formats;
  final QRCodeDartScanController? controller;
  final QRCodeDartScanResolutionPreset resolutionPreset;
  final Widget? child;
  final double? widthPreview;
  final double? heightPreview;
  final TakePictureButtonBuilder? takePictureButtonBuilder;
  const QRCodeDartScanView({
    Key? key,
    this.typeCamera = TypeCamera.back,
    this.typeScan = TypeScan.live,
    this.onCapture,
    this.scanInvertedQRCode = false,
    this.resolutionPreset = QRCodeDartScanResolutionPreset.high,
    this.controller,
    this.formats,
    this.child,
    this.takePictureButtonBuilder,
    this.widthPreview = double.maxFinite,
    this.heightPreview = double.maxFinite,
  }) : super(key: key);

  @override
  _QRCodeDartScanViewState createState() => _QRCodeDartScanViewState();
}

class _QRCodeDartScanViewState extends State<QRCodeDartScanView>
    implements DartScanInterface {
  CameraController? controller;
  late QRCodeDartScanController qrCodeDartScanController;
  late QRCodeDartScanDecoder dartScanDecoder;
  bool initialized = false;
  bool processingImg = false;

  @override
  void initState() {
    dartScanDecoder = QRCodeDartScanDecoder(formats: widget.formats);
    _initController();
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: initialized
          ? SizedBox(
              width: widget.widthPreview,
              height: widget.heightPreview,
              child: CameraPreview(controller!,
                  child: Stack(children: [
                    if (widget.typeScan == TypeScan.takePicture) _buildButton(),
                    widget.child ?? SizedBox.shrink(),
                  ])),
            )
          : widget.child,
    );
  }

  void _initController() async {
    final cameras = await availableCameras();
    var camera = cameras.first;
    if (widget.typeCamera == TypeCamera.front && cameras.length > 1) {
      camera = cameras[1];
    }
    controller = CameraController(
      camera,
      widget.resolutionPreset.toResolutionPreset(),
      enableAudio: false,
    );
    qrCodeDartScanController = widget.controller ?? QRCodeDartScanController();
    await controller!.initialize();
    qrCodeDartScanController.configure(controller!, this);
    if (widget.typeScan == TypeScan.live) {
      controller?.startImageStream(_imageStream);
    }
    postFrame(() {
      setState(() {
        initialized = true;
      });
    });
  }

  void _imageStream(CameraImage image) async {
    if (!qrCodeDartScanController.scanEnabled) return;
    if (processingImg) return;
    processingImg = true;
    _processImage(image);
  }

  void _processImage(CameraImage image) async {
    final decoded = await dartScanDecoder.decodeCameraImage(
      image,
      scanInvertedQRCode: widget.scanInvertedQRCode,
    );

    if (decoded != null && mounted) {
      widget.onCapture?.call(decoded);
    }

    processingImg = false;
  }

  @override
  void takePictureAndDecode() async {
    if (processingImg) return;
    setState(() {
      processingImg = true;
    });
    final xFile = await controller?.takePicture();

    if (xFile != null) {
      final decoded = await dartScanDecoder.decodeFile(
        File(xFile.path),
        scanInvertedQRCode: widget.scanInvertedQRCode,
      );

      if (decoded != null && mounted) {
        widget.onCapture?.call(decoded);
      }
    }

    setState(() {
      processingImg = false;
    });
  }

  Widget _buildButton() {
    return widget.takePictureButtonBuilder?.call(
          context,
          qrCodeDartScanController,
          processingImg,
        ) ??
        _ButtonTakePicture(
          onTakePicture: () => qrCodeDartScanController.takePictureAndDecode(),
          isLoading: processingImg,
        );
  }
}

class _ButtonTakePicture extends StatelessWidget {
  final VoidCallback onTakePicture;
  final bool isLoading;
  const _ButtonTakePicture(
      {Key? key, required this.onTakePicture, this.isLoading = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 150,
        color: Colors.black,
        child: Center(
          child: InkWell(
            onTap: onTakePicture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Container(
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          width: 40,
                          height: 40,
                        ),
                      )
                    : SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
