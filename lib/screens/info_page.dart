import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

// ─── Mock data ─────────────────────────────────────────────────────────────────

const _months = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
const _cciValues = [58.0, 63.0, 66.0, 68.0, 70.0, 85.0];

// ─── Page ──────────────────────────────────────────────────────────────────────

class InfoPage extends ConsumerWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── BLURRED ROOM BACKGROUND (fills the whole screen) ────────────
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Image.asset(
                'assets/images/info/info_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
          builder: (ctx, constraints) {
            // designW is the Figma FRAME width (narrower than the rightmost
            // elements): scaling it to the screen width makes the left column
            // fill nicely while the right column (robot / select-area / Advance)
            // bleeds past the right edge and gets CLIPPED — matching the design.
            const designW = 930.0, designH = 1220.0;
            final s = constraints.maxWidth / designW;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              SizedBox(
                width: constraints.maxWidth,
                height: designH * s,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                  // ── TOP PURPLE BANNER (backmost) ────────────────────────────
                  // Large rounded purple gradient that bleeds off the top edge,
                  // sitting behind the INFO header (Figma #585:7).
                  Positioned(
                    left: -41 * s,
                    top: -174 * s,
                    width: 1197 * s,
                    height: 691 * s,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(0.7, -0.7),
                          end: Alignment(-0.7, 0.7),
                          colors: [Color(0xFFA699FF), Color(0xFF6F6ADE)],
                          stops: [0.19, 0.98],
                        ),
                        borderRadius: BorderRadius.circular(70 * s),
                        border: Border.all(color: Colors.white, width: 12 * s),
                      ),
                    ),
                  ),

                  // ── HEADER ──────────────────────────────────────────────────

                  // "INFO" title
                  Positioned(
                    left: 45 * s,
                    top: 50 * s,
                    width: 260 * s,
                    height: 122 * s,
                    child: _InfoTitle(s: s),
                  ),

                  // Name
                  Positioned(
                    left: 45 * s,
                    top: 178 * s,
                    width: 400 * s,
                    height: 34 * s,
                    child: Text(
                      'ชื่อ: ณัฐธัญ กาวาฮารา',
                      style: montserrat(
                        size: 28 * s,
                        weight: FontWeight.w700,
                        color: const Color(0xFF323232),
                      ),
                    ),
                  ),

                  // Age
                  Positioned(
                    left: 45 * s,
                    top: 216 * s,
                    width: 200 * s,
                    height: 34 * s,
                    child: Text(
                      'อายุ: 80',
                      style: montserrat(
                        size: 28 * s,
                        weight: FontWeight.w800,
                        color: const Color(0xFF323232),
                      ),
                    ),
                  ),

                  // ── LEFT CARD ────────────────────────────────────────────────

                  Positioned(
                    left: 30 * s,
                    top: 267 * s,
                    width: 500 * s,
                    height: 675 * s,
                    child: _LeftCard(s: s),
                  ),

                  // ── RIGHT CARD ───────────────────────────────────────────────

                  Positioned(
                    left: 558 * s,
                    top: 100 * s,
                    width: 598 * s,
                    height: 624 * s,
                    child: _RightCard(s: s),
                  ),

                  // ── PURPLE ADVANCE CARD ──────────────────────────────────────

                  Positioned(
                    left: 558 * s,
                    top: 749 * s,
                    width: 350 * s,
                    height: 190 * s,
                    child: _AdvanceCard(s: s),
                  ),

                  // ── BOTTOM CARD ──────────────────────────────────────────────

                  Positioned(
                    left: 30 * s,
                    top: 964 * s,
                    width: 1080 * s,
                    height: 220 * s,
                    child: _BottomCard(s: s),
                  ),
                ],
              ),
            ),
              SizedBox(height: context.r(16)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.r(16)),
                child: const _WeekStripCard(),
              ),
              SizedBox(height: context.r(24)),
            ],
          ),
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INFO title widget ─────────────────────────────────────────────────────────

class _InfoTitle extends StatelessWidget {
  final double s;
  const _InfoTitle({required this.s});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // White outline via stroke
        Text(
          'INFO',
          style: TextStyle(
            fontFamily: 'Kanit',
            fontSize: 100 * s,
            fontWeight: FontWeight.w600,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4 * s
              ..color = Colors.white,
          ),
        ),
        Text(
          'INFO',
          style: montserrat(
            size: 100 * s,
            weight: FontWeight.w600,
            color: const Color(0xFF262626),
          ),
        ),
      ],
    );
  }
}

// ─── Left card ────────────────────────────────────────────────────────────────

class _LeftCard extends StatelessWidget {
  final double s;
  const _LeftCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(40 * s),
        boxShadow: const [
          BoxShadow(color: Color(0x28000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // EMG/Posture toggle
          Positioned(
            left: 11 * s,
            top: 24 * s,
            width: 478 * s,
            height: 64 * s,
            child: _EmgToggle(s: s),
          ),

          // "Last 6 months" pill
          Positioned(
            left: 78 * s,
            top: 105 * s,
            width: 343 * s,
            height: 41 * s,
            child: _Last6MonthsPill(s: s),
          ),

          // Chart 1 title
          Positioned(
            left: 0,
            top: 160 * s,
            width: 500 * s,
            height: 44 * s,
            child: Center(
              child: Text(
                'การทรงตัวของข้อเข่า',
                style: montserrat(
                  size: 28 * s,
                  weight: FontWeight.w700,
                  color: const Color(0xFF1F2F66),
                ),
              ),
            ),
          ),

          // Knee "ดี" badge
          Positioned(
            left: 36 * s,
            top: 231 * s,
            width: 90 * s,
            height: 135 * s,
            child: _DiBadge(
              s: s,
              faceAsset: 'assets/images/info/face_knee.png',
              ringColor: const Color(0xFF11C18E),
            ),
          ),

          // Chart 1 (knee)
          Positioned(
            left: 120 * s,
            top: 222 * s,
            width: 360 * s,
            height: 153 * s,
            child: _CciLineChart(
              s: s,
              lineColor: const Color(0xFF6349F1),
              gradientColor: const Color(0x336349F1),
              labelColor: const Color(0xFF6349F1),
            ),
          ),

          // Chart 2 title
          Positioned(
            left: 0,
            top: 401 * s,
            width: 500 * s,
            height: 44 * s,
            child: Center(
              child: Text(
                'การทรงตัวของข้อเท้า',
                style: montserrat(
                  size: 28 * s,
                  weight: FontWeight.w700,
                  color: const Color(0xFF1F2F66),
                ),
              ),
            ),
          ),

          // Ankle "ดี" badge
          Positioned(
            left: 36 * s,
            top: 466 * s,
            width: 90 * s,
            height: 135 * s,
            child: _DiBadge(
              s: s,
              faceAsset: 'assets/images/info/face_ankle.png',
              ringColor: const Color(0xFFFFB365),
            ),
          ),

          // Chart 2 (ankle)
          Positioned(
            left: 120 * s,
            top: 457 * s,
            width: 360 * s,
            height: 153 * s,
            child: _CciLineChart(
              s: s,
              lineColor: const Color(0xFFFA7F00),
              gradientColor: const Color(0x33FA7F00),
              labelColor: const Color(0xFFFA7F00),
            ),
          ),

          // CCI legend
          Positioned(
            left: 35 * s,
            top: 629 * s,
            width: 429 * s,
            height: 30 * s,
            child: _CciLegend(s: s),
          ),
        ],
      ),
    );
  }
}

// ─── EMG / Posture toggle ──────────────────────────────────────────────────────

class _EmgToggle extends StatelessWidget {
  final double s;
  const _EmgToggle({required this.s});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Selected: EMG
        GestureDetector(
          onTap: () => debugPrint('EMG toggle tapped'),
          child: Container(
            width: 219 * s,
            height: 64 * s,
            decoration: BoxDecoration(
              color: const Color(0xFF6349F1),
              borderRadius: BorderRadius.circular(20 * s),
            ),
            alignment: Alignment.center,
            child: Text(
              'Muscles (EMG)',
              style: montserrat(
                size: 20 * s,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4 * s),
          child: Text(
            '/',
            style: montserrat(
              size: 28 * s,
              weight: FontWeight.w400,
              color: const Color(0xFF6349F1),
            ),
          ),
        ),
        // Unselected: Posture
        GestureDetector(
          onTap: () => debugPrint('Posture toggle tapped'),
          child: Container(
            width: 230 * s,
            height: 64 * s,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: const Color(0xFF6349F1), width: 2 * s),
            ),
            alignment: Alignment.center,
            child: Text(
              'Posture\n(Pose Estimation)',
              textAlign: TextAlign.center,
              style: montserrat(
                size: 18 * s,
                weight: FontWeight.w800,
                color: const Color(0xFF6349F1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── "Last 6 months" pill ─────────────────────────────────────────────────────

class _Last6MonthsPill extends StatelessWidget {
  final double s;
  const _Last6MonthsPill({required this.s});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => debugPrint('Last 6 months tapped'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6983D9),
          borderRadius: BorderRadius.circular(15 * s),
        ),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Last 6 months',
                  style: montserrat(
                    size: 20 * s,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 6 * s),
              child: Container(
                width: 27 * s,
                height: 27 * s,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(4 * s),
                child: Image.asset('assets/images/info/arrow.png', fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── "ดี" circular badge ──────────────────────────────────────────────────────

class _DiBadge extends StatelessWidget {
  final double s;
  final String faceAsset;
  final Color ringColor;
  const _DiBadge({
    required this.s,
    required this.faceAsset,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = 74 * s;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ดี',
          style: montserrat(
            size: 28 * s,
            weight: FontWeight.w700,
            color: const Color(0xFF11C18E),
          ),
        ),
        SizedBox(height: 4 * s),
        Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: ringColor, width: 5 * s),
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(faceAsset, fit: BoxFit.cover),
        ),
      ],
    );
  }
}

// ─── CCI Line Chart ───────────────────────────────────────────────────────────

class _CciLineChart extends StatelessWidget {
  final double s;
  final Color lineColor;
  final Color gradientColor;
  final Color labelColor;
  const _CciLineChart({
    required this.s,
    required this.lineColor,
    required this.gradientColor,
    required this.labelColor,
  });

  List<FlSpot> get _spots => List.generate(
        _cciValues.length,
        (i) => FlSpot(i.toDouble(), _cciValues[i]),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LineChart(
          LineChartData(
            minX: 0,
            maxX: 5,
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.black12,
                strokeWidth: 0.8,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 25,
                  reservedSize: 38 * s,
                  getTitlesWidget: (v, meta) => Text(
                    '${v.toInt()}%',
                    style: montserrat(
                      size: 12 * s,
                      weight: FontWeight.w500,
                      color: const Color(0xFF1F2F66),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 20 * s,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= _months.length) return const SizedBox();
                    return Text(
                      _months[idx],
                      style: montserrat(
                        size: 11 * s,
                        weight: FontWeight.w500,
                        color: const Color(0xFF1F2F66),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _spots,
                isCurved: true,
                color: lineColor,
                barWidth: 2.5 * s,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                    radius: 4 * s,
                    color: lineColor,
                    strokeWidth: 1.5 * s,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gradientColor, Colors.transparent],
                  ),
                ),
              ),
            ],
            lineTouchData: const LineTouchData(enabled: false),
          ),
        ),
        // CCI tag overlay (top-left of plot area)
        Positioned(
          left: 38 * s,
          top: 2 * s,
          child: Text(
            'CCI',
            style: montserrat(
              size: 16 * s,
              weight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── CCI Legend ───────────────────────────────────────────────────────────────

class _CciLegend extends StatelessWidget {
  final double s;
  const _CciLegend({required this.s});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(const Color(0xFF6349F1), s),
        SizedBox(width: 4 * s),
        _dot(const Color(0xFFFA7F00), s),
        SizedBox(width: 8 * s),
        Expanded(
          child: Text(
            'CCI: ดัชนีการหดตัวของกล้ามเนื้อคู่ตรงข้าม (%)',
            style: montserrat(
              size: 16 * s,
              weight: FontWeight.w700,
              color: const Color(0xFF1F2F66),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color, double s) => Container(
        width: 12 * s,
        height: 12 * s,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─── Right card ───────────────────────────────────────────────────────────────

class _RightCard extends StatelessWidget {
  final double s;
  const _RightCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.71, 0.71), // 225° ≈ bottom-left
          end: Alignment(0.71, -0.71),
          colors: [Color(0xFFD6E6F8), Color(0xFFEBF1FA)],
        ),
        borderRadius: BorderRadius.circular(40 * s),
        boxShadow: const [
          BoxShadow(color: Color(0x28000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // k3_body behind robot
          Positioned(
            left: 150 * s,
            top: 129 * s,
            width: 350 * s,
            height: 340 * s,
            child: Image.asset('assets/images/info/k3_body.png', fit: BoxFit.contain),
          ),

          // robot
          Positioned(
            left: 51 * s,
            top: -22 * s,
            width: 240 * s,
            height: 597 * s,
            child: Image.asset('assets/images/info/robot.png', fit: BoxFit.contain),
          ),

          // select-area panel
          Positioned(
            left: 17 * s,
            top: 381 * s,
            width: 446 * s,
            height: 226 * s,
            child: _SelectAreaPanel(s: s),
          ),
        ],
      ),
    );
  }
}

// ─── Select area panel ────────────────────────────────────────────────────────

class _SelectAreaPanel extends StatelessWidget {
  final double s;
  const _SelectAreaPanel({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFBFB5FF),
        borderRadius: BorderRadius.circular(30 * s),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Title
          Positioned(
            left: 0,
            top: 15 * s,
            width: 446 * s,
            child: Center(
              child: Text(
                'เลือกบริเวณที่ประเมิน',
                style: montserrat(
                  size: 28 * s,
                  weight: FontWeight.w700,
                  color: const Color(0xFF1F2F66),
                ),
              ),
            ),
          ),

          // "ขาขวา" pill
          Positioned(
            left: 44 * s,
            top: 62 * s,
            width: 264 * s,
            height: 110 * s,
            child: GestureDetector(
              onTap: () => debugPrint('ขาขวา tapped'),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F2FB),
                  borderRadius: BorderRadius.circular(40 * s),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 14 * s),
                    Text(
                      'ขาขวา',
                      style: montserrat(
                        size: 44 * s,
                        weight: FontWeight.w700,
                        color: const Color(0xFF6349F1),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 70 * s,
                      height: 90 * s,
                      child: Image.asset(
                        'assets/images/info/robot_small.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 6 * s),
                  ],
                ),
              ),
            ),
          ),

          // Sub label
          Positioned(
            left: 0,
            top: 183 * s,
            width: 446 * s,
            child: Center(
              child: Text(
                'กดเพื่อสลับบริเวณ',
                style: montserrat(
                  size: 20 * s,
                  weight: FontWeight.w700,
                  color: const Color(0xFF1F2F66),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Advance card ─────────────────────────────────────────────────────────────

class _AdvanceCard extends StatelessWidget {
  final double s;
  const _AdvanceCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/emg/pin'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF746EE0),
          borderRadius: BorderRadius.circular(40 * s),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF746EE0).withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'กดเพื่อเข้าสู่หน้า',
                style: montserrat(
                  size: 34 * s,
                  weight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2 * s),
              Stack(
                children: [
                  Text(
                    'Advance INFO!',
                    style: TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 30 * s,
                      fontWeight: FontWeight.w800,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3 * s
                        ..color = Colors.white,
                    ),
                  ),
                  Text(
                    'Advance INFO!',
                    style: montserrat(
                      size: 30 * s,
                      weight: FontWeight.w800,
                      color: const Color(0xFF6349F1),
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

// ─── Bottom recommendation card ───────────────────────────────────────────────

class _BottomCard extends StatelessWidget {
  final double s;
  const _BottomCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(40 * s),
        boxShadow: const [
          BoxShadow(color: Color(0x28000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // review_icon
          Positioned(
            left: 22 * s,
            top: 35 * s,
            width: 150 * s,
            height: 150 * s,
            child: Image.asset('assets/images/info/review_icon.png', fit: BoxFit.contain),
          ),

          // "คำแนะนำ"
          Positioned(
            left: 181 * s,
            top: 11 * s,
            width: 300 * s,
            height: 63 * s,
            child: Text(
              'คำแนะนำ',
              style: montserrat(
                size: 48 * s,
                weight: FontWeight.w800,
                color: const Color(0xFF6349F1),
              ),
            ),
          ),

          // "ข้อเท้าขวา"
          Positioned(
            left: 298 * s,
            top: 74 * s,
            width: 280 * s,
            height: 59 * s,
            child: Text(
              'ข้อเท้าขวา',
              style: montserrat(
                size: 44 * s,
                weight: FontWeight.w700,
                color: const Color(0xFFF98D1F),
              ),
            ),
          ),

          // "ปรับปรุง" label button
          Positioned(
            left: 181 * s,
            top: 90 * s,
            child: GestureDetector(
              onTap: () => debugPrint('ปรับปรุง tapped'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1F2F66), width: 1.5 * s),
                  borderRadius: BorderRadius.circular(8 * s),
                ),
                child: Text(
                  'ปรับปรุง',
                  style: montserrat(
                    size: 26 * s,
                    weight: FontWeight.w700,
                    color: const Color(0xFF1F2F66),
                  ),
                ),
              ),
            ),
          ),

          // Recommendation text
          Positioned(
            left: 177 * s,
            top: 142 * s,
            width: 700 * s,
            height: 70 * s,
            child: Text(
              '  - ลงน้ำหนักที่ขาซ้ายให้มากขึ้น\n  - ควรฝึกการทรงตัวของข้อเท้า',
              style: montserrat(
                size: 22 * s,
                weight: FontWeight.w700,
                color: const Color(0xFF1F2F66),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Weekly Strip Card ────────────────────────────────────────────────────────

class _WeekStripCard extends ConsumerWidget {
  const _WeekStripCard();

  static const _labels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // DateTime.weekday: Mon=1 … Sun=7 → index 0..6
    final todayIndex = DateTime.now().weekday - 1;
    // DEMO: placeholder — week shown as done up to & including today. Swap back
    // to ref.watch(weekDotsProvider) / dayStreakProvider for real session data.
    final dots = List.generate(7, (i) => i <= todayIndex);
    const streak = 5;

    return Container(
      padding: EdgeInsets.all(context.r(16)),
      decoration: cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สัปดาห์นี้',
            style: thaiSans(
              size: context.r(16),
              weight: FontWeight.w800,
              color: KColors.navyText,
            ),
          ),
          SizedBox(height: context.r(12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final done = dots[i];
              final isToday = i == todayIndex;
              return _DayCell(
                label: _labels[i],
                done: done,
                isToday: isToday,
              );
            }),
          ),
          SizedBox(height: context.r(10)),
          Text(
            streak > 0 ? 'ทำต่อเนื่อง $streak วัน' : 'เริ่มทำวันแรก!',
            style: thaiSans(
              size: context.r(13),
              weight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final bool done;
  final bool isToday;

  const _DayCell({
    required this.label,
    required this.done,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.r(32);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: thaiSans(
            size: context.r(11),
            weight: FontWeight.w700,
            color: isToday ? KColors.blue : Colors.grey.shade500,
          ),
        ),
        SizedBox(height: context.r(4)),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done ? KColors.blueGradient : null,
            color: done ? null : Colors.transparent,
            border: Border.all(
              color: isToday
                  ? KColors.blue
                  : done
                      ? Colors.transparent
                      : Colors.grey.shade300,
              width: isToday ? 2.5 : 1.5,
            ),
          ),
          child: done
              ? Icon(Icons.check_rounded, color: Colors.white, size: context.r(16))
              : null,
        ),
      ],
    );
  }
}
