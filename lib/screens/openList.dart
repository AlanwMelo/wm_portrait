import 'dart:io';
import 'package:clippy_flutter/clippy_flutter.dart';
import 'package:device_info/device_info.dart';
import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:panorama/panorama.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:portrait/classes/appColors.dart';
import 'package:portrait/classes/classes.dart';
import 'package:portrait/db/dbManager.dart';
import 'package:portrait/screens/newSlideShow.dart';
import 'package:portrait/screens/slideshow.dart';
import 'package:video_compress/video_compress.dart';

class OpenList extends StatefulWidget {
  final String listName;
  final double screenSize;
  final String appName;

  const OpenList({Key key, this.listName, this.screenSize, this.appName})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _OpenListState();
}

class _OpenListState extends State<OpenList> {
  final MyDbManager dbManager = MyDbManager();
  Directory internalStorage;
  String deviceName;
  String loadFromDir;
  String listPath;
  String cachePath;
  List<ListOfFiles> filesList = [];
  List<FileSystemEntity> filesInDir = [];
  List<FileSystemEntity> imagesVideosInDir = [];

  //Variáveis para a barra de carregamento
  int _actualListTotal = 0;
  int _actualListProcessed = 0;
  bool loadingFiles = false;
  int loadingFilesActual;
  int loadingFilesTotal;
  double tweenBegin = 0;
  double tweenEnd = 0;

  //Animated Containers
  Widget widgetLoadingTextSwitcher = Container();
  Widget widgetBottomBar;
  bool widgetBottomBarIsVisible = true;
  Widget widgetArcLeft;
  Widget widgetArcCenter;
  Widget widgetArcRight;
  ScrollController gridScrollController;
  Edge whereShowEdge = Edge.TOP;
  MainAxisAlignment whereShowAlignment = MainAxisAlignment.end;

  //Alignment margins
  double alignPlayIcon;
  double alignAddIcon;
  double alignOptionsIcon;

  @override
  void initState() {
    dbManager.createListOfFiles(widget.listName);
    getStoragePath();
    getDeviceInfo();
    loadList();
    gridScrollController = ScrollController();
    gridScrollController.addListener(_bottomBarVisibility);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    widgetArcLeft = arcLeftButton();
    widgetArcCenter = arcCenterButton();
    widgetArcRight = arcRightButton();
    widgetBottomBar = widgetBottomBarVisible();

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.appName),
        ),
        body: Stack(
          children: [
            Container(
              child: Column(
                children: [
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          height:
                              (MediaQuery.of(context).size.height - 106) * 0.97,
                          margin: EdgeInsets.only(
                              left: 8, right: 8, bottom: 8, top: 8),
                          child: GridView.builder(
                            controller: gridScrollController,
                            itemCount: filesList.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              childAspectRatio: 1,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              crossAxisCount:
                                  (MediaQuery.of(context).size.width / 120)
                                      .round(),
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              String thumbImg =
                                  '${listPath}thumb_${fileNameWithoutExtension(fileName: filesList[index].fileName)}jpg';
                              bool loadingFile = File(thumbImg).existsSync();
                              return GestureDetector(
                                onLongPress: () async {
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => NewSlideShow(
                                                slideShowList: filesList,
                                                startIndex: index,
                                              )));
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                      topLeft: Radius.circular(10)),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          color: Colors.lightBlueAccent
                                              .withOpacity(0.08),
                                          child: loadingFile == true
                                              ? Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                      Image.file(
                                                          new File(thumbImg),
                                                          fit: BoxFit.cover),
                                                      Container(
                                                          child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                            filesList[index]
                                                                        .fileType ==
                                                                    'video'
                                                                ? Row(
                                                                    children: [
                                                                      Container(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.3),
                                                                        margin: EdgeInsets.only(
                                                                            left:
                                                                                2,
                                                                            right:
                                                                                2),
                                                                        child: Icon(
                                                                            Icons
                                                                                .play_circle_fill,
                                                                            size:
                                                                                16,
                                                                            color:
                                                                                Colors.white),
                                                                      ),
                                                                      Text(
                                                                        filesList[index]
                                                                            .videoLength,
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          backgroundColor: Colors
                                                                              .black
                                                                              .withOpacity(0.3),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                : Container(),
                                                            Container(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.3),
                                                                height: 20,
                                                                child: Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: Container(
                                                                          margin: EdgeInsets.only(left: 4),
                                                                          child: filesList[index].fileName.length >= 14
                                                                              ? Text(
                                                                                  filesList[index].fileName,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style: TextStyle(color: Colors.white),
                                                                                )
                                                                              : Text(filesList[index].fileName, style: TextStyle(color: Colors.white))),
                                                                    )
                                                                  ],
                                                                ))
                                                          ]))
                                                    ])
                                              : Center(
                                                  child: Icon(
                                                      Icons
                                                          .image_search_outlined,
                                                      size: 40,
                                                      color: Colors.black
                                                          .withOpacity(0.4))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Column(
                mainAxisAlignment: whereShowAlignment,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: widgetBottomBar,
                  ),
                ],
              ),
            ),
            loadingFiles == true
                ? Container(
                    color: AppColorsDialga().white().withOpacity(0.8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 100,
                                width: 100,
                                child: Center(
                                  child: Container(
                                    child: Text(
                                      //Se o valor da lista atual for diferente de zero retorna a porcentagem já processada
                                      _actualListProcessed !=
                                              0
                                          ? '${((_actualListProcessed / _actualListTotal) * 100).round()}%'
                                          : '0%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: AppColorsDialga().black()),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                  child: Container(
                                height: 100,
                                width: 100,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                      begin: tweenBegin, end: tweenEnd),
                                  duration: const Duration(milliseconds: 500),
                                  builder: (context, value, _) =>
                                      CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 10,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColorsDialga().black()),
                                  ),
                                ),
                              )),
                            ],
                          ),
                          SizedBox(height: 15),
                          Container(
                            child: Container(
                              child: Text(
                                  'Carregando arquivos:  $_actualListProcessed/${_actualListTotal == 0 ? '?' : _actualListTotal}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: AppColorsDialga().black(),
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(),
          ],
        ));
  }

  ///Recupera o diretório do app
  getStoragePath() async {
    final directory = await getApplicationDocumentsDirectory();
    internalStorage = directory;
    listPath = '${directory.path}/${widget.listName}/';
    cachePath = '${directory.path}/thisList/cache/';

    checkDir(listPath).then((value) {
      checkDir(cachePath);
    });
  }

  dirSelector() async {
    String result;
    if (await Permission.storage.request().isGranted) {
      result = await FilePicker.platform.getDirectoryPath();
      loadFromDir = result;
      if (result != null) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  filePickerLoader(List<PlatformFile> result, {String cacheDeleterDir}) async {
    result.forEach((file) async {
      var compressedImage = new File(file.path);

      Future<File> testCompressAndGetFile(File file, String targetPath) async {
        var result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 40,
        );
        compressedImage = result;
        return result;
      }

      ///Recupera o nome original do arquivo sem a extensão
      String thisFileName = fileNameWithoutExtension(file: file);

      ///Comprime um pouco a imagem
      await testCompressAndGetFile(
              compressedImage, '${listPath}thumb_${thisFileName}jpg')
          .then((value) {
        filesList.add(ListOfFiles(file.path, file.name, 'video', '', '', ''));
        print('actual $_actualListProcessed total $_actualListTotal');
        _actualListProcessed = _actualListProcessed + 1;
        setState(() {
          if (_actualListProcessed == _actualListTotal) {
            _actualListProcessed = 0;
            _actualListTotal = 0;
            loadingFiles = !loadingFiles;
          }
        });
      });
    });
  }

  ///Verifica se existe/cria o diretório
  checkDir(String dirPath) async {
    if (await Directory(dirPath).exists()) {
      print('The directory already exists');
      print('Directory: $dirPath');
      return true;
    } else {
      print('The directory doesn\'t exists');
      print('Creating directory');
      await Directory(dirPath).create();
      print('Directory created');
      print('Directory: $dirPath');
      return true;
    }
  }

  ///Recupera o nome original do arquivo sem a extensão
  fileNameWithoutExtension({PlatformFile file, String fileName}) {
    if (file != null) {
      String thisFileName =
          file.name.substring(0, file.name.length - file.extension.length);
      return thisFileName;
    }
    if (fileName != null) {
      int extensionPosition = fileName.lastIndexOf('.');
      String rmvExtension = fileName.substring(0, extensionPosition + 1);
      return rmvExtension;
    }
  }

  ///Deleta a imagem original do cache
  cacheDeleter(PlatformFile file, {String targetDir}) {
    String path = targetDir;
    File targetFile = File('$path${file.name}');
    targetFile.delete();
    print('File deleted from cache: $path${file.name}');
    return true;
  }

  getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceName = androidInfo.model;
  }

  loadList() async {
    var result = await dbManager.readFilesOfList(widget.listName);
    result.forEach((file) {
      filesList.add(ListOfFiles(
          file['FilePath'],
          file['FileName'],
          file['FileType'],
          file['VideoDuration'],
          file['FileOrientation'],
          file['SpecialIMG']));

      setState(() {});
    });
  }

  clearList() {
    filesList.clear();
  }

  prepareToLoadAllFromFolder() async {
    //Zera os valores das animações de carregamento
    tweenEnd = 0;
    tweenBegin = 0;
    _actualListTotal = 0;
    _actualListProcessed = 0;
    imagesVideosInDir.clear();
    await dirSelector().then((value) async {
      if (value == true) {
        ///Foi necessário para resolver o problema da tela preta após seleção
        ///aparentemente a seleção aguarda a execução da próxima variável para sair de lá
        await Future.delayed(Duration(milliseconds: 100));
        setState(() {
          print('##### Start loading bar');
          loadingFiles = !loadingFiles;
        });
        await loadAllFromFolder(loadFromDir);
      }
    });
  }

  loadAllFromFolder(String result) async {
    print('############### Started loading files from folder');
    //filesInDir = Directory(result).listSync();
    int auxIndex = result.lastIndexOf('/');
    String dirName = result.substring(auxIndex + 1);

    final albums = await PhotoManager.getAssetPathList();
    final selectedAlbum =
        albums[albums.indexWhere((element) => element.name == dirName)];
    var filesInDir = await selectedAlbum.assetList;
    _actualListTotal = filesInDir.length;

    var filesAlreadyLoaded = await dbManager.readFilesOfList(widget.listName);
    filesAlreadyLoaded.forEach((file) {
      var foundIndex =
          filesInDir.indexWhere((element) => element.title == file['FileName']);
      if (foundIndex >= 0) {
        _actualListTotal = _actualListTotal - 1;
        filesInDir.removeWhere((element) => element.title == file['FileName']);
      }
    });

    int sublistStart = 1;
    int sublistEnd = 50;
    int sublistTotal = _actualListTotal;

    for (var i = 1; i <= ((sublistTotal / 50).ceil()); i++) {
      //print('start: $sublistStart, end: $sublistEnd, total: $sublistTotal, i: $i');

      int loadFromListStart = sublistStart;
      int loadFromListEnd = sublistEnd;

      if (sublistEnd > sublistTotal) {
        loadFromListEnd = sublistTotal;
      }

      print(
          'loading list from $loadFromListStart to $loadFromListEnd <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
      await Future.forEach(
          filesInDir.sublist(loadFromListStart - 1, loadFromListEnd),
          (file) async {
        bool videoError = false;
        String fileOrientation;
        String videoLength = '';
        String type;
        String specialIMG = '';

        getFileOrientation(int orientation) {
          if (orientation == 90 || orientation == 270) {
            fileOrientation = 'portrait';
          } else {
            fileOrientation = 'landscape';
          }
        }

        if (file.type.toString() == 'AssetType.video') {
          final videoInfo = FlutterVideoInfo();
          String videoFilePath = '$result/${file.title}';
          var info = await videoInfo.getVideoInfo(videoFilePath);
          int videoAux = file.videoDuration.toString().indexOf('.');
          videoLength = file.videoDuration.toString().substring(0, videoAux);
          type = 'video';

          if (info.orientation == 0) {
            if (info.width > info.height) {
              fileOrientation = 'landscape';
            } else {
              fileOrientation = 'portrait';
            }
          } else {
            getFileOrientation(info.orientation);
          }

          await dbManager.insertFileIntoList(
              widget.listName,
              file.title,
              'video',
              '$result/${file.title}',
              fileOrientation,
              videoLength,
              deviceName,
              '',
              DateTime.now().millisecondsSinceEpoch);

          final thumbnailFile =
              await VideoCompress.getFileThumbnail(videoFilePath,
                      quality: 30, // default(100)
                      position: 0 // default(-1)
                      )
                  .onError((error, stackTrace) {
            print('Error --->>>> ${file.title}');
            dbManager.deleteFileOfList(widget.listName, file.title);
            videoError = true;
          });

          if (videoError == false) {
            thumbnailFile.copy(
                '$listPath/thumb_${fileNameWithoutExtension(fileName: file.title)}jpg');
          }
        } else {
          getFileOrientation(file.orientation);
          type = 'image';

          Future<Map<String, IfdTag>> data = readExifFromBytes(
              await File('$result/${file.title}').readAsBytes());
          await data.then((data) async {
            if (data['Image ImageWidth'] != null) {
              int width = int.parse(data['Image ImageWidth'].toString());
              int height = int.parse(data['Image ImageLength'].toString());
              if ((width / 2) >= height) {
                specialIMG = 'true';
              }
            }
          });

          await dbManager.insertFileIntoList(
              widget.listName,
              file.title,
              'image',
              '$result/${file.title}',
              fileOrientation,
              '',
              deviceName,
              specialIMG,
              DateTime.now().millisecondsSinceEpoch);

          var thumb = await file.thumbData;
          File('$listPath/thumb_${file.title}').writeAsBytes(thumb);
        }

        if (videoError == false) {
          filesList.add(ListOfFiles('$result/${file.title}', file.title, type,
              videoLength, fileOrientation, specialIMG));
        }
        _actualListProcessed = _actualListProcessed + 1;
        tweenBegin = tweenEnd;
        tweenEnd = _actualListProcessed / _actualListTotal;
        setState(() {});
      });

      sublistStart = sublistEnd + 1;
      sublistEnd = sublistStart + 49;

      //print('start: $sublistStart, end: $sublistEnd, total: $sublistTotal, i: $i');
    }

    setState(() {
      loadingFiles = !loadingFiles;
    });
  }

  widgetBottomBarVisible() {
    return Arc(
      arcType: ArcType.CONVEX,
      edge: whereShowEdge,
      height: 25,
      clipShadows: [ClipShadow(color: Colors.black)],
      child: new Container(
        height: 60,
        width: MediaQuery.of(context).size.width,
        color: AppColorsDialga().primaryColor(),
        child: Container(
          child: Row(
            children: [
              Expanded(
                child: widgetArcLeft,
              ),
              Expanded(
                child: widgetArcCenter,
              ),
              Expanded(
                child: widgetArcRight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  arcLeftButton() {
    return GestureDetector(
      onTap: () {
        prepareToLoadAllFromFolder();
      },
      child: Container(
        margin: EdgeInsets.only(top: 12),
        child: Icon(Icons.my_library_add_outlined,
            size: 30, color: AppColorsDialga().white()),
      ),
    );
  }

  arcCenterButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewSlideShow(
                  slideShowList: filesList,
                  startIndex: 0,
                )));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Icon(Icons.play_circle_outline,
            size: 40, color: AppColorsDialga().white()),
      ),
    );
  }

  /*arcCenterButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Slideshow(
                  slideShowList: filesList,
                  startIndex: 0,
                )));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Icon(Icons.play_circle_outline,
            size: 40, color: AppColorsDialga().white()),
      ),
    );
  }*/

  arcRightButton() {
    return GestureDetector(
      onTap: () {
        filesList.sort((a, b) {
          int indexOfA = a.fileName.indexOf('_');
          int indexOfB = b.fileName.indexOf('_');

          return a.fileName
              .substring(indexOfA + 1)
              .compareTo(b.fileName.substring(indexOfB + 1));
        });
        setState(() {});
      },
      child: Container(
          margin: EdgeInsets.only(top: 12),
          child: Icon(Icons.workspaces_outline,
              size: 30, color: AppColorsDialga().white())),
    );
  }

  widgetLoadingTextSwitcherDone() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      child: Row(
        children: [
          SizedBox(width: 15),
          Container(
            child: Container(
              child: Text('Arquivos carregados!',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Center(
                  child: Container(
                    height: 35,
                    width: 35,
                    child: Center(
                      child: Container(
                          child: Container(
                        child: Icon(
                          Icons.done,
                          color: Colors.white,
                          size: 30,
                        ),
                      )),
                    ),
                  ),
                ),
                SizedBox(width: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _bottomBarVisibility() {
    if (gridScrollController.offset >=
            gridScrollController.position.maxScrollExtent &&
        !gridScrollController.position.outOfRange) {
      widgetBottomBar = Container();
      widgetBottomBarIsVisible = false;
      setState(() {});
    }
    if (gridScrollController.offset !=
        gridScrollController.position.maxScrollExtent) {
      if (!widgetBottomBarIsVisible) {
        widgetBottomBarIsVisible = true;
        widgetBottomBar = widgetBottomBarVisible();
        setState(() {});
      }
    }
  }
}
