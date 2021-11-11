/// Corretamente configurado mas por motivos de perfomance foi substituido pelo VLC, ao final da implementação do VLC
/// será apagado

import 'package:better_player/better_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyBetterPlayer extends StatefulWidget {
  final String path;
  final String orientation;
  final Function(String) videoCallback;

  const MyBetterPlayer(
      {Key? key,
      required this.path,
      required this.orientation,
      required this.videoCallback})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyBetterPlayerState();
}

class _MyBetterPlayerState extends State<MyBetterPlayer> {
  late BetterPlayerDataSource _betterPlayerDataSource;
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    _initPlayerController();
    super.initState();
  }

  @override
  dispose() {
    print('disposed');
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? height;
    double? width;

    if (widget.orientation == 'portrait' &&
        MediaQuery.of(context).orientation == Orientation.landscape) {
      height = MediaQuery.of(context).size.height;
      width = MediaQuery.of(context).size.width * 0.33;
    } else if (widget.orientation == 'portrait' &&
        MediaQuery.of(context).orientation == Orientation.portrait) {
      height = MediaQuery.of(context).size.height;
      width = MediaQuery.of(context).size.width;
    }

    return Stack(
      children: [
        Container(
          child: Center(
            child: Container(
              height: height,
              width: width,
              child: BetterPlayer(
                controller: _betterPlayerController,
              ),
            ),
          ),
        ),
      ],
    );
  }

  _initPlayerController() {
    double aspectRatio = 16 / 9;
    if (widget.orientation == 'portrait') {
      aspectRatio = 9 / 16;
    }

    _betterPlayerDataSource = BetterPlayerDataSource.file(widget.path);
    _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          aspectRatio: aspectRatio,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            showControls: false,
            showControlsOnInitialize: false,
            enableProgressText: false,
          ),
        ),
        betterPlayerDataSource: _betterPlayerDataSource);
    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
        widget.videoCallback('done');
      }
    });
  }
}
