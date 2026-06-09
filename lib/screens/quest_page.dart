import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestPage extends ConsumerWidget {
  const QuestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quests')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text('Quest ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Complete 5 MEGA DANCE sessions'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (i + 1) * 0.3,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 4),
                  Text('${((i + 1) * 30).toStringAsFixed(0)}% complete',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
