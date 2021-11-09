import 'dart:ui';

import 'package:flutter/cupertino.dart';

class PortraitTextStyle {
  topText(String s, Color? color) {
    return Text(
      s,
      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: color),
    );
  }
}
