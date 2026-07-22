import 'package:flutter/material.dart';

class KColors {
  static const blue = Color(0xFF2766EF);
  // Brand accents — MUTABLE so the shop "ธีมสี" color sets can reskin the app at
  // runtime (see applyAccentSet + accentSets below). Muted amethyst by default.
  static Color purple = const Color(0xFF7A67C0);
  static Color deepPurple = const Color(0xFF5C4B9E);
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
  static Color purpleCard = const Color(0xFF5C4B9E);
  static Color indigo = const Color(0xFF6E5FB0);
  static const teal = Color(0xFF11C18E);
  static const tealDark = Color(0xFF0E9E78);

  // ── Accent color sets (shop "ธีมสี") ──────────────────────────────────────
  // Each set = [main, deep, mid, card] → maps to [purple, deepPurple, indigo,
  // purpleCard]. Index 0 = ต้นฉบับ (original app colours). Each set is a harmonious
  // multi-shade ramp of ONE hue so buttons/cards/headers reskin cohesively.
  // applyAccentSet reskins the mutable accents + accent-driven gradients below;
  // app.dart applies the active set at startup and whenever the user equips one.
  static const List<List<Color>> accentSets = [
    [Color(0xFF7A67C0), Color(0xFF5C4B9E), Color(0xFF6E5FB0), Color(0xFF5C4B9E)], // ต้นฉบับ
    [Color(0xFF7C5CE6), Color(0xFF5A3EC8), Color(0xFF8E72F0), Color(0xFF4E32B0)], // ไวโอเล็ต
    [Color(0xFF3A78F0), Color(0xFF235FD1), Color(0xFF5B8DF7), Color(0xFF1E4FB8)], // มหาสมุทร
    [Color(0xFF17B890), Color(0xFF0E9E78), Color(0xFF2EC9A6), Color(0xFF0B7A5E)], // เขียวมรกต
    [Color(0xFFF2764B), Color(0xFFD95A2E), Color(0xFFFF9166), Color(0xFFC24A22)], // พระอาทิตย์ตก
    [Color(0xFFE85C97), Color(0xFFC93B76), Color(0xFFF27BAD), Color(0xFFA82C5E)], // กุหลาบ
  ];
  static const List<String> accentSetNames = [
    'ต้นฉบับ', 'ไวโอเล็ต', 'มหาสมุทร', 'เขียวมรกต', 'พระอาทิตย์ตก', 'กุหลาบ',
  ];

  static void applyAccentSet(int i) {
    final s = accentSets[(i < 0 || i >= accentSets.length) ? 0 : i];
    purple = s[0];
    deepPurple = s[1];
    indigo = s[2];
    purpleCard = s[3];
    // Rebuild the accent-driven gradients so themed surfaces (world hero, section
    // header bands) follow the equipped set instead of frozen literal colours.
    purpleRadial = _buildPurpleRadial();
    accentBand = _buildAccentBand();
  }

  // Section-title / card-header band: a subtle same-hue gradient (lighter → main →
  // deep) used by the "banner" treatment. Rebuilt per accent set.
  static LinearGradient accentBand = _buildAccentBand();
  static LinearGradient _buildAccentBand() => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(purple, Colors.white, 0.14)!, purple, deepPurple],
        stops: const [0.0, 0.55, 1.0],
      );

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

  // De-slopped: calm muted radial. Now ACCENT-DRIVEN (deep → mid of the equipped
  // set) so themed surfaces recolour; rebuilt in applyAccentSet.
  static RadialGradient purpleRadial = _buildPurpleRadial();
  static RadialGradient _buildPurpleRadial() => RadialGradient(
        center: const Alignment(0.78, -0.64),
        radius: 1.0,
        colors: [deepPurple, indigo],
      );

  static const orangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [orange, orangeDark],
  );

  // ── Home-tab cards ────────────────────────────────────────────────────────
  // Both home cards use FIXED gradients, deliberately not the accent theme, so
  // equipping a shop colour set never restyles the two primary entry points.
  // Each ramp stays inside one hue family and only shifts a little (blue→teal,
  // amber→clay) instead of the long neon hue sweeps that read as generic.

  // ประเมินสมรรถภาพ — cool "clinic" blue easing into teal.
  static const assessmentInk = Color(0xFF0B5E7A);
  static const assessmentCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E6FA8), Color(0xFF127C93), Color(0xFF0E8A83)],
    stops: [0.0, 0.55, 1.0],
  );

  // เรียนรู้ท่าฝึก — warm amber settling into clay; the counterweight to the
  // cool assessment card so the two never read as the same button twice.
  static const learnCardInk = Color(0xFF8A3F14);
  static const learnCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0912F), Color(0xFFC96A22), Color(0xFFA84E1A)],
    stops: [0.0, 0.55, 1.0],
  );

  // ภารกิจ — green, picking up the lime/green progress fills and reward
  // buttons already used on the quest screen itself.
  static const questCardInk = Color(0xFF14532D);
  static const questCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FA765), Color(0xFF2F8C57), Color(0xFF1E7350)],
    stops: [0.0, 0.55, 1.0],
  );

  // การ์ดเรียนรู้ — indigo easing into plum. The third home card needs to read
  // as a sibling of the other two without repeating either's temperature, so it
  // sits between the assessment card's cool blue and the learn card's warm clay.
  static const cardGameInk = Color(0xFF4A2B6B);
  static const cardGameGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B62B5), Color(0xFF7A55A8), Color(0xFF94498F)],
    stops: [0.0, 0.55, 1.0],
  );

  // ลองเล่นใน 2 นาที — warm amber→ember, distinct from the cool assessment
  // card so the two read as siblings (see home_page.dart _DemoTourCard).
  static const demoTourInk = Color(0xFFB23B2E);
  static const demoTourGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9A2E), Color(0xFFEF5A4C)],
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
