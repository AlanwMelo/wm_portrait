/*
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:panorama/panorama.dart';
import 'package:portrait/classes/blocManager.dart';
import 'package:portrait/classes/usableFilesForList.dart';
import 'package:portrait/classes/videoStateStream.dart';
import 'package:portrait/classes/vlcPlayer.dart';
import 'package:wakelock/wakelock.dart';

class NewSlideShow extends StatefulWidget {
  final List<ListOfFiles> slideShowList;
  final int startIndex;

  const NewSlideShow({Key key, this.slideShowList, this.startIndex})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _NewSlideShowState();
}

class _NewSlideShowState extends State<NewSlideShow> {
  int actualPageIndex = 0;
  Duration fileDuration = Duration(seconds: 45);

  /// Controle para saber se o widget ainda está aberto
  bool userQuitedSlideShow = false;

  /// Controle para saber se o usuário está segurando a imagem
  bool userPressing = false;

  /// Variaveis para controle de arquivos pre carregados
  List preLoadedFiles = [];
  List<ListOfFiles> slideShowControlList = [];
  int preLoadOnIndexChangeCounter = 0;
  bool preLoadOnIndexChangeRunning = false;

  /// Variaveis para controle de duração de vídeo
  VideoStateStream actualVideoStream;

  /// Controlador do swiper
  SwiperController _swiperController = SwiperController();

  @override
  void dispose() {
    // Libera o bloqueio de tela.
    Wakelock.disable();
    // Retira o app do modo tela cheia
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    _nextPage(slideShowControlList[widget.startIndex], widget.startIndex);
    // Index atual recebe o index pelo qual a apresentação foi iniciada
    actualPageIndex = widget.startIndex;
    userQuitedSlideShow = true;
    super.dispose();
  }

  @override
  void initState() {
    // Não permite que a tela seja bloqueada
    Wakelock.enable();
    // Coloca o app em tela cheia
    SystemChrome.setEnabledSystemUIOverlays([]);
    //Carrega a lista a partir do index informado na contrução da tela
    slideShowControlList = widget.slideShowList;
    _nextPage(slideShowControlList[widget.startIndex], widget.startIndex);
    actualPageIndex = widget.startIndex;
    preLoadFiles();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VideoCubit>(
      create: (context) => VideoCubit(),
      child: Scaffold(
        body: Container(
          color: Colors.black,
          child: Center(
            child: Container(
              child: GestureDetector(
                onLongPress: () {
                  print('hold');
                },
                child: Swiper(
                  controller: _swiperController,
                  index: widget.startIndex,
                  onIndexChanged: (index) {
                    actualPageIndex = index;
                    preLoadOnIndexChangeCounter = 0;
                    preLoadOnIndexChange(index);
                    _nextPage(slideShowControlList[index], index);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      child: Center(
                        child: Wrap(
                          children: [
                            Container(
                              //Deixando o Container somente com a altura definida as imagens se ajustam tanto no modo retrato como no paisagem
                              height: MediaQuery.of(context).size.height,
                              child: slideShowItem(
                                  widget.slideShowList[index], index),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: widget.slideShowList.length,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  preLoadFiles() {
    /// Carrega a imagem anterior e a próxima atrás de um container para que a transição fique mais suave
    /// não funciona para vídeos e imagens especiais
    preLoadedFiles.clear();
    int thisSlideShowLength = widget.slideShowList.length - 1;
    loadFiles(element) {
      if (element.fileType != 'video' && element.specialIMG == '') {
        preLoadedFiles.add(element.filePath);
      }
    }

    //Carrega a próxima imagem da lista
    int auxCounter = 0;
    for (int index = actualPageIndex; index <= actualPageIndex + 1; index++) {
      if (index > thisSlideShowLength) {
        loadFiles(slideShowControlList[auxCounter]);
        auxCounter++;
      } else {
        loadFiles(slideShowControlList[index]);
      }
    }
    //Carrega a imagem anterior da lista
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
      //setState(() {});   --->>> Set State reinicia os vídeos, preciso trabalhar melhor com eles
    }
  }

  preLoadOnIndexChange(int index) async {
    /// Chama o preLoadFiles quando o index mudar
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

  _nextPage(ListOfFiles file, int index) async {
    ///Controlador para a troca automática de slides da apresentação

    String fileType = file.fileType;
    bool canContinue = false;
    // Se for um vídeo aguarda o fim do vídeo para pular de página
    if (fileType == 'video') {
      VideoStateStream videoStateStream = VideoStateStream();
      actualVideoStream = videoStateStream;

      while (actualVideoStream == null) {
        await Future.delayed(Duration(milliseconds: 500));
      }

      actualVideoStream.getVideoStateStream.listen((event) async {
        print(event);
        if (event.contains(file.filePath) && event.contains('done')) {
          print('video ended in Slideshow');
          await Future.delayed(Duration(seconds: 1));
          canContinue = true;
        }
      });

      while (!canContinue) {
        await Future.delayed(Duration(milliseconds: 500));
      }
      _canChangePage(index);
    } else {
      // Se for uma imagem aguarda o valor do duration
      await Future.delayed(fileDuration);
      _canChangePage(index);
    }
  }

  _canChangePage(int index) async {
    //Aguarda até que o usuário solte a tela
    while (userPressing == true) {
      await Future.delayed(Duration(seconds: 3));
    }
    //Se o index da chamada ainda for o mesmo index do swiper, pula de página

    print('teste');
    print(actualPageIndex);
    print(index);
    if (userQuitedSlideShow == false) {
      if (index == actualPageIndex) {
        _swiperController.next();
      } else {}
    }
  }

  slideShowItem(ListOfFiles slideShowListItem, int fileIndex) {
    // Retorna a imagem ou vídeo
    if (slideShowListItem.fileType == 'image' &&
        slideShowListItem.specialIMG == '') {
      return Image.file(File(slideShowListItem.filePath));
    } else if (slideShowListItem.fileType == 'image' &&
        slideShowListItem.specialIMG == 'true') {
      bool panoramaRunning = false;
      if (actualPageIndex == fileIndex) {
        print('Show Panorama');
        panoramaRunning = true;
      } else {
        panoramaRunning = false;
      }
      return Container(
          child: panoramaRunning == true
              ? Panorama(
                  onLongPressEnd: _release360(),
                  animSpeed: 3,
                  child: Image.file(File(slideShowListItem.filePath)))
              : Container());
    } else {
      bool videoRunning = false;
      VlcPlayerController _thisVlcController;

      // Espera o vídeo ser exibido na tela por completo antes de iniciar o controlador
      // encerra o controlador quando o video sair da tela
      // o metodo faz com que o vídeo demore um pouco mais para ser exibido mas evita erros e poupa memória
      if (actualPageIndex == fileIndex) {
        print(
            'Starting video controller for file: ${slideShowListItem.fileName}');
        videoRunning = true;
        _thisVlcController = VlcPlayerController.file(
            File(slideShowListItem.filePath),
            hwAcc: HwAcc.AUTO,
            autoInitialize: true,
            autoPlay: true,
            options: VlcPlayerOptions());
      } else {
        videoRunning = false;
      }
      // Retorna um container vazio até que o controlador de video esteja carregado
      // ele só é carreagado quando o slide está quase por completo na tela
      return Container(
          child: videoRunning
              ? vlcPlayer(slideShowListItem.filePath,
                  slideShowListItem.fileOrientation, _thisVlcController)
              : Container());
    }
  }

  vlcPlayer(
      String filePath, String orientation, VlcPlayerController _vlcController) {
    return MyVlcPlayer(
      path: filePath,
      orientation: orientation,
      vlcController: _vlcController,
      videoStateStream: actualVideoStream,
      key: UniqueKey(),
    );
  }

  _release360() {
    userPressing = false;
  }
}
*/
