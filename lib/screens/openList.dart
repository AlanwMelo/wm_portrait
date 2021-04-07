import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:device_info/device_info.dart';
import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:portrait/classes/classes.dart';
import 'package:portrait/classes/videoStateStream.dart';
import 'package:portrait/db/dbManager.dart';
import 'file:///C:/Users/AlanWillianMelo/AndroidStudioProjects/portrait/lib/classes/networkDevices.dart';
import 'file:///C:/Users/AlanWillianMelo/AndroidStudioProjects/portrait/lib/screens/slideshow.dart';
import 'package:thumbnails/thumbnails.dart' as videoThumb;
import 'package:wifi/wifi.dart';

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
  double _valueOfLoadingIndicator = 0;
  int _actualListTotal = 0;
  int _actualListProcessed = 0;
  bool loadingFiles = false;
  int loadingFilesActual;
  int loadingFilesTotal;

  //Animated Containers
  double gridViewHeight;
  double loadingBarHeight = 0;
  double buttonsHigh = 40;
  Widget widgetLoadingTextSwitcher = Container();
  Duration animatedTransition = Duration(milliseconds: 500);

  @override
  void initState() {
    dbManager.createListOfFiles(widget.listName);
    getStoragePath();
    gridViewHeight = widget.screenSize;
    getDeviceInfo();
    loadList();

    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceName = androidInfo.model;
  }

  loadList() async {
    var result = await dbManager.readFilesOfList(widget.listName);
    result.forEach((file) {
      filesList.add(ListOfFiles(file['FilePath'], file['FileName'],
          file['FileType'], file['VideoDuration'], file['FileOrientation']));
      setState(() {});
    });
  }

  clearList() {
    filesList.clear();
  }

  loadingBarHighController(bool loading) async {
    if (loading) {
      loadingBarHeight = 40;
      setState(() {});
      await Future.delayed(Duration(seconds: 1));
      widgetLoadingTextSwitcher = widgetLoadingTextSwitcherLoading();
      setState(() {});
    } else {
      widgetLoadingTextSwitcher = Container();
      setState(() {});
      await Future.delayed(Duration(milliseconds: 500));
      widgetLoadingTextSwitcher = widgetLoadingTextSwitcherDone();
      setState(() {});
      await Future.delayed(Duration(seconds: 2));
      widgetLoadingTextSwitcher = Container();
      setState(() {});
      await Future.delayed(Duration(seconds: 1));
      loadingBarHeight = 0;
      setState(() {});
    }
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
      widgetLoadingTextSwitcher = widgetLoadingTextSwitcherLoading();
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
        String fileOrientation;
        String videoLength = '';
        String type;

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
          getFileOrientation(info.orientation);

          await dbManager.insertFileIntoList(
              widget.listName,
              file.title,
              'video',
              '$result/${file.title}',
              fileOrientation,
              videoLength,
              deviceName,
              DateTime.now().millisecondsSinceEpoch);

          var apiThumb = await videoThumb.Thumbnails.getThumbnail(
              thumbnailFolder: '$listPath/',
              // creates the specified path if it doesnt exist
              videoFile: '$result/${file.title}',
              imageType: videoThumb.ThumbFormat.JPEG,
              quality: 30);

          //Renomeia o thumb criado pela API
          File(apiThumb)
              .renameSync(apiThumb.replaceAll(listPath, '${listPath}thumb_'));
        } else {
          getFileOrientation(file.orientation);
          type = 'image';
          await dbManager.insertFileIntoList(
              widget.listName,
              file.title,
              'image',
              '$result/${file.title}',
              fileOrientation,
              '',
              deviceName,
              DateTime.now().millisecondsSinceEpoch);

          var thumb = await file.thumbData;
          File('$listPath/thumb_${file.title}').writeAsBytes(thumb);
        }

        filesList.add(ListOfFiles('$result/${file.title}', file.title, type,
            videoLength, fileOrientation));
        _actualListProcessed = _actualListProcessed + 1;
        _valueOfLoadingIndicator = _actualListProcessed / _actualListTotal;
      });

      setState(() {});

      sublistStart = sublistEnd + 1;
      sublistEnd = sublistStart + 49;

      //print('start: $sublistStart, end: $sublistEnd, total: $sublistTotal, i: $i');
    }

    setState(() {
      _valueOfLoadingIndicator = 0;
      _actualListTotal = 0;
      _actualListProcessed = 0;
      loadingFiles = !loadingFiles;
      loadingBarHighController(loadingFiles);
      imagesVideosInDir.clear();
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
        filesList.add(ListOfFiles(file.path, file.name, 'video', '', ''));
        print('actual $_actualListProcessed total $_actualListTotal');
        _actualListProcessed = _actualListProcessed + 1;
        _valueOfLoadingIndicator =
            (_actualListProcessed / _actualListTotal).toDouble();
        setState(() {
          if (_actualListProcessed == _actualListTotal) {
            _actualListProcessed = 0;
            _actualListTotal = 0;
            loadingFiles = !loadingFiles;
            loadingBarHighController(loadingFiles);
          }
        });
      });

      //await cacheDeleter(file, targetDir: cacheDeleterDir);

      ///Cria um thumbnail para a imagem
      /*ImageEditor.Image image =
          ImageEditor.decodeImage(compressedImage.readAsBytesSync());*/
      // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
      // ImageEditor.Image thumbnail = ImageEditor.copyResize(image, width: 600);

      /* ///Recupera a orientação da foto
      findOrientationBySize(ImageEditor.Image file) {
        print('from findOrientationBySize');
        if (file.height > file.width) {
          return 'orientação: vertical';
        } else {
          return 'orientação: horizontal';
        }
      }

      Future<Map<String, IfdTag>> data = readExifFromBytes(helpFile);
      data.then((data) async {
        if (data == null || data.isEmpty) {
          print("No EXIF information found\n");
          print(findOrientationBySize(image));
          return;
        } else {
          print('EXIF found');
          String dataOrientation =
              data['Image Orientation'].toString().toLowerCase();
          if (dataOrientation.contains('horizontal') ||
              dataOrientation.contains('180')) {
            print('orientação: horizontal');
          } else if (dataOrientation.contains('90')) {
            print('orientação: vertical');
          } else {
            print(findOrientationBySize(image));
          }
        }
        //compressedImage.deleteSync();

      });*/
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

  @override
  Widget build(BuildContext context) {
    gridViewHeight = MediaQuery.of(context).size.height -
        89.1 -
        loadingBarHeight -
        buttonsHigh;
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
                    height: buttonsHigh,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                              onPressed: () async {
                                await dirSelector().then((value) async {
                                  if (value == true) {
                                    ///Foi necessário para resolver o problema da tela preta após seleção
                                    ///aparentemente a seleção aguarda a execução da próxima variável para sair de lá
                                    await Future.delayed(
                                        Duration(milliseconds: 100));
                                    setState(() {
                                      print('##### Start loading bar');
                                      loadingFiles = !loadingFiles;
                                      loadingBarHighController(loadingFiles);
                                    });
                                    await loadAllFromFolder(loadFromDir);
                                  }
                                });
                              },
                              child: Text(
                                'Adcionar pasta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Slideshow(
                                            slideShowList: filesList,
                                          )));

                              clearList();
                              loadList();

                              //loadList();
                              //dbManager.createNewList('alan', listPath, 'hoje');
                              //print(await dbManager.readListOfLists());

                              //NetworkDevices().udpServer();
                              //NetworkDevices().udpClient();
                              /*final String ip = await Wifi.ip;
                              final String subnet =
                                  ip.substring(0, ip.lastIndexOf('.'));
                              final int port = 80;

                              void checkPortRange(
                                  String subnet, int fromPort, int toPort) {
                                if (fromPort > toPort) {
                                  return;
                                }

                                final stream =
                                    NetworkAnalyzer.discover2(subnet, fromPort);

                                stream.listen((NetworkAddress addr) {
                                  if (addr.exists) {
                                    print(
                                        'Found device: ${addr.ip}:${fromPort}');
                                  }
                                }).onDone(() {
                                  checkPortRange(subnet, fromPort + 1, toPort);
                                });
                              }

                              checkPortRange(subnet, 400, 500);

                              final stream =
                                  NetworkAnalyzer.discover2(subnet, port);
                              stream.listen((NetworkAddress addr) {
                                if (addr.exists) {
                                  print('Found device: ${addr.ip}');
                                }
                              });*/

                              /*FilePickerResult result =
                                  await FilePicker.platform.pickFiles(
                                allowMultiple: true,
                                type: FileType.custom,
                                allowedExtensions: ['jpg', 'mp4', 'png'],
                              );

                              if (result != null) {
                                ///Quebra os resultados para serem processados por partes para tentar poupar memória

                                int sublistStart = 1;
                                int sublistEnd = 5;
                                int sublistTotal = result.files.length;

                                print(
                                    'Start loading files <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');

                                for (var i = 1;
                                    i <= ((sublistTotal / 5).ceil());
                                    i++) {
                                  //print('start: $sublistStart, end: $sublistEnd, total: $sublistTotal, i: $i');

                                  int loadFromListStart = sublistStart;
                                  int loadFromListEnd = sublistEnd;

                                  if (sublistEnd > sublistTotal) {
                                    loadFromListEnd = sublistTotal;
                                  }

                                  print(
                                      'loading list from $loadFromListStart to $loadFromListEnd <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');

                                  await filePickerLoader(
                                      result.files.sublist(
                                          loadFromListStart - 1,
                                          loadFromListEnd),
                                      cacheDeleterDir:
                                          '${listPath}cache/file_picker/'
                                              .replaceAll(
                                                  '/app_flutter/thisList', ''));

                                  sublistStart = sublistEnd + 1;
                                  sublistEnd = sublistStart + 4;
                                  //print('start: $sublistStart, end: $sublistEnd, total: $sublistTotal, i: $i');
                                }

                                print(
                                    'Files loaded <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');

                                setState(() {});
                              } else {
                                // User canceled the picker*/
                              //}
                            },
                            child: Text(
                              'Testes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          height: gridViewHeight,
                          child: Container(
                            margin:
                                EdgeInsets.only(left: 8, right: 8, bottom: 8),
                            child: GridView.builder(
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
                                return ClipRRect(
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
                                                                            .videoLenght,
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
                                                      size: loadingBarHeight,
                                                      color: Colors.black
                                                          .withOpacity(0.4))),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            color: Theme.of(context).accentColor,
                            height: loadingBarHeight,
                            child: AnimatedSwitcher(
                                duration: Duration(seconds: 1),
                                child: widgetLoadingTextSwitcher)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  widgetLoadingTextSwitcherLoading() {
    return AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: Row(
          children: [
            SizedBox(width: 15),
            Container(
              child: Container(
                child: Text(
                    'Carregando arquivos:  $_actualListProcessed/${_actualListTotal == 0 ? '?' : _actualListTotal}',
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
                    child: Stack(
                      children: [
                        Container(
                          height: 35,
                          width: 35,
                          child: Center(
                            child: Container(
                              child: Text(
                                '${((_actualListProcessed / _actualListTotal) * 100).round()}%',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Container(
                            child: Container(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            value: _valueOfLoadingIndicator,
                          ),
                        )),
                      ],
                    ),
                  ),
                  SizedBox(width: 15),
                ],
              ),
            ),
          ],
        ));
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
}
