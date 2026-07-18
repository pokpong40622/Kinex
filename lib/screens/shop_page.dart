import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/kui.dart';
import '../theme/responsive.dart';
import '../state/shop_providers.dart';
import '../data/customize_catalog.dart';

// Theme/character catalog now lives in data/customize_catalog.dart (shared
// with the customize page). Ids match the entries stored in the *Provider
// sets in state/shop_providers.dart, persisted via ShopRepository.

class _GameUnlock {
  final String id;
  final String titleTh;
  final String subtitleEn;
  final IconData icon;
  final int price;
  const _GameUnlock(
      this.id, this.titleTh, this.subtitleEn, this.icon, this.price);
}

const _gameUnlock = _GameUnlock(
    'kinex_world', 'KINEX World', 'KINEX World', Icons.self_improvement_rounded, 1000);
const _gameUnlockDasher = _GameUnlock(
    'thedasher', 'THE DASHER', 'The Dasher', Icons.rocket_launch_rounded, 800);

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
                    EdgeInsets.fromLTRB(w * 0.06, h * 0.025, w * 0.06, h * 0.02),
                child: Row(
                  children: [
                    Text('ร้านค้า',
                        style: montserrat(
                            size: w * 0.09,
                            weight: FontWeight.w900,
                            color: KColors.purple)),
                    const Spacer(),
                    const _CoinPill(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04, vertical: h * 0.01),
                  children: [
                    const KSectionHeader('ปลดล็อกเกม',
                        icon: Icons.lock_open_rounded, color: KColors.purple),
                    const _GameUnlockCard(item: _gameUnlock),
                    SizedBox(height: h * 0.015),
                    const _GameUnlockCard(item: _gameUnlockDasher),
                    SizedBox(height: h * 0.03),
                    const KSectionHeader('ตัวละคร',
                        icon: Icons.person_rounded, color: KColors.purple),
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
                    const KSectionHeader('ธีมเกม',
                        icon: Icons.palette_rounded, color: KColors.purple),
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
                      color: KColors.purple, icon: Icons.check_circle_rounded)
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
            width: r(48),
            height: r(48),
            decoration:
                BoxDecoration(color: KColors.purple.withAlpha(30), shape: BoxShape.circle),
            child: Icon(item.icon, color: KColors.purple, size: r(26)),
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
              ? Icon(Icons.check_circle_rounded, color: KColors.purple, size: r(24))
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
