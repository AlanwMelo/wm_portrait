import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/fileProcessor.dart';
import 'package:portrait/classes/usableFilesForList.dart';
import 'package:portrait/db/dbManager.dart';

class OpenAlbum extends StatefulWidget {
  final List<String> albumsNames;

  const OpenAlbum({Key? key, required this.albumsNames}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _OpenAlbumState();
}

class _OpenAlbumState extends State<OpenAlbum> {
  late String displayName;
  List<Map> datedFiles = [];
  List<List> listOfLists = [];

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
        body: ListView.builder(
          shrinkWrap: true,
          itemCount: listOfLists.length,
          itemBuilder: (context, index) {
            return Container(child: _imagesOfTheDay(index));
          },
        ));
  }

  _appBar() {
    return AppBar(
      centerTitle: true,
      title: GestureDetector(
          onTap: () async {
            await FileProcessor()
                .generateLocalInfo(widget.albumsNames[0], forceResync: true);
          },
          child: Text(displayName)),
      elevation: 0,
    );
  }

  _getFilesOfDir() async {
    /// Create a list with all files mapped with date
    var result = await dbManager.readDirectoryOfFiles(widget.albumsNames[0]);

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

      DateTime getConvertedDate =
          DateTime.fromMillisecondsSinceEpoch(usableFile.createdDate);
      String convertedDate =
          '${getConvertedDate.day.toString().padLeft(2, '0')}/${getConvertedDate.month}/${getConvertedDate.year}';
      Map mapWithDates =
          await _createMap(element['Created'], convertedDate, usableFile);

      datedFiles.add(mapWithDates);
    }
    _createLists();
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
                shrinkWrap: true,
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
