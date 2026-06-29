import 'package:flutter/material.dart';

class KColors {
  static const blue = Color(0xFF2766EF);
  static const purple = Color(0xFFA556ED);
  static const deepPurple = Color(0xFF6F1BC8);
  static const greenLight = Color(0xFF8BFA48);
  static const greenDark = Color(0xFF5EC832);
  static const pinkLight = Color(0xFFFFA08D);
  static const pinkDark = Color(0xFFFD4C86);
  static const cardBg = Color(0xFFF9F9F9);
  static const navyText = Color(0xFF1F2F66);
  static const darkText = Color(0xFF262626);
  static const labelBlue = Color(0xFF8395FF);
  static const orange = Color(0xFFFFC107);
  static const orangeDark = Color(0xFFFFA000);
  static const white = Colors.white;
  static const purpleCard = Color(0xFF6F1BC8);
  static const indigo = Color(0xFF6349F1);
  static const teal = Color(0xFF11C18E);
  static const tealDark = Color(0xFF0E9E78);

  static const greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [greenLight, greenDark],
  );

  static const pinkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pinkLight, pinkDark],
  );

  static const blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blue, purple],
  );

  static const purpleRadial = RadialGradient(
    center: Alignment(0.78, -0.64),
    radius: 1.0,
    colors: [Color(0xFF6F1BC8), Color(0xFFB83FF4)],
  );

  static const orangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [orange, orangeDark],
  );

  // Healthcare palette for the fitness-assessment module.
  static const tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, blue],
  );
}

// The whole app now uses Kanit (Cadson Demak), bundled in assets/fonts so it works offline.
// Kanit covers both Thai and Latin, so every text helper routes to it — keeping the names/signatures
// so no call sites need to change. Weights map to the bundled .ttf files declared in pubspec.yaml.
const String _kanit = 'Kanit';

TextStyle montserrat({
  double size = 16,
  FontWeight weight = FontWeight.w700,
  Color color = KColors.navyText,
  FontStyle style = FontStyle.normal,
}) =>
    TextStyle(
        fontFamily: _kanit, fontSize: size, fontWeight: weight, color: color, fontStyle: style);

TextStyle nunito({
  double size = 16,
  FontWeight weight = FontWeight.w900,
  Color color = Colors.white,
  FontStyle style = FontStyle.normal,
}) =>
    TextStyle(
        fontFamily: _kanit, fontSize: size, fontWeight: weight, color: color, fontStyle: style);

TextStyle poppins({
  double size = 16,
  FontWeight weight = FontWeight.w400,
  Color color = Colors.white,
}) =>
    TextStyle(fontFamily: _kanit, fontSize: size, fontWeight: weight, color: color);

/// Thai text helper — now Kanit (was Noto Sans Thai). Kept for the assessment module call sites.
TextStyle thaiSans({
  double size = 16,
  FontWeight weight = FontWeight.w700,
  Color color = KColors.navyText,
}) =>
    TextStyle(fontFamily: _kanit, fontSize: size, fontWeight: weight, color: color);

BoxDecoration cardDecoration({double radius = 25, Color color = KColors.cardBg}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 4))],
    );
