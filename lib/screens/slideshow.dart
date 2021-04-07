import 'dart:io' as Io;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/classes.dart';
import 'file:///C:/Users/AlanWillianMelo/AndroidStudioProjects/portrait/lib/classes/betterPlayer.dart';
import 'package:portrait/classes/videoStateStream.dart';

class Slideshow extends StatefulWidget {
  final List<ListOfFiles> slideShowList;

  const Slideshow({Key key, this.slideShowList}) : super(key: key);

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
  List carouselList = [];
  int slideIndex = 0;
  Duration autoPlayDuration = Duration(seconds: 5);

  List preLoadedFiles = [];

  @override
  void dispose() {
    // TODO: implement dispose
    userQuitedSlideShow = true;
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
    super.dispose();
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    slideShowControlList = widget.slideShowList;
    slideShowLength = slideShowControlList.length;
    _nextPage(slideShowControlList[0], 0);
    actualPageIndex = 0;
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

  betterPlayer(String filePath, String orientation) {
    return MyBetterPlayer(
      path: filePath,
      orientation: orientation,
      videoStreamController: actualVideoStream,
    );
  }

  preLoadFiles() {
    preLoadedFiles.clear();
    int thisSlideShowLength = slideShowLength - 1;
    loadFiles(element) {
      if (element.fileType != 'video') {
        preLoadedFiles.add(element.filePath);
      }
    }

    int auxCounter = 0;

    for (int index = actualPageIndex; index <= actualPageIndex + 2; index++) {
      if (index > thisSlideShowLength) {
        loadFiles(slideShowControlList[auxCounter]);
        auxCounter++;
      } else {
        loadFiles(slideShowControlList[index]);
      }
    }
    auxCounter = 0;

    for (int index = actualPageIndex - 2; index <= actualPageIndex; index++) {
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
            enlargeStrategy: CenterPageEnlargeStrategy.height,
            onPageChanged: (index, reason) {
              setState(() {
                actualPageIndex = index;
                preLoadOnIndexChangeCounter = 0;
                preLoadOnIndexChange(index);
                _nextPage(slideShowControlList[index], index);
              });
            },
          ),
          items: slideShowControlList.map((file) {
            if (file.fileType == 'image') {
              return Builder(builder: (BuildContext context) {
                return Container(
                    height: height,
                    width: width,
                    child: Image.file(Io.File(file.filePath)));
              });
            } else {
              return Builder(builder: (BuildContext context) {
                return Container(
                    child: betterPlayer(file.filePath, file.fileOrientation));
              });
            }
          }).toList(),
        ),
      ),
    );
  }

  _nextPage(ListOfFiles file, int index) async {
    var x = 'BetterPlayerEventType.finished';
    var y = '';
    String fileType = file.fileType;
    if (fileType == 'video') {
      VideoStateStream videoStateStream = VideoStateStream();
      VideoStateStream thisVideoStream;
      actualVideoStream = videoStateStream;
      thisVideoStream = actualVideoStream;
      while (actualVideoStream == null) {
        await Future.delayed(Duration(milliseconds: 500));
      }
      actualVideoStream.getVideoStateStream.listen((event) {
        if (event == 'BetterPlayerEventType.finished') {
          y = 'BetterPlayerEventType.finished';
        }
      });
      while (x != y && actualVideoStream == thisVideoStream) {
        await Future.delayed(Duration(milliseconds: 500));
      }
      await Future.delayed(Duration(milliseconds: 1000));
      _canChangePage(index);
    } else {
      await Future.delayed(Duration(seconds: 10));
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
        SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
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
      while (preLoadOnIndexChangeCounter <= 2) {
        preLoadOnIndexChangeCounter = preLoadOnIndexChangeCounter + 1;
        await Future.delayed(Duration(seconds: 1));
      }
      preLoadFiles();
      preLoadOnIndexChangeRunning = false;
    }
  }
}
