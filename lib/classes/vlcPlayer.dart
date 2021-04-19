import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:portrait/classes/videoStateStream.dart';

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


  @override
  dispose(){
    /// Encerra corretamente o vídeo
    vlcControllerDisposer();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _vlcPlayerController = widget.vlcController;
    playing();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return VlcPlayer(
      aspectRatio: 16 / 9,
      controller: _vlcPlayerController,
      placeholder: Center(child: CircularProgressIndicator()),
    );
  }

  playing() {
    _vlcPlayerController.addOnInitListener(() async {
      bool playing = true;
      var position1;
      var position2;
      while (playing) {
        await Future.delayed(Duration(milliseconds: 1000));
        position2 = position1;
        position1 = await _vlcPlayerController.getPosition().catchError((onError){
          if(onError.toString().contains('getTime()\' on a null object reference')){
            print('Vídeo pulado antes do fim');
          }
        });
        if (position2 == position1) {
          playing = false;
          print('Video ended in VLC Player');
          widget.videoStateStream.updateVideoState.add('${widget.path} done');
        }
      }
    });
  }

  Future<void> vlcControllerDisposer() async {
    await widget.vlcController.stopRendererScanning();
    await widget.vlcController.dispose();
  }
}
