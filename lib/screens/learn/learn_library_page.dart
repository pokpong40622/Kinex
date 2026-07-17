import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/pose_library.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

/// Pose library — "เรียนรู้ท่าฝึก". Two sections (strength, balance), each
/// listing its poses as tappable cards that push to the pose detail page.
class LearnLibraryPage extends StatelessWidget {
  const LearnLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: KColors.learnBg),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.r(16), context.r(12), context.r(16), context.r(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _BackButton(onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    }),
                    SizedBox(width: context.r(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เรียนรู้ท่าฝึก',
                            style: thaiSans(
                                size: context.r(22), weight: FontWeight.w800),
                          ),
                          SizedBox(height: context.r(2)),
                          Text(
                            'เลือกท่าที่อยากเรียนรู้ · 9 ท่าบริหาร',
                            style: thaiSans(
                                size: context.r(13),
                                weight: FontWeight.w500,
                                color: KColors.navyText.withAlpha(150)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      context.r(16), context.r(8), context.r(16), context.r(24)),
                  children: [
                    _CategorySection(category: PoseCategory.strength),
                    SizedBox(height: context.r(22)),
                    _CategorySection(category: PoseCategory.balance),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final PoseCategory category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    final poses = posesIn(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionPill(category: category, count: poses.length),
        SizedBox(height: context.r(12)),
        for (final pose in poses) ...[
          _PoseCard(pose: pose),
          SizedBox(height: context.r(12)),
        ],
      ],
    );
  }
}

class _SectionPill extends StatelessWidget {
  final PoseCategory category;
  final int count;
  const _SectionPill({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(12), vertical: context.r(10)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            category.color.withAlpha(40),
            category.color.withAlpha(14),
          ],
        ),
        borderRadius: BorderRadius.circular(context.r(18)),
        border: Border.all(color: category.color.withAlpha(45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.r(38),
            height: context.r(38),
            decoration: BoxDecoration(
              gradient: category.gradient,
              borderRadius: BorderRadius.circular(context.r(12)),
              boxShadow: [
                BoxShadow(
                    color: category.color.withAlpha(70),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(category.icon, color: Colors.white, size: context.r(21)),
          ),
          SizedBox(width: context.r(10)),
          Flexible(
            child: Text(
              category.thaiTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: thaiSans(
                  size: context.r(15.5),
                  weight: FontWeight.w800,
                  color: KColors.navyText),
            ),
          ),
          SizedBox(width: context.r(6)),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.r(9), vertical: context.r(3)),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count ท่า',
              style: thaiSans(
                  size: context.r(12),
                  weight: FontWeight.w700,
                  color: category.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoseCard extends StatelessWidget {
  final LearnPose pose;
  const _PoseCard({required this.pose});

  @override
  Widget build(BuildContext context) {
    final color = pose.category.color;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(20)),
        onTap: () => context.push('/learn/${pose.id}'),
        child: Container(
          padding: EdgeInsets.all(context.r(12)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withAlpha(15)],
            ),
            borderRadius: BorderRadius.circular(context.r(20)),
            border: Border.all(color: color.withAlpha(30), width: 1),
            boxShadow: [
              BoxShadow(
                  color: color.withAlpha(28),
                  blurRadius: 12,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.r(64),
                height: context.r(64),
                decoration: BoxDecoration(
                  gradient: pose.image == null ? pose.category.gradient : null,
                  color: pose.image == null ? null : Colors.white,
                  borderRadius: BorderRadius.circular(context.r(16)),
                  border: Border.all(color: color.withAlpha(40), width: 1),
                  boxShadow: [
                    BoxShadow(
                        color: color.withAlpha(85),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: pose.image == null
                    ? Icon(pose.icon, color: Colors.white, size: context.r(28))
                    : Image.asset(pose.image!, fit: BoxFit.cover),
              ),
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
                          color: KColors.navyText),
                    ),
                    SizedBox(height: context.r(3)),
                    Text(
                      pose.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: thaiSans(
                          size: context.r(12.5),
                          weight: FontWeight.w500,
                          color: KColors.navyText.withAlpha(150)),
                    ),
                    SizedBox(height: context.r(6)),
                    Row(
                      children: [
                        Icon(
                          pose.facts.isNotEmpty
                              ? pose.facts.first.icon
                              : Icons.info_outline_rounded,
                          size: context.r(13),
                          color: color.withAlpha(200),
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
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.r(6)),
              Container(
                width: context.r(30),
                height: context.r(30),
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: context.r(14), color: color),
              ),
            ],
          ),
        ),
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
