import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/assessment_session.dart';
import '../../models/person_info.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../theme/kui.dart';
import '../../widgets/assessment_button.dart';
import '../../widgets/assessment_scaffold.dart';

/// First intake screen: collects the person's name (optional), age and
/// gender before the height/weight/BMI and movement tests.
class PersonInfoPage extends ConsumerStatefulWidget {
  const PersonInfoPage({super.key});

  @override
  ConsumerState<PersonInfoPage> createState() => _PersonInfoPageState();
}

class _PersonInfoPageState extends ConsumerState<PersonInfoPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    // Prefill from the saved profile seeded into the session (returning users).
    final person = ref.read(assessmentSessionProvider).person;
    if (person != null) {
      if (person.name != null) _nameController.text = person.name!;
      _ageController.text = person.age.toString();
      _gender = person.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  int? get _age => int.tryParse(_ageController.text.trim());

  bool get _isValid {
    final age = _age;
    return age != null && age > 0 && _gender != null;
  }

  void _submit() {
    final age = _age;
    final gender = _gender;
    if (age == null || gender == null) return;

    final name = _nameController.text.trim();
    ref.read(assessmentSessionProvider.notifier).setPerson(
          PersonInfo(name: name.isEmpty ? null : name, age: age, gender: gender),
        );
    context.push('/assessment/height');
  }

  @override
  Widget build(BuildContext context) {
    return AssessmentScaffold(
      title: 'ข้อมูลผู้รับการประเมิน',
      stepIndex: 0,
      stepCount: 4,
      body: Padding(
        padding: EdgeInsets.fromLTRB(context.r(20), context.r(4), context.r(20), context.r(8)),
        child: ListView(
          children: [
            // Name + age are typed fields — grouped into one card so the form
            // reads as a single unit rather than loose floating inputs.
            KCard(
              padding: EdgeInsets.all(context.r(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ชื่อ (ไม่บังคับ)',
                      style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
                  SizedBox(height: context.r(8)),
                  _TextField(
                    controller: _nameController,
                    hint: 'กรอกชื่อ',
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: context.r(20)),
                  Text('อายุ (ปี)', style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
                  SizedBox(height: context.r(8)),
                  _TextField(
                    controller: _ageController,
                    hint: 'กรอกอายุ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.r(24)),
            // Gender is a big visual choice, kept outside the card so the two
            // tap targets stay full-width and unmistakably separate.
            Text('เพศ', style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
            SizedBox(height: context.r(10)),
            Row(
              children: [
                Expanded(
                  child: _GenderButton(
                    label: Gender.male.thaiLabel,
                    icon: Icons.male_rounded,
                    selected: _gender == Gender.male,
                    onTap: () => setState(() => _gender = Gender.male),
                  ),
                ),
                SizedBox(width: context.r(16)),
                Expanded(
                  child: _GenderButton(
                    label: Gender.female.thaiLabel,
                    icon: Icons.female_rounded,
                    selected: _gender == Gender.female,
                    onTap: () => setState(() => _gender = Gender.female),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottom: AssessmentButton(
        label: 'ถัดไป',
        onTap: _isValid ? _submit : null,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String> onChanged;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KColors.hairline, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: thaiSans(size: context.r(18), weight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: thaiSans(
              size: context.r(18),
              weight: FontWeight.w500,
              color: KColors.navyText.withAlpha(120)),
          contentPadding:
              EdgeInsets.symmetric(horizontal: context.r(20), vertical: context.r(18)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.r(24)),
        decoration: BoxDecoration(
          color: selected ? KColors.teal.withAlpha(28) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? KColors.teal : KColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: context.r(36),
                color: selected ? KColors.tealDark : KColors.navyText.withAlpha(160)),
            SizedBox(height: context.r(8)),
            Text(label,
                style: thaiSans(
                    size: context.r(18),
                    weight: FontWeight.w800,
                    color: selected ? KColors.tealDark : KColors.navyText)),
          ],
        ),
      ),
    );
  }
}
