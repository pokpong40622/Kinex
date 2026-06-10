import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large numeric entry for elderly users: a big value display, a range hint,
/// and an oversized 0–9 keypad. Reports the parsed value via [onChanged]
/// (null when empty or outside [min]–[max]).
class BigNumberPad extends StatefulWidget {
  final String unit;
  final double min;
  final double max;
  final bool allowDecimal;
  final double? initial;
  final ValueChanged<double?> onChanged;

  const BigNumberPad({
    super.key,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.allowDecimal = false,
    this.initial,
  });

  @override
  State<BigNumberPad> createState() => _BigNumberPadState();
}

class _BigNumberPadState extends State<BigNumberPad> {
  late String _text = widget.initial == null
      ? ''
      : (widget.allowDecimal
          ? widget.initial.toString()
          : widget.initial!.toInt().toString());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  double? get _value {
    final v = double.tryParse(_text);
    if (v == null) return null;
    if (v < widget.min || v > widget.max) return null;
    return v;
  }

  void _notify() => widget.onChanged(_value);

  void _tap(String key) {
    setState(() {
      if (key == '⌫') {
        if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1);
      } else if (key == '.') {
        if (widget.allowDecimal && !_text.contains('.') && _text.isNotEmpty) {
          _text += '.';
        }
      } else {
        if (_text.length < 6) _text += key;
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final v = double.tryParse(_text);
    final outOfRange =
        v != null && (v < widget.min || v > widget.max);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(_text.isEmpty ? '0' : _text,
                style: thaiSans(
                    size: 64,
                    weight: FontWeight.w800,
                    color: _text.isEmpty
                        ? KColors.navyText.withAlpha(60)
                        : KColors.navyText)),
            const SizedBox(width: 8),
            Text(widget.unit,
                style: thaiSans(
                    size: 24,
                    weight: FontWeight.w700,
                    color: KColors.navyText.withAlpha(150))),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          outOfRange
              ? 'กรุณากรอกค่าระหว่าง ${_fmt(widget.min)}–${_fmt(widget.max)}'
              : 'ค่าที่ยอมรับ ${_fmt(widget.min)}–${_fmt(widget.max)} ${widget.unit}',
          style: thaiSans(
              size: 14,
              weight: FontWeight.w600,
              color: outOfRange ? const Color(0xFFD32F2F) : KColors.navyText.withAlpha(140)),
        ),
        const SizedBox(height: 16),
        // Keypad
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          _row(row),
        _row(['.', '0', '⌫']),
      ],
    );
  }

  Widget _row(List<String> keys) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: keys.map((k) {
            final disabled = k == '.' && !widget.allowDecimal;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _Key(label: disabled ? '' : k, onTap: disabled ? null : () => _tap(k)),
              ),
            );
          }).toList(),
        ),
      );

  static String _fmt(double d) =>
      d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap == null
              ? null
              : const [
                  BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
        ),
        child: label == '⌫'
            ? const Icon(Icons.backspace_outlined, color: KColors.navyText)
            : Text(label,
                style: thaiSans(size: 28, weight: FontWeight.w700)),
      ),
    );
  }
}
