import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

enum _StepKind { welcome, install, lift, done }

class _GuideStep {
  final _StepKind kind;
  final String? imagePath; // null for welcome/done and placeholder legs
  final String title;
  final String body;
  final String legLabel; // 'ขาขวา' / 'ขาซ้าย' / ''
  final int padIndex; // 1..4, or 0
  final bool isPlaceholder; // true for second-leg screens (no art yet)
  const _GuideStep({
    required this.kind,
    this.imagePath,
    required this.title,
    required this.body,
    this.legLabel = '',
    this.padIndex = 0,
    this.isPlaceholder = false,
  });
}

class HardwareGuidePage extends StatefulWidget {
  const HardwareGuidePage({super.key});

  @override
  State<HardwareGuidePage> createState() => _HardwareGuidePageState();
}

class _HardwareGuidePageState extends State<HardwareGuidePage> {
  int _step = 0;
  late final List<_GuideStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
  }

  List<_GuideStep> _buildSteps() {
    final steps = <_GuideStep>[];
    steps.add(const _GuideStep(
      kind: _StepKind.welcome,
      title: 'ติดตั้งอุปกรณ์ EMG',
      body: 'มาเริ่มติดแผ่นเซนเซอร์ EMG ทั้ง 4 จุดในแต่ละขากันก่อนเริ่มใช้งาน',
    ));

    final legs = ['ขาขวา', 'ขาซ้าย'];
    for (var li = 0; li < legs.length; li++) {
      final leg = legs[li];
      final placeholder = li == 1; // second leg = no art yet
      for (var n = 1; n <= 4; n++) {
        steps.add(_GuideStep(
          kind: _StepKind.install,
          imagePath: placeholder ? null : 'assets/images/hardware_guide/R$n-1.png',
          title: 'ติดแผ่นที่ ตำแหน่งที่ $n',
          body: 'ติดแผ่นเซนเซอร์ EMG ที่ตำแหน่งที่ $n บน$leg ตามภาพ แล้วกด "ถัดไป"',
          legLabel: leg,
          padIndex: n,
          isPlaceholder: placeholder,
        ));
        steps.add(_GuideStep(
          kind: _StepKind.lift,
          imagePath: placeholder ? null : 'assets/images/hardware_guide/R$n-2.png',
          title: 'ยกขาขึ้นค้างไว้',
          body: 'ยก$legขึ้นค้างไว้สักครู่ — แตะที่ภาพเพื่อจำลองสัญญาณ',
          legLabel: leg,
          padIndex: n,
          isPlaceholder: placeholder,
        ));
      }
    }

    steps.add(const _GuideStep(
      kind: _StepKind.done,
      title: 'ติดตั้งสำเร็จ',
      body: 'พร้อมใช้งานแล้ว!',
    ));
    return steps;
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final step = _steps[_step];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFEFF3FB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.04, w * 0.06, w * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(w, step),
                SizedBox(height: w * 0.04),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildBody(w, step),
                  ),
                ),
                SizedBox(height: w * 0.04),
                _buildBottom(w, step),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Header: back affordance + progress ----------------------------------
  Widget _buildHeader(double w, _GuideStep step) {
    final showProgress = step.kind == _StepKind.install || step.kind == _StepKind.lift;
    return Row(
      children: [
        SizedBox(
          width: w * 0.11,
          height: w * 0.11,
          child: _step == 0
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: const Color(0x22000000),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _back,
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: w * 0.05, color: KColors.navyText),
                  ),
                ),
        ),
        Expanded(
          child: showProgress
              ? _buildProgress(w, step)
              : const SizedBox.shrink(),
        ),
        SizedBox(width: w * 0.11),
      ],
    );
  }

  Widget _buildProgress(double w, _GuideStep step) {
    return Column(
      children: [
        Text(
          '${step.legLabel} · ตำแหน่ง ${step.padIndex}/4',
          textAlign: TextAlign.center,
          style: thaiSans(size: w * 0.038, weight: FontWeight.w600, color: KColors.blue),
        ),
        SizedBox(height: w * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < step.padIndex;
            final current = i == step.padIndex - 1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: w * 0.012),
              width: current ? w * 0.07 : w * 0.025,
              height: w * 0.025,
              decoration: BoxDecoration(
                gradient: filled ? KColors.blueGradient : null,
                color: filled ? null : const Color(0xFFD7DEEC),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---- Body ----------------------------------------------------------------
  Widget _buildBody(double w, _GuideStep step) {
    switch (step.kind) {
      case _StepKind.welcome:
        return _buildWelcome(w, step);
      case _StepKind.done:
        return _buildDone(w, step);
      case _StepKind.install:
      case _StepKind.lift:
        return _buildPadStep(w, step);
    }
  }

  Widget _buildWelcome(double w, _GuideStep step) {
    return Column(
      children: [
        SizedBox(height: w * 0.06),
        Container(
          width: w * 0.62,
          height: w * 0.62,
          decoration: BoxDecoration(
            gradient: KColors.blueGradient,
            borderRadius: BorderRadius.circular(w * 0.09),
            boxShadow: [
              BoxShadow(
                  color: KColors.blue.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 14)),
            ],
          ),
          padding: EdgeInsets.all(w * 0.1),
          child: Image.asset('assets/images/kinex_logo.png', fit: BoxFit.contain),
        ),
        SizedBox(height: w * 0.09),
        _title(w, step.title),
        SizedBox(height: w * 0.035),
        _bodyText(w, step.body),
      ],
    );
  }

  Widget _buildDone(double w, _GuideStep step) {
    return Column(
      children: [
        SizedBox(height: w * 0.1),
        Container(
          width: w * 0.4,
          height: w * 0.4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: KColors.tealGradient,
            boxShadow: [
              BoxShadow(color: Color(0x3311C18E), blurRadius: 30, offset: Offset(0, 14)),
            ],
          ),
          child: Icon(Icons.check_rounded, color: Colors.white, size: w * 0.24),
        ),
        SizedBox(height: w * 0.1),
        _title(w, step.title),
        SizedBox(height: w * 0.035),
        _bodyText(w, step.body),
      ],
    );
  }

  Widget _buildPadStep(double w, _GuideStep step) {
    final isLift = step.kind == _StepKind.lift;
    return Column(
      children: [
        SizedBox(height: w * 0.02),
        _buildImageCard(w, step, tappable: isLift && !step.isPlaceholder),
        SizedBox(height: w * 0.07),
        _title(w, step.title),
        SizedBox(height: w * 0.035),
        _bodyText(w, step.body),
      ],
    );
  }

  Widget _buildImageCard(double w, _GuideStep step, {required bool tappable}) {
    final radius = w * 0.075;
    final card = Container(
      width: double.infinity,
      height: w * 1.05,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: step.isPlaceholder || step.imagePath == null
          ? _placeholderArt(w, step)
          : Image.asset(step.imagePath!, fit: BoxFit.cover),
    );

    if (!tappable) return card;

    return GestureDetector(
      onTap: _next,
      child: Stack(
        children: [
          card,
          Positioned(
            left: 0,
            right: 0,
            bottom: w * 0.05,
            child: Center(child: _tapBadge(w)),
          ),
        ],
      ),
    );
  }

  Widget _tapBadge(double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.025),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(w * 0.1),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, size: w * 0.05, color: KColors.teal),
          SizedBox(width: w * 0.02),
          Text('แตะเพื่อจำลองสัญญาณ',
              style: thaiSans(size: w * 0.035, weight: FontWeight.w600, color: KColors.navyText)),
        ],
      ),
    );
  }

  Widget _placeholderArt(double w, _GuideStep step) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF1F5FC)),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(w * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: w * 0.18, color: const Color(0xFFB9C4DC)),
              SizedBox(height: w * 0.04),
              Text(
                'ภาพสำหรับ${step.legLabel} — เร็วๆ นี้',
                textAlign: TextAlign.center,
                style: thaiSans(size: w * 0.042, weight: FontWeight.w600, color: const Color(0xFF8C99B5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Bottom button -------------------------------------------------------
  Widget _buildBottom(double w, _GuideStep step) {
    // Lift screens with real art advance by tapping the image -> show hint only.
    final tapImageToAdvance = step.kind == _StepKind.lift && !step.isPlaceholder;

    if (step.kind == _StepKind.done) {
      return _primaryButton(w, 'เริ่มใช้งาน', () => context.pop());
    }

    if (tapImageToAdvance) {
      return Center(
        child: Text(
          'แตะที่ภาพเพื่อจำลองสัญญาณ',
          style: thaiSans(size: w * 0.04, weight: FontWeight.w500, color: const Color(0xFF8C99B5)),
        ),
      );
    }

    return _primaryButton(w, 'ถัดไป', _next);
  }

  Widget _primaryButton(double w, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: w * 0.15,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: KColors.blueGradient,
          borderRadius: BorderRadius.circular(w * 0.075),
          boxShadow: const [
            BoxShadow(color: Color(0x402766EF), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: thaiSans(size: w * 0.05, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ---- Shared text helpers -------------------------------------------------
  Widget _title(double w, String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: thaiSans(size: w * 0.062, weight: FontWeight.w700, color: KColors.navyText),
    );
  }

  Widget _bodyText(double w, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: thaiSans(size: w * 0.043, weight: FontWeight.w400, color: const Color(0xFF5A6685)),
      ),
    );
  }
}
