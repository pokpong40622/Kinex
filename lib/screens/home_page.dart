import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          // Home "World" card now launches Kinex World (the exercise class).
          // MEGA DANCE stays reachable from the Practice tab.
          _HomeTab(onStartGame: () => context.go('/world')),
          const _QuestTab(),
          _PracticeTab(onStartGame: () => context.go('/mega-dance')),
          const _InfoTab(),
        ],
      ),
      bottomNavigationBar: _KinexNavBar(
        selected: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Bottom Navigation ───────────────────────────────────────────────────────

class _KinexNavBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _KinexNavBar({required this.selected, required this.onTap});

  static const _labels = ['Home', 'Quest', 'Practice', 'Info'];
  static const _icons = [
    'assets/images/nav_home.png',
    'assets/images/nav_quest.png',
    'assets/images/nav_practice.png',
    'assets/images/nav_info.png',
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(w * 0.030, 10, w * 0.030, 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x73A7A7A7), width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (i) {
                  final active = i == selected;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: active ? 1.0 : 0.4,
                          child: Image.asset(_icons[i], width: 42, height: 42),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[i],
                          style: montserrat(
                            size: 12,
                            weight: FontWeight.w900,
                            color: active
                                ? KColors.navyText
                                : KColors.navyText.withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── HOME TAB ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final VoidCallback onStartGame;
  const _HomeTab({required this.onStartGame});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.035, w * 0.04, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: const _ProfileCard()),
                    SizedBox(width: w * 0.025),
                    const _TopBarIconButton(
                      asset: 'assets/images/icon_bluetooth.png',
                      solidBorderColor: Color(0xFF60A343),
                    ),
                    SizedBox(width: w * 0.025),
                    const _TopBarIconButton(
                      asset: 'assets/images/icon_notif.png',
                      gradientBorder: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.26, 0.67],
                        colors: [Color(0xFFFFC107), Color(0xFFF44336)],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: h * 0.025),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.02),
                // 35% smaller: 65% width (left-aligned) keeps the card's aspect ratio so the
                // width-driven content scales down with the reduced height (see card heights).
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.65,
                    child: _WorldCard(
                      onTap: onStartGame,
                      gradient: KColors.purpleRadial,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.02),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.65,
                    child: _AssessmentCard(
                      onTap: () => context.push('/assessment'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Home-tab entry point for the elderly fitness-assessment module.
/// Styled after [_WorldCard] but in the healthcare (teal→blue) palette.
class _AssessmentCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AssessmentCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final cardH = h * 0.145; // ~25% smaller than the old 0.195 (0.127 clipped the content)
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: cardH,
        child: LayoutBuilder(
          builder: (context, cs) {
            final cw = cs.maxWidth;
            // Use card height for vertical spacing so the column never exceeds
            // the card's fixed height, regardless of device aspect ratio.
            final vPad = cardH * 0.12;
            final gap1 = cardH * 0.04;
            final gap2 = cardH * 0.06;
            final btnVPad = cw * 0.025;
            return Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                gradient: KColors.tealGradient,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withAlpha(112), width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20,
                      offset: Offset(5, 5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          cw * 0.06, vPad, cw * 0.03, vPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ประเมินสมรรถภาพ',
                              style: thaiSans(
                                  size: cw * 0.060,
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                          SizedBox(height: gap1),
                          Text('ทดสอบสมรรถภาพทางกายสำหรับผู้สูงอายุ',
                              style: thaiSans(
                                  size: cw * 0.030,
                                  weight: FontWeight.w600,
                                  color: Colors.white)),
                          SizedBox(height: gap2),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: cw * 0.05, vertical: btnVPad),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('เริ่มประเมิน',
                                style: thaiSans(
                                    size: cw * 0.036,
                                    weight: FontWeight.w800,
                                    color: KColors.tealDark)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: cw * 0.05),
                    child: Icon(Icons.monitor_heart_rounded,
                        size: cw * 0.22, color: Colors.white.withAlpha(230)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final String asset;
  final Color? solidBorderColor;
  final LinearGradient? gradientBorder;

  const _TopBarIconButton({
    required this.asset,
    this.solidBorderColor,
    this.gradientBorder,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.135;
    final radius = size * 0.28;

    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: KColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: solidBorderColor != null
            ? Border.all(color: solidBorderColor!, width: 3)
            : null,
        boxShadow: const [
          BoxShadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(asset, fit: BoxFit.contain),
    );

    if (gradientBorder != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradientBorder,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            color: KColors.cardBg,
            borderRadius: BorderRadius.circular(radius - 3),
          ),
          padding: EdgeInsets.all(size * 0.14),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      );
    }

    return inner;
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final cardH = h * 0.10;
    final avatarR = cardH * 0.48;

    return SizedBox(
      height: cardH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardH / 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000),
                blurRadius: 8,
                offset: Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardH / 2),
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: const Color(0xFFF4F4F4))),
              Positioned(
                left: avatarR * 0.4,
                top: cardH * 0.55,
                bottom: 0,
                right: 0,
                child: Container(color: KColors.blue),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: avatarR * 0.15),
                  Container(
                    width: avatarR * 2,
                    height: avatarR * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border:
                          Border.all(color: const Color(0xFFBEBEBE), width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x25000000),
                            blurRadius: 6,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/app_logo.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/icon_award.png',
                                width: w * 0.065),
                            SizedBox(width: w * 0.015),
                            Text('1,436',
                                style: montserrat(
                                    size: w * 0.048,
                                    weight: FontWeight.w900,
                                    color: KColors.blue)),
                          ],
                        ),
                        Text('@ray_lorkasemsan',
                            style: montserrat(
                                size: w * 0.030,
                                weight: FontWeight.w900,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  final VoidCallback onTap;
  final Gradient gradient;

  const _WorldCard({required this.onTap, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: h * 0.145, // ~25% smaller than the old 0.195 (0.127 clipped the content)
      child: LayoutBuilder(
        builder: (context, cs) {
          final cw = cs.maxWidth;
          return Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withAlpha(112), width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 20,
                    offset: Offset(5, 5))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        cw * 0.07, cw * 0.05, cw * 0.04, cw * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('WORLD',
                            style: montserrat(
                                size: cw * 0.085,
                                weight: FontWeight.w900,
                                color: Colors.white)),
                        SizedBox(height: cw * 0.02),
                        Text('Join the multiplayer world!',
                            style: montserrat(
                                size: cw * 0.030,
                                weight: FontWeight.w900,
                                color: Colors.white)),
                        SizedBox(height: cw * 0.025),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: cw * 0.05, vertical: cw * 0.025),
                            decoration: BoxDecoration(
                              gradient: KColors.orangeGradient,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withAlpha(115), width: 2),
                            ),
                            child: Text('Click to Start!',
                                style: montserrat(
                                    size: cw * 0.040,
                                    weight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: cw * 0.03),
                  child: Image.asset('assets/images/fox_char.png',
                      width: cw * 0.28, fit: BoxFit.contain),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── QUEST TAB ───────────────────────────────────────────────────────────────

class _QuestTab extends StatelessWidget {
  const _QuestTab();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.06, h * 0.025, w * 0.06, h * 0.025),
                child: Text(
                  'Complete\nYour Quest',
                  textAlign: TextAlign.left,
                  style: nunito(size: w * 0.085, weight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04, vertical: h * 0.01),
                  children: [
                    _QuestCard(
                      imagePath: 'assets/images/quest_card1.png',
                      aspectRatio: 1768 / 654,
                      progress: 0.75,
                      progressLabel: '15/20',
                      progressFillColors: const [
                        Color(0xFF8B5CF6),
                        Color(0xFFA3E635),
                      ],
                      receiveButtonPath: 'assets/images/red_receive_button.png',
                    ),
                    SizedBox(height: h * 0.022),
                    _QuestCard(
                      imagePath: 'assets/images/quest_card2.png',
                      aspectRatio: 1762 / 654,
                      progress: 0.3,
                      progressLabel: '3/10',
                      progressFillColors: const [Color(0xFF4ADE80)],
                      receiveButtonPath: 'assets/images/red_receive_button.png',
                    ),
                    SizedBox(height: h * 0.022),
                    _QuestCard(
                      imagePath: 'assets/images/quest_card3.png',
                      aspectRatio: 1796 / 606,
                      progress: 1.0,
                      progressLabel: '100%',
                      progressFillColors: const [Color(0xFFA3E635)],
                      receiveButtonPath: 'assets/images/green_receive_button.png',
                    ),
                    SizedBox(height: h * 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  final String imagePath;
  final double aspectRatio;
  final double progress;
  final String progressLabel;
  final List<Color> progressFillColors;
  final String receiveButtonPath;
  final VoidCallback? onTap;

  const _QuestCard({
    required this.imagePath,
    required this.aspectRatio,
    required this.progress,
    required this.progressLabel,
    required this.progressFillColors,
    required this.receiveButtonPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image.asset(imagePath, fit: BoxFit.fill),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(right: w * 0.03),
              child: Align(
                alignment: Alignment.centerRight,
                child: Image.asset(receiveButtonPath, width: w * 0.28),
              ),
            ),
          ),
          Positioned(
            bottom: h * 0.014,
            left: w * 0.04,
            right: w * 0.32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestProgressBar(
                    progress: progress, fillColors: progressFillColors),
                SizedBox(height: h * 0.004),
                Text(progressLabel,
                    style: montserrat(
                        size: w * 0.028,
                        weight: FontWeight.w700,
                        color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> fillColors;

  const _QuestProgressBar(
      {required this.progress, required this.fillColors});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: h * 0.014,
        color: const Color(0xFF2D2D2D),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: fillColors.length > 1
                  ? BoxDecoration(
                      gradient: LinearGradient(colors: fillColors),
                    )
                  : BoxDecoration(color: fillColors.first),
            ),
          ),
        ),
      ),
    );
  }
}

// ── PRACTICE TAB ────────────────────────────────────────────────────────────

class _PracticeTab extends StatelessWidget {
  final VoidCallback onStartGame;
  const _PracticeTab({required this.onStartGame});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_room.png', fit: BoxFit.cover),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.06, h * 0.025, w * 0.06, h * 0.02),
                child: Text('Practice',
                    style: montserrat(
                        size: w * 0.09,
                        weight: FontWeight.w900,
                        color: Colors.white)),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04, vertical: h * 0.01),
                  children: [
                    _PracticeCard(
                      imagePath: 'assets/images/practice_card1.png',
                      aspectRatio: 1780 / 536,
                      onTap: null,
                    ),
                    SizedBox(height: h * 0.025),
                    _PracticeCard(
                      imagePath: 'assets/images/practice_card2.png',
                      aspectRatio: 1772 / 638,
                      onTap: onStartGame,
                    ),
                    SizedBox(height: h * 0.025),
                    _PracticeCard(
                      imagePath: 'assets/images/practice_card3.png',
                      aspectRatio: 1762 / 650,
                      onTap: () => context.go('/world'),
                    ),
                    SizedBox(height: h * 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String imagePath;
  final double aspectRatio;
  final VoidCallback? onTap;

  const _PracticeCard({
    required this.imagePath,
    required this.aspectRatio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.asset(imagePath, fit: BoxFit.fill),
          ),
        ),
        Positioned(
          left: w * 0.05,
          child: GestureDetector(
            onTap: onTap,
            child: Image.asset(
              'assets/images/clicktostartbutton.png',
              width: w * 0.30,
            ),
          ),
        ),
      ],
    );
  }
}

// ── INFO TAB ────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFF999999)],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.05, vertical: h * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Text('INFO',
                                style: GoogleFonts.montserrat(
                                  fontSize: w * 0.13,
                                  fontWeight: FontWeight.w600,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = w * 0.012
                                    ..color = Colors.white,
                                )),
                            Text('INFO',
                                style: montserrat(
                                    size: w * 0.13,
                                    weight: FontWeight.w600,
                                    color: KColors.navyText)),
                          ],
                        ),
                        Text('Username: ray_lorkasemsan',
                            style: montserrat(
                                size: w * 0.035,
                                weight: FontWeight.w700,
                                color: KColors.navyText)),
                        Text('Age: 80',
                            style: montserrat(
                                size: w * 0.035,
                                weight: FontWeight.w800,
                                color: KColors.navyText)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      height: h * 0.22,
                      width: w * 0.3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE8E0FF), Color(0xFFD0C4FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x20000000),
                              blurRadius: 12,
                              offset: Offset(0, 6))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/images/char_main.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.02),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(w * 0.05),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF1FA),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Best update',
                              style: montserrat(
                                  size: w * 0.038,
                                  weight: FontWeight.w800,
                                  color: KColors.indigo)),
                          const Spacer(),
                          _ArrowCircleButton(),
                        ],
                      ),
                      SizedBox(height: h * 0.01),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('15%',
                                    style: montserrat(
                                        size: w * 0.095,
                                        weight: FontWeight.w700,
                                        color: KColors.teal)),
                                Text('Right Muscle Leg better',
                                    style: montserrat(
                                        size: w * 0.03,
                                        weight: FontWeight.w700,
                                        color: KColors.navyText)),
                                Text('from last month',
                                    style: montserrat(
                                        size: w * 0.028,
                                        weight: FontWeight.w600,
                                        color: KColors.navyText.withAlpha(140))),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: h * 0.005),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _MiniBar(fraction: 0.63, label: 'Jan'),
                                SizedBox(width: w * 0.02),
                                _MiniBar(fraction: 1.0, label: 'Feb', active: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.02),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(w * 0.05),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2FB),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recommend Action',
                          style: montserrat(
                              size: w * 0.045,
                              weight: FontWeight.w800,
                              color: KColors.indigo)),
                      SizedBox(height: h * 0.015),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: w * 0.13,
                            height: w * 0.13,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6349F1), Color(0xFF2766EF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Color(0x40000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            child: Icon(Icons.workspace_premium_rounded,
                                color: Colors.white, size: w * 0.07),
                          ),
                          SizedBox(width: w * 0.04),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Improve',
                                  style: montserrat(
                                      size: w * 0.04,
                                      weight: FontWeight.w700,
                                      color: KColors.navyText)),
                              Text('Left Leg',
                                  style: montserrat(
                                      size: w * 0.075,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFFD2812D))),
                            ],
                          ),
                        ],
                      ),
                      Divider(
                          color: KColors.indigo.withAlpha(40),
                          height: h * 0.028,
                          thickness: 1.5),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Put more weight on your right leg.',
                                style: montserrat(
                                    size: w * 0.033,
                                    weight: FontWeight.w700,
                                    color: KColors.indigo.withAlpha(200))),
                          ),
                          SizedBox(width: w * 0.03),
                          _ArrowCircleButton(),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.02),
                Row(
                  children: [
                    Expanded(child: _MuscleStatCard()),
                    SizedBox(width: w * 0.04),
                    Expanded(child: _PostureStatCard()),
                  ],
                ),
                SizedBox(height: h * 0.02),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2FB),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  padding: EdgeInsets.all(w * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: w * 0.04, vertical: h * 0.008),
                            decoration: BoxDecoration(
                              color: KColors.indigo,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Last 6 months',
                                style: montserrat(
                                    size: w * 0.032,
                                    weight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                          const Spacer(),
                          _ArrowCircleButton(),
                        ],
                      ),
                      SizedBox(height: h * 0.02),
                      SizedBox(
                        height: h * 0.20,
                        child: _LineChart(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.03),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// A small circle button with a right-arrow icon, matching Figma's arrow pill.
class _ArrowCircleButton extends StatelessWidget {
  const _ArrowCircleButton();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.09;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KColors.indigo,
        boxShadow: const [
          BoxShadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}

// Muscles (EMG) stat card — "Right Leg" label with robot icon placeholder.
class _MuscleStatCard extends StatelessWidget {
  const _MuscleStatCard();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Color(0x30000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Muscles (EMG)',
              style: montserrat(
                  size: w * 0.035,
                  weight: FontWeight.w800,
                  color: KColors.indigo)),
          SizedBox(height: w * 0.03),
          Row(
            children: [
              Icon(Icons.smart_toy_rounded,
                  size: w * 0.14, color: KColors.indigo.withAlpha(180)),
              SizedBox(width: w * 0.03),
              Text('Right\nLeg',
                  style: montserrat(
                      size: w * 0.045,
                      weight: FontWeight.w800,
                      color: KColors.navyText)),
            ],
          ),
        ],
      ),
    );
  }
}

// Posture (Pose Estimation) stat card — "/" separator with "Excellent Stability".
class _PostureStatCard extends StatelessWidget {
  const _PostureStatCard();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Color(0x30000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Posture\n(Pose Estimation)',
              style: montserrat(
                  size: w * 0.035,
                  weight: FontWeight.w800,
                  color: KColors.indigo)),
          SizedBox(height: w * 0.02),
          Text('/',
              style: montserrat(
                  size: w * 0.12,
                  weight: FontWeight.w900,
                  color: KColors.indigo.withAlpha(80))),
          Text('Excellent\nStability',
              style: montserrat(
                  size: w * 0.038,
                  weight: FontWeight.w800,
                  color: KColors.teal)),
        ],
      ),
    );
  }
}

// Line chart for "Last 6 months" — Sep 58% → Oct 63% → Nov 66% → Dec 68% → Jan 70% → Feb 85%.
class _LineChart extends StatelessWidget {
  const _LineChart();

  static const _points = [0.58, 0.63, 0.66, 0.68, 0.70, 0.85];
  static const _labels = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
  static const _yLabels = ['100%', '75%', '50%', '25%', '0%'];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _yLabels
              .map((l) => Text(l,
                  style: montserrat(
                      size: w * 0.022,
                      weight: FontWeight.w600,
                      color: KColors.navyText.withAlpha(140))))
              .toList(),
        ),
        SizedBox(width: w * 0.02),
        // Chart area
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _LineChartPainter(
                    points: _points,
                    lineColor: KColors.indigo,
                    dotColor: const Color(0xFF6F51F5),
                    activeDotColor: const Color(0xFF6F51F5),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 6),
              // X-axis labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _labels
                    .map((l) => Text(l,
                        style: montserrat(
                            size: w * 0.022,
                            weight: FontWeight.w600,
                            color: KColors.navyText.withAlpha(140))))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final Color dotColor;
  final Color activeDotColor;

  const _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.dotColor,
    required this.activeDotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = points.length;
    if (n < 2) return;

    final dx = size.width / (n - 1);
    List<Offset> offsets = [];
    for (int i = 0; i < n; i++) {
      offsets.add(Offset(i * dx, size.height * (1.0 - points[i])));
    }

    // Grid lines at 0%, 25%, 50%, 75%, 100%
    final gridPaint = Paint()
      ..color = KColors.navyText.withAlpha(25)
      ..strokeWidth = 1;
    for (final frac in [0.0, 0.25, 0.50, 0.75, 1.0]) {
      final y = size.height * frac;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(offsets[0].dx, offsets[0].dy);
    for (int i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Dots
    for (int i = 0; i < offsets.length; i++) {
      final isLast = i == offsets.length - 1;
      final dotPaint = Paint()
        ..color = isLast ? activeDotColor : dotColor
        ..style = PaintingStyle.fill;
      final outerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offsets[i], isLast ? 7.0 : 5.0, outerPaint);
      canvas.drawCircle(offsets[i], isLast ? 5.0 : 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => false;
}

class _MiniBar extends StatelessWidget {
  final double fraction;
  final String label;
  final bool active;

  const _MiniBar({required this.fraction, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: w * 0.055,
          height: h * 0.07 * fraction,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6F51F5) : const Color(0xFFC0C0CB),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        SizedBox(height: 3),
        Text(label,
            style: montserrat(
                size: w * 0.022,
                weight: FontWeight.w600,
                color: active ? const Color(0xFF6F51F5) : KColors.navyText.withAlpha(140))),
      ],
    );
  }
}


