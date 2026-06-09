import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.music_note, size: 36, color: Colors.deepPurple),
                title: const Text('MEGA DANCE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Rhythm-based dance rehab'),
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
                subtitle: Text('Lateral balance training'),
                trailing: Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.people, size: 36, color: Colors.grey),
                title: Text('KINEX WORLD',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Multiplayer duel mode'),
                trailing: Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
