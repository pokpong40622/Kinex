import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinex_app/screens/practice_page.dart';

/// The practice tab packs a header, plaque, card carousel, dots and a fixed-size
/// CTA into one non-scrolling Column, so it is exactly the kind of layout that
/// silently overflows on a short screen. These pump it at the extremes of the
/// device range and fail on any overflow (Flutter reports those as exceptions
/// during paint, which `tester.takeException()` surfaces).
void main() {
  Widget host(Size size) => MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(
            body: PracticeTab(onStartGame: () {}),
          ),
        ),
      );

  const sizes = <String, Size>{
    'tablet portrait (target)': Size(800, 1280),
    'large tablet': Size(1200, 1920),
    'phone': Size(412, 915),
    'short phone': Size(360, 640),
    'small tablet': Size(600, 1024),
    'landscape tablet (worst case)': Size(1024, 768),
    'very small phone': Size(320, 568),
    'huge tablet': Size(1600, 2560),
  };

  sizes.forEach((label, size) {
    testWidgets('lays out without overflow — $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(size));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'overflow/paint error at $label');
      expect(find.text('เข้าเกม'), findsOneWidget);
      expect(find.text('ฝึกซ้อม'), findsOneWidget);
    });
  });

  testWidgets('swiping the carousel advances the activity counter',
      (tester) async {
    const size = Size(800, 1280);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(size));
    await tester.pump();

    // Counter is a TextSpan pair: "กิจกรรมที่ " + "1/5".
    expect(find.textContaining('1/5', findRichText: true), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('2/5', findRichText: true), findsOneWidget);
  });
}
