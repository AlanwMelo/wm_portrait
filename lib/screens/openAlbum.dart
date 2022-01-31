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
  final bool hideAppBar;

  const OpenAlbum(
      {Key? key,
      required this.albumsNames,
      required this.openDB,
      this.hideAppBar = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _OpenAlbumState(openDB);
}

class _OpenAlbumState extends State<OpenAlbum> {
  final Database openDB;

  _OpenAlbumState(this.openDB);

  late String displayName;
  List differentDates = [];
  List allFiles = [];
  List<List> allLists = [];
  MyDbManager dbManager = MyDbManager();

  @override
  void initState() {
    _getAllFilesOfDir();
    _getDisplayName(widget.albumsNames);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _appBar(),
        body: Container(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: differentDates.length,
                itemBuilder: (BuildContext context, int itemIndex) {
                  return Column(
                    children: [
                      Row(
                        children: [_dateText(differentDates[itemIndex])],
                      ),
                      _imagesOfTheDay(allLists[itemIndex]),
                    ],
                  );
                })));
  }

  _appBar() {
    return widget.hideAppBar
        ? AppBar(
            toolbarHeight: 0,
          )
        : AppBar(
            centerTitle: true,
            title: GestureDetector(
                onTap: () async {
                  setState(() {
                    print('clever');
                  });
                },
                child: Text(displayName)),
            elevation: 0,
          );
  }

  _getAllFilesOfDir() async {
    for (var element in widget.albumsNames) {
      print(element);

      var result = await dbManager.readDirectoryFromAllFiles(element, openDB);

      for (var element in result) {
        UsableFilesForList usableFile = UsableFilesForList(
            element['FilePath'],
            element['FileName'],
            element['ThumbPath'],
            element['FileType'],
            element['VideoDuration'],
            element['FileOrientation'],
            element['SpecialIMG'],
            element['CreatedDay'],
            element['Created']);

        File thumbFile = File(element['ThumbPath']);

        allFiles.add([usableFile, thumbFile]);
      }
      allFiles.sort((a, b) => b[0].createdDate.compareTo(a[0].createdDate));
    }
    _createLists();
  }

  _createLists() {
    // Extrai as datas distintas entre o mapa de listas e cria uma lista para cada
    List getDates = [];

    for (var file in allFiles) {
      getDates.add(file[0].createdDay);
    }
    differentDates.addAll(getDates.toSet().toList());

    for (var item in differentDates) {
      List filesByDay = [];
      filesByDay
          .addAll(allFiles.where((element) => element[0].createdDay == item));
      allLists.add(filesByDay);
    }
    setState(() {});
  }

  _getDisplayName(List<String> albumsNames) {
    String albumName;
    albumName = albumsNames[0].substring(0, albumsNames[0].length - 1);
    albumName = albumName.substring(albumName.lastIndexOf('/') + 1);
    displayName = albumName;
  }

  _imagesOfTheDay(List imagesOfTheDay) {
    List<Widget> myGrid = [];
    imagesOfTheDay.forEach((item) {
      myGrid.add(Container(
        height: (MediaQuery.of(context).size.width / 4) - 3,
        width: (MediaQuery.of(context).size.width / 4) - 3,
        child: Stack(fit: StackFit.expand, children: [
          _ImageBuilder(image: item[1]),
          Container(
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            item[0].fileType == 'video'
                ? Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 6, bottom: 6),
                        child: Icon(Icons.play_circle_fill,
                            size: 15, color: Colors.white),
                      ),
                    ],
                  )
                : Container(),
            item[0].specialIMG == 'true'
                ? Row(
                    children: [
                      Container(
                          margin: EdgeInsets.only(left: 6, bottom: 6),
                          child: Image.asset("lib/assets/icons/360-graus.png",
                              color: Colors.white, height: 15)),
                    ],
                  )
                : Container(),
          ]))
        ]),
      ));
    });
    return Container(
      margin: EdgeInsets.only(right: 3, left: 3),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          runSpacing: 2,
          spacing: 2,
          children: myGrid,
        ),
      ),
    );
  }

  _dateText(String text) {
    return Container(
        margin: EdgeInsets.all(8),
        child: Text(text,
            style: TextStyle(fontFamily: 'RobotoMono', fontSize: 15)));
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
        color: const Color(0xffabb2b9));
    _fullImageLoader();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
    );
  }

  _fullImageLoader() async {
    await Future.delayed(Duration(seconds: 1));
    child = Container(
        key: Key('secondImage'),
        height: 150,
        width: 150,
        child:
            Image.file(image, fit: BoxFit.cover, cacheWidth: 180, height: 180));

    /// Checa se o widget esta montado antes de chamar o setstate
    if (this.mounted) {
      setState(() {});
    }
  }
}
