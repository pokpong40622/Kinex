import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/data/pose_library.dart';
import 'package:kinex_app/screens/learn/pose_coach_page.dart';

/// Contract test for the live camera coach.
///
/// The cue-id list below is transcribed from the wire contract
/// (docs/adr/2026-08-02-pose-coach-all-poses.md) ON PURPOSE — it is a second,
/// independent copy. If someone edits the Thai tables in pose_coach_page.dart
/// and drops an id Unity still emits, this test fails; if Unity's ADR grows a
/// new id, this list is the one place to add it and the test then demands the
/// Thai line. That is the drift this suite exists to catch.

/// Cue ids ANY pose may emit.
const _globalCueIds = <String>[
  'get_ready',
  'not_in_frame',
  'stand_tall',
  'hold',
  'steady',
  'go_slower',
  'rep_good',
  'switch_side',
  'done',
];

/// Cue ids only the named pose emits.
const _poseCueIds = <String, List<String>>{
  'sit_to_stand': ['sit_first', 'stand_up', 'sit_down', 'knees_behind_toes'],
  'seated_knee_lift': ['lift_knee', 'lift_more', 'lower_slow'],
  'hip_abduction': ['knee_straight', 'lift_more', 'too_high', 'lower_slow'],
  'hip_extension': [
    'extend_more',
    'too_high',
    'no_arch',
    'knee_straight',
    'lower_slow',
  ],
  'narrow_base_stand': ['on_heels', 'on_toes', 'phase_done'],
  'tandem_stand': ['feet_in_line'],
  'single_leg_balance': ['lift_foot'],
  'tandem_walk': ['heel_to_toe', 'walk_forward', 'step_good'],
  'side_walk': ['step_side', 'feet_together', 'step_good'],
};

/// Thai script covers U+0E00..U+0E7F.
bool _isThai(String s) => s.runes.any((r) => r >= 0x0E00 && r <= 0x0E7F);

void main() {
  group('cue table covers the wire contract', () {
    test('the ADR lists exactly the 9 poses in the library', () {
      expect(
        poseLibrary.map((p) => p.id).toSet(),
        _poseCueIds.keys.toSet(),
      );
    });

    for (final pose in poseLibrary) {
      test('${pose.id} has a Thai line for every cue it can emit', () {
        final fallback = coachCueText(pose.id, 'get_ready');
        final ids = [..._globalCueIds, ..._poseCueIds[pose.id]!];

        for (final cue in ids) {
          final text = coachCueText(pose.id, cue);
          expect(text, isNotEmpty, reason: '${pose.id}/$cue is blank');
          expect(text, isNot(cue), reason: '${pose.id}/$cue leaks the raw id');
          expect(_isThai(text), isTrue,
              reason: '${pose.id}/$cue is not Thai: "$text"');
          if (cue != 'get_ready') {
            expect(text, isNot(fallback),
                reason: '${pose.id}/$cue silently fell back to get_ready');
          }
          // TTS budget: ~2 seconds at the narrator's slow rate.
          expect(text.length, lessThanOrEqualTo(40),
              reason: '${pose.id}/$cue is too long to speak: "$text"');
        }
      });
    }

    test('an id Flutter has never heard of still reads as an instruction', () {
      final text = coachCueText('hip_abduction', 'some_future_unity_cue');
      expect(text, coachCueText('hip_abduction', 'get_ready'));
      expect(_isThai(text), isTrue);
    });

    test('pose-specific wording wins over the global wording', () {
      // 'hold' is global; no pose overrides it, so both poses read the same.
      expect(coachCueText('tandem_stand', 'hold'),
          coachCueText('single_leg_balance', 'hold'));
      // 'lift_more' means different things in two different poses.
      expect(coachCueText('hip_abduction', 'lift_more'),
          isNot(coachCueText('seated_knee_lift', 'lift_more')));
    });

    test('phase0/phase1 are labelled as phases, not as legs', () {
      expect(coachSideLabel('phase0'), isNotEmpty);
      expect(coachSideLabel('phase1'), isNotEmpty);
      expect(coachSideLabel('phase0'), isNot(coachSideLabel('left')));
      expect(coachSideLabel('phase1'), isNot(coachSideLabel('right')));
      expect(coachSideLabel(''), isEmpty);
    });
  });

  group('coach HUD layout', () {
    const sizes = <String, Size>{
      'tablet portrait (target)': Size(800, 1280),
      'phone': Size(412, 915),
      'short phone': Size(360, 640),
    };

    Widget host(Size size, Widget child) => MediaQuery(
          data: MediaQueryData(size: size),
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Column(
                children: [child, const Spacer()],
              ),
            ),
          ),
        );

    sizes.forEach((label, size) {
      testWidgets('reps mode lays out without overflow — $label',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(
          size,
          CoachHud(
            mode: 'reps',
            reps: 7,
            target: 10,
            hold: 0,
            side: 'left',
            onExit: () {},
          ),
        ));
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'overflow at $label');
        expect(find.text('7/10'), findsOneWidget);
        expect(find.text(coachSideLabel('left')), findsOneWidget);
      });

      testWidgets('hold mode lays out without overflow — $label',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(
          size,
          CoachHud(
            mode: 'hold',
            reps: 0,
            target: 10,
            hold: 0.62,
            side: 'phase1',
            onExit: () {},
          ),
        ));
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'overflow at $label');
        // Ring, not the rep counter.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('0/10'), findsNothing);
        expect(find.text('6/10'), findsOneWidget); // 0.62 * 10s banked
        expect(find.text(coachSideLabel('phase1')), findsOneWidget);
      });
    });

    testWidgets('the cue card shows the pose-specific Thai line',
        (tester) async {
      await tester.pumpWidget(host(
        const Size(412, 915),
        const CoachCueCard(poseId: 'side_walk', cue: 'feet_together'),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(coachCueText('side_walk', 'feet_together')),
          findsOneWidget);
    });
  });

  testWidgets('an unknown poseId shows the not-found screen, not a crash',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PoseCoachPage(poseId: 'not_a_real_pose'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('ไม่พบท่านี้'), findsOneWidget);
  });

  testWidgets('a known poseId opens on the start overlay, camera untouched',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PoseCoachPage(poseId: 'tandem_stand'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('เริ่ม'), findsOneWidget);
    expect(find.text('ยืนต่อเท้า'), findsOneWidget);
  });
}
