import 'package:flutter/material.dart';
import '../data/content.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/kawaii_widgets.dart';
import '../widgets/pictogram_painter.dart';
import 'result_screen.dart';

const _letters = ['ก', 'ข', 'ค', 'ง'];

class MultipleChoiceScreen extends StatefulWidget {
  final Topic topic;
  const MultipleChoiceScreen({super.key, required this.topic});

  @override
  State<MultipleChoiceScreen> createState() => _MultipleChoiceScreenState();
}

class _MultipleChoiceScreenState extends State<MultipleChoiceScreen> {
  late final List<McQuestion> _questions = mcQuestions[widget.topic.id]!;
  int _index = 0;
  int? _selected;
  int _correctCount = 0;

  McQuestion get _q => _questions[_index];

  void _select(int i) {
    if (_selected != null) return;
    setState(() {
      _selected = i;
      if (i == _q.correctIndex) _correctCount++;
    });
  }

  void _next() {
    if (_index == _questions.length - 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            color: widget.topic.color,
            correctCount: _correctCount,
            total: _questions.length,
            onReplay: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MultipleChoiceScreen(topic: widget.topic),
              ),
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.topic.color;
    final answered = _selected != null;
    final isCorrect = answered && _selected == _q.correctIndex;

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
                          'ข้อ ก ข ค ง · ${widget.topic.title.replaceAll('\n', ' ')}',
                          style: AppTheme.body(
                            size: 22,
                            weight: FontWeight.w700,
                            color: AppColors.inkLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'ข้อ ${_index + 1} / ${_questions.length}',
                        style: AppTheme.body(
                          size: 22,
                          weight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_index + (answered ? 1 : 0)) / _questions.length,
                    minHeight: 12,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 760;
                      final questionCard = KawaiiCard(
                        borderColor: color,
                        borderWidth: 9,
                        radius: 34,
                        padding: const EdgeInsets.all(28),
                        child: Row(
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: PictogramIcon(
                                  type: _q.illustration,
                                  size: 70,
                                  accent: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: Text(
                                _q.question,
                                style: AppTheme.body(
                                  size: 26,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      final options = GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: wide ? 4.1 : 2.35,
                        ),
                        itemBuilder: (context, i) {
                          if (!answered) {
                            return AnswerTile.idle(
                              letter: _letters[i],
                              text: _q.options[i],
                              color: color,
                              onTap: () => _select(i),
                            );
                          }
                          if (i == _q.correctIndex) {
                            return AnswerTile.correct(
                              letter: _letters[i],
                              text: _q.options[i],
                              color: color,
                            );
                          }
                          if (i == _selected) {
                            return AnswerTile.wrong(
                              letter: _letters[i],
                              text: _q.options[i],
                              color: color,
                            );
                          }
                          return AnswerTile.faded(
                            letter: _letters[i],
                            text: _q.options[i],
                            color: color,
                          );
                        },
                      );

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            questionCard,
                            const SizedBox(height: 16),
                            options,
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (answered) ...[
                  const SizedBox(height: 12),
                  FeedbackBanner(
                    correct: isCorrect,
                    message: isCorrect
                        ? 'เก่งมากค่ะ! ตอบถูกต้องเลย'
                        : 'ไม่เป็นไรนะคะ คำตอบที่ใช่คือ "${_q.options[_q.correctIndex]}"',
                    nextLabel: _index == _questions.length - 1
                        ? 'ดูผล'
                        : 'ข้อต่อไป',
                    onNext: _next,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
