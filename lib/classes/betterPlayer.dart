/// Corretamente configurado mas por motivos de perfomance foi substituido pelo VLC, ao final da implementação do VLC
/// será apagado

import 'package:better_player/better_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/videoStateStream.dart';

class MyBetterPlayer extends StatefulWidget {
  final String path;
  final String orientation;
  final VideoStateStream videoStreamController;

  const MyBetterPlayer(
      {Key key, this.path, this.orientation, this.videoStreamController})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyBetterPlayerState();
}

class _MyBetterPlayerState extends State<MyBetterPlayer> {
  BetterPlayerController _betterPlayerController;

  @override
  dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    BetterPlayerDataSource betterPlayerDataSource =
        BetterPlayerDataSource.file(widget.path);
    _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            showControlsOnInitialize: false,
            enableProgressText: false,
          ),
        ),
        betterPlayerDataSource: betterPlayerDataSource);

    _betterPlayerController.addEventsListener((event) async {
      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        await Future.delayed(Duration(seconds: 1));
        _betterPlayerController.retryDataSource();
      }
      if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
        widget.videoStreamController.updateVideoState
            .add('${event.betterPlayerEventType}');
        await Future.delayed(Duration(seconds: 1));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orientation == 'portrait' &&
        MediaQuery.of(context).orientation == Orientation.landscape) {
      _betterPlayerController.setOverriddenAspectRatio(0.55);
      return Container(
        width: MediaQuery.of(context).size.width * 0.31,
        height: MediaQuery.of(context).size.height,
        child: BetterPlayer(
          controller: _betterPlayerController,
        ),
      );
    } else if (widget.orientation == 'portrait' &&
        MediaQuery.of(context).orientation == Orientation.portrait) {
      _betterPlayerController.setOverriddenAspectRatio(0.55);
      return Container(
        height: MediaQuery.of(context).size.height,
        child: BetterPlayer(
          controller: _betterPlayerController,
        ),
      );
    }
    if (widget.orientation == 'landscape') {
      return Container(
        child: BetterPlayer(
          controller: _betterPlayerController,
        ),
      );
    } else {
      return Container();
    } //if(MediaQuery.of(context).){}
    // TODO: implement build
  }
}
