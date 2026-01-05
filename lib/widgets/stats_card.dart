import 'package:flutter/material.dart';

import '../models/user_stats.dart';

class StatsCard extends StatelessWidget {
  final UserStats stats;

  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Your Stats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  icon: Icons.local_fire_department,
                  value: '${stats.currentStreak}',
                  label: 'Streak',
                  color: Colors.orange,
                ),
                _StatItem(
                  icon: Icons.emoji_events,
                  value: '${stats.longestStreak}',
                  label: 'Best',
                  color: Colors.amber,
                ),
                _StatItem(
                  icon: Icons.games,
                  value: '${stats.totalGamesPlayed}',
                  label: 'Played',
                  color: Colors.blue,
                ),
                _StatItem(
                  icon: Icons.percent,
                  value: '${stats.winPercentage.toStringAsFixed(0)}%',
                  label: 'Win Rate',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
