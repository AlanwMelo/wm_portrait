import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/fileProcessor.dart';
import 'package:portrait/classes/usableFilesForList.dart';
import 'package:portrait/db/dbManager.dart';
import 'package:sqflite/sqflite.dart';

class OpenAlbum extends StatefulWidget {
  final List<String> albumsNames;
  final Database openDB;

  const OpenAlbum({Key? key, required this.albumsNames, required this.openDB})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _OpenAlbumState(openDB);
}

class _OpenAlbumState extends State<OpenAlbum> {
  final Database openDB;

  _OpenAlbumState(this.openDB);

  late String displayName;
  List<Map> datedFiles = [];
  List<List> listOfLists = [];
  List allFiles = [];

  MyDbManager dbManager = MyDbManager();

  @override
  void initState() {
    _getFilesOfDir();
    _getDisplayName(widget.albumsNames);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _appBar(),
        body: Container(
          child: GridView.builder(
              shrinkWrap: true,
              itemCount: allFiles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 1,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                crossAxisCount:
                    (MediaQuery.of(context).size.width / 120).round(),
              ),
              itemBuilder: (BuildContext context, int itemIndex) {
                return GestureDetector(
                    onTap: () {},
                    child: Stack(fit: StackFit.expand, children: [
                      _ImageBuilder(image: allFiles[itemIndex][1]),
                      Container(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                            allFiles[itemIndex][0].fileType == 'video'
                                ? Row(
                                    children: [
                                      Container(
                                        margin:
                                            EdgeInsets.only(left: 6, bottom: 6),
                                        child: Icon(Icons.play_circle_fill,
                                            size: 15, color: Colors.white),
                                      ),
                                    ],
                                  )
                                : Container(),
                            allFiles[itemIndex][0].specialIMG == 'true'
                                ? Row(
                                    children: [
                                      Container(
                                          margin: EdgeInsets.only(
                                              left: 6, bottom: 6),
                                          child: Image.asset(
                                              "lib/assets/icons/360-graus.png",
                                              color: Colors.white,
                                              height: 15)),
                                    ],
                                  )
                                : Container(),
                            Container(
                                color: Colors.black.withOpacity(0.3),
                                height: 20,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                          margin: EdgeInsets.only(left: 4),
                                          child: allFiles[itemIndex][0]
                                                      .fileName
                                                      .length >=
                                                  14
                                              ? Text(
                                                  allFiles[itemIndex][0]
                                                      .fileName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )
                                              : Text(
                                                  allFiles[itemIndex][0]
                                                      .fileName,
                                                  style: TextStyle(
                                                      color: Colors.white))),
                                    )
                                  ],
                                ))
                          ]))
                    ]));
              }),
        ));
  }

  _appBar() {
    return AppBar(
      centerTitle: true,
      title: GestureDetector(
          onTap: () async {
            Database openDB = await dbManager.dbManagerStartDB();
            await FileProcessor().generateLocalInfo(
                widget.albumsNames[0], openDB,
                forceResync: true);
          },
          child: Text(displayName)),
      elevation: 0,
    );
  }

  _getFilesOfDir() async {
    /// Create a list with all files mapped with date
    /*var result =
        await dbManager.readDirectoryOfFiles(widget.albumsNames[4], openDB);*/

    var result = await dbManager.readDirectoryFromAllFiles(
        widget.albumsNames[0], openDB);

    for (var element in result) {
      UsableFilesForList usableFile = UsableFilesForList(
          element['FilePath'],
          element['FileName'],
          element['ThumbPath'],
          element['FileType'],
          element['VideoDuration'],
          element['FileOrientation'],
          element['SpecialIMG'],
          element['Created']);

      File thumbFile = File(element['ThumbPath']);

      allFiles.add([usableFile, thumbFile]);
      allFiles.sort((a, b) => b[0].createdDate.compareTo(a[0].createdDate));
      setState(() {});

      /*DateTime getConvertedDate =
      DateTime.fromMillisecondsSinceEpoch(usableFile.createdDate);
      String convertedDate =
          '${getConvertedDate.day.toString().padLeft(2, '0')}/${getConvertedDate.month}/${getConvertedDate.year}';
      Map mapWithDates =
      await _createMap(element['Created'], convertedDate, usableFile);

      datedFiles.add(mapWithDates);*/
    }

    // _createLists();
  }

  _createLists() {
    List getDates = [];

    /// Extrai as datas distintas entre o mapa de listas e cria uma lista para cada
    for (var element in datedFiles) {
      getDates.add(element['convertedDate']);
    }
    for (var element in getDates.toSet().toList()) {
      List filesOfTheDay = [];
      for (var secondElement in datedFiles) {
        if (secondElement['convertedDate'] == element) {
          filesOfTheDay.add(secondElement);
        }
      }
      filesOfTheDay
          .sort((a, b) => b['dayTimeStamp'].compareTo(a['dayTimeStamp']));
      listOfLists.add(filesOfTheDay);
    }
    listOfLists
        .sort((a, b) => b[0]['dayTimeStamp'].compareTo(a[0]['dayTimeStamp']));
    setState(() {});
  }

  _createMap(
      int timestamp, String convertedDate, UsableFilesForList usableFiles) {
    Map<String, dynamic> fileToList = {
      "dayTimeStamp": timestamp,
      "convertedDate": convertedDate,
      "file": usableFiles,
    };

    return fileToList;
  }

  _getDisplayName(List<String> albumsNames) {
    String albumName;
    albumName = albumsNames[0].substring(0, albumsNames[0].length - 1);
    albumName = albumName.substring(albumName.lastIndexOf('/') + 1);
    displayName = albumName;
  }

  _imagesOfTheDay(int listIndex) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6, left: 6),
            child: _dateText(listOfLists[listIndex][0]['convertedDate']),
          ),
          Container(
            margin: EdgeInsets.only(top: 6),
            child: GridView.builder(
                physics: ScrollPhysics(),
                itemCount: listOfLists[listIndex].length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 1,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  crossAxisCount:
                      (MediaQuery.of(context).size.width / 120).round(),
                ),
                itemBuilder: (BuildContext context, int itemIndex) {
                  UsableFilesForList usableFile =
                      listOfLists[listIndex][itemIndex]['file'];

                  return GestureDetector(
                      onTap: () {},
                      child: Stack(fit: StackFit.expand, children: [
                        Image.file(new File(usableFile.thumbPath),
                            fit: BoxFit.cover),
                        Container(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                              usableFile.fileType == 'video'
                                  ? Row(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(
                                              left: 6, bottom: 6),
                                          child: Icon(Icons.play_circle_fill,
                                              size: 15, color: Colors.white),
                                        ),
                                      ],
                                    )
                                  : Container(),
                              usableFile.specialIMG == 'true'
                                  ? Row(
                                      children: [
                                        Container(
                                            margin: EdgeInsets.only(
                                                left: 6, bottom: 6),
                                            child: Image.asset(
                                                "lib/assets/icons/360-graus.png",
                                                color: Colors.white,
                                                height: 15)),
                                      ],
                                    )
                                  : Container(),
                              Container(
                                  color: Colors.black.withOpacity(0.3),
                                  height: 20,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                            margin: EdgeInsets.only(left: 4),
                                            child: usableFile.fileName.length >=
                                                    14
                                                ? Text(
                                                    usableFile.fileName,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  )
                                                : Text(usableFile.fileName,
                                                    style: TextStyle(
                                                        color: Colors.white))),
                                      )
                                    ],
                                  ))
                            ]))
                      ]));
                }),
          ),
        ],
      ),
    );
  }

  _dateText(String text) {
    return Text(text, style: TextStyle(fontFamily: 'RobotoMono', fontSize: 13));
  }
}

class _ImageBuilder extends StatefulWidget {
  final File image;

  const _ImageBuilder({Key? key, required this.image}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageBuilderState(image);
}

/// Carrega primeiro uma imagem de qualidade ruim e somente depois uma com qualidade boa para poupar memória
class _ImageBuilderState extends State<_ImageBuilder> {
  final File image;

  _ImageBuilderState(this.image);

  late Widget child;

  @override
  void initState() {
    child = Container(
        key: Key('firstImage'),
        height: 150,
        width: 150,
        child:
            Image.file(image, fit: BoxFit.cover, cacheWidth: 60, height: 60));
    _fullImageLoader();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 2000),
      child: child,
      switchInCurve: Curves.ease,
    );
  }

  _fullImageLoader() async {
    await Future.delayed(Duration(seconds: 1));
    child = Container(
        key: Key('secondImage'),
        height: 150,
        width: 150,
        child:
            Image.file(image, fit: BoxFit.cover, cacheWidth: 200, height: 200));

    /// Checa se o widget esta montado antes de chamar o setstate
    if (this.mounted) {
      setState(() {});
    }
  }
}
