import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/clipRecct.dart';
import 'package:sqflite/sqflite.dart';

class AlbumsList extends StatefulWidget {
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
  State<AlbumsList> createState() => _AlbumsListState();
}

class _AlbumsListState extends State<AlbumsList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6),
      child: GridView.builder(
          itemCount: widget.albumFolders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1 / 1.2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            crossAxisCount: (MediaQuery.of(context).size.width / 120).round(),
          ),
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () => widget.presentation!
                  ? widget.itemTapped(widget.albumFolders[0])
                  : widget.itemTapped(widget.albumFolders[index][0]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Container(
                          child: widget.albumFolders[index][1] == ''
                              ? MyClipRRect().myClipRRect(
                                  Container(color: Colors.blueAccent))
                              : MyClipRRect().myClipRRect(Container(
                                  width: 120,
                                  child: Image.file(
                                      File(widget.albumFolders[index][1]),
                                      fit: BoxFit.cover,
                                      cacheWidth: 180,
                                      height: 180))))),
                  Container(
                      height: 40,
                      child: Text(widget.albumFolders[index][0],
                          style: TextStyle(
                              fontSize: 15, fontFamily: 'RobotoMono')))
                ],
              ),
            );
          }),
    );
  }
}
