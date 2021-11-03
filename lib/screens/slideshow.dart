/*
/// Não está sendo utilizada, mantenho temporariamente para consultas.

import 'dart:io' as Io;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:panorama/panorama.dart';
import 'package:portrait/classes/betterPlayer.dart';
import 'package:portrait/classes/genericClasses.dart';
import 'package:portrait/classes/videoStateStream.dart';
import 'package:portrait/classes/vlcPlayer.dart';
import 'package:wakelock/wakelock.dart';

class Slideshow extends StatefulWidget {
  final List<ListOfFiles> slideShowList;
  final int startIndex;

  const Slideshow({Key key, this.slideShowList, this.startIndex})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SlideshowState();
}

class _SlideshowState extends State<Slideshow> {
  final CarouselController _carouselController = CarouselController();
  int slideShowLength;
  List<ListOfFiles> slideShowControlList = [];
  Widget slideContainer = Container();
  bool userPressing = false;
  int actualPageIndex;
  int preLoadOnIndexChangeCounter = 0;
  bool preLoadOnIndexChangeRunning = false;
  bool userQuitedSlideShow = false;

  //video
  VideoStateStream actualVideoStream;
  VlcPlayerController _vlcController;
  List carouselList = [];
  Duration autoPlayDuration = Duration(seconds: 5);

  List preLoadedFiles = [];

  @override
  void dispose() {
    // TODO: implement dispose
    // Libera o bloqueio de tela.
    Wakelock.disable();
    userQuitedSlideShow = true;
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  @override
  void initState() {
    // Impede que a tela seja bloqueada.
    Wakelock.enable();
    SystemChrome.setEnabledSystemUIOverlays([]);
    slideShowControlList = widget.slideShowList;
    slideShowLength = slideShowControlList.length;
    //Carrega a lista a partir do index informado na contrução da tela
    _nextPage(slideShowControlList[widget.startIndex], widget.startIndex);
    actualPageIndex = widget.startIndex;
    preLoadFiles();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        body: Stack(
      children: [
        //Container para esconder as imagens pré carregadas (criadas para suavizar a transição entre imagens)
        Container(
          child: ListView.builder(
              itemCount: preLoadedFiles.length,
              itemBuilder: (context, index) {
                return Container(
                    width: 10,
                    height: 10,
                    child: Image.file(Io.File(preLoadedFiles[index])));
              }),
        ),
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.black,
          child: Container(child: animatedSlideshow()),
        ),
      ],
    ));
  }

  vlcPlayer(String filePath, String orientation) {
    _vlcController = VlcPlayerController.file(Io.File(filePath), autoInitialize: true,
        hwAcc: HwAcc.AUTO, autoPlay: true, options: VlcPlayerOptions());

    return MyVlcPlayer(
      path: filePath,
      orientation: orientation,
      vlcController: _vlcController,
      videoStateStream: actualVideoStream,
      key: UniqueKey(),
    );
  }

  preLoadFiles() {
    preLoadedFiles.clear();
    int thisSlideShowLength = slideShowLength - 1;
    loadFiles(element) {
      if (element.fileType != 'video' && element.specialIMG == '') {
        preLoadedFiles.add(element.filePath);
      }
    }

    int auxCounter = 0;

    for (int index = actualPageIndex; index <= actualPageIndex + 1; index++) {
      if (index > thisSlideShowLength) {
        loadFiles(slideShowControlList[auxCounter]);
        auxCounter++;
      } else {
        loadFiles(slideShowControlList[index]);
      }
    }
    auxCounter = 0;

    for (int index = actualPageIndex - 1; index <= actualPageIndex; index++) {
      if (index < 0) {
        loadFiles(slideShowControlList[thisSlideShowLength - auxCounter]);
        auxCounter++;
      } else {
        loadFiles(slideShowControlList[index]);
      }
    }
    if (userQuitedSlideShow == false) {
      setState(() {});
    }
  }

  animatedSlideshow() {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        userPressing = true;
      },
      onLongPressEnd: (LongPressEndDetails details) {
        userPressing = false;
      },
      child: Container(
        child: CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: height,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: false,
            aspectRatio: 2.0,
            initialPage: widget.startIndex,
            enlargeStrategy: CenterPageEnlargeStrategy.height,
            onPageChanged: (index, reason) async {
              setState(() {
                actualPageIndex = index;
                preLoadOnIndexChangeCounter = 0;
                preLoadOnIndexChange(index);
                _nextPage(slideShowControlList[index], index);
              });
            },
          ),
          items: slideShowControlList.map((file) {
            if (file.fileType == 'image' && file.specialIMG == '') {
              return Builder(builder: (BuildContext context) {
                return Container(
                    height: height,
                    width: width,
                    child: Image.file(Io.File(file.filePath)));
              });
            } else if (file.fileType == 'image' && file.specialIMG == 'true') {
              return Container(
                height: height,
                width: width,
                child: Panorama(
                    onLongPressEnd: _release360(),
                    animSpeed: 3,
                    child: Image.file(Io.File(file.filePath))),
              );
            } else {
              print('starting vlc? ${file.fileName}');
              return Builder(builder: (BuildContext context) {
                return Container(
                    child: vlcPlayer(file.filePath, file.fileOrientation));
              });
            }
          }).toList(),
        ),
      ),
    );
  }

  _nextPage(ListOfFiles file, int index) async {
    String fileType = file.fileType;
    bool canContinue = false;
    if (fileType == 'video') {
      VideoStateStream videoStateStream = VideoStateStream();
      actualVideoStream = videoStateStream;

      while (actualVideoStream == null) {
        print('while null');
        await Future.delayed(Duration(milliseconds: 500));
      }

      print('here');
      actualVideoStream.getVideoStateStream.listen((event) async {
        if (event.contains(file.fileName) && event.contains('done')) {
          print('video ended in Slideshow');
          await Future.delayed(Duration(seconds: 1));
          canContinue = true;
        }
      });

      while(!canContinue){await Future.delayed(Duration(milliseconds: 500));}

      await Future.delayed(Duration(milliseconds: 1000));
      print('call change');
      _canChangePage(index);
    } else {
      await Future.delayed(Duration(seconds: 45));
      _canChangePage(index);
    }
  }

  Duration getVideoDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }

  _canChangePage(int index) async {
    //Aguarda até que o usuário solte a tela
    while (userPressing == true) {
      await Future.delayed(Duration(seconds: 3));
    }
    //Se o index da chamada ainda for o mesmo index do carrosel pula de página
    if (userQuitedSlideShow == false) {
      if (index == actualPageIndex) {
        setState(() {});
        _carouselController
            .nextPage(duration: Duration(milliseconds: 800))
            .onError((error, stackTrace) {
          if (error.toString().contains('positions.isNotEmpty')) {
            print('Carousel disposed');
          }
        });
      } else {}
    }
  }

  preLoadOnIndexChange(int index) async {
    if (preLoadOnIndexChangeRunning == false) {
      preLoadOnIndexChangeRunning = true;
      while (preLoadOnIndexChangeCounter <= 1) {
        preLoadOnIndexChangeCounter = preLoadOnIndexChangeCounter + 1;
        await Future.delayed(Duration(seconds: 1));
      }
      preLoadFiles();
      preLoadOnIndexChangeRunning = false;
    }
  }

  _release360() {
    userPressing = false;
  }
}
*/
