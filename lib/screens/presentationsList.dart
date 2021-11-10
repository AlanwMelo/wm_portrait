import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/db/dbManager.dart';
import 'package:portrait/screens/albumsList.dart';
import 'package:portrait/classes/textStyle.dart';
import 'package:portrait/screens/openPresentation.dart';
import 'package:sqflite/sqflite.dart';

class PresentationsList extends StatefulWidget {
  final Database openDB;

  const PresentationsList({Key? key, required this.openDB}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PresentationsListState(openDB);
}

class _PresentationsListState extends State<PresentationsList> {
  final Database openDB;

  _PresentationsListState(this.openDB);

  MyDbManager dbManager = MyDbManager();
  List<String> presentationsList = ['lista Total'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _floatingActionButton(),
      body: SafeArea(
          child: Container(
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(12),
                    child: Center(
                      child: PortraitTextStyle()
                          .topText('Presentations lists', Colors.blueAccent),
                    ),
                  ),
                ),
              ],
            ),
            presentationsList.isEmpty
                ? Expanded(
                    child: Center(
                    child: Container(
                      child: _newPresentationButton(),
                    ),
                  ))
                : Container(),
            _body(),
          ],
        ),
      )),
    );
  }

  _body() {
    return presentationsList.isEmpty
        ? Container()
        : Expanded(
            child: Container(
                child: AlbumsList(
            albumFolders: presentationsList,
            openDB: openDB,
            presentation: true,
            itemTapped: (selectedPresentation) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OpenPresentation(
                          presentationName: selectedPresentation,
                          openDB: openDB)));
            },
          )));
  }

  _newPresentationButton() {
    return Container(
      height: 175,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Colors.blueAccent, shape: CircleBorder()),
        onPressed: () async {
          /*showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return NewListDialog(
                    alertTitle: 'Criar nova lista',
                    answer: (answer) {
                      _addItemToList(answer);
                    });
              });*/
        },
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New presentation', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Icon(Icons.play_circle_outline),
          ],
        )),
      ),
    );
  }

  _floatingActionButton() {
    return FloatingActionButton(onPressed: () async {
      await dbManager.createNewPresentation(
          'lista Total', openDB, DateTime.now().millisecondsSinceEpoch);
      var result = await dbManager.readAllFromAllFiles(openDB);
      for (var element in result) {
        await dbManager.insertIntoPresentationFiles(
            'lista Total',
            element['FileName'],
            element['FileType'],
            element['FilePath'],
            element['ThumbPath'],
            element['FileOrientation'],
            element['VideoDuration'],
            element['SpecialIMG'],
            element['Created'],
            openDB);
      }
    });
  }
}
