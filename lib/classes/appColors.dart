import 'dart:ui';

class AppColors {
  final Color primaryColor;
  final Color accentColor;
  final Color scaffoldBackGround;
  final Color white;
  final Color lightColor;
  final Color black;

  AppColors(this.primaryColor, this.accentColor, this.scaffoldBackGround,
      this.white, this.lightColor, this.black);
}

class AppColorsDialgaDos extends AppColors {
  AppColorsDialgaDos()
      : super(
      //primaryColor
      const Color(0xff205a94),
      //accentColor
      const Color(0xff397bb4),
      //scaffoldBackGround
      const Color(0xffdeeeff),
      //white
      const Color(0xffbdcdde),
      //lightColor
      const Color(0xff9cd5f6),
      //black
      const Color(0xff414152));
}
class AppColorsRayquaza extends AppColors {
  AppColorsRayquaza()
      : super(
      //primaryColor
      const Color(0xff205a94),
      //accentColor
      const Color(0xff397bb4),
      //scaffoldBackGround
      const Color(0xffdeeeff),
      //white
      const Color(0xffbdcdde),
      //lightColor
      const Color(0xff9cd5f6),
      //black
      const Color(0xff9cd5f6));
}

class AppColorsDialga {
  /// Paleta https://htmlcolorcodes.com/color-chart/ FLAT color

  primaryColor() {
    return const Color(0xff205a94);
  }

  accentColor() {
    return const Color(0xff397bb4);
  }

  scaffoldBackGround() {
    return const Color(0xffdeeeff);
  }

  white() {
    return const Color(0xffbdcdde);
  }

  black() {
    return const Color(0xff414152);
  }
  lightColor() {
    return const Color(0xff9cd5f6);
  }
}
