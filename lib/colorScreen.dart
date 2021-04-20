import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/appColors.dart';

class ColorScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
  AppColorsDialgaDos _appColorsDialga = AppColorsDialgaDos();
  AppColorsRayquaza _appColorsRayquaza = AppColorsRayquaza();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Colors'),
      ),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                height: 80,
                color: Colors.black,
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    palleteContainer(color: _appColorsDialga.primaryColor),
                    palleteContainer(color: _appColorsDialga.accentColor),
                    palleteContainer(color: _appColorsDialga.scaffoldBackGround),
                    palleteContainer(color: _appColorsDialga.lightColor),
                    palleteContainer(color: _appColorsDialga.white),
                    palleteContainer(color: _appColorsDialga.black),
                  ],
                )
            ),
            Container(
                height: 80,
                color: Colors.black,
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    palleteContainer(color: Color(0xff295241)), //Primary
                    palleteContainer(color: Color(0xff4a8373)), //Accent
                    palleteContainer(color: Color(0xffd3efdf)), // Scaffold
                    palleteContainer(color: Color(0xff80c5a2)), // Light
                    palleteContainer(color: Color(0xfff1e7b7)), // White
                    palleteContainer(color: Color(0xff566961)), // Black
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }

  palleteContainer({@required Color color}){
    return Container(
      height: 60,
      width: 60,
      color: color,
    );
  }

}
