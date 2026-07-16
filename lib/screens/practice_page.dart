import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ฝึกซ้อม')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Assessment shortcut — purple (the app's main colour, matching the info-page
            // heading) with a warm orange icon badge + chevron so it reads lively, not flat.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                  shadowColor: KColors.deepPurple.withValues(alpha: 0.4),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: KColors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.assignment_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('แบบประเมิน',
                        style: thaiSans(
                            size: 16,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Flagship game — hero card, deliberately bigger than the list below.
            Material(
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.go('/dance-star'),
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2B1B54), Color(0xFF6C2BD9)],
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/game_icons/dancestar.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFFFD155), size: 22),
                                const SizedBox(width: 4),
                                Text('เกมแนะนำ',
                                    style: TextStyle(
                                        color: Colors.amber.shade200,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Text('เวทีซุปตาร์',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const Text('เต้นตามโค้ชบนเวทีคอนเสิร์ต',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.music_note, size: 36, color: Colors.deepPurple),
                title: const Text('MEGA DANCE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('ฟื้นฟูด้วยการเต้นตามจังหวะ'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => context.go('/mega-dance'),
              ),
            ),
            const SizedBox(height: 12),
            // The Dasher (Unity scene id stays "astrostance") — hero card using the
            // provided pre-designed card graphic, same tap structure as the DanceStar card.
            Material(
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/the-dasher-intro'),
                child: Ink(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/the_dasher/card.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.air, size: 36, color: Colors.grey),
                title: Text('HangGlider',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ฝึกการทรงตัวด้านข้าง'),
                trailing: Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.people, size: 36, color: Colors.grey),
                title: Text('KINEX WORLD',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('โหมดดวลหลายผู้เล่น'),
                trailing: Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
