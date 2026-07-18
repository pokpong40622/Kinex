import 'package:flutter/material.dart';

class KColors {
  static const blue = Color(0xFF2766EF);
  // Purple kept as brand, but MUTED to one calm shade family (no more vivid violet).
  static const purple = Color(0xFF7A67C0);
  static const deepPurple = Color(0xFF5C4B9E);
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
  static const purpleCard = Color(0xFF5C4B9E);
  static const indigo = Color(0xFF6E5FB0);
  static const teal = Color(0xFF11C18E);
  static const tealDark = Color(0xFF0E9E78);

  // De-slop tokens: solid near-white app background + hairline border for flat cards.
  static const appBg = Color(0xFFFAFAFB);
  static const hairline = Color(0x14000000);

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

  // De-slopped: was blue→purple. Now a subtle same-hue blue (no purple gradient).
  static const blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3B78F0), blue],
  );

  // De-slopped: was a vivid violet radial. Now a calm muted-purple, low-contrast.
  static const purpleRadial = RadialGradient(
    center: Alignment(0.78, -0.64),
    radius: 1.0,
    colors: [Color(0xFF5C4B9E), Color(0xFF6E5FB0)],
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

  // De-slopped: near-neutral off-white (dropped the green tint) for a calm page bg.
  static const assessmentBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF6F8F8), appBg],
  );

  // Primary teal action button — brighter top-left, deeper bottom-right for depth.
  static const tealButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22D3A6), tealDark],
  );

  // De-slopped: dropped the lilac tint for a calm neutral off-white.
  static const learnBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F7F9), appBg],
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

// De-slopped: flat card — white fill + hairline border + a whisper of lift (no big
// soft drop-shadow). Default radius calmed from 25 → 20.
BoxDecoration cardDecoration({double radius = 20, Color color = KColors.white}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: KColors.hairline, width: 1),
      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 1))],
    );
