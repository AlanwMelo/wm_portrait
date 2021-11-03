import 'package:flutter/cupertino.dart';

class MyClipRRect {
  myClipRRect(Widget child) {
    return ClipRRect(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
            topLeft: Radius.circular(10)),
        child: child);
  }
}
