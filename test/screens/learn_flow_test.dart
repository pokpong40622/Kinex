import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/data/pose_library.dart';
import 'package:kinex_app/screens/learn/pose_detail_page.dart';
import 'package:kinex_app/screens/learn/pose_success_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The learn flow's shape: read the whole wizard first, and only then is the
/// camera offered; finishing in front of the camera lands on a success screen
/// that counts the pose towards the library total.

void main() {
  Widget host(Widget child) => ProviderScope(
        child: MaterialApp(home: child),
      );

  void sizeTo(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('wizard gates the camera behind the last step', () {
    testWidgets('the try button is absent until the final page',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      sizeTo(tester, const Size(800, 1280));

      await tester.pumpWidget(host(const PoseDetailPage(poseId: 'tandem_stand')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Overview page: read first, no shortcut to the camera.
      expect(find.text('ลองทำเอง'), findsNothing);
      // The library position is shown up front.
      final index = poseLibrary.indexWhere((p) => p.id == 'tandem_stand') + 1;
      expect(find.text('ท่าที่ $index จาก ${poseLibrary.length}'),
          findsOneWidget);

      // Swipe through every step page.
      final steps = poseById('tandem_stand')!.steps.length;
      for (var i = 0; i < steps; i++) {
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      expect(find.text('ลองทำเอง'), findsOneWidget);
    });
  });

  group('success screen', () {
    testWidgets('names the pose and counts it towards the library total',
        (tester) async {
      // One pose already practised, so the read-out must be 1 / 9.
      SharedPreferences.setMockInitialValues({
        'learn_practiced_poses': <String>['tandem_stand'],
      });
      sizeTo(tester, const Size(800, 1280));

      var exited = 0;
      var retried = 0;
      await tester.pumpWidget(host(PoseSuccessView(
        pose: poseById('tandem_stand')!,
        reps: 4,
        mode: 'hold',
        onExit: () => exited++,
        onRetry: () => retried++,
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ยอดเยี่ยม!'), findsOneWidget);
      expect(find.text('ยืนต่อเท้า'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text(' / ${poseLibrary.length} ท่า'), findsOneWidget);
      // hold mode reports rounds held, not reps performed.
      expect(find.text('ค้างครบ 4 รอบ'), findsOneWidget);

      await tester.tap(find.text('ฝึกอีกครั้ง'));
      await tester.tap(find.text('เสร็จสิ้น'));
      expect(retried, 1);
      expect(exited, 1);
    });

    testWidgets('lays out with nothing practised yet', (tester) async {
      SharedPreferences.setMockInitialValues({});
      sizeTo(tester, const Size(360, 640));

      await tester.pumpWidget(host(PoseSuccessView(
        pose: poseById('sit_to_stand')!,
        reps: 15,
        mode: 'reps',
        onExit: () {},
        onRetry: () {},
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'overflow on a short phone');
      expect(find.text('ทำได้ 15 ครั้ง'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });
}
