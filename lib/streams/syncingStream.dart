import 'dart:async';

import 'package:rxdart/rxdart.dart';

class SyncingStream {
  final StreamController<String> _streamController = BehaviorSubject<String>();

  Sink<String> get streamControllerSink => _streamController.sink;

  Stream<String> get streamControllerStream => _streamController.stream;

  closeStream(){
    _streamController.close();
  }
}
