import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/clipRecct.dart';
import 'package:sqflite/sqflite.dart';

class AlbumsList extends StatelessWidget {
  final List albumFolders;
  final Database openDB;
  final Function(String) itemTapped;
  final bool? presentation;

  const AlbumsList(
      {Key? key,
      required this.albumFolders,
      required this.openDB,
      required this.itemTapped,
      this.presentation = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6),
      child: GridView.builder(
          itemCount: albumFolders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1 / 1.2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            crossAxisCount: (MediaQuery.of(context).size.width / 120).round(),
          ),
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () => presentation!
                  ? itemTapped(albumFolders[0])
                  : itemTapped(albumFolders[index].path),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Container(
                          child: MyClipRRect().myClipRRect(
                              Container(color: Colors.blueAccent)))),
                  Container(height: 40, child: _albumsName(index))
                ],
              ),
            );
          }),
    );
  }

  _albumsName(int index) {
    if (albumFolders.runtimeType.toString() == 'List<String>') {
      return Text(albumFolders[0],
          style: TextStyle(fontSize: 15, fontFamily: 'RobotoMono'));
    }
    if (albumFolders.runtimeType.toString() == 'List<Directory>') {
      String dirName = albumFolders[index].path;
      dirName = dirName.substring(0, dirName.lastIndexOf('/'));
      dirName = dirName.substring(dirName.lastIndexOf('/') + 1);

      return Text(dirName,
          style: TextStyle(fontSize: 15, fontFamily: 'RobotoMono'));
    }
  }
}
