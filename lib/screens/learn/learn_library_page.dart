import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/pose_library.dart';
import '../../state/learn_progress.dart';
import '../../theme/app_theme.dart';
import '../../theme/kui.dart';
import '../../theme/responsive.dart';

/// Greyscale matrix — desaturates an undiscovered pose's thumbnail so it reads
/// as "not learned yet" until the user opens it.
const ColorFilter _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

List<LearnPose> get _allPoses =>
    [...posesIn(PoseCategory.strength), ...posesIn(PoseCategory.balance)];

/// Pose library — "เรียนรู้ท่าฝึก". A discovery collection: each pose starts
/// locked/greyed and lights up in colour once opened. A progress header turns
/// "learn all 9" into a small goal the user wants to complete.
class LearnLibraryPage extends StatelessWidget {
  const LearnLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.appBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.r(16), context.r(12), context.r(16), context.r(4)),
              child: Row(
                children: [
                  _BackButton(onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  }),
                  SizedBox(width: context.r(12)),
                  Text('เรียนรู้ท่าฝึก',
                      style: thaiSans(
                          size: context.r(22), weight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    context.r(16), context.r(8), context.r(16), context.r(24)),
                children: [
                  const _DiscoveryHeader(),
                  SizedBox(height: context.r(20)),
                  const _CategorySection(category: PoseCategory.strength),
                  SizedBox(height: context.r(22)),
                  const _CategorySection(category: PoseCategory.balance),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collection progress — "เรียนรู้แล้ว X / N ท่า" with a bar. Invites the user to
/// open every pose (each open unlocks it below).
class _DiscoveryHeader extends ConsumerWidget {
  const _DiscoveryHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewed = ref.watch(learnProgressProvider);
    final all = _allPoses;
    final done = all.where((p) => viewed.contains(p.id)).length;
    final total = all.length;
    final pct = total == 0 ? 0.0 : done / total;
    final complete = done >= total;

    return KCard(
      radius: context.r(20),
      padding: EdgeInsets.all(context.r(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.r(46),
                height: context.r(46),
                decoration: BoxDecoration(
                  color: KColors.purple.withAlpha(28),
                  borderRadius: BorderRadius.circular(context.r(14)),
                ),
                child: Icon(
                    complete
                        ? Icons.emoji_events_rounded
                        : Icons.auto_stories_rounded,
                    color: KColors.purple,
                    size: context.r(24)),
              ),
              SizedBox(width: context.r(13)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        complete
                            ? 'เรียนรู้ครบทุกท่าแล้ว!'
                            : 'เปิดดูให้ครบทุกท่า',
                        style: thaiSans(
                            size: context.r(16.5), weight: FontWeight.w800)),
                    Text(
                        complete
                            ? 'เก่งมาก ลองฝึกตามได้เลย'
                            : 'แตะท่าที่ยังเป็นสีเทาเพื่อปลดล็อก',
                        style: thaiSans(
                            size: context.r(12.5),
                            weight: FontWeight.w500,
                            color: KColors.navyText.withAlpha(150))),
                  ],
                ),
              ),
              Text('$done/$total',
                  style: thaiSans(
                      size: context.r(20),
                      weight: FontWeight.w900,
                      color: KColors.purple)),
            ],
          ),
          SizedBox(height: context.r(14)),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: context.r(9),
              backgroundColor: KColors.purple.withAlpha(28),
              valueColor: AlwaysStoppedAnimation(KColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final PoseCategory category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poses = posesIn(category);
    final viewed = ref.watch(learnProgressProvider);
    final done = poses.where((p) => viewed.contains(p.id)).length;
    final color = category.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KSectionHeader(
          category.thaiTitle,
          icon: category.icon,
          color: color,
          trailing: KPill('$done/${poses.length}', color: color),
        ),
        SizedBox(height: context.r(10)),
        for (final pose in poses) ...[
          _PoseCard(pose: pose),
          SizedBox(height: context.r(12)),
        ],
      ],
    );
  }
}

class _PoseCard extends ConsumerWidget {
  final LearnPose pose;
  const _PoseCard({required this.pose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = pose.category.color;
    final discovered = ref.watch(learnProgressProvider).contains(pose.id);
    final grey = KColors.navyText.withAlpha(90);

    // Thumbnail — full colour + a green "learned" check once discovered;
    // desaturated + dimmed while still locked.
    Widget thumbInner = Container(
      width: context.r(64),
      height: context.r(64),
      decoration: BoxDecoration(
        color: (discovered ? color : grey).withAlpha(22),
        borderRadius: BorderRadius.circular(context.r(15)),
        border: Border.all(
            color: (discovered ? color : grey).withAlpha(60), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: pose.image == null
          ? Icon(pose.icon, color: discovered ? color : grey, size: context.r(30))
          : Image.asset(pose.image!, fit: BoxFit.cover),
    );
    if (!discovered && pose.image != null) {
      thumbInner = ColorFiltered(
        colorFilter: _greyscale,
        child: Opacity(opacity: 0.6, child: thumbInner),
      );
    }
    final thumb = Stack(
      clipBehavior: Clip.none,
      children: [
        thumbInner,
        if (discovered)
          Positioned(
            right: -context.r(4),
            bottom: -context.r(4),
            child: Container(
              padding: EdgeInsets.all(context.r(2)),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded,
                  color: KColors.teal, size: context.r(19)),
            ),
          ),
      ],
    );

    return KCard(
      radius: context.r(18),
      padding: EdgeInsets.all(context.r(12)),
      onTap: () => context.push('/learn/${pose.id}'),
      child: Row(
        children: [
          thumb,
          SizedBox(width: context.r(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pose.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: thaiSans(
                      size: context.r(16),
                      weight: FontWeight.w800,
                      color: discovered ? KColors.navyText : grey),
                ),
                SizedBox(height: context.r(3)),
                Text(
                  pose.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: thaiSans(
                      size: context.r(12.5),
                      weight: FontWeight.w500,
                      color:
                          KColors.navyText.withAlpha(discovered ? 150 : 80)),
                ),
                SizedBox(height: context.r(6)),
                discovered
                    ? Row(
                        children: [
                          Icon(
                            pose.facts.isNotEmpty
                                ? pose.facts.first.icon
                                : Icons.info_outline_rounded,
                            size: context.r(13),
                            color: color,
                          ),
                          SizedBox(width: context.r(5)),
                          Expanded(
                            child: Text(
                              pose.facts.isNotEmpty
                                  ? pose.facts.first.label
                                  : pose.target,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: thaiSans(
                                  size: context.r(11.5),
                                  weight: FontWeight.w600,
                                  color: color),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: context.r(13), color: grey),
                          SizedBox(width: context.r(5)),
                          Text('ยังไม่ได้เรียนรู้ · แตะเพื่อเปิด',
                              style: thaiSans(
                                  size: context.r(11.5),
                                  weight: FontWeight.w600,
                                  color: grey)),
                        ],
                      ),
              ],
            ),
          ),
          SizedBox(width: context.r(6)),
          Icon(
              discovered
                  ? Icons.chevron_right_rounded
                  : Icons.lock_outline_rounded,
              size: context.r(22),
              color: discovered ? color.withAlpha(180) : grey),
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
                color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 1)),
          ],
        ),
        child: Icon(Icons.arrow_back_rounded,
            size: context.r(24), color: KColors.navyText),
      ),
    );
  }
}
