import 'package:example/live_decode.dart';
import 'package:example/picture_decode.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        ...HomePage.route,
        ...LiveDecodePage.route,
        ...PictureDecode.route,
      },
    );
  }
}

class HomePage extends StatelessWidget {
  static const routeName = '/';
  static get route => {routeName: (BuildContext context) => HomePage()};

  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QRCodeDartScan'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => LiveDecodePage.open(context),
              child: Text('Live decode'),
            ),
            ElevatedButton(
              onPressed: () => PictureDecode.open(context),
              child: Text('Picture decode'),
            )
          ],
        ),
      ),
    );
  }
}
