import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class MyVlcPlayer extends StatefulWidget {
  final String path;
  final String orientation;
  final Function(String) videoCallback;

  const MyVlcPlayer(
      {Key? key,
      required this.path,
      required this.orientation,
      required this.videoCallback})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyVlcPlayerState();
}

class _MyVlcPlayerState extends State<MyVlcPlayer> {
  /// Controles de exibição do painel de controle
  late Widget videoControls;
  late VlcPlayerController vlcPlayerController;
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
    _initVlcController();
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
                  controller: vlcPlayerController,
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

  vlcControllerDisposer() async {
    await vlcPlayerController.stopRendererScanning().catchError((onError) {});
    await vlcPlayerController.dispose();
  }

  Widget videoControlBar() {
    return Container();
  }

  _initVlcController() async {
    vlcPlayerController = VlcPlayerController.file(
      File(widget.path),
      hwAcc: HwAcc.FULL,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    vlcPlayerController.addListener(() async {
      /* print(await vlcPlayerController.isPlaying());
      print(await vlcPlayerController.getPosition());*/
      bool? playing = false;
      Duration? position = Duration(seconds: 0);

      if (this.mounted) {
        try {
          playing = await vlcPlayerController.isPlaying();
          position = await vlcPlayerController.getPosition();
        } catch (e) {
          print(e);
        }
      }

      if (!playing! && position! > Duration(milliseconds: 1)) {
        widget.videoCallback('done');
      }
    });
  }
}
