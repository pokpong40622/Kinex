import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/emg_repository.dart';
import '../models/emg_metrics.dart';
import '../models/muscle.dart';
import '../state/info_view_providers.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/balance_widgets.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDate(DateTime dt) =>
    '${dt.year}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

// ─── Page ─────────────────────────────────────────────────────────────────────

class InfoPage extends ConsumerWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdvanced = ref.watch(infoAdvancedProvider);
    final report = ref.watch(balanceReportProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      appBar: AppBar(
        title: Text(
          'ข้อมูล',
          style: montserrat(size: context.r(18), weight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: KColors.navyText,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          _ViewToggle(
            isAdvanced: isAdvanced,
            onChanged: (v) =>
                ref.read(infoAdvancedProvider.notifier).state = v,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.r(16),
                context.r(16),
                context.r(16),
                context.r(32),
              ),
              child: isAdvanced
                  ? _AdvancedBody(report: report)
                  : _NormalBody(report: report),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Normal / Advanced Toggle ─────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final bool isAdvanced;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.isAdvanced, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: context.r(16),
        vertical: context.r(10),
      ),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment<bool>(
            value: false,
            label: Text(
              'ทั่วไป',
              style: thaiSans(size: context.r(14), color: KColors.navyText),
            ),
            icon: const Icon(Icons.person_outline, size: 18),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text(
              'ขั้นสูง',
              style: thaiSans(size: context.r(14), color: KColors.navyText),
            ),
            icon: const Icon(Icons.science_outlined, size: 18),
          ),
        ],
        selected: {isAdvanced},
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Normal View ──────────────────────────────────────────────────────────────

class _NormalBody extends StatelessWidget {
  final BalanceReport report;
  const _NormalBody({required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Intro card
        const _IntroParagraphCard(),
        SizedBox(height: context.r(16)),

        // 2. Balance — CCI per leg (left / right) as a 2×2 gauge grid
        _BalanceCard(report: report),
        SizedBox(height: context.r(16)),

        // 3. MVC info card (left / right peaks + "ดูรายละเอียด" link)
        const _NormalMvcCard(),
        SizedBox(height: context.r(16)),

        // 4. Lifetime stats
        const _LifetimeStatsCard(),
      ],
    );
  }
}

/// Balance per leg: a 2×2 grid of CCI ring gauges (rows = joints, columns =
/// left / right leg) so the user reads each leg's knee & ankle co-contraction.
class _BalanceCard extends StatelessWidget {
  final BalanceReport report;
  const _BalanceCard({required this.report});

  static const _leftColor = KColors.teal;
  static const _rightColor = KColors.indigo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'การทรงตัวของข้อต่อขา',
            style: montserrat(
              size: context.r(16),
              weight: FontWeight.w700,
              color: KColors.navyText,
            ),
          ),
          SizedBox(height: context.r(14)),
          Row(
            children: [
              SizedBox(width: context.r(50)),
              Expanded(child: _legHeader(context, 'ขาซ้าย (L)', _leftColor)),
              Expanded(child: _legHeader(context, 'ขาขวา (R)', _rightColor)),
            ],
          ),
          SizedBox(height: context.r(10)),
          _jointRow(context, 'ข้อเข่า', BalanceJoint.knee),
          SizedBox(height: context.r(12)),
          _jointRow(context, 'ข้อเท้า', BalanceJoint.ankle),
          SizedBox(height: context.r(12)),
          const Divider(height: 1, color: Color(0xFFE4EBF2)),
          SizedBox(height: context.r(10)),
          Text(
            'ตัวเลข = ดัชนีการทำงานร่วมกันของกล้ามเนื้อรอบข้อ (CCI %)',
            style: thaiSans(
              size: context.r(12),
              weight: FontWeight.w500,
              color: const Color(0xFF8090AA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legHeader(BuildContext context, String label, Color color) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.r(10), vertical: context.r(5)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(context.r(20)),
        ),
        child: Text(
          label,
          style: thaiSans(
              size: context.r(13), weight: FontWeight.w800, color: color),
        ),
      ),
    );
  }

  Widget _jointRow(BuildContext context, String label, BalanceJoint joint) {
    return Row(
      children: [
        SizedBox(
          width: context.r(50),
          child: Text(
            label,
            style: thaiSans(
                size: context.r(13),
                weight: FontWeight.w700,
                color: KColors.navyText),
          ),
        ),
        Expanded(
          child: Center(
            child: CciRingGauge(
              cci: report.forJoint(joint, LegSide.left).cci,
              color: _leftColor,
              size: context.r(84),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: CciRingGauge(
              cci: report.forJoint(joint, LegSide.right).cci,
              color: _rightColor,
              size: context.r(84),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroParagraphCard extends StatelessWidget {
  const _IntroParagraphCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(color: KColors.teal),
      padding: EdgeInsets.all(context.r(16)),
      child: Text(
        'แพลตฟอร์มออกกำลังกายและฟื้นฟู '
        'สำหรับผู้มีปัญหาด้านการทรงตัว '
        '— ใช้กล้องตรวจจับท่าทาง ร่วมกับเซ็นเซอร์ EMG '
        'วัดกล้ามเนื้อขา 4 มัด (VL, BF, TA, GCM)',
        style: thaiSans(
          size: context.r(14),
          weight: FontWeight.w500,
          color: KColors.white,
        ),
      ),
    );
  }
}

// ─── Normal MVC Info Card ─────────────────────────────────────────────────────

class _NormalMvcCard extends ConsumerWidget {
  const _NormalMvcCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mvcAsync = ref.watch(mvcCalibrationProvider);

    return Container(
      decoration: cardDecoration(),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ค่าสูงสุดของกล้ามเนื้อ (MVC)',
            style: montserrat(
              size: context.r(15),
              weight: FontWeight.w700,
              color: KColors.navyText,
            ),
          ),
          SizedBox(height: context.r(12)),
          mvcAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, st) => Text(
              'โหลดข้อมูลล้มเหลว',
              style: thaiSans(size: context.r(14), color: Colors.redAccent),
            ),
            data: (mvc) {
              if (mvc == null || !mvc.isComplete) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยังไม่ได้วัดค่าสูงสุด (MVC) — วัดได้ตอนติดตั้งแผ่น EMG',
                      style: thaiSans(
                        size: context.r(14),
                        color: const Color(0xFF8090AA),
                      ),
                    ),
                    SizedBox(height: context.r(12)),
                    ElevatedButton(
                      onPressed: () => context.push('/hardware-guide'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KColors.teal,
                        foregroundColor: KColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(12)),
                        ),
                      ),
                      child: Text(
                        'ไปวัดค่า EMG',
                        style: thaiSans(
                          size: context.r(14),
                          color: KColors.white,
                        ),
                      ),
                    ),
                  ],
                );
              }
              // Calibrated — compact per-muscle table with left / right %MVC.
              Widget sideCell(EmgSample? s, Color color) {
                final pct = s?.percentMvc;
                return Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pct == null ? '—' : '${pct.toStringAsFixed(0)}%',
                        style: montserrat(
                            size: context.r(14),
                            weight: FontWeight.w800,
                            color: color),
                      ),
                      Text(
                        s == null ? '' : '${s.peakMicrovolts.toStringAsFixed(0)} µV',
                        style: thaiSans(
                            size: context.r(11), color: const Color(0xFFAAB4C0)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text('กล้ามเนื้อ',
                            style: thaiSans(
                                size: context.r(12),
                                weight: FontWeight.w700,
                                color: const Color(0xFF8090AA))),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text('ซ้าย (L)',
                            textAlign: TextAlign.end,
                            style: thaiSans(
                                size: context.r(12),
                                weight: FontWeight.w800,
                                color: KColors.teal)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text('ขวา (R)',
                            textAlign: TextAlign.end,
                            style: thaiSans(
                                size: context.r(12),
                                weight: FontWeight.w800,
                                color: KColors.indigo)),
                      ),
                    ],
                  ),
                  SizedBox(height: context.r(8)),
                  ...Muscle.values.map((m) => Padding(
                        padding: EdgeInsets.symmetric(vertical: context.r(5)),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text('${m.code} · ${m.thaiName}',
                                  style: thaiSans(
                                      size: context.r(13),
                                      weight: FontWeight.w700,
                                      color: KColors.navyText)),
                            ),
                            sideCell(mvc.sampleFor(m, LegSide.left), KColors.teal),
                            sideCell(mvc.sampleFor(m, LegSide.right), KColors.indigo),
                          ],
                        ),
                      )),
                  SizedBox(height: context.r(8)),
                  Text(
                    'วัดล่าสุด: ${_fmtDate(mvc.calibratedAt)}',
                    style: thaiSans(
                      size: context.r(12),
                      color: const Color(0xFFAAB4C0),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          ref.read(infoAdvancedProvider.notifier).state = true,
                      child: Text(
                        'ดูรายละเอียดเพิ่มเติม',
                        style: thaiSans(
                          size: context.r(13),
                          weight: FontWeight.w600,
                          color: KColors.teal,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Lifetime Stats Card ──────────────────────────────────────────────────────

class _LifetimeStatsCard extends StatelessWidget {
  const _LifetimeStatsCard();

  static final _rows = <(String, String)>[
    ('จำนวนครั้งที่เล่น', '0'),
    ('คะแนนท่าทางเฉลี่ย', '—'),
    ('เวลารวม', '0 นาที'),
    ('เซ็นเซอร์ EMG', 'ยังไม่ได้เชื่อมต่อ (ข้อมูลตัวอย่าง)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      padding: EdgeInsets.symmetric(
        horizontal: context.r(16),
        vertical: context.r(8),
      ),
      child: Column(
        children: _rows.map((row) {
          final isLast = row == _rows.last;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.r(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.$1,
                      style: thaiSans(
                        size: context.r(14),
                        weight: FontWeight.w500,
                        color: const Color(0xFF6B7A90),
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        row.$2,
                        textAlign: TextAlign.right,
                        style: thaiSans(
                          size: context.r(14),
                          weight: FontWeight.w700,
                          color: KColors.navyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, color: Color(0xFFEDF0F5)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Advanced View ────────────────────────────────────────────────────────────

class _AdvancedBody extends StatelessWidget {
  final BalanceReport report;
  const _AdvancedBody({required this.report});

  @override
  Widget build(BuildContext context) {
    Widget legSection(LegSide side) {
      final color = side == LegSide.left ? KColors.teal : KColors.indigo;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.r(12), vertical: context.r(6)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.r(20)),
                ),
                child: Text('${side.thaiName} (${side.code})',
                    style: thaiSans(
                        size: context.r(14),
                        weight: FontWeight.w800,
                        color: color)),
              ),
            ],
          ),
          SizedBox(height: context.r(10)),
          _JointDetailCard(jb: report.forJoint(BalanceJoint.knee, side)),
          SizedBox(height: context.r(12)),
          _JointDetailCard(jb: report.forJoint(BalanceJoint.ankle, side)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        legSection(LegSide.left),
        SizedBox(height: context.r(18)),
        legSection(LegSide.right),
        SizedBox(height: context.r(16)),
        // MVC reference card — the 100% denominator for every %MVC reading
        const MvcCard(),
        SizedBox(height: context.r(16)),
        const _ExplainerCard(),
      ],
    );
  }
}

class _JointDetailCard extends StatelessWidget {
  final JointBalance jb;
  const _JointDetailCard({required this.jb});

  @override
  Widget build(BuildContext context) {
    // Colour each card by LEG so left/right stay visually distinct.
    final isLeft = jb.side == LegSide.left;
    final accent = isLeft ? KColors.teal : KColors.indigo;
    final accentSoft =
        isLeft ? const Color(0xFF0E9E78) : const Color(0xFF4A37C0);

    return Container(
      decoration: cardDecoration(),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with accent bar
          Row(
            children: [
              Container(
                width: context.r(4),
                height: context.r(22),
                margin: EdgeInsets.only(right: context.r(10)),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '${jb.joint.thaiName} · ${jb.side.thaiName}',
                style: montserrat(
                  size: context.r(15),
                  weight: FontWeight.w700,
                  color: KColors.navyText,
                ),
              ),
            ],
          ),
          SizedBox(height: context.r(14)),

          // Agonist %MVC bar
          MvcPercentBar(reading: jb.agonist, barColor: accent),
          SizedBox(height: context.r(12)),

          // Antagonist %MVC bar (slightly muted shade)
          MvcPercentBar(reading: jb.antagonist, barColor: accentSoft),
          SizedBox(height: context.r(14)),

          const Divider(height: 1, color: Color(0xFFE4EBF2)),
          SizedBox(height: context.r(10)),

          // CCI display
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'CCI  ${jb.cci.toStringAsFixed(1)}%',
                style: montserrat(
                  size: context.r(20),
                  weight: FontWeight.w800,
                  color: accent,
                ),
              ),
              SizedBox(width: context.r(10)),
              Expanded(
                child: Text(
                  'ดัชนีการหดตัวร่วม = 2·min/(a+b) ของ %MVC',
                  style: thaiSans(
                    size: context.r(11),
                    weight: FontWeight.w400,
                    color: const Color(0xFF8090AA),
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

class _ExplainerCard extends StatelessWidget {
  const _ExplainerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(color: const Color(0xFFF0EDFF)),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เกี่ยวกับ %MVC และ CCI',
            style: montserrat(
              size: context.r(14),
              weight: FontWeight.w700,
              color: KColors.deepPurple,
            ),
          ),
          SizedBox(height: context.r(8)),
          Text(
            '%MVC = EMGMean ÷ EMGPeak '
            '— เปอร์เซ็นต์แรงหดตัวเทียบกับแรงสูงสุดของผู้ใช้ '
            '(อ้างอิง EMGPeak/EMGMean). '
            'CCI บอกว่ากล้ามเนื้อคู่ตรงข้ามทำงานร่วมกันมากแค่ไหน. '
            'ขณะนี้ยังไม่ได้เชื่อมต่อ EMG จึงเป็นข้อมูลตัวอย่าง.',
            style: thaiSans(
              size: context.r(13),
              weight: FontWeight.w400,
              color: const Color(0xFF5A4A7A),
            ),
          ),
        ],
      ),
    );
  }
}
