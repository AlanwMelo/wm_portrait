import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/clipRecct.dart';
import 'package:portrait/screens/openAlbum.dart';
import 'package:sqflite/sqflite.dart';

class AlbumsList extends StatelessWidget {
  final List<Directory> directories;
  final Database openDB;

  const AlbumsList({Key? key, required this.directories, required this.openDB})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6),
      child: GridView.builder(
          itemCount: directories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1 / 1.2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            crossAxisCount: (MediaQuery.of(context).size.width / 120).round(),
          ),
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OpenAlbum(
                            albumsNames: [directories[index].path],
                            openDB: openDB)));
              },
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
    String dirName = directories[index].path;
    dirName = dirName.substring(0, dirName.lastIndexOf('/'));
    dirName = dirName.substring(dirName.lastIndexOf('/') + 1);

    return Text(dirName,
        style: TextStyle(fontSize: 15, fontFamily: 'RobotoMono'));
  }
}
