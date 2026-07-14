import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

// ─── Mock data ─────────────────────────────────────────────────────────────
// Everything on this page is mock while the EMG pipeline + game history wiring
// land. Left/right values are each leg's SHARE of total EMG effort (sum = 100).

const _leftShare = 57.0;
const _rightShare = 43.0;
const _weekImprovement = 15; // % better than last week
const _monthImprovement = 22; // % better than last month

const _weekSessions = 5;
const _weekMinutes = 55;
const _weekAvgScore = 65;

class _MockGame {
  final String name;
  final String dateLabel;
  final int minutes;
  final int score;
  final IconData icon;
  final List<Color> iconGradient;
  final List<double> spark; // recent scores, oldest → newest

  const _MockGame({
    required this.name,
    required this.dateLabel,
    required this.minutes,
    required this.score,
    required this.icon,
    required this.iconGradient,
    required this.spark,
  });
}

const _mockGames = [
  _MockGame(
    name: 'MEGA DANCE',
    dateLabel: 'วันนี้',
    minutes: 10,
    score: 88,
    icon: Icons.music_note_rounded,
    iconGradient: [Color(0xFFB83FF4), Color(0xFF6F1BC8)],
    spark: [40, 52, 48, 66, 74, 88],
  ),
  _MockGame(
    name: 'KINEX WORLD',
    dateLabel: 'เมื่อวาน',
    minutes: 15,
    score: 76,
    icon: Icons.public_rounded,
    iconGradient: [Color(0xFF11C18E), Color(0xFF2766EF)],
    spark: [45, 42, 58, 55, 70, 76],
  ),
  _MockGame(
    name: 'FRUIT GAME',
    dateLabel: '12 ก.ค.',
    minutes: 8,
    score: 64,
    icon: Icons.apple,
    iconGradient: [Color(0xFFFFC107), Color(0xFFFA7F00)],
    spark: [30, 42, 40, 50, 56, 64],
  ),
  _MockGame(
    name: 'BALANCE QUEST',
    dateLabel: '11 ก.ค.',
    minutes: 12,
    score: 52,
    icon: Icons.balance_rounded,
    iconGradient: [Color(0xFF8BFA48), Color(0xFF5EC832)],
    spark: [22, 30, 28, 38, 44, 52],
  ),
  _MockGame(
    name: 'MEGA DANCE',
    dateLabel: '10 ก.ค.',
    minutes: 10,
    score: 47,
    icon: Icons.music_note_rounded,
    iconGradient: [Color(0xFFB83FF4), Color(0xFF6F1BC8)],
    spark: [50, 38, 45, 33, 40, 47],
  ),
];

// ─── Traffic-light status per leg ───────────────────────────────────────────
// Status comes from the leg's share of total effort: the weaker leg carries
// the signal (≥45 fine, 35–44 needs attention, <35 needs training).

class _LegStatus {
  final String label;
  final Color color;
  const _LegStatus(this.label, this.color);

  static _LegStatus of(double share) {
    if (share >= 45) return const _LegStatus('ดี', Color(0xFF11C18E));
    if (share >= 35) return const _LegStatus('พอใช้', Color(0xFFF5A623));
    return const _LegStatus('ควรฝึกเพิ่ม', Color(0xFFFD4C86));
  }
}

/// Band label + colour for a game score, mirroring WorldBand.
class _ScoreBand {
  final String label;
  final Color color;
  const _ScoreBand(this.label, this.color);

  static _ScoreBand of(int score) {
    if (score >= 85) return const _ScoreBand('ยอดเยี่ยม', Color(0xFF11C18E));
    if (score >= 70) return const _ScoreBand('ดีมาก', KColors.purple);
    if (score >= 50) return const _ScoreBand('ดี', KColors.blue);
    return const _ScoreBand('สู้ๆ นะ', KColors.orangeDark);
  }
}

// ─── Page ──────────────────────────────────────────────────────────────────

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0, -0.2),
            colors: [Color(0xFFF6F5FD), Colors.white],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: context.r(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.r(10), context.r(10), context.r(10), 0),
                  child: const _HeaderBanner(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.r(14), context.r(16), context.r(14), 0),
                  child: const _BalanceCard(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.r(14), context.r(16), context.r(14), 0),
                  child: const _HistoryCard(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.r(14), context.r(18), context.r(14), 0),
                  child: const _ActionButtons(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header banner ──────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          context.r(22), context.r(18), context.r(22), context.r(18)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA699FF), Color(0xFF6F6ADE)],
        ),
        borderRadius: BorderRadius.circular(context.r(28)),
        border: Border.all(color: Colors.white, width: context.r(5)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x596F6ADE), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Text(
                'INFO',
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: context.r(52),
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = context.r(4)
                    ..color = Colors.white,
                ),
              ),
              Text(
                'INFO',
                style: montserrat(
                  size: context.r(52),
                  weight: FontWeight.w900,
                  color: const Color(0xFF262626),
                ).copyWith(height: 1.05),
              ),
            ],
          ),
          SizedBox(height: context.r(6)),
          Text(
            'ชื่อ: ณัฐธัญ กาวาฮารา',
            style: montserrat(
                size: context.r(17), weight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            'อายุ: 80',
            style: montserrat(
                size: context.r(17), weight: FontWeight.w600, color: Colors.white),
          ),
          SizedBox(height: context.r(2)),
          Text(
            'อัปเดตล่าสุด: วันนี้ 09:41 น.',
            style: montserrat(
              size: context.r(12),
              weight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Balance card (EMG L/R) ─────────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  const _BalanceCard();

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _weekly = true;

  @override
  Widget build(BuildContext context) {
    final balanceScore =
        (2 * (_leftShare < _rightShare ? _leftShare : _rightShare) /
                (_leftShare + _rightShare) *
                100)
            .round();

    return Container(
      padding: EdgeInsets.all(context.r(16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD6E6F8), Color(0xFFEBF1FA)],
        ),
        borderRadius: BorderRadius.circular(context.r(26)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สมดุลซ้าย–ขวา (EMG)',
              style: montserrat(size: context.r(19), weight: FontWeight.w900)),
          SizedBox(height: context.r(2)),
          Text(
            'สัดส่วนการออกแรงของขาทั้งสองข้างขณะเล่นเกม',
            style: montserrat(
                size: context.r(12.5),
                weight: FontWeight.w500,
                color: const Color(0xFF6D78A8)),
          ),
          SizedBox(height: context.r(12)),

          // Per-leg gauges
          Row(
            children: const [
              Expanded(child: _LegGauge(label: 'ขาซ้าย', share: _leftShare)),
              SizedBox(width: 12),
              Expanded(child: _LegGauge(label: 'ขาขวา', share: _rightShare)),
            ],
          ),
          SizedBox(height: context.r(14)),

          // Split bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ขาซ้าย',
                  style: montserrat(
                      size: context.r(13),
                      weight: FontWeight.w900,
                      color: KColors.indigo)),
              Text('ขาขวา',
                  style: montserrat(
                      size: context.r(13),
                      weight: FontWeight.w900,
                      color: const Color(0xFFFA7F00))),
            ],
          ),
          SizedBox(height: context.r(5)),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(12)),
            child: SizedBox(
              height: context.r(34),
              child: Row(
                children: [
                  Expanded(
                    flex: _leftShare.round(),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF8B7BFF), KColors.indigo],
                        ),
                      ),
                      child: Text('${_leftShare.round()}%',
                          style: montserrat(
                              size: context.r(15),
                              weight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
                  Container(width: context.r(3), color: Colors.white),
                  Expanded(
                    flex: _rightShare.round(),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFB365), Color(0xFFFA7F00)],
                        ),
                      ),
                      child: Text('${_rightShare.round()}%',
                          style: montserrat(
                              size: context.r(15),
                              weight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.r(12)),

          // Balance score
          Row(
            children: [
              Text('$balanceScore',
                  style: montserrat(
                      size: context.r(34),
                      weight: FontWeight.w900,
                      color: const Color(0xFF11C18E))),
              SizedBox(width: context.r(10)),
              Expanded(
                child: Text(
                  'คะแนนสมดุล /100\nใช้ขาสองข้างร่วมกันได้ดี',
                  style: montserrat(
                      size: context.r(13), weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: context.r(12)),

          // Improvement trend + week/month toggle
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(12), vertical: context.r(10)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: context.r(30),
                  height: context.r(30),
                  decoration: const BoxDecoration(
                      color: Color(0xFF11C18E), shape: BoxShape.circle),
                  child: Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: context.r(18)),
                ),
                SizedBox(width: context.r(9)),
                Expanded(
                  child: Text(
                    _weekly
                        ? 'ดีขึ้น $_weekImprovement% จากสัปดาห์ที่แล้ว'
                        : 'ดีขึ้น $_monthImprovement% จากเดือนที่แล้ว',
                    style: montserrat(
                        size: context.r(14.5),
                        weight: FontWeight.w900,
                        color: const Color(0xFF11C18E)),
                  ),
                ),
                _RangeToggle(
                  weekly: _weekly,
                  onChanged: (w) => setState(() => _weekly = w),
                ),
              ],
            ),
          ),
          SizedBox(height: context.r(12)),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: Color(0xFF11C18E), label: 'ดี'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFFF5A623), label: 'พอใช้'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFFFD4C86), label: 'ควรฝึกเพิ่ม'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final bool weekly;
  final ValueChanged<bool> onChanged;
  const _RangeToggle({required this.weekly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.r(3)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, 'สัปดาห์', weekly, () => onChanged(true)),
          _segment(context, 'เดือน', !weekly, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(
      BuildContext context, String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.r(11), vertical: context.r(4)),
        decoration: BoxDecoration(
          color: on ? KColors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: montserrat(
            size: context.r(12),
            weight: FontWeight.w900,
            color: on ? Colors.white : KColors.indigo,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.r(9),
          height: context.r(9),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: context.r(5)),
        Text(label,
            style: montserrat(
                size: context.r(11.5),
                weight: FontWeight.w600,
                color: const Color(0xFF4B5788))),
      ],
    );
  }
}

// ─── Leg gauge ──────────────────────────────────────────────────────────────

class _LegGauge extends StatelessWidget {
  final String label;
  final double share;
  const _LegGauge({required this.label, required this.share});

  @override
  Widget build(BuildContext context) {
    final status = _LegStatus.of(share);
    final size = context.r(112);
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.r(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Column(
        children: [
          Text(label,
              style: montserrat(
                  size: context.r(16),
                  weight: FontWeight.w900,
                  color: KColors.indigo)),
          SizedBox(height: context.r(8)),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                fraction: share / 100,
                color: status.color,
                trackColor: const Color(0xFFE7E4F8),
                strokeWidth: context.r(11),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${share.round()}%',
                        style: montserrat(
                            size: context.r(25),
                            weight: FontWeight.w900,
                            color: status.color)),
                    Text('สัดส่วนการออกแรง',
                        style: montserrat(
                            size: context.r(9),
                            weight: FontWeight.w500,
                            color: const Color(0xFF6D78A8))),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: context.r(8)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(14), vertical: context.r(3)),
            decoration: BoxDecoration(
              color: status.color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(status.label,
                style: montserrat(
                    size: context.r(13.5),
                    weight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction; // 0..1
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -1.5708, 6.2832 * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ─── History card ───────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.r(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(context.r(26)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ประวัติการเล่น',
              style: montserrat(size: context.r(19), weight: FontWeight.w900)),
          SizedBox(height: context.r(2)),
          Text('สัปดาห์นี้',
              style: montserrat(
                  size: context.r(12.5),
                  weight: FontWeight.w500,
                  color: const Color(0xFF6D78A8))),
          SizedBox(height: context.r(10)),
          Row(
            children: const [
              Expanded(child: _StatTile(value: '$_weekSessions', label: 'ครั้ง')),
              SizedBox(width: 8),
              Expanded(child: _StatTile(value: '$_weekMinutes', label: 'นาที')),
              SizedBox(width: 8),
              Expanded(
                  child:
                      _StatTile(value: '$_weekAvgScore%', label: 'คะแนนเฉลี่ย')),
            ],
          ),
          SizedBox(height: context.r(4)),
          for (final g in _mockGames)
            Padding(
              padding: EdgeInsets.only(top: context.r(8)),
              child: _GameRow(game: g),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.r(8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
      ),
      child: Column(
        children: [
          Text(value,
              style: montserrat(
                  size: context.r(20),
                  weight: FontWeight.w900,
                  color: KColors.indigo)),
          Text(label,
              style: montserrat(
                  size: context.r(11),
                  weight: FontWeight.w600,
                  color: const Color(0xFF6D78A8))),
        ],
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  final _MockGame game;
  const _GameRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final band = _ScoreBand.of(game.score);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(10), vertical: context.r(9)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: Row(
        children: [
          Container(
            width: context.r(44),
            height: context.r(44),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: game.iconGradient,
              ),
              borderRadius: BorderRadius.circular(context.r(13)),
            ),
            child: Icon(game.icon, color: Colors.white, size: context.r(24)),
          ),
          SizedBox(width: context.r(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.name,
                    style: montserrat(
                        size: context.r(14.5), weight: FontWeight.w900)),
                Text('${game.dateLabel} · ${game.minutes} นาที',
                    style: montserrat(
                        size: context.r(11.5),
                        weight: FontWeight.w500,
                        color: const Color(0xFF6D78A8))),
              ],
            ),
          ),
          SizedBox(
            width: context.r(60),
            height: context.r(24),
            child: CustomPaint(
              painter: _SparklinePainter(
                values: game.spark,
                color: game.iconGradient.first,
                strokeWidth: context.r(2.4),
              ),
            ),
          ),
          SizedBox(width: context.r(10)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${game.score}%',
                  style: montserrat(
                      size: context.r(18),
                      weight: FontWeight.w900,
                      color: band.color)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.r(8), vertical: context.r(1)),
                decoration: BoxDecoration(
                  color: band.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(band.label,
                    style: montserrat(
                        size: context.r(10),
                        weight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values; // 0..100
  final Color color;
  final double strokeWidth;

  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final dx = size.width / (values.length - 1);
    Offset at(int i) =>
        Offset(i * dx, size.height * (1 - values[i] / 100));

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawCircle(at(values.length - 1), strokeWidth + 0.6,
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

// ─── Action buttons ─────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () => context.push('/emg/pin'),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: context.r(13)),
              decoration: BoxDecoration(
                color: const Color(0xFF746EE0),
                borderRadius: BorderRadius.circular(context.r(22)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x80746EE0),
                      blurRadius: 22,
                      offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Text('Advance INFO!',
                      style: montserrat(
                          size: context.r(16.5),
                          weight: FontWeight.w900,
                          color: Colors.white)),
                  Text('ข้อมูลเชิงลึกสำหรับนักกายภาพ',
                      style: montserrat(
                          size: context.r(12),
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: context.r(12)),
        Expanded(
          flex: 4,
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export PDF — เร็วๆ นี้',
                    style: montserrat(size: 15, color: Colors.white)),
                behavior: SnackBarBehavior.floating,
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: context.r(13)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.r(22)),
                border: Border.all(color: KColors.indigo, width: 2.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded,
                          color: KColors.indigo, size: context.r(18)),
                      SizedBox(width: context.r(4)),
                      Text('Export PDF',
                          style: montserrat(
                              size: context.r(16.5),
                              weight: FontWeight.w900,
                              color: KColors.indigo)),
                    ],
                  ),
                  Text('บันทึกรายงาน',
                      style: montserrat(
                          size: context.r(12),
                          weight: FontWeight.w600,
                          color: const Color(0xFF6D78A8))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
