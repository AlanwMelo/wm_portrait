import 'package:flutter/material.dart';
import 'package:portrait/classes/appColors.dart';
import 'package:portrait/db/dbManager.dart';
import 'dart:io';

import 'file:///C:/Users/AlanWillianMelo/AndroidStudioProjects/portrait/lib/screens/openList.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final MyDbManager dbManager = MyDbManager();

  @override
  _MyAppState createState() {
    dbManager.createDB();
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WG Portrait',
      theme: ThemeData(
        primaryColor: AppColorsDialga().primaryColor(),
        accentColor: AppColorsDialga().accentColor(),
        scaffoldBackgroundColor: AppColorsDialga().scaffoldBackGround(),
      ),
      home: MyHomePage(title: 'WG Portrait'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String testeIMG;
  int _counter = 0;

  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OpenList(
                              listName: 'thisList',
                              appName: widget.title,
                              screenSize: MediaQuery.of(context).size.height -
                                  89.1 -
                                  //tamanho dos widgets da outra tela
                                  40)));
                },
                child: Container(
                  height: 50,
                  color: Colors.limeAccent,
                  child: Text("test"),
                ),
              ),
              testeIMG == null
                  ? Container()
                  : Container(child: Image.file(new File(testeIMG))),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
