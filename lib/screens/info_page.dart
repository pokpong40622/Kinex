import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/emg_repository.dart';
import '../data/game_repository.dart';
import '../models/emg_metrics.dart';
import '../models/game_session_record.dart';
import '../models/muscle.dart';
import '../state/shop_providers.dart';
import '../data/customize_catalog.dart';
import '../theme/app_theme.dart';
import '../theme/kui.dart';
import '../theme/responsive.dart';

// The history list reads real game sessions from gameHistoryProvider
// (game_repository.dart). The L/R balance card reads real data from
// balanceReportProvider (emg_repository.dart).

const _weekImprovement = 15; // % better than last week
const _monthImprovement = 22; // % better than last month

// ─── Balance status strip ───────────────────────────────────────────────────
// Driven by the GAP between the two legs' share (|left% - right%|), not by
// either leg alone — a small gap is fine even if both legs are individually
// low-effort; a big gap is the clinically interesting signal.

class _BalanceStatus {
  final String label;
  final Color color;
  final IconData icon;
  const _BalanceStatus(this.label, this.color, this.icon);

  static _BalanceStatus of(double gap) {
    if (gap <= 10) {
      return const _BalanceStatus(
          'สมดุลดี', Color(0xFF11C18E), Icons.check_circle_rounded);
    }
    if (gap <= 20) {
      return const _BalanceStatus('ควรฝึกข้างที่อ่อนเพิ่ม',
          Color(0xFFF5A623), Icons.warning_rounded);
    }
    return const _BalanceStatus(
        'ความไม่สมดุลสูง — แนะนำปรึกษาแพทย์หรือนักกายภาพ',
        Color(0xFFFD4C86),
        Icons.local_hospital_rounded);
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
      backgroundColor: KColors.appBg,
      body: SafeArea(
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
    );
  }
}

// ─── Header banner ──────────────────────────────────────────────────────────

class _HeaderBanner extends ConsumerWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final character = characterById(ref.watch(activeCharacterProvider));

    return Container(
      padding: EdgeInsets.fromLTRB(
          context.r(22), context.r(18), context.r(22), context.r(18)),
      decoration: BoxDecoration(
        color: KColors.purple,
        borderRadius: BorderRadius.circular(context.r(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูลของฉัน',
                  style: montserrat(
                    size: context.r(28),
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: context.r(6)),
                Text(
                  'ชื่อ: $userName',
                  style: montserrat(
                      size: context.r(17),
                      weight: FontWeight.w600,
                      color: Colors.white),
                ),
                Text(
                  'อายุ: 80',
                  style: montserrat(
                      size: context.r(17),
                      weight: FontWeight.w600,
                      color: Colors.white),
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
          ),
          SizedBox(width: context.r(10)),
          // Active character + customize shortcut
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(context.r(8)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: context.r(2)),
                ),
                child: Image.asset(
                  character.asset,
                  height: context.r(74),
                  width: context.r(74),
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: context.r(8)),
              GestureDetector(
                onTap: () => context.push('/customize'),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.r(14), vertical: context.r(6)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.brush_rounded,
                          color: KColors.indigo, size: context.r(15)),
                      SizedBox(width: context.r(4)),
                      Text('ปรับแต่ง',
                          style: montserrat(
                              size: context.r(13),
                              weight: FontWeight.w900,
                              color: KColors.indigo)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Balance card (EMG L/R) ─────────────────────────────────────────────────

/// Sums each muscle reading's %MVC per leg from the balance report and
/// normalizes to a left/right SHARE of total effort (sums to 100). This is
/// the same "share of effort" concept the old mock consts modeled, now
/// derived from real per-muscle %MVC data.
(double left, double right) _legShares(BalanceReport report) {
  double totalFor(LegSide side) {
    var total = 0.0;
    for (final j in report.joints) {
      if (j.side != side) continue;
      total += j.agonist.percentMvc + j.antagonist.percentMvc;
    }
    return total;
  }

  final left = totalFor(LegSide.left);
  final right = totalFor(LegSide.right);
  final sum = left + right;
  if (sum <= 0) return (50.0, 50.0);
  return (left / sum * 100, right / sum * 100);
}

class _BalanceCard extends ConsumerStatefulWidget {
  const _BalanceCard();

  @override
  ConsumerState<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<_BalanceCard> {
  bool _weekly = true;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(balanceReportProvider);
    final (leftShare, rightShare) = _legShares(report);
    final gap = (leftShare - rightShare).abs();
    final status = _BalanceStatus.of(gap);

    return KCard(
      radius: context.r(22),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สมดุลซ้าย–ขวา (EMG)',
              style: montserrat(size: context.r(19), weight: FontWeight.w900)),
          SizedBox(height: context.r(2)),
          Text(
            '% การใช้กล้ามเนื้อจาก EMG ขณะทำท่าที่ลงน้ำหนัก 2 ข้างเท่ากัน '
            '(เช่น ยืนสองเท้า หรือเทียบยืนขาเดียวซ้าย-ขวา)',
            style: montserrat(
                size: context.r(12),
                weight: FontWeight.w500,
                color: const Color(0xFF6D78A8)),
          ),
          SizedBox(height: context.r(12)),

          // Balance result — the main focus of this page.
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
            borderRadius: BorderRadius.circular(context.r(16)),
            child: SizedBox(
              height: context.r(52),
              child: Row(
                children: [
                  Expanded(
                    flex: leftShare.round().clamp(1, 99),
                    child: Container(
                      alignment: Alignment.center,
                      color: KColors.indigo,
                      child: Text('${leftShare.round()}%',
                          style: montserrat(
                              size: context.r(22),
                              weight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
                  Container(width: context.r(4), color: Colors.white),
                  Expanded(
                    flex: rightShare.round().clamp(1, 99),
                    child: Container(
                      alignment: Alignment.center,
                      color: const Color(0xFFFA7F00),
                      child: Text('${rightShare.round()}%',
                          style: montserrat(
                              size: context.r(22),
                              weight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.r(10)),

          // Status strip — driven by |left% - right%| gap
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(12), vertical: context.r(10)),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.10),
              border: Border.all(color: status.color.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(context.r(14)),
            ),
            child: Row(
              children: [
                Icon(status.icon, color: status.color, size: context.r(20)),
                SizedBox(width: context.r(8)),
                Expanded(
                  child: Text(
                    status.label,
                    style: montserrat(
                        size: context.r(13.5),
                        weight: FontWeight.w800,
                        color: status.color),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.r(5)),
          Text(
            'ค่าแนะนำเบื้องต้น ไม่ใช่การวินิจฉัยทางการแพทย์',
            style: montserrat(
                size: context.r(10.5),
                weight: FontWeight.w500,
                color: const Color(0xFF9099BC)),
          ),
          SizedBox(height: context.r(12)),

          // Improvement trend + week/month toggle
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(12), vertical: context.r(10)),
            decoration: BoxDecoration(
              color: KColors.appBg,
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

// ─── History card ───────────────────────────────────────────────────────────

/// Sample sessions shown when the user has no real game history yet, so the
/// history card always demonstrates its layout (mock data kept per design
/// request). Real sessions replace these the moment one is played.
List<GameSessionRecord> _mockHistory() {
  final now = DateTime.now();
  return [
    GameSessionRecord(
        id: 'm1',
        dateTime: now,
        gameId: 'megadance',
        gameName: 'MEGA DANCE',
        iconAsset: 'assets/images/game_icons/megadance.png',
        durationSeconds: 600,
        scoreLabel: '88%',
        percent: 88),
    GameSessionRecord(
        id: 'm2',
        dateTime: now.subtract(const Duration(days: 1)),
        gameId: 'world',
        gameName: 'KINEX WORLD',
        iconAsset: 'assets/images/game_icons/world.png',
        durationSeconds: 900,
        scoreLabel: '76%',
        percent: 76),
    GameSessionRecord(
        id: 'm3',
        dateTime: now.subtract(const Duration(days: 1)),
        gameId: 'thedasher',
        gameName: 'THE DASHER',
        iconAsset: 'assets/images/game_icons/thedasher.png',
        durationSeconds: 540,
        scoreLabel: '2★',
        percent: 72),
    GameSessionRecord(
        id: 'm4',
        dateTime: now.subtract(const Duration(days: 6)),
        gameId: 'megadance',
        gameName: 'MEGA DANCE',
        iconAsset: 'assets/images/game_icons/megadance.png',
        durationSeconds: 600,
        scoreLabel: '47%',
        percent: 47),
    GameSessionRecord(
        id: 'm5',
        dateTime: now.subtract(const Duration(days: 6)),
        gameId: 'world',
        gameName: 'KINEX WORLD',
        iconAsset: 'assets/images/game_icons/world.png',
        durationSeconds: 720,
        scoreLabel: '68%',
        percent: 68),
  ];
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final real =
        ref.watch(gameHistoryProvider).valueOrNull ?? const <GameSessionRecord>[];
    // Fall back to sample data so the card is never empty (mock kept per request).
    final records = real.isEmpty ? _mockHistory() : real;

    // Week stats — only sessions within the last 7 days.
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final week = records.where((r) => r.dateTime.isAfter(cutoff)).toList();
    final weekSessions = week.length;
    final weekMinutes = week.isEmpty
        ? 0
        : (week.fold<double>(0, (s, r) => s + r.durationSeconds) / 60).round();
    final weekAvgScore = week.isEmpty
        ? 0
        : (week.fold<double>(0, (s, r) => s + r.percent) / week.length).round();

    final recent = records.take(5).toList();

    return KCard(
      radius: context.r(22),
      padding: EdgeInsets.all(context.r(16)),
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
            children: [
              Expanded(child: KStatTile(value: '$weekSessions', label: 'ครั้ง')),
              const SizedBox(width: 8),
              Expanded(child: KStatTile(value: '$weekMinutes', label: 'นาที')),
              const SizedBox(width: 8),
              Expanded(
                  child: KStatTile(
                      value: '$weekAvgScore%', label: 'คะแนนเฉลี่ย')),
            ],
          ),
          SizedBox(height: context.r(4)),
          if (recent.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.r(18)),
              child: Center(
                child: Text('ยังไม่มีประวัติการเล่น',
                    style: montserrat(
                        size: context.r(13.5),
                        weight: FontWeight.w600,
                        color: const Color(0xFF9099BC))),
              ),
            )
          else
            for (final r in recent)
              Padding(
                padding: EdgeInsets.only(top: context.r(8)),
                child: _GameRow(record: r),
              ),
        ],
      ),
    );
  }
}

/// Thai relative-date label for a session: today / yesterday / 'd MMM'.
String _thaiDateLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'วันนี้';
  if (diff == 1) return 'เมื่อวาน';
  // No locale arg: Thai date symbols aren't initialized app-wide (matches the
  // assessment/world history pages), so we use the default-locale month name.
  return DateFormat('d MMM').format(dt);
}

class _GameRow extends StatelessWidget {
  final GameSessionRecord record;
  const _GameRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final band = _ScoreBand.of(record.percent.round());
    final minutes = (record.durationSeconds / 60).round();
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(10), vertical: context.r(9)),
      decoration: BoxDecoration(
        color: KColors.appBg,
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(13)),
            child: Image.asset(
              record.iconAsset,
              width: context.r(44),
              height: context.r(44),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: context.r(44),
                height: context.r(44),
                color: const Color(0xFFE7E5F5),
                child: Icon(Icons.sports_esports_rounded,
                    color: KColors.indigo, size: context.r(24)),
              ),
            ),
          ),
          SizedBox(width: context.r(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.gameName,
                    style: montserrat(
                        size: context.r(14.5), weight: FontWeight.w900)),
                Text('${_thaiDateLabel(record.dateTime)} · $minutes นาที',
                    style: montserrat(
                        size: context.r(11.5),
                        weight: FontWeight.w500,
                        color: const Color(0xFF6D78A8))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(record.scoreLabel,
                  style: montserrat(
                      size: context.r(18),
                      weight: FontWeight.w900,
                      color: band.color)),
              SizedBox(height: context.r(2)),
              KPill(band.label, color: band.color),
            ],
          ),
        ],
      ),
    );
  }
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
                color: KColors.purple,
                borderRadius: BorderRadius.circular(context.r(22)),
              ),
              child: Column(
                children: [
                  Text('ข้อมูลเชิงลึก',
                      style: montserrat(
                          size: context.r(16.5),
                          weight: FontWeight.w800,
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
