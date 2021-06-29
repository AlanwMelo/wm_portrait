import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CubitVideoStreamControllerState {
  String videoState;
  String videoName;
  Duration videoPosition;

  CubitVideoStreamControllerState(
      {@required this.videoState, this.videoName, this.videoPosition});
}

class VideoCubit extends Cubit<CubitVideoStreamControllerState> {
  VideoCubit() : super(CubitVideoStreamControllerState(videoState: 'null'));

  void videoStart(String videoName) => emit(CubitVideoStreamControllerState(
      videoState: 'started', videoName: videoName));

  void actualVideoPosition(Duration position, String videoName) {
    emit(CubitVideoStreamControllerState(videoName: videoName,
        videoState: '', videoPosition: position));
  }

  void videoFinished(String videoName) => emit(CubitVideoStreamControllerState(
      videoState: 'finished', videoName: videoName));
}
