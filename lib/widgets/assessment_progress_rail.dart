import 'package:flutter/material.dart';
import '../data/assessment_session.dart';
import '../models/assessment_stage.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Slim horizontal "you are here" rail shown at the top of in-test screens.
/// Five icon nodes connected by a line + a finish flag, current one enlarged.
class AssessmentProgressRail extends StatelessWidget {
  final AssessmentSession session;
  final int currentStage;

  const AssessmentProgressRail({
    super.key,
    required this.session,
    required this.currentStage,
  });

  static const _teal = KColors.teal;
  static const _grey = Color(0xFFCBD5D1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < kStages.length; i++) ...[
              _dot(context, i),
              if (i < kStages.length - 1) _line(context, i),
            ],
            _line(context, kStages.length - 1),
            _flag(context),
          ],
        ),
        SizedBox(height: context.r(8)),
        Text(
          'ขั้นที่ ${currentStage + 1} จาก ${kStages.length} · ${kStages[currentStage].title}',
          style: thaiSans(
              size: context.r(13), weight: FontWeight.w700, color: KColors.tealDark),
        ),
      ],
    );
  }

  bool _done(int i) => stageDone(i, session) || i < currentStage;

  Widget _dot(BuildContext context, int i) {
    final isCurrent = i == currentStage;
    final done = _done(i) && !isCurrent;
    final color = isCurrent || done ? _teal : _grey;
    final size = isCurrent ? context.r(34) : context.r(26);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: done || isCurrent ? color : const Color(0xFFEFF3F2),
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? [BoxShadow(color: _teal.withAlpha(110), blurRadius: 10)]
            : null,
      ),
      child: Icon(
        done ? Icons.check_rounded : kStages[i].icon,
        size: isCurrent ? context.r(18) : context.r(14),
        color: done || isCurrent ? Colors.white : _grey,
      ),
    );
  }

  Widget _line(BuildContext context, int i) => Expanded(
        child: Container(
          height: context.r(4),
          margin: EdgeInsets.symmetric(horizontal: context.r(2)),
          color: i < currentStage ? _teal : _grey,
        ),
      );

  Widget _flag(BuildContext context) {
    final finished = currentStage >= kStages.length;
    return Icon(Icons.emoji_events_rounded,
        size: context.r(24), color: finished ? const Color(0xFFF6A609) : _grey);
  }
}
