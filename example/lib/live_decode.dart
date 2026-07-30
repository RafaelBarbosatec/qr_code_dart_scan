import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:zxing_lib/src/result_point.dart';

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
/// on 28/06/22
class LiveDecodePage extends StatefulWidget {
  static const routeName = '/live';
  static get route => {routeName: (BuildContext context) => const LiveDecodePage()};
  static open(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const LiveDecodePage({Key? key}) : super(key: key);

  @override
  LiveDecodePageState createState() => LiveDecodePageState();
}

class LiveDecodePageState extends State<LiveDecodePage> {
  Result? currentResult;
  final QRCodeDartScanController _controller = QRCodeDartScanController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRCodeDartScanView(
        controller: _controller,
        resolutionPreset: QRCodeDartScanResolutionPreset.medium,
        onCameraError: print,
        onCapture: (Result result) {
          setState(() {
            currentResult = result;
          });
        },
        child: Stack(
          children: [
            // Canvas para desenhar os pontos do QR code
            if (currentResult?.resultPoints != null)
              CustomPaint(
                painter: QRCodePointsPainter(currentResult!.resultPoints!),
                size: Size.infinite,
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('isLive: ${_controller.isLiveScan}'),
                    Text('Text: ${currentResult?.text ?? 'Not found'}'),
                    Text('Format: ${currentResult?.barcodeFormat ?? 'Not found'}'),
                    if (currentResult?.resultPoints != null)
                      Text(
                        'Points: ${currentResult!.resultPoints!.where((p) => p != null).length}',
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        _controller.changeCamera(
                          _controller.state.value.typeCamera == TypeCamera.front
                              ? TypeCamera.back
                              : TypeCamera.front,
                        );
                      },
                      child: const Text('Change cam'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_controller.isLiveScan) {
                          await _controller.stopScan();
                          currentResult = null;
                        } else {
                          await _controller.startScan();
                        }
                        setState(() {});
                      },
                      child: Text(
                        _controller.isLiveScan ? 'Stop scan' : 'Start scan',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QRCodePointsPainter extends CustomPainter {
  final List<ResultPoint?> points;

  QRCodePointsPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final validPoints = points.where((p) => p != null).cast<ResultPoint>().toList();

    // Desenha as linhas conectando os pontos (formando um polígono)
    if (validPoints.length >= 2) {
      final path = Path();
      path.moveTo(validPoints[0].x, validPoints[0].y);
      for (int i = 1; i < validPoints.length; i++) {
        path.lineTo(validPoints[i].x, validPoints[i].y);
      }
      path.close();
      canvas.drawPath(path, linePaint);
    }

    // Desenha os pontos
    for (final point in validPoints) {
      canvas.drawCircle(
        Offset(point.x, point.y),
        8,
        paint,
      );

      // Desenha um círculo branco no centro para melhor visibilidade
      canvas.drawCircle(
        Offset(point.x, point.y),
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(QRCodePointsPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
