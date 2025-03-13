import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

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

Future<ui.Image> myDecodeImageFromList(Uint8List bytes) {
  Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(bytes, (image) => completer.complete(image));
  return completer.future;
}
