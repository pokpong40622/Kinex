import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InfoPage extends ConsumerWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Info')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _StatCard(label: 'Sessions Completed', value: '0'),
          SizedBox(height: 12),
          _StatCard(label: 'Average Pose Score', value: '—'),
          SizedBox(height: 12),
          _StatCard(label: 'EMG Sensor', value: 'Not connected'),
          SizedBox(height: 12),
          _StatCard(label: 'Total Time', value: '0 min'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ],
        ),
      ),
    );
  }
}
