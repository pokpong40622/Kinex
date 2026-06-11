import 'package:flutter/material.dart';
import '../data/assessment_session.dart';
import '../models/assessment_stage.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Vertical "train-line" journey map of the 5 assessment stages. Icon-in-circle
/// nodes on a connecting rail, with done / current / upcoming styling. Used on
/// the Intro (as a preview) and Progress (live) screens.
class AssessmentRoadmap extends StatelessWidget {
  final AssessmentSession session;

  /// Tapped the current stage's row (e.g. to continue). Null = display-only.
  final VoidCallback? onTapCurrent;

  const AssessmentRoadmap({super.key, required this.session, this.onTapCurrent});

  static const _teal = KColors.teal;
  static const _grey = Color(0xFFCBD5D1);

  @override
  Widget build(BuildContext context) {
    final current = currentStageIndex(session);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _endpoint(
          context,
          icon: Icons.play_arrow_rounded,
          label: 'เริ่มการประเมิน',
          color: _teal,
          lineBelow: true,
          lineBelowColor: current > 0 ? _teal : _grey,
        ),
        for (var i = 0; i < kStages.length; i++) _stageRow(context, i, current),
        _endpoint(
          context,
          icon: Icons.emoji_events_rounded,
          label: current >= kStages.length ? 'เสร็จสิ้น • ดูผลสรุป' : 'เสร็จสิ้น',
          color: current >= kStages.length ? const Color(0xFFF6A609) : _grey,
          lineAbove: true,
          lineAboveColor: current >= kStages.length ? _teal : _grey,
        ),
      ],
    );
  }

  Widget _stageRow(BuildContext context, int i, int current) {
    final status = stageStatus(i, session);
    final isCurrent = status == StageStatus.current;
    final isDone = status == StageStatus.done;
    final nodeColor = isDone || isCurrent ? _teal : _grey;

    final card = Container(
      margin: EdgeInsets.symmetric(vertical: context.r(6)),
      padding: EdgeInsets.symmetric(horizontal: context.r(16), vertical: context.r(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isCurrent ? Border.all(color: _teal, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isCurrent ? _teal.withAlpha(40) : const Color(0x14000000),
            blurRadius: isCurrent ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kStages[i].title,
                    style: thaiSans(
                        size: context.r(17),
                        weight: FontWeight.w800,
                        color: isDone || isCurrent
                            ? KColors.navyText
                            : KColors.navyText.withAlpha(140))),
                SizedBox(height: context.r(2)),
                Text(kStages[i].subtitle,
                    style: thaiSans(
                        size: context.r(12.5),
                        weight: FontWeight.w500,
                        color: KColors.navyText.withAlpha(120))),
              ],
            ),
          ),
          SizedBox(width: context.r(8)),
          if (isCurrent)
            _pill(context, 'อยู่ที่นี่', _teal)
          else if (isDone)
            Icon(Icons.check_circle_rounded, color: _teal, size: context.r(26))
          else
            Icon(Icons.lock_outline_rounded,
                color: _grey.withAlpha(200), size: context.r(22)),
        ],
      ),
    );

    return _RailRow(
      node: _node(context, kStages[i].icon, nodeColor, isDone: isDone, pulse: isCurrent),
      lineAboveColor: i <= current && i != 0 ? _teal : (i == 0 ? _teal : _grey),
      lineBelowColor: (i < current) ? _teal : _grey,
      content: GestureDetector(
        onTap: isCurrent ? onTapCurrent : null,
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }

  Widget _node(BuildContext context, IconData icon, Color color, {bool isDone = false, bool pulse = false}) {
    return Container(
      width: context.r(48),
      height: context.r(48),
      decoration: BoxDecoration(
        color: color == _grey ? const Color(0xFFEFF3F2) : color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: pulse
            ? [BoxShadow(color: color.withAlpha(110), blurRadius: 14)]
            : null,
      ),
      child: Icon(
        isDone ? Icons.check_rounded : icon,
        color: color == _grey ? _grey : Colors.white,
        size: context.r(24),
      ),
    );
  }

  Widget _endpoint(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool lineAbove = false,
    bool lineBelow = false,
    Color lineAboveColor = _grey,
    Color lineBelowColor = _grey,
  }) {
    return _RailRow(
      node: Container(
        width: context.r(40),
        height: context.r(40),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(icon, color: Colors.white, size: context.r(22)),
      ),
      lineAboveColor: lineAbove ? lineAboveColor : Colors.transparent,
      lineBelowColor: lineBelow ? lineBelowColor : Colors.transparent,
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: context.r(10)),
        child: Text(label,
            style: thaiSans(
                size: context.r(14),
                weight: FontWeight.w700,
                color: KColors.navyText.withAlpha(160))),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color color) => Container(
        padding: EdgeInsets.symmetric(horizontal: context.r(12), vertical: context.r(6)),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: thaiSans(size: context.r(12), weight: FontWeight.w800, color: Colors.white)),
      );
}

/// One row of the rail: a fixed-width gutter (connector line + node) + content.
class _RailRow extends StatelessWidget {
  final Widget node;
  final Widget content;
  final Color lineAboveColor;
  final Color lineBelowColor;

  const _RailRow({
    required this.node,
    required this.content,
    required this.lineAboveColor,
    required this.lineBelowColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: context.r(56),
            child: Column(
              children: [
                Expanded(
                    child: Center(
                        child: Container(width: context.r(4), color: lineAboveColor))),
                node,
                Expanded(
                    child: Center(
                        child: Container(width: context.r(4), color: lineBelowColor))),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
