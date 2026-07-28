import 'dart:async';
import 'dart:isolate';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';

enum _IsoCommand {
  decode,
  success,
  fail,
}

class _IsoPlanesMessage {
  _IsoPlanesMessage(this.cmd, [this.data, this.rotation, this.formats, this.croppingStrategy])
      : result = null,
        assert(cmd != _IsoCommand.decode || data != null);

  _IsoPlanesMessage.result(this.result)
      : cmd = _IsoCommand.success,
        data = null,
        rotation = null,
        formats = null,
        croppingStrategy = null,
        assert(result != null);

  _IsoPlanesMessage.fail()
      : cmd = _IsoCommand.success,
        data = null,
        rotation = null,
        formats = null,
        croppingStrategy = null,
        result = null;

  // Usa TransferableYuv420Planes para transferência eficiente entre isolates
  final List<TransferableYuv420Planes>? data;
  final Result? result;
  final _IsoCommand cmd;
  final RotationType? rotation;
  final List<BarcodeFormat>? formats;
  final CroppingStrategy? croppingStrategy;
}

/// controller an isolate to executer decode command
class IsolateCameraDecode {
  Isolate? _newIsolate;
  late ReceivePort _receivePort;
  late SendPort _newIceSP;
  Capability? _capability;

  List<Yuv420Planes> _currentYuv420Planess = <Yuv420Planes>[];
  final List<Result?> _currentResults = [];
  bool _created = false;
  bool _paused = false;

  /// Limite máximo de resultados armazenados para evitar memory leak.
  /// Mantém apenas os últimos 10 resultados.
  static const int _maxResultsLimit = 10;

  /// get current data of yuv Yuv420Planess
  List<Yuv420Planes> get currentMultiplier => _currentYuv420Planess;

  /// isolate status: is paused
  bool get paused => _paused;

  /// isolate status: is created
  bool get created => _created;

  /// get last result
  List<Result?> get currentResults => _currentResults;

  Future<void> _createIsolate() async {
    _receivePort = ReceivePort();
    _newIsolate = await Isolate.spawn(_decodeFromCamera, _receivePort.sendPort);
  }

  void _listen() {
    _receivePort.listen((dynamic message) {
      if (message is SendPort) {
        _newIceSP = message;
        if (_currentYuv420Planess.isNotEmpty) {
          _newIceSP.send(_currentYuv420Planess);
        }
      } else if (message is _IsoPlanesMessage) {
        if (message.cmd == _IsoCommand.success || message.cmd == _IsoCommand.fail) {
          _setCurrentResults(message.result);
        }
      }
    });
  }

  /// start isolate
  Future<void> start() async {
    if (_created == false && _paused == false) {
      await _createIsolate();
      _listen();
      _created = true;
    }
  }

  /// dispose isolate
  void terminate() {
    _newIsolate?.kill();
    _created = false;
    _currentResults.clear();
  }

  /// pause/resume isolate
  void pausedSwitch() {
    if (_paused && _capability != null) {
      _newIsolate?.resume(_capability!);
    } else {
      _capability = _newIsolate?.pause();
    }

    _paused = !_paused;
  }

  Completer<Result?>? _completer;

  /// set a yuv Yuv420Planess to start decode
  Future<Result?> setYuv420Planess(
    List<Yuv420Planes> yuv420Planess, {
    RotationType? rotation,
    List<BarcodeFormat>? formats,
    CroppingStrategy? croppingStrategy,
  }) {
    _currentYuv420Planess = yuv420Planess;
    _completer = Completer<Result?>();

    // Converte para formato transferível (zero-copy)
    final transferablePlanes = yuv420Planess.map((plane) => plane.toTransferable()).toList();

    _newIceSP.send(
      _IsoPlanesMessage(
        _IsoCommand.decode,
        transferablePlanes,
        rotation,
        formats,
        croppingStrategy,
      ),
    );

    return _completer!.future;
  }

  void _setCurrentResults(Result? result) {
    _currentResults.insert(0, result);

    // Limita o tamanho da lista para evitar memory leak
    if (_currentResults.length > _maxResultsLimit) {
      _currentResults.removeLast();
    }

    if (!(_completer?.isCompleted ?? true)) {
      if (result != null) {
        _completer?.complete(result);
      } else {
        _completer?.complete(null);
      }
    }
  }

  void dispose() {
    _newIsolate?.kill(priority: Isolate.immediate);
    _newIsolate = null;
  }
}

Future<void> _decodeFromCamera(SendPort callerSP) async {
  final newIceRP = ReceivePort();
  callerSP.send(newIceRP.sendPort);

  List<Yuv420Planes>? yuv420Planess;
  RotationType? rotation;
  List<BarcodeFormat>? formats;
  CroppingStrategy? croppingStrategy;
  Completer<bool> goNext = Completer();
  newIceRP.listen((dynamic message) {
    if (message is _IsoPlanesMessage) {
      if (message.cmd == _IsoCommand.decode) {
        if (goNext.isCompleted) {
          return;
        }
        // Converte de TransferableYuv420Planes de volta para Yuv420Planes
        yuv420Planess = message.data?.map((transferable) => Yuv420Planes.fromTransferable(transferable)).toList();
        rotation = message.rotation;
        formats = message.formats;
        croppingStrategy = message.croppingStrategy;
        goNext.complete(true);
      }
    }
  });

  callerSP.send(newIceRP.sendPort);

  while (true) {
    await goNext.future;
    if (yuv420Planess != null) {
      try {
        final results = CameraDecode.decode(
          yuv420Planess!,
          rotation: rotation,
          formats: formats,
          croppingStrategy: croppingStrategy,
        );
        callerSP.send(_IsoPlanesMessage.result(results));
      } catch (_) {
        callerSP.send(_IsoPlanesMessage.fail());
      }
    }

    goNext = Completer();
  }
}
