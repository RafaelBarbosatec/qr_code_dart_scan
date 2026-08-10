import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

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
  static get route => {
        routeName: (BuildContext context) => const LiveDecodePage(),
      };
  static open(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const LiveDecodePage({Key? key}) : super(key: key);

  @override
  LiveDecodePageState createState() => LiveDecodePageState();
}

class LiveDecodePageState extends State<LiveDecodePage> {
  ScanResult? currentResult;
  final QRCodeDartScanController _controller = QRCodeDartScanController();

  /// Guards against a second capture while the result page is being pushed.
  bool navigating = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });
  }

  /// Pause the scan, show the result, then resume it.
  ///
  /// While the result page is open the scan stays paused even if the app is
  /// minimized and reopened, so coming back does not decode a stale frame.
  Future<void> _onCapture(ScanResult result) async {
    if (navigating) return;
    navigating = true;

    setState(() {
      currentResult = result;
    });

    await _controller.stopScan();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ResultWidget(result: result),
      ),
    );
    if (!mounted) return;

    await _controller.startScan();
    navigating = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRCodeDartScanView(
        controller: _controller,
        resolutionPreset: QRCodeDartScanResolutionPreset.medium,
        onCameraError: print,
        onCapture: _onCapture,
        child: Stack(
          children: [
            // Canvas para desenhar os pontos do QR code
            if (currentResult?.corners.isNotEmpty == true)
              CustomPaint(
                painter: QRCodePointsPainter(currentResult!.corners),
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
                    Text('Format: ${currentResult?.format ?? 'Not found'}'),
                    if (currentResult?.corners.isNotEmpty == true)
                      Text('Points: ${currentResult!.corners.length}'),
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
  final List<Offset> points;

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

    // Desenha as linhas conectando os pontos (formando um polígono)
    if (points.length >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
      canvas.drawPath(path, linePaint);
    }

    // Desenha os pontos
    for (final point in points) {
      canvas.drawCircle(point, 8, paint);

      // Desenha um círculo branco no centro para melhor visibilidade
      canvas.drawCircle(
        point,
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

class ResultWidget extends StatelessWidget {
  const ResultWidget({super.key, required this.result});
  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Center(child: Text(result.text)),
    );
  }
}
