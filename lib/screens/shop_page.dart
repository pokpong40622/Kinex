import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/kui.dart';
import '../theme/responsive.dart';
import '../state/shop_providers.dart';
import '../state/accent_theme.dart';
import '../data/customize_catalog.dart';

// Theme/character catalog now lives in data/customize_catalog.dart (shared
// with the customize page). Ids match the entries stored in the *Provider
// sets in state/shop_providers.dart, persisted via ShopRepository.

class _GameUnlock {
  final String id;
  final String titleTh;
  final String subtitleEn;
  final String iconAsset; // logo from assets/images/game_icons/
  final IconData icon; // fallback if the asset fails to load
  final int price;
  const _GameUnlock(this.id, this.titleTh, this.subtitleEn, this.iconAsset,
      this.icon, this.price);
}

// The Dasher ships free/owned by default (see ShopState.defaults.unlockedGames)
// — its card still renders here but always shows as owned, never for sale.
const _gameUnlockDasher = _GameUnlock('thedasher', 'THE DASHER', 'The Dasher',
    'assets/images/game_icons/thedasher.png', Icons.rocket_launch_rounded, 800);
const _gameUnlock = _GameUnlock('kinex_world', 'KINEX World', 'KINEX World',
    'assets/images/game_icons/world.png', Icons.self_improvement_rounded, 1000);
const _gameUnlockHangGlider = _GameUnlock('hangglider', 'นักร่อน',
    'Hang Glider', 'assets/images/game_icons/hangglider.png', Icons.flight_rounded, 600);
const _gameUnlockQuakeEscape = _GameUnlock('quakeescape', 'QUAKE ESCAPE',
    'Quake Escape', 'assets/images/game_icons/quakeescape.png',
    Icons.warning_amber_rounded, 700);

// ── Shop tab ──────────────────────────────────────────────────────────────

class ShopTab extends ConsumerWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final r = context.r;

    return Stack(
      fit: StackFit.expand,
      children: [
        const _ShopBackground(),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    EdgeInsets.fromLTRB(w * 0.045, h * 0.02, w * 0.045, 0),
                child: const _ShopHeaderBanner(),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.045, vertical: h * 0.02),
                  children: [
                    const _SectionBanner(
                      title: 'ปลดล็อกเกม',
                      subtitle: 'ใช้เหรียญปลดล็อกโหมดเกมใหม่',
                      icon: Icons.lock_open_rounded,
                    ),
                    SizedBox(height: h * 0.015),
                    const _GameUnlockCard(item: _gameUnlockDasher),
                    SizedBox(height: h * 0.012),
                    const _GameUnlockCard(item: _gameUnlock),
                    SizedBox(height: h * 0.012),
                    const _GameUnlockCard(item: _gameUnlockHangGlider),
                    SizedBox(height: h * 0.012),
                    const _GameUnlockCard(item: _gameUnlockQuakeEscape),
                    SizedBox(height: h * 0.03),
                    const _SectionBanner(
                      title: 'ตัวละคร',
                      subtitle: 'เลือกตัวละครประจำตัวของคุณ',
                      icon: Icons.person_rounded,
                    ),
                    SizedBox(height: h * 0.015),
                    SizedBox(
                      height: r(160),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kCharacterCatalog.length,
                        separatorBuilder: (_, i) => SizedBox(width: r(12)),
                        itemBuilder: (_, i) =>
                            _CharacterCard(item: kCharacterCatalog[i]),
                      ),
                    ),
                    SizedBox(height: h * 0.03),
                    const _SectionBanner(
                      title: 'ธีมสี',
                      subtitle: 'เปลี่ยนโทนสีทั้งแอปได้ทันที — พร้อมใช้งานทุกธีม',
                      icon: Icons.color_lens_rounded,
                    ),
                    SizedBox(height: h * 0.015),
                    const _AccentThemeSection(),
                    SizedBox(height: h * 0.03),
                    const _SectionBanner(
                      title: 'ธีมเกม',
                      subtitle: 'ฉากและบรรยากาศใหม่สำหรับเกม',
                      icon: Icons.palette_rounded,
                    ),
                    SizedBox(height: h * 0.015),
                    const _ComingSoonCard(titleTh: 'ธีมเกม', subtitleEn: 'Themes'),
                    SizedBox(height: h * 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shop header banner ────────────────────────────────────────────────────
// Solid-accent header block (mirrors info_page.dart's _HeaderBanner) so the
// shop opens with the same visual weight as the info tab instead of a bare
// title row.

class _ShopHeaderBanner extends ConsumerWidget {
  const _ShopHeaderBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.fromLTRB(r(22), r(18), r(20), r(18)),
      decoration: BoxDecoration(
        gradient: KColors.accentBand,
        borderRadius: BorderRadius.circular(r(24)),
        border: Border.all(color: KColors.deepPurple.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
              color: KColors.deepPurple.withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DEV: tap the ร้านค้า title to grant +500 coins, stacks per tap.
                // Dev convenience only — remove before release.
                GestureDetector(
                  onTap: () => ref.read(coinsProvider.notifier).state += 500,
                  child: Text('ร้านค้า',
                      style: montserrat(
                          size: r(28), weight: FontWeight.w900, color: Colors.white)),
                ),
                SizedBox(height: r(4)),
                Text('ปลดล็อกเกม ตัวละคร และธีมสี',
                    style: montserrat(
                        size: r(13),
                        weight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const _CoinPill(),
        ],
      ),
    );
  }
}

// ── Section banner ────────────────────────────────────────────────────────
// Secondary, lighter treatment (pale accent-tinted fill + thin border, no
// heavy shadow) so sub-section titles read clearly below the bold gradient
// _ShopHeaderBanner instead of matching its visual weight.

class _SectionBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  const _SectionBanner({
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(14)),
      decoration: BoxDecoration(
        color: KColors.purple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(r(14)),
        border: Border.all(color: KColors.purple.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: r(36),
              height: r(36),
              decoration:
                  BoxDecoration(color: KColors.purple.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(icon, color: KColors.purple, size: r(19)),
            ),
            SizedBox(width: r(12)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        montserrat(size: r(16.5), weight: FontWeight.w800, color: KColors.deepPurple)),
                SizedBox(height: r(2)),
                Text(subtitle,
                    style: thaiSans(
                        size: r(11.5),
                        weight: FontWeight.w600,
                        color: KColors.deepPurple.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Accent colour theme selector (ธีมสี) ─────────────────────────────────────
// The main new feature: 3 tappable accent colour sets that reskin the whole
// app live via accentSetProvider (state/accent_theme.dart) + KColors.applyAccentSet
// (applied at the app root in app.dart). All 3 are always selectable — framed
// as equippable themes, no coin gate.

class _AccentThemeSection extends StatelessWidget {
  const _AccentThemeSection();

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: r(10),
      crossAxisSpacing: r(10),
      childAspectRatio: 0.85,
      children: [
        for (var i = 0; i < KColors.accentSets.length; i++) _AccentSwatchCard(index: i),
      ],
    );
  }
}

class _AccentSwatchCard extends ConsumerWidget {
  final int index;
  const _AccentSwatchCard({required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final active = ref.watch(accentSetProvider) == index;
    final set = KColors.accentSets[index];
    final name = KColors.accentSetNames[index];

    final card = KCard(
      radius: r(16),
      padding: EdgeInsets.all(r(10)),
      onTap: active
          ? null
          : () => _confirmAccentChange(context, ref, index: index, name: name, color: set[0]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: r(28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r(8)),
                gradient: LinearGradient(colors: [set[2], set[0], set[1]]),
              ),
            ),
          ),
          SizedBox(height: r(8)),
          Text(name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: thaiSans(size: r(12.5), weight: FontWeight.w700, color: KColors.navyText)),
          SizedBox(height: r(6)),
          active
              ? KPill('ใช้งานอยู่', color: set[0], icon: Icons.check_circle_rounded)
              : KPill('ปุ่มหลัก', color: set[0]),
        ],
      ),
    );

    if (!active) return card;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r(16)),
        border: Border.all(color: set[0], width: 2.5),
      ),
      child: card,
    );
  }
}

// ── Accent theme change confirmation dialog ─────────────────────────────────

void _confirmAccentChange(
  BuildContext context,
  WidgetRef ref, {
  required int index,
  required String name,
  required Color color,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('เปลี่ยนธีมสี',
          style: thaiSans(size: 18, weight: FontWeight.w700, color: KColors.navyText)),
      content: Text('เปลี่ยนเป็นธีม “$name” ไหม?',
          style: thaiSans(size: 15, color: const Color(0xFF5A6685))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('ยกเลิก', style: thaiSans(size: 15, color: KColors.navyText)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: () {
            Navigator.pop(dialogContext);
            ref.read(accentSetProvider.notifier).select(index);
          },
          child: Text('เปลี่ยน', style: thaiSans(size: 15, weight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    ),
  );
}

// ── Shop background ───────────────────────────────────────────────────────
// Calm, flat app background so the white/hairline-bordered cards read clean.

class _ShopBackground extends StatelessWidget {
  const _ShopBackground();

  @override
  Widget build(BuildContext context) {
    return Container(color: KColors.appBg);
  }
}

// ── Coin pill ─────────────────────────────────────────────────────────────

class _CoinPill extends ConsumerWidget {
  const _CoinPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider);
    return KPill(
      _formatCoins(coins),
      color: KColors.orangeDark,
      icon: Icons.monetization_on_rounded,
    );
  }
}

/// "1,250" thousands-separator formatting — one call site, no intl package needed.
String _formatCoins(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Price pill for use on a card — wraps KPill with the shop's coin semantics.
class _PriceChipLight extends StatelessWidget {
  final int price;
  const _PriceChipLight({required this.price});

  @override
  Widget build(BuildContext context) {
    return KPill('$price',
        color: KColors.orangeDark, icon: Icons.monetization_on_rounded);
  }
}

// ── Character card ────────────────────────────────────────────────────────

class _CharacterCard extends ConsumerWidget {
  final CharacterItem item;
  const _CharacterCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final unlocked = ref.watch(unlockedCharactersProvider).contains(item.id);
    final active = ref.watch(activeCharacterProvider) == item.id;

    final avatar = Image.asset(item.asset, height: r(70), fit: BoxFit.contain);

    return GestureDetector(
      onTap: () {
        if (!unlocked) {
          _confirmBuy(
            context,
            ref,
            name: item.name,
            price: item.price,
            onConfirm: () {
              ref.read(unlockedCharactersProvider.notifier).update((s) => {...s, item.id});
              ref.read(activeCharacterProvider.notifier).state = item.id;
            },
          );
        } else if (!active) {
          ref.read(activeCharacterProvider.notifier).state = item.id;
        }
      },
      child: SizedBox(
        width: r(110),
        child: KCard(
          padding: EdgeInsets.all(r(10)),
          radius: r(18),
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
                      Image.asset('assets/images/icon_padlock.png', width: r(28)),
                  ],
                ),
              ),
              SizedBox(height: r(6)),
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: thaiSans(size: r(12), weight: FontWeight.w700, color: KColors.navyText),
              ),
              SizedBox(height: r(4)),
              active
                  ? const KPill('ใช้งานอยู่',
                      icon: Icons.check_circle_rounded)
                  : (unlocked ? const SizedBox.shrink() : _PriceChipLight(price: item.price)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Game unlock card (list style, mirrors debug/game_debug_page.dart _GameCard) ──

class _GameUnlockCard extends ConsumerWidget {
  final _GameUnlock item;
  const _GameUnlockCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final unlocked = ref.watch(unlockedGamesProvider).contains(item.id);

    return KCard(
      radius: r(18),
      padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
      onTap: unlocked
          ? null
          : () => _confirmBuy(
                context,
                ref,
                name: item.titleTh,
                price: item.price,
                onConfirm: () {
                  ref
                      .read(unlockedGamesProvider.notifier)
                      .update((s) => {...s, item.id});
                },
              ),
      child: Row(
        children: [
          Container(
            width: r(52),
            height: r(52),
            // Some game-icon assets are wide title-banner art (e.g. Hang
            // Glider / Quake Escape), not square icons — BoxFit.cover was
            // center-cropping those down to an unreadable sliver of gradient.
            // BoxFit.contain always shows the whole image (a no-op for the
            // assets that already are square) and the padding + tinted plate
            // keep every icon, regardless of source aspect ratio, looking
            // like a deliberate badge instead of a stretched/cropped photo.
            padding: EdgeInsets.all(r(6)),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: KColors.purple.withAlpha(30),
              borderRadius: BorderRadius.circular(r(14)),
            ),
            child: Image.asset(
              item.iconAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) =>
                  Icon(item.icon, size: r(26), color: KColors.purple),
            ),
          ),
          SizedBox(width: r(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titleTh,
                    style: thaiSans(
                        size: r(16), weight: FontWeight.w700, color: KColors.navyText)),
                SizedBox(height: r(2)),
                Text(item.subtitleEn,
                    style: montserrat(size: r(12), weight: FontWeight.w500, color: Colors.grey)),
              ],
            ),
          ),
          unlocked
              ? Icon(Icons.check_circle_rounded, size: r(24), color: KColors.purple)
              : _PriceChipLight(price: item.price),
        ],
      ),
    );
  }
}

// ── Coming-soon (disabled) card ───────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  final String titleTh;
  final String subtitleEn;
  const _ComingSoonCard({this.titleTh = 'โหมดพิเศษ', this.subtitleEn = 'Special Mode'});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Opacity(
      opacity: 0.55,
      child: KCard(
        radius: r(18),
        padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
        child: Row(
          children: [
            Container(
              width: r(48),
              height: r(48),
              decoration: BoxDecoration(color: Colors.grey.withAlpha(60), shape: BoxShape.circle),
              child: Icon(Icons.hourglass_empty_rounded, color: Colors.grey.shade700, size: r(26)),
            ),
            SizedBox(width: r(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleTh,
                      style: thaiSans(size: r(16), weight: FontWeight.w700, color: KColors.navyText)),
                  SizedBox(height: r(2)),
                  Text(subtitleEn,
                      style: montserrat(size: r(12), weight: FontWeight.w500, color: Colors.grey)),
                ],
              ),
            ),
            Text('เร็วๆ นี้',
                style: thaiSans(size: r(13), weight: FontWeight.w700, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

// ── Buy confirmation dialog ────────────────────────────────────────────────
// Follows the same AlertDialog shape used elsewhere (e.g. onboarding/
// hardware_guide_page.dart's skip-confirm dialog); the confirm action is
// styled like WorldButton (filled, rounded, bold) since the dialog itself
// sits on a white surface rather than WorldButton's usual purple background.

void _confirmBuy(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required int price,
  required VoidCallback onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('ปลดล็อก $name?',
          style: thaiSans(size: 18, weight: FontWeight.w700, color: KColors.navyText)),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: KColors.orangeDark, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text('ใช้ $price เหรียญเพื่อปลดล็อกรายการนี้',
                style: thaiSans(size: 15, color: const Color(0xFF5A6685))),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('ยกเลิก', style: thaiSans(size: 15, color: KColors.navyText)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: KColors.purple,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: () {
            Navigator.pop(dialogContext);
            final coins = ref.read(coinsProvider);
            if (coins < price) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text('เหรียญไม่พอ', style: thaiSans(size: 14, color: Colors.white)),
                  backgroundColor: KColors.navyText,
                  behavior: SnackBarBehavior.floating,
                ));
              return;
            }
            ref.read(coinsProvider.notifier).state = coins - price;
            onConfirm();
          },
          child: Text('ยืนยัน', style: thaiSans(size: 15, weight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    ),
  );
}
