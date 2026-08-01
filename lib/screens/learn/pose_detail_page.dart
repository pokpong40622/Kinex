import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/pose_library.dart';
import '../../models/daily_quest.dart';
import '../../services/tts_service.dart';
import '../../state/learn_progress.dart';
import '../../state/quest_providers.dart';
import '../../state/tts_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/kui.dart';
import '../../theme/responsive.dart';

/// Detail screen for one learnable pose, shown as a step-by-step wizard:
/// page 0 is the overview (hero + facts), pages 1..N are one per
/// `pose.steps`, and the final step's page also shows the breathing / tips /
/// caution callouts.
///
/// Opening this page "discovers" the pose (see `learn_progress.dart`): the
/// library card turns from greyed-out to full colour from then on.
class PoseDetailPage extends ConsumerStatefulWidget {
  final String poseId;
  const PoseDetailPage({super.key, required this.poseId});

  @override
  ConsumerState<PoseDetailPage> createState() => _PoseDetailPageState();
}

class _PoseDetailPageState extends ConsumerState<PoseDetailPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Mark viewed after the first frame — same pattern as other pages that
    // touch a provider from initState (see emg_detail_page.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pose = poseById(widget.poseId);
      if (pose != null) {
        ref.read(learnProgressProvider.notifier).markViewed(widget.poseId);
        ref.read(dailyQuestsProvider.notifier).bump(QuestId.learnPose);
        if (ref.read(ttsNarratorEnabledProvider)) {
          ref.read(ttsServiceProvider).speak('${pose.name} ${pose.subtitle}');
        }
      }
    });
  }

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
        backgroundColor: KColors.appBg,
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
                      size: context.r(18),
                      weight: FontWeight.w700,
                    ),
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
    // Only this one pose has a live camera coach so far; every other pose keeps
    // the plain read-only wizard.
    final hasCoach = pose.id == 'hip_abduction';

    return Scaffold(
      backgroundColor: KColors.appBg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: context.r(8)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.r(16)),
              child: Row(children: [_BackButton(onTap: () => _exit(context))]),
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
            if (hasCoach && isLast)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.r(24),
                  0,
                  context.r(24),
                  context.r(4),
                ),
                child: _PracticeButton(
                  color: color,
                  onTap: () => context.push('/learn/coach/hip_abduction'),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.r(24),
                vertical: context.r(20),
              ),
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
                      ? _DoneButton(color: color, onTap: () => _finish(context))
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

/// "ฝึกกับกล้อง" — opens the live Unity camera coach. Shown on the final wizard
/// page of the one pose that has a coach.
class _PracticeButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _PracticeButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: context.r(56),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(context.r(28)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_rounded,
              color: Colors.white,
              size: context.r(24),
            ),
            SizedBox(width: context.r(8)),
            Text(
              'ฝึกกับกล้อง',
              style: thaiSans(
                size: context.r(17),
                weight: FontWeight.w800,
                color: Colors.white,
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
        context.r(16),
        context.r(12),
        context.r(16),
        context.r(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(pose: pose),
          if (pose.image != null) ...[
            SizedBox(height: context.r(16)),
            _PosePhoto(pose: pose),
          ],
          SizedBox(height: context.r(22)),
          Text(
            'ข้อมูลโดยสังเขป',
            style: thaiSans(
              size: context.r(14),
              weight: FontWeight.w700,
              color: KColors.navyText.withAlpha(170),
            ),
          ),
          SizedBox(height: context.r(10)),
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
        context.r(16),
        context.r(12),
        context.r(16),
        context.r(20),
      ),
      child: Column(
        children: [
          SizedBox(height: context.r(16)),
          Container(
            width: context.r(60),
            height: context.r(60),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${stepIndex + 1}',
              style: thaiSans(
                size: context.r(24),
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: context.r(22)),
          SizedBox(
            width: double.infinity,
            child: KCard(
              radius: context.r(18),
              padding: EdgeInsets.all(context.r(22)),
              child: Text(
                pose.steps[stepIndex],
                textAlign: TextAlign.center,
                style: thaiSans(
                  size: context.r(19),
                  weight: FontWeight.w700,
                  color: KColors.navyText,
                ),
              ),
            ),
          ),
          if (showExtras) ...[
            if (pose.breathing != null) ...[
              SizedBox(height: context.r(20)),
              _BreathingCallout(text: pose.breathing!),
            ],
            if (pose.tips.isNotEmpty) ...[
              SizedBox(height: context.r(20)),
              Text(
                'เคล็ดลับ',
                style: thaiSans(size: context.r(18), weight: FontWeight.w800),
              ),
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

/// Large reference photo of the pose (from the physiotherapy booklet), shown
/// on a calm flat card so the cut-out figure reads clearly.
class _PosePhoto extends StatelessWidget {
  final LearnPose pose;
  const _PosePhoto({required this.pose});

  @override
  Widget build(BuildContext context) {
    final color = pose.category.color;
    return KCard(
      radius: context.r(20),
      padding: EdgeInsets.all(context.r(12)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera_back_rounded,
                size: context.r(16),
                color: color,
              ),
              SizedBox(width: context.r(6)),
              Text(
                'ตัวอย่างท่า',
                style: thaiSans(
                  size: context.r(13),
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: context.r(8)),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.r(14)),
            child: Image.asset(
              pose.image!,
              height: context.r(220),
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// Overview hero — flat white card with a solid category-color accent bar
/// (no gradients, no icon glow).
class _HeroCard extends StatelessWidget {
  final LearnPose pose;
  const _HeroCard({required this.pose});

  @override
  Widget build(BuildContext context) {
    final color = pose.category.color;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: KColors.hairline, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: context.r(6), color: color),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(context.r(18)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.r(52),
                      height: context.r(52),
                      decoration: BoxDecoration(
                        color: color.withAlpha(24),
                        borderRadius: BorderRadius.circular(context.r(15)),
                        border: Border.all(
                          color: color.withAlpha(70),
                          width: 1,
                        ),
                      ),
                      child: Icon(pose.icon, color: color, size: context.r(26)),
                    ),
                    SizedBox(width: context.r(14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pose.name,
                            style: thaiSans(
                              size: context.r(20),
                              weight: FontWeight.w800,
                              color: KColors.navyText,
                            ),
                          ),
                          SizedBox(height: context.r(5)),
                          Text(
                            pose.subtitle,
                            style: thaiSans(
                              size: context.r(13.5),
                              weight: FontWeight.w500,
                              color: KColors.navyText.withAlpha(160),
                            ),
                          ),
                          SizedBox(height: context.r(12)),
                          Wrap(
                            spacing: context.r(8),
                            runSpacing: context.r(8),
                            children: [
                              KPill(
                                pose.category.thaiShort,
                                color: color,
                                icon: pose.category.icon,
                              ),
                              KPill(
                                pose.target,
                                color: color,
                                icon: Icons.track_changes_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      spacing: context.r(8),
      runSpacing: context.r(8),
      children: [
        for (final fact in pose.facts)
          KPill(fact.label, color: color, icon: fact.icon),
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
        color: KColors.blue.withAlpha(16),
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: KColors.blue.withAlpha(50), width: 1),
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
                Text(
                  'การหายใจ',
                  style: thaiSans(
                    size: context.r(14.5),
                    weight: FontWeight.w800,
                    color: KColors.blue,
                  ),
                ),
                SizedBox(height: context.r(4)),
                Text(
                  text,
                  style: thaiSans(
                    size: context.r(13.5),
                    weight: FontWeight.w600,
                    color: KColors.navyText,
                  ),
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
    return KCard(
      radius: context.r(16),
      padding: EdgeInsets.all(context.r(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            if (i != 0) SizedBox(height: context.r(10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: KColors.orangeDark,
                  size: context.r(19),
                ),
                SizedBox(width: context.r(9)),
                Expanded(
                  child: Text(
                    tips[i],
                    style: thaiSans(
                      size: context.r(13.5),
                      weight: FontWeight.w600,
                      color: KColors.navyText,
                    ),
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
        border: Border.all(color: const Color(0x30EF6C00), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety_rounded, color: Color(0xFFEF6C00)),
          SizedBox(width: context.r(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อควรระวัง',
                  style: thaiSans(
                    size: context.r(14.5),
                    weight: FontWeight.w800,
                    color: const Color(0xFFB23C00),
                  ),
                ),
                SizedBox(height: context.r(4)),
                Text(
                  text,
                  style: thaiSans(
                    size: context.r(13.5),
                    weight: FontWeight.w600,
                    color: const Color(0xFFB23C00),
                  ),
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
          border: Border.all(color: KColors.hairline, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: context.r(24),
          color: KColors.navyText,
        ),
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
  const _WizardNavButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: context.r(22)),
            SizedBox(width: context.r(6)),
            Text(
              'เสร็จสิ้น',
              style: thaiSans(
                size: context.r(16),
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
