import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/customize_catalog.dart';
import '../state/shop_providers.dart';
import '../theme/app_theme.dart';
import '../theme/kui.dart';
import '../theme/responsive.dart';

/// ปรับแต่ง — profile customization: display name, equipped character and
/// theme. Only items already bought in the shop are selectable; locked items
/// are greyed with a padlock and a hint to buy them in the shop tab.
class CustomizePage extends ConsumerWidget {
  const CustomizePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: KColors.appBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              context.r(14), context.r(10), context.r(14), context.r(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CustomizeHeader(),
              SizedBox(height: context.r(16)),
              const _CharacterPreviewCard(),
              SizedBox(height: context.r(16)),
              const _NameCard(),
              SizedBox(height: context.r(16)),
              const _CharacterPickerCard(),
              SizedBox(height: context.r(16)),
              const _ThemePickerCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header (back + title) ──────────────────────────────────────────────────

class _CustomizeHeader extends StatelessWidget {
  const _CustomizeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: EdgeInsets.all(context.r(9)),
            decoration: BoxDecoration(
              color: KColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: KColors.hairline, width: 1),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: KColors.navyText, size: context.r(22)),
          ),
        ),
        SizedBox(width: context.r(12)),
        const Expanded(child: KSectionHeader('ปรับแต่งตัวละคร')),
      ],
    );
  }
}

// ─── Big preview of the active character ────────────────────────────────────

class _CharacterPreviewCard extends ConsumerWidget {
  const _CharacterPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = characterById(ref.watch(activeCharacterProvider));
    final userName = ref.watch(userNameProvider);

    return KCard(
      radius: context.r(28),
      padding: EdgeInsets.all(context.r(18)),
      child: Column(
        children: [
          Image.asset(
            character.asset,
            height: context.r(190),
            fit: BoxFit.contain,
          ),
          SizedBox(height: context.r(10)),
          Text(userName,
              style: montserrat(
                  size: context.r(20),
                  weight: FontWeight.w900,
                  color: KColors.navyText)),
          Text(character.name,
              style: thaiSans(
                  size: context.r(14),
                  weight: FontWeight.w700,
                  color: KColors.purple)),
        ],
      ),
    );
  }
}

// ─── Display-name edit ──────────────────────────────────────────────────────

class _NameCard extends ConsumerStatefulWidget {
  const _NameCard();

  @override
  ConsumerState<_NameCard> createState() => _NameCardState();
}

class _NameCardState extends ConsumerState<_NameCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(userNameProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    ref.read(userNameProvider.notifier).state = name;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('บันทึกชื่อแล้ว',
            style: thaiSans(size: 14, color: Colors.white)),
        backgroundColor: KColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return KCard(
      radius: context.r(26),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ชื่อที่แสดง',
              style: montserrat(size: context.r(17), weight: FontWeight.w900)),
          SizedBox(height: context.r(10)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 24,
                  style: thaiSans(
                      size: context.r(15), weight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'ผู้ใช้ KINEX',
                    filled: true,
                    fillColor: KColors.appBg,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: context.r(14), vertical: context.r(12)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.r(14)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ),
              SizedBox(width: context.r(10)),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KColors.purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                      horizontal: context.r(18), vertical: context.r(13)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(14))),
                ),
                child: Text('บันทึก',
                    style: thaiSans(
                        size: context.r(14),
                        weight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Character picker ───────────────────────────────────────────────────────

class _CharacterPickerCard extends ConsumerWidget {
  const _CharacterPickerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedCharactersProvider);
    final active = ref.watch(activeCharacterProvider);

    return _PickerCard(
      title: 'ตัวละคร',
      hint: 'ตัวละครที่ล็อกอยู่ ซื้อได้ในร้านค้า',
      child: SizedBox(
        height: context.r(160),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kCharacterCatalog.length,
          separatorBuilder: (_, i) => SizedBox(width: context.r(12)),
          itemBuilder: (_, i) {
            final item = kCharacterCatalog[i];
            return _CharacterPickTile(
              item: item,
              unlocked: unlocked.contains(item.id),
              active: active == item.id,
              onTap: () {
                if (unlocked.contains(item.id)) {
                  ref.read(activeCharacterProvider.notifier).state = item.id;
                } else {
                  _lockedHint(context, item.name);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

/// Same visual language as the shop's _CharacterCard (white card, grey-scaled
/// avatar + padlock when locked, "ใช้งานอยู่" badge when equipped).
class _CharacterPickTile extends StatelessWidget {
  final CharacterItem item;
  final bool unlocked;
  final bool active;
  final VoidCallback onTap;
  const _CharacterPickTile({
    required this.item,
    required this.unlocked,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final avatar = Image.asset(item.asset, height: r(70), fit: BoxFit.contain);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: r(110),
        padding: EdgeInsets.all(r(10)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r(18)),
          border: Border.all(
            color: active ? KColors.purple : Colors.transparent,
            width: r(2.5),
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: r(70),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  unlocked
                      ? avatar
                      : ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0, 0, 0, 1, 0, //
                          ]),
                          child: Opacity(opacity: 0.6, child: avatar),
                        ),
                  if (!unlocked)
                    Image.asset('assets/images/icon_padlock.png',
                        width: r(28)),
                ],
              ),
            ),
            SizedBox(height: r(6)),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: thaiSans(
                  size: r(12),
                  weight: FontWeight.w700,
                  color: KColors.navyText),
            ),
            SizedBox(height: r(4)),
            _statusBadge(context, active: active, unlocked: unlocked),
          ],
        ),
      ),
    );
  }
}

// ─── Theme picker ───────────────────────────────────────────────────────────

class _ThemePickerCard extends ConsumerWidget {
  const _ThemePickerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedThemesProvider);
    final active = ref.watch(activeThemeProvider);

    return _PickerCard(
      title: 'ธีมเกม',
      hint: 'ธีมที่ล็อกอยู่ ซื้อได้ในร้านค้า',
      child: SizedBox(
        height: context.r(150),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kThemeCatalog.length,
          separatorBuilder: (_, i) => SizedBox(width: context.r(12)),
          itemBuilder: (_, i) {
            final item = kThemeCatalog[i];
            final isUnlocked = unlocked.contains(item.id);
            final isActive = active == item.id;
            return GestureDetector(
              onTap: () {
                if (isUnlocked) {
                  ref.read(activeThemeProvider.notifier).state = item.id;
                } else {
                  _lockedHint(context, item.title.replaceAll('\n', ' '));
                }
              },
              child: Container(
                width: context.r(130),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(context.r(20)),
                  border: Border.all(
                    color: isActive ? KColors.purple : Colors.transparent,
                    width: context.r(2.5),
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(context.r(10)),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(item.title,
                            style: thaiSans(
                                size: context.r(13),
                                weight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                    if (!isUnlocked)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withAlpha(90),
                          alignment: Alignment.center,
                          child: Image.asset('assets/images/icon_padlock.png',
                              width: context.r(34)),
                        ),
                      ),
                    Positioned(
                      top: context.r(8),
                      right: context.r(8),
                      child: _statusBadge(context,
                          active: isActive, unlocked: isUnlocked),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Shared picker-card shell + small helpers ───────────────────────────────

class _PickerCard extends StatelessWidget {
  final String title;
  final String hint;
  final Widget child;
  const _PickerCard(
      {required this.title, required this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return KCard(
      radius: context.r(26),
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: montserrat(size: context.r(17), weight: FontWeight.w900)),
          SizedBox(height: context.r(2)),
          Text(hint,
              style: thaiSans(
                  size: context.r(12),
                  weight: FontWeight.w500,
                  color: KColors.navyText.withAlpha(140))),
          SizedBox(height: context.r(10)),
          child,
        ],
      ),
    );
  }
}

Widget _statusBadge(BuildContext context,
    {required bool active, required bool unlocked}) {
  if (active) {
    return const KPill('ใช้งานอยู่',
        color: KColors.purple, icon: Icons.check_circle_rounded);
  }
  if (!unlocked) {
    return const KPill('ล็อก',
        color: KColors.navyText, icon: Icons.lock_rounded);
  }
  return SizedBox(height: context.r(19));
}

void _lockedHint(BuildContext context, String name) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$name ยังไม่ปลดล็อก — ซื้อได้ที่แท็บร้านค้า',
          style: thaiSans(size: 14, color: Colors.white)),
      backgroundColor: KColors.navyText,
      behavior: SnackBarBehavior.floating,
    ));
}
