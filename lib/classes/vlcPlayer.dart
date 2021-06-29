import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:portrait/classes/videoStateStream.dart';

import 'blocManager.dart';

class MyVlcPlayer extends StatefulWidget {
  final String path;
  final String orientation;
  final VlcPlayerController vlcController;
  final VideoStateStream videoStateStream;

  const MyVlcPlayer(
      {Key key,
      this.path,
      this.orientation,
      this.vlcController,
      this.videoStateStream})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyVlcPlayerState();
}

class _MyVlcPlayerState extends State<MyVlcPlayer> {
  VlcPlayerController _vlcPlayerController;

  /// Controles de exibição do painel de controle
  Widget videoControls;
  bool showControls = false;

  // Som
  bool soundOn = false;

  @override
  dispose() {
    /// Encerra corretamente o vídeo
    vlcControllerDisposer();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _vlcPlayerController = widget.vlcController;
    playingControl();
    videoControls = Container();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    videoControls = videoControlBar();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: [
          GestureDetector(
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: GestureDetector(
                onTap: () {
                  print('tap');
                  showControls = !showControls;
                  if (showControls) {
                    videoControls = videoControlBar();
                  } else {
                    videoControls = Container();
                  }
                  setState(() {});
                },
                child: VlcPlayer(
                  aspectRatio: 16 / 9,
                  controller: _vlcPlayerController,
                  placeholder: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  child: videoControls,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  playingControl() async {
    _vlcPlayerController.addOnInitListener(() async {
      BlocProvider.of<VideoCubit>(context).videoStart(widget.path);
      print('########### Cubit Start');
      print(BlocProvider.of<VideoCubit>(context).state.videoState);
      print(BlocProvider.of<VideoCubit>(context).state.videoName);

      Duration videoDuration = Duration(seconds: 30);
      Duration videoPosition = Duration(seconds: 1);
      bool timeToBreak = false;
      String videoName = widget.path;

      while ((videoDuration.inSeconds - videoPosition.inSeconds) > 1) {
        if (timeToBreak) {
          print('Time to Break');
          break;
        }
        var durationHelper =
            await _vlcPlayerController.getDuration().catchError((onError) {
          print('<<<<<<<<<<< $onError');
        });
        var positionHelper =
            await _vlcPlayerController.getPosition().catchError((onError) {
          print('>>>>>>>>>>>>>>>>. $onError');
          if (onError
              .toString()
              .contains('was called on a disposed VlcPlayerController')) {
            timeToBreak = true;
          }
        });
        if (durationHelper != null && positionHelper != null) {
          videoDuration = durationHelper;
          videoPosition = positionHelper;
          await Future.delayed(Duration(milliseconds: 500));
          ///Insere a posição atual do video executado no cubit se o video ainda for o mesmo
          if(BlocProvider.of<VideoCubit>(context).state.videoName == videoName){
            BlocProvider.of<VideoCubit>(context)
                .actualVideoPosition(videoPosition, videoName);
          }

          print('?????????????? ${BlocProvider.of<VideoCubit>(context).state.videoPosition}');
        } else {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      BlocProvider.of<VideoCubit>(context).videoFinished(widget.path);
      print('########### Cubit End');
      print(BlocProvider.of<VideoCubit>(context).state.videoState);
      print(BlocProvider.of<VideoCubit>(context).state.videoName);

      print('Video ended in VLC Player');

      if (videoName == BlocProvider.of<VideoCubit>(context).state.videoName) {
        widget.videoStateStream.updateVideoState.add('${widget.path} done');
      }
    });
  }

  Future<void> vlcControllerDisposer() async {
    await widget.vlcController.stopRendererScanning().catchError((onError) {});
    await widget.vlcController.dispose();
  }

  Widget videoControlBar() {
    return Container();
    /*return Container(
      padding: EdgeInsets.only(right: 8, left: 8),
      height: 50,
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              _vlcPlayerController.pause();
            },
            child: Container(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 35,
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.75,
            child: Slider(
              value: 50,
              min: 0,
              max: 100,
              onChanged: (newValue) {},
            ),
          ),
          GestureDetector(
            onTap: () {
              print('????');
              soundOn = !soundOn;
              print(soundOn);
              setState(() {});
            },
            child: Container(
                child: soundOn == true
                    ? Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: 35,
                      )
                    : Icon(
                        Icons.volume_off,
                        color: Colors.white,
                        size: 35,
                      )),
          ),
        ],
      ),
    );*/
  }
}
