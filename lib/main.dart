import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:file_manager/controller/file_manager_controller.dart';
import 'package:file_manager/file_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:portrait/screens/albumsList.dart';
import 'package:portrait/classes/appColors.dart';
import 'package:portrait/classes/clipRecct.dart';
import 'package:portrait/classes/directoryManager.dart';
import 'package:portrait/classes/fileProcessor.dart';
import 'package:portrait/classes/floatingLoadingBarForStack.dart';
import 'package:portrait/classes/syncFiles.dart';
import 'package:portrait/classes/textStyle.dart';
import 'package:portrait/colorScreen.dart';
import 'package:portrait/db/dbManager.dart';
import 'package:portrait/screens/openAlbum.dart';
import 'dart:io';
import 'package:portrait/screens/openList.dart';
import 'package:portrait/screens/presentationsList.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';

import 'streams/syncingStream.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WM Portrait',
      theme: ThemeData(
        primaryColor: AppColorsDialga().primaryColor(),
        accentColor: AppColorsDialga().accentColor(),
        scaffoldBackgroundColor: AppColorsDialga().scaffoldBackGround(),
      ),
      home: _MyHomePage(),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  _MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage>
    with SingleTickerProviderStateMixin {
  late Database openDB;
  MyDbManager dbManager = MyDbManager();

  int animatedTextIndex = 0;

  // List with all directories that contains images or videos
  late List<Map> directoriesInDB;
  List<Directory> usableDirectories = [];

  // Animated Text color controllers
  late Animation<Color?> photoAnimation;
  late Animation<Color?> albumAnimation;
  late AnimationController colorAnimationController;

  SwiperController swiperController = SwiperController();
  List<Widget> swiperItems = [];

  // Stream of syncing files used in the whole APP
  bool syncRunning = false;
  final SyncingStream syncingStreamClass = SyncingStream();

  late SyncFiles syncFiles;

  @override
  void initState() {
    _openDB();
    _initTextControllers();
    super.initState();
  }

  @override
  void dispose() {
    syncingStreamClass.closeStream();
    openDB.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  colorAnimationController.reverse();
                                  swiperController.move(0);
                                },
                                child: PortraitTextStyle()
                                    .topText('Photos', photoAnimation.value),
                              ),
                              GestureDetector(
                                onTap: () {
                                  colorAnimationController.forward();
                                  swiperController.move(1);
                                },
                                child: PortraitTextStyle()
                                    .topText('Albums', albumAnimation.value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PresentationsList(
                                          openDB: openDB,
                                        )));
                          },
                          child:
                              Container(child: Icon(Icons.more_vert_rounded))),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    child:
                        NotificationListener<OverscrollIndicatorNotification>(
                      //Removes glow animation on overscroll
                      onNotification:
                          (OverscrollIndicatorNotification? overscroll) {
                        overscroll!.disallowGlow();
                        return true;
                      },
                      child: Swiper(
                          controller: swiperController,
                          loop: false,
                          itemCount: 2,
                          onIndexChanged: (index) {
                            index == 0
                                ? colorAnimationController.reverse()
                                : colorAnimationController.forward();
                          },
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              child: index == 0 ? _photos() : _albums(),
                            );
                          }),
                    ),
                  ),
                ),
              ],
            ),
            FloatingLoadingBarForStack(syncingStream: syncingStreamClass),
          ],
        ),
      ),
    );
  }

  _openDB() async {
    openDB = await dbManager.dbManagerStartDB();
    syncFiles = SyncFiles(syncingStreamClass, openDB);
    await _loadDirectoriesFromDB();
    print('DB Initialized');
  }

  _initTextControllers() {
    colorAnimationController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    albumAnimation = ColorTween(begin: Colors.black, end: Colors.blueAccent)
        .animate(colorAnimationController)
      ..addListener(() {
        setState(() {});
      });
    photoAnimation = ColorTween(begin: Colors.blueAccent, end: Colors.black)
        .animate(colorAnimationController)
      ..addListener(() {
        setState(() {});
      });
  }

  /// Cria diretorios no banco de dados se nao existirem e aponta os que devem ser atualizados
  _syncDirectories() async {
    List<Directory> directoriesToUpdate = [];
    syncFiles.syncDirectories((event) async {
      if (event == 'done') {
        for (var element in usableDirectories) {
          if (directoriesInDB.toString().contains(element.path)) {
            print('DIR already in DB... DIR: ${element.path}');
            directoriesToUpdate.add(element);

            int lastModified = await directoriesInDB.firstWhere(
                (directoriesInDBElement) => directoriesInDBElement
                    .containsValue(element.path))['Modified'];

            if (lastModified !=
                element.statSync().modified.millisecondsSinceEpoch) {
              /// Se o diretorio foi alterado desde sua ultima observação
              directoriesToUpdate.add(element);
            }
          } else {
            if(element.path.toLowerCase().contains('cancun')){
              directoriesToUpdate.add(element);
            }
            await dbManager.addDirectoryToDB(element.path, openDB,
                element.statSync().modified.millisecondsSinceEpoch);
          }
        }
        await syncFiles.syncFiles(
            directoriesToUpdate); // trocar para directoriesToUpdate
      } else if (!usableDirectories.toString().contains(event)) {
        usableDirectories.add(Directory(event));
        setState(() {});
      }
    });
  }

  _loadDirectoriesFromDB() async {
    directoriesInDB = await dbManager.readListOfDirectories(openDB);
    for (var element in directoriesInDB) {
      if (!usableDirectories.contains(element['DirectoryPath'])) {
        usableDirectories.add(Directory(element['DirectoryPath']));
        setState(() {});
      }
    }
    return true;
  }

  _photos() {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              onTap: () async {
                await _loadDirectoriesFromDB();
                _syncDirectories();
              },
              child: Container(
                height: 50,
                color: Colors.limeAccent,
                child: Text("test"),
              ),
            ),
            GestureDetector(
              onTap: () async {
                syncingStreamClass.streamControllerSink.add('start');
                await Future.delayed(Duration(seconds: 1));
                syncingStreamClass.streamControllerSink.add('Frase 1');
                await Future.delayed(Duration(seconds: 1));
                syncingStreamClass.streamControllerSink.add('Frase 2');
                await Future.delayed(Duration(seconds: 1));
                syncingStreamClass.streamControllerSink.add('stop');
              },
              child: Container(
                height: 50,
                color: Colors.limeAccent,
                child: Text("Colors"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _albums() {
    return AlbumsList(
      albumFolders: usableDirectories,
      openDB: openDB,
      itemTapped: (selectedAlbum) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OpenAlbum(
                    albumsNames: [selectedAlbum], openDB: openDB)));
      },
    );
  }

  Stream<String> syncingFilesStream() async* {}
}
