import 'package:card_swiper/card_swiper.dart';
import 'package:file_manager/controller/file_manager_controller.dart';
import 'package:file_manager/file_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:portrait/classes/appColors.dart';
import 'package:portrait/classes/clipRecct.dart';
import 'package:portrait/classes/directoryManager.dart';
import 'package:portrait/colorScreen.dart';
import 'package:portrait/db/dbManager.dart';
import 'dart:io';
import 'package:portrait/screens/openList.dart';

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
  String? testeIMG;
  int animatedTextIndex = 0;

  // List with all directories that contains images or videos
  List<Directory> usableDirectories = [];

  // Animated Text color controllers
  late Animation<Color?> photoAnimation;
  late Animation<Color?> albumAnimation;
  late AnimationController colorAnimationController;

  SwiperController swiperController = SwiperController();
  List<Widget> swiperItems = [];

  @override
  void initState() {
    _initTextControllers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                            child: _topText('Photos', photoAnimation.value),
                          ),
                          GestureDetector(
                            onTap: () {
                              colorAnimationController.forward();
                              swiperController.move(1);
                            },
                            child: _topText('Albums', albumAnimation.value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                      onTap: () {
                        print('ayaya');
                      },
                      child: Container(child: Icon(Icons.more_vert_rounded))),
                ],
              ),
            ),
            Expanded(
              child: Container(
                child: NotificationListener<OverscrollIndicatorNotification>(
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
      ),
    );
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

  _photos() {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              onTap: () async {
                DirectoryManager().getDirectoriesWithImagesAndVideos((answer) {
                  answer.forEach((element) {
                    usableDirectories.add(Directory(element));
                    setState(() {
                      print('add');
                    });
                  });
                });
              },
              child: Container(
                height: 50,
                color: Colors.limeAccent,
                child: Text("test"),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ColorScreen()));
              },
              child: Container(
                height: 50,
                color: Colors.limeAccent,
                child: Text("Colors"),
              ),
            ),
            testeIMG == null
                ? Container()
                : Container(child: Image.file(new File(testeIMG!))),
          ],
        ),
      ),
    );
  }

  _albums() {
    return Container(
      padding: EdgeInsets.all(6),
      child: GridView.builder(
          itemCount: usableDirectories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            crossAxisCount: (MediaQuery.of(context).size.width / 120).round(),
          ),
          itemBuilder: (BuildContext context, int index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Container(
                        child: MyClipRRect()
                            .myClipRRect(Container(color: Colors.blueAccent)))),
                Container(height: 40, child: _albumsName(index))
              ],
            );
            /*return Container(
              child: MyClipRRect().myClipRRect(Container(
                color: Colors.blueAccent,
              )),
            );*/
          }),
    );
  }

  _topText(String s, Color? color) {
    return Text(
      s,
      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: color),
    );
  }

  _albumsName(int index) {
    String dirName = usableDirectories[index].path;
    dirName = dirName.substring(0, dirName.lastIndexOf('/'));
    dirName = dirName.substring(dirName.lastIndexOf('/') + 1);

    return Text(dirName, style: TextStyle(fontSize: 15,
    fontFamily: 'RobotoMono'));
  }
}
