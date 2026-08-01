import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// 6-digit code gate in front of the (placeholder) EMG detail page. Any 6 digits
/// open it for now — the destination is intentionally blank. Premium dark look:
/// glowing lock, animated dots, frosted keypad.
class EmgPinPage extends StatefulWidget {
  const EmgPinPage({super.key});

  @override
  State<EmgPinPage> createState() => _EmgPinPageState();
}

class _EmgPinPageState extends State<EmgPinPage> {
  String _code = '';

  void _tap(String k) {
    if (_code.length >= 6) return;
    setState(() => _code += k);
    if (_code.length == 6) {
      // Any 6 digits unlock it (placeholder destination).
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) context.pushReplacement('/emg/detail');
      });
    }
  }

  void _back() {
    if (_code.isNotEmpty) {
      setState(() => _code = _code.substring(0, _code.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF241646), Color(0xFF0E1630)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              SizedBox(height: w * 0.03),
              Container(
                width: w * 0.21,
                height: w * 0.21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: KColors.blueGradient,
                  boxShadow: [
                    BoxShadow(
                        color: KColors.blue.withAlpha(140),
                        blurRadius: 30,
                        spreadRadius: 2),
                  ],
                ),
                child: Icon(Icons.lock_rounded, color: Colors.white, size: w * 0.10),
              ),
              SizedBox(height: w * 0.06),
              Text('ใส่รหัส 6 หลัก',
                  style: thaiSans(
                      size: w * 0.062,
                      weight: FontWeight.w800,
                      color: Colors.white)),
              SizedBox(height: w * 0.015),
              Text('กรอกรหัสเพื่อเข้าสู่ข้อมูล EMG เชิงลึก',
                  textAlign: TextAlign.center,
                  style: thaiSans(
                      size: w * 0.032,
                      weight: FontWeight.w500,
                      color: Colors.white.withAlpha(160))),
              SizedBox(height: w * 0.09),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _code.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.symmetric(horizontal: w * 0.022),
                    width: w * 0.042,
                    height: w * 0.042,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.white : Colors.transparent,
                      border: Border.all(
                          color: Colors.white.withAlpha(filled ? 255 : 90),
                          width: 2),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                  color: Colors.white.withAlpha(130),
                                  blurRadius: 10)
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.11),
                child: Column(
                  children: [
                    for (final row in const [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['', '0', '⌫'],
                    ])
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: w * 0.014),
                        child: Row(
                          children: row
                              .map((k) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: w * 0.03),
                                      child: _key(k, w),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: w * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _key(String k, double w) {
    if (k.isEmpty) return SizedBox(height: w * 0.16);
    return GestureDetector(
      onTap: () => k == '⌫' ? _back() : _tap(k),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: w * 0.16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(38)),
        ),
        child: k == '⌫'
            ? Icon(Icons.backspace_outlined, color: Colors.white, size: w * 0.06)
            : Text(k,
                style: thaiSans(
                    size: w * 0.072,
                    weight: FontWeight.w700,
                    color: Colors.white)),
      ),
    );
  }
}
