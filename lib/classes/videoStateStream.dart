import 'dart:async';

class VideoStateStream {
  final _streamController = StreamController<String>();

  StreamSink<String> get updateVideoState =>
      _streamController.sink; // expose data from stream
  Stream<String> get getVideoStateStream => _streamController.stream;

  dispose() async {
    if (_streamController != null) {
      await _streamController.close();
      return true;
    } else {
      return true;
    }
  }
}
