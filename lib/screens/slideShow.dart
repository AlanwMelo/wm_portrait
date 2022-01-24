import 'dart:async';
import 'dart:io';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:panorama/panorama.dart';
import 'package:portrait/classes/betterPlayer.dart';
import 'package:portrait/classes/usableFilesForList.dart';
import 'package:portrait/classes/vlcPlayer.dart';
import 'package:wakelock/wakelock.dart';

class SlideShow extends StatefulWidget {
  final List<UsableFilesForList> slideShowList;
  final int startIndex;

  const SlideShow(
      {Key? key, required this.slideShowList, required this.startIndex})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SlideShowState();
}

class _SlideShowState extends State<SlideShow> {
  int actualPageIndex = 0;
  Duration fileDuration = Duration(seconds: 45);

  /// Controle para saber se o widget ainda está aberto
  bool userQuitedSlideShow = false;

  /// Controle para saber se o usuário está segurando a imagem
  bool userPressing = false;

  /// Variaveis para controle de arquivos pre carregados
  List preLoadedFiles = [];
  List<UsableFilesForList> slideShowControlList = [];
  int preLoadOnIndexChangeCounter = 0;
  bool preLoadOnIndexChangeRunning = false;

  /// Controlador do swiper
  SwiperController swiperController = SwiperController();

  /// Timer que pula de imagem sozinho
  Timer? debounce;

  @override
  void dispose() {
    // Libera o bloqueio de tela.
    Wakelock.disable();
    // Retira o app do modo tela cheia
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);

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
    _autoChangePage(slideShowControlList[widget.startIndex]);
    actualPageIndex = widget.startIndex;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Center(
          child: Container(
            child: GestureDetector(
              onLongPress: () {
                print('hold');
              },
              child: Swiper(
                controller: swiperController,
                index: widget.startIndex,
                onIndexChanged: (index) {
                  actualPageIndex = index;
                  _autoChangePage(slideShowControlList[index]);
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

  _autoChangePage(UsableFilesForList file) async {
    ///Controlador para a troca automática de slides da apresentação (utilizado apenas para imagens)
    if (file.fileType == 'image') {
      if (debounce?.isActive ?? false) {
        debounce!.cancel();
      }
      debounce = Timer(Duration(seconds: 45), () {
        swiperController.next();
      });
    } else {
      if (debounce?.isActive ?? false) {
        debounce!.cancel();
      }
    }
  }

  slideShowItem(UsableFilesForList slideShowListItem, int fileIndex) {
    if (slideShowListItem.fileType == 'image' &&
        slideShowListItem.specialIMG.toString() == 'false') {
      return InteractiveViewer(
        child: Container(child: Image.file(File(slideShowListItem.filePath))),
      );
    } else if (slideShowListItem.fileType == 'image' &&
        slideShowListItem.specialIMG.toString() == 'true') {
      /// Retorna um container vazio até que a imagem esteja na tela para melhorar perfomace
      return actualPageIndex == fileIndex
          ? Panorama(
              onLongPressEnd: _release360(),
              animSpeed: 3,
              child: Image.file(File(slideShowListItem.filePath)))
          : Container();
    } else if (slideShowListItem.fileType == 'video') {
      /// Retorna um container vazio até que o video esteja na tela para melhorar perfomace

      // Aux criada pois o done é retornado diversas vezes
      int aux = 0;
      return actualPageIndex == fileIndex
          ? MyVlcPlayer(
              path: slideShowListItem.filePath,
              orientation: slideShowListItem.fileOrientation,
              videoCallback: (videoCallback) async {
                if(aux == 0){
                  aux = 1;
                  await Future.delayed(Duration(milliseconds: 500));
                  swiperController.next();
                }

              })

          /*MyBetterPlayer(
              path: slideShowListItem.filePath,
              orientation: slideShowListItem.fileOrientation,
              videoCallback: (videoEvent) async {
                /// Ao final do video muda a pagina
                if (videoEvent == 'done') {
                  await Future.delayed(Duration(milliseconds: 500));
                  swiperController.next();
                }
              })*/
          : Container();
    }
  }

  _release360() {
    userPressing = false;
  }
}
