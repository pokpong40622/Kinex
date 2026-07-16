import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/pose_library.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

/// Detail screen for one learnable pose, shown as a step-by-step wizard:
/// page 0 is the overview (hero + facts), pages 1..N are one per
/// `pose.steps`, and the final step's page also shows the breathing / tips /
/// caution callouts.
class PoseDetailPage extends StatefulWidget {
  final String poseId;
  const PoseDetailPage({super.key, required this.poseId});

  @override
  State<PoseDetailPage> createState() => _PoseDetailPageState();
}

class _PoseDetailPageState extends State<PoseDetailPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Exits the whole detail page (top-left close button, and the circular
  /// back button on page 0) — same fallback behavior as the previous
  /// single-scroll version of this page.
  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  /// Done button on the final page — returns to the pose library.
  void _finish(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/learn');
    }
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pose = poseById(widget.poseId);
    if (pose == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F3FA),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(context.r(16)),
                child: Row(
                  children: [_BackButton(onTap: () => _exit(context))],
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'ไม่พบท่านี้',
                    style: thaiSans(
                        size: context.r(18), weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = pose.category.color;
    final pageCount = 1 + pose.steps.length;
    final isLast = _page == pageCount - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FA),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: context.r(8)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.r(16)),
              child: Row(
                children: [_BackButton(onTap: () => _exit(context))],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pageCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _OverviewPage(pose: pose);
                  }
                  final stepIndex = index - 1;
                  final isLastStep = stepIndex == pose.steps.length - 1;
                  return _StepPage(
                    pose: pose,
                    color: color,
                    stepIndex: stepIndex,
                    showExtras: isLastStep,
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.r(24), vertical: context.r(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _WizardNavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    color: color,
                    onTap: () {
                      if (_page == 0) {
                        _exit(context);
                      } else {
                        _goTo(_page - 1);
                      }
                    },
                  ),
                  Row(
                    children: List.generate(
                      pageCount,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(horizontal: context.r(4)),
                        width: i == _page ? context.r(22) : context.r(8),
                        height: context.r(8),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? color
                              : Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(context.r(6)),
                        ),
                      ),
                    ),
                  ),
                  isLast
                      ? _DoneButton(
                          color: color, onTap: () => _finish(context))
                      : _WizardNavButton(
                          icon: Icons.arrow_forward_ios_rounded,
                          color: color,
                          onTap: () => _goTo(_page + 1),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 0 — hero card + facts chips.
class _OverviewPage extends StatelessWidget {
  final LearnPose pose;
  const _OverviewPage({required this.pose});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          context.r(16), context.r(12), context.r(16), context.r(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(pose: pose),
          SizedBox(height: context.r(20)),
          _FactsWrap(pose: pose),
        ],
      ),
    );
  }
}

/// One page per `pose.steps[stepIndex]` — big numbered badge + step text.
/// The final step's page also shows breathing / tips / caution when present.
class _StepPage extends StatelessWidget {
  final LearnPose pose;
  final Color color;
  final int stepIndex;
  final bool showExtras;
  const _StepPage({
    required this.pose,
    required this.color,
    required this.stepIndex,
    required this.showExtras,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          context.r(16), context.r(12), context.r(16), context.r(20)),
      child: Column(
        children: [
          SizedBox(height: context.r(16)),
          Container(
            width: context.r(64),
            height: context.r(64),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '${stepIndex + 1}',
              style: thaiSans(
                  size: context.r(26),
                  weight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          SizedBox(height: context.r(22)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.r(22)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(16)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              pose.steps[stepIndex],
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(19),
                  weight: FontWeight.w700,
                  color: KColors.navyText),
            ),
          ),
          if (showExtras) ...[
            if (pose.breathing != null) ...[
              SizedBox(height: context.r(20)),
              _BreathingCallout(text: pose.breathing!),
            ],
            if (pose.tips.isNotEmpty) ...[
              SizedBox(height: context.r(20)),
              Text('เคล็ดลับ',
                  style:
                      thaiSans(size: context.r(18), weight: FontWeight.w800)),
              SizedBox(height: context.r(10)),
              _TipsCard(tips: pose.tips),
            ],
            if (pose.caution != null) ...[
              SizedBox(height: context.r(20)),
              _CautionCallout(text: pose.caution!),
            ],
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final LearnPose pose;
  const _HeroCard({required this.pose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.r(22)),
      decoration: BoxDecoration(
        gradient: pose.category.gradient,
        borderRadius: BorderRadius.circular(context.r(26)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.r(64),
            height: context.r(64),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(context.r(18)),
            ),
            child: Icon(pose.icon, color: Colors.white, size: context.r(34)),
          ),
          SizedBox(height: context.r(16)),
          Text(
            pose.name,
            style: thaiSans(
                size: context.r(24),
                weight: FontWeight.w800,
                color: Colors.white),
          ),
          SizedBox(height: context.r(6)),
          Text(
            pose.subtitle,
            style: thaiSans(
                size: context.r(14),
                weight: FontWeight.w500,
                color: Colors.white.withAlpha(230)),
          ),
          SizedBox(height: context.r(14)),
          Wrap(
            spacing: context.r(8),
            runSpacing: context.r(8),
            children: [
              _HeroPill(text: pose.category.thaiShort),
              _HeroPill(text: 'กล้ามเนื้อ/ความสามารถ: ${pose.target}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String text;
  const _HeroPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(12), vertical: context.r(7)),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(55),
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Text(
        text,
        style: thaiSans(
            size: context.r(12.5),
            weight: FontWeight.w700,
            color: Colors.white),
      ),
    );
  }
}

class _FactsWrap extends StatelessWidget {
  final LearnPose pose;
  const _FactsWrap({required this.pose});

  @override
  Widget build(BuildContext context) {
    if (pose.facts.isEmpty) return const SizedBox.shrink();
    final color = pose.category.color;
    return Wrap(
      spacing: context.r(10),
      runSpacing: context.r(10),
      children: [
        for (final fact in pose.facts)
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(14), vertical: context.r(10)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(14)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(fact.icon, size: context.r(17), color: color),
                SizedBox(width: context.r(8)),
                Text(
                  fact.label,
                  style: thaiSans(
                      size: context.r(13.5),
                      weight: FontWeight.w700,
                      color: KColors.navyText),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BreathingCallout extends StatelessWidget {
  final String text;
  const _BreathingCallout({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.r(14)),
      decoration: BoxDecoration(
        color: KColors.blue.withAlpha(20),
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.air_rounded, color: KColors.blue, size: context.r(22)),
          SizedBox(width: context.r(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('การหายใจ',
                    style: thaiSans(
                        size: context.r(14.5),
                        weight: FontWeight.w800,
                        color: KColors.blue)),
                SizedBox(height: context.r(4)),
                Text(
                  text,
                  style: thaiSans(
                      size: context.r(13.5),
                      weight: FontWeight.w600,
                      color: KColors.navyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final List<String> tips;
  const _TipsCard({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.r(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            if (i != 0) SizedBox(height: context.r(10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: KColors.orangeDark, size: context.r(19)),
                SizedBox(width: context.r(9)),
                Expanded(
                  child: Text(
                    tips[i],
                    style: thaiSans(
                        size: context.r(13.5),
                        weight: FontWeight.w600,
                        color: KColors.navyText),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CautionCallout extends StatelessWidget {
  final String text;
  const _CautionCallout({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.r(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety_rounded,
              color: Color(0xFFEF6C00)),
          SizedBox(width: context.r(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ข้อควรระวัง',
                    style: thaiSans(
                        size: context.r(14.5),
                        weight: FontWeight.w800,
                        color: const Color(0xFFB23C00))),
                SizedBox(height: context.r(4)),
                Text(
                  text,
                  style: thaiSans(
                      size: context.r(13.5),
                      weight: FontWeight.w600,
                      color: const Color(0xFFB23C00)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.r(48),
        height: context.r(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(Icons.arrow_back_rounded,
            size: context.r(24), color: KColors.navyText),
      ),
    );
  }
}

/// Circular back/next control used on the wizard pager (colored per the
/// pose's category, unlike the deep-purple version in the_dasher_intro_page).
class _WizardNavButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _WizardNavButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.r(52);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: s * 0.4),
      ),
    );
  }
}

/// Wide pill "done" button shown on the wizard's final page.
class _DoneButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _DoneButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: context.r(52),
        padding: EdgeInsets.symmetric(horizontal: context.r(22)),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(context.r(26)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded,
                color: Colors.white, size: context.r(22)),
            SizedBox(width: context.r(6)),
            Text('เสร็จสิ้น',
                style: thaiSans(
                    size: context.r(16),
                    weight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
