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
class PictureDecode extends StatefulWidget {
  static const routeName = '/picture';
  static get route => {routeName: (BuildContext context) => PictureDecode()};
  static open(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const PictureDecode({Key? key}) : super(key: key);

  @override
  State<PictureDecode> createState() => _PictureDecodeState();
}

class _PictureDecodeState extends State<PictureDecode> {
  Result? currentResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRCodeDartScanView(
        scanInvertedQRCode: true,
        typeScan: TypeScan.takePicture,
        onCapture: (Result result) {
          setState(() {
            currentResult = result;
          });
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 200),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text: ${currentResult?.text ?? 'Not found'}'),
                Text('Format: ${currentResult?.barcodeFormat ?? 'Not found'}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
