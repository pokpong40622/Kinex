import 'dart:math';
import 'package:flutter/material.dart';
import '../data/content.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/kawaii_widgets.dart';
import '../widgets/pictogram_painter.dart';
import 'result_screen.dart';

/// Matching mode: tap a situation card, then tap its care-tip card. A soft
/// curved line is drawn to connect them once matched. Tap-to-connect (rather
/// than drag-to-draw) keeps this comfortable for hands that find precise
/// dragging difficult — the connecting line still appears as the reward.
class MatchingScreen extends StatefulWidget {
  final Topic topic;
  const MatchingScreen({super.key, required this.topic});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  late final List<MatchPair> _pairs = matchPairs[widget.topic.id]!;
  late final List<int> _leftOrder = List.generate(_pairs.length, (i) => i);
  late final List<int> _rightOrder = List.generate(_pairs.length, (i) => i)
    ..shuffle(Random(widget.topic.id.hashCode));

  final GlobalKey _stackKey = GlobalKey();
  final Map<int, GlobalKey> _leftKeys = {};
  final Map<int, GlobalKey> _rightKeys = {};
  Map<int, Offset> _leftCenters = {};
  Map<int, Offset> _rightCenters = {};

  final Set<int> _matched = {};
  int? _selectedLeft;
  int? _selectedRight;
  int? _mismatchLeft;
  int? _mismatchRight;

  @override
  void initState() {
    super.initState();
    for (final i in _leftOrder) {
      _leftKeys[i] = GlobalKey();
    }
    for (final i in _rightOrder) {
      _rightKeys[i] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;
    final left = <int, Offset>{};
    final right = <int, Offset>{};
    for (final entry in _leftKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final global = box.localToGlobal(box.size.centerRight(Offset.zero));
      left[entry.key] = stackBox.globalToLocal(global);
    }
    for (final entry in _rightKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final global = box.localToGlobal(box.size.centerLeft(Offset.zero));
      right[entry.key] = stackBox.globalToLocal(global);
    }
    if (!mounted) return;
    setState(() {
      _leftCenters = left;
      _rightCenters = right;
    });
  }

  void _tapLeft(int pairIndex) {
    if (_matched.contains(pairIndex) || _mismatchLeft != null) return;
    setState(() => _selectedLeft = pairIndex);
    if (_selectedRight != null) _evaluate();
  }

  void _tapRight(int pairIndex) {
    if (_matched.contains(pairIndex) || _mismatchRight != null) return;
    setState(() => _selectedRight = pairIndex);
    if (_selectedLeft != null) _evaluate();
  }

  void _evaluate() {
    if (_selectedLeft == _selectedRight) {
      setState(() {
        _matched.add(_selectedLeft!);
        _selectedLeft = null;
        _selectedRight = null;
      });
      if (_matched.length == _pairs.length) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                color: widget.topic.color,
                correctCount: _pairs.length,
                total: _pairs.length,
                onReplay: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MatchingScreen(topic: widget.topic),
                  ),
                ),
              ),
            ),
          );
        });
      }
    } else {
      setState(() {
        _mismatchLeft = _selectedLeft;
        _mismatchRight = _selectedRight;
      });
      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        setState(() {
          _selectedLeft = null;
          _selectedRight = null;
          _mismatchLeft = null;
          _mismatchRight = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.topic.color;
    return Scaffold(
      body: SafeArea(
        child: CenteredGameArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KawaiiTopBar(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.ink,
                          size: 34,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'จับคู่การ์ด · ${widget.topic.title.replaceAll('\n', ' ')}',
                          style: AppTheme.body(
                            size: 22,
                            weight: FontWeight.w700,
                            color: AppColors.inkLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'จับคู่แล้ว ${_matched.length} / ${_pairs.length}',
                        style: AppTheme.body(
                          size: 22,
                          weight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'แตะการ์ดสถานการณ์ แล้วแตะวิธีดูแลที่เข้าคู่กันนะคะ',
                  style: AppTheme.body(size: 20, color: AppColors.inkLight),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    key: _stackKey,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _LinePainter(
                              matched: _matched,
                              leftCenters: _leftCenters,
                              rightCenters: _rightCenters,
                              color: AppColors.happyGreen,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1080),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final i in _leftOrder)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _MatchCard(
                                          key: _leftKeys[i],
                                          text: _pairs[i].situation,
                                          illustration:
                                              _pairs[i].situationIllustration,
                                          color: color,
                                          state: _stateFor(i, isLeft: true),
                                          onTap: () => _tapLeft(i),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 76),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final i in _rightOrder)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _MatchCard(
                                          key: _rightKeys[i],
                                          text: _pairs[i].tip,
                                          illustration:
                                              _pairs[i].tipIllustration,
                                          color: color,
                                          state: _stateFor(i, isLeft: false),
                                          onTap: () => _tapRight(i),
                                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  _MatchCardState _stateFor(int pairIndex, {required bool isLeft}) {
    if (_matched.contains(pairIndex)) return _MatchCardState.matched;
    if (isLeft ? _mismatchLeft == pairIndex : _mismatchRight == pairIndex) {
      return _MatchCardState.mismatch;
    }
    if (isLeft ? _selectedLeft == pairIndex : _selectedRight == pairIndex) {
      return _MatchCardState.selected;
    }
    return _MatchCardState.idle;
  }
}

enum _MatchCardState { idle, selected, matched, mismatch }

class _MatchCard extends StatelessWidget {
  final String text;
  final PictogramType illustration;
  final Color color;
  final _MatchCardState state;
  final VoidCallback onTap;

  const _MatchCard({
    super.key,
    required this.text,
    required this.illustration,
    required this.color,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border = color;
    Color? fill;
    Widget? badge;
    if (state == _MatchCardState.matched) {
      border = AppColors.happyGreen;
      fill = AppColors.happyGreen.withValues(alpha: 0.10);
      badge = const Icon(
        Icons.check_circle_rounded,
        color: AppColors.happyGreen,
        size: 26,
      );
    } else if (state == _MatchCardState.selected) {
      fill = color.withValues(alpha: 0.035);
    } else if (state == _MatchCardState.mismatch) {
      border = AppColors.gentleRed;
      fill = AppColors.gentleRed.withValues(alpha: 0.08);
    }

    return KawaiiCard(
      borderColor: border,
      fillColor: fill,
      borderWidth:
          state == _MatchCardState.matched || state == _MatchCardState.selected
          ? 9
          : 8,
      radius: 28,
      onTap: state == _MatchCardState.matched ? null : onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          PictogramIcon(type: illustration, size: 50, accent: color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTheme.body(size: 20, weight: FontWeight.w700),
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 4), badge],
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Set<int> matched;
  final Map<int, Offset> leftCenters;
  final Map<int, Offset> rightCenters;
  final Color color;

  _LinePainter({
    required this.matched,
    required this.leftCenters,
    required this.rightCenters,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final i in matched) {
      final l = leftCenters[i];
      final r = rightCenters[i];
      if (l == null || r == null) continue;
      final path = Path()..moveTo(l.dx, l.dy);
      final mid = Offset((l.dx + r.dx) / 2, (l.dy + r.dy) / 2);
      path.quadraticBezierTo(mid.dx, l.dy, r.dx, r.dy);
      canvas.drawPath(path, paint);
      canvas.drawCircle(l, 6, Paint()..color = color);
      canvas.drawCircle(r, 6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.matched.length != matched.length ||
      oldDelegate.leftCenters != leftCenters ||
      oldDelegate.rightCenters != rightCenters;
}
