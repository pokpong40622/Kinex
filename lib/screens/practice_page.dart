import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
