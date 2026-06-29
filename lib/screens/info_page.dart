import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/emg_repository.dart';
import '../models/emg_metrics.dart';
import '../models/muscle.dart';
import '../state/info_view_providers.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/balance_widgets.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class InfoPage extends ConsumerWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdvanced = ref.watch(infoAdvancedProvider);
    final report = ref.watch(mockBalanceReportProvider);

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
    final knee = report.forJoint(BalanceJoint.knee);
    final ankle = report.forJoint(BalanceJoint.ankle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro paragraph
        const _IntroParagraphCard(),
        SizedBox(height: context.r(16)),

        // Balance gauges + leg diagram
        Container(
          decoration: cardDecoration(),
          padding: EdgeInsets.all(context.r(16)),
          child: Column(
            children: [
              Text(
                'การทรงตัวของข้อต่อขา',
                style: montserrat(
                  size: context.r(16),
                  weight: FontWeight.w700,
                  color: KColors.navyText,
                ),
              ),
              SizedBox(height: context.r(16)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Knee gauge (left)
                  Expanded(
                    child: _JointGaugeColumn(
                      thaiLabel: BalanceJoint.knee.thaiName,
                      shortLabel: 'ข้อเข่า',
                      cci: knee.cci,
                      color: KColors.teal,
                      gaugeSize: context.r(88),
                    ),
                  ),
                  // Leg diagram (centre)
                  SizedBox(
                    width: context.r(86),
                    child: LegDiagram(
                      kneeCci: knee.cci,
                      ankleCci: ankle.cci,
                    ),
                  ),
                  // Ankle gauge (right)
                  Expanded(
                    child: _JointGaugeColumn(
                      thaiLabel: BalanceJoint.ankle.thaiName,
                      shortLabel: 'ข้อเท้า',
                      cci: ankle.cci,
                      color: KColors.blue,
                      gaugeSize: context.r(88),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.r(14)),
              const Divider(height: 1, color: Color(0xFFE4EBF2)),
              SizedBox(height: context.r(10)),
              _CciCaption(
                text:
                    'กล้ามเนื้อรอบข้อเข่าทำงานประสานกัน '
                    '${knee.cci.toStringAsFixed(0)}%',
                color: KColors.teal,
              ),
              SizedBox(height: context.r(5)),
              _CciCaption(
                text:
                    'กล้ามเนื้อรอบข้อเท้าทำงานประสานกัน '
                    '${ankle.cci.toStringAsFixed(0)}%',
                color: KColors.blue,
              ),
            ],
          ),
        ),
        SizedBox(height: context.r(16)),

        // Lifetime stats
        const _LifetimeStatsCard(),
        SizedBox(height: context.r(16)),

        // MVC summary (compact)
        const MvcCard(compact: true),
      ],
    );
  }
}

class _JointGaugeColumn extends StatelessWidget {
  final String thaiLabel;
  final String shortLabel;
  final double cci;
  final Color color;
  final double gaugeSize;

  const _JointGaugeColumn({
    required this.thaiLabel,
    required this.shortLabel,
    required this.cci,
    required this.color,
    required this.gaugeSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CciRingGauge(cci: cci, color: color, size: gaugeSize),
        SizedBox(height: context.r(6)),
        Text(
          shortLabel,
          style: thaiSans(
            size: context.r(13),
            weight: FontWeight.w600,
            color: KColors.navyText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CciCaption extends StatelessWidget {
  final String text;
  final Color color;
  const _CciCaption({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: context.r(8),
          height: context.r(8),
          margin: EdgeInsets.only(right: context.r(6)),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text(
            text,
            style: thaiSans(
              size: context.r(12),
              weight: FontWeight.w500,
              color: const Color(0xFF5A6880),
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
        'วัดกล้ามเนื้อขา 4 มัด',
        style: thaiSans(
          size: context.r(14),
          weight: FontWeight.w500,
          color: KColors.white,
        ),
      ),
    );
  }
}

class _LifetimeStatsCard extends StatelessWidget {
  const _LifetimeStatsCard();

  static final _rows = <(String, String)>[
    ('จำนวนครั้งที่เล่น', '0'),
    ('คะแนนท่าทางเฉลี่ย', '—'),
    ('เวลารวม', '0 นาที'),
    ('เซ็นเซอร์ EMG', 'ยังไม่ได้เชื่อมต่อ (ใช้ข้อมูลตัวอย่าง)'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JointDetailCard(jb: report.forJoint(BalanceJoint.knee)),
        SizedBox(height: context.r(16)),
        _JointDetailCard(jb: report.forJoint(BalanceJoint.ankle)),
        SizedBox(height: context.r(16)),
        const _ExplainerCard(),
        SizedBox(height: context.r(16)),
        const MvcCard(),
      ],
    );
  }
}

class _JointDetailCard extends StatelessWidget {
  final JointBalance jb;
  const _JointDetailCard({required this.jb});

  @override
  Widget build(BuildContext context) {
    final isKnee = jb.joint == BalanceJoint.knee;
    final accent = isKnee ? KColors.teal : KColors.blue;
    final accentSoft = isKnee
        ? const Color(0xFF0EA47A) // tealDark-ish
        : const Color(0xFF1B55C8); // blue-dark

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
                jb.joint.thaiName,
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

          // Antagonist %MVC bar (slightly muted)
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
            '(EMGPeak / EMGMean). '
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
