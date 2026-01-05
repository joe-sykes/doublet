import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/about_dialog.dart';
import '../widgets/app_footer.dart';
import '../widgets/stats_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleAsync = ref.watch(todaysPuzzleProvider);
    final puzzleNumber = ref.watch(todaysPuzzleNumberProvider);
    final stats = ref.watch(userStatsProvider);
    final hasCompletedToday = ref.watch(hasCompletedTodayProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DAILY DOUBLET',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showAboutGameDialog(context),
            tooltip: 'How to play',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats card
              StatsCard(stats: stats),
              const SizedBox(height: 24),

              // Today's puzzle card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Puzzle #$puzzleNumber',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      puzzleAsync.when(
                        data: (puzzle) => Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _InfoChip(
                                  icon: Icons.text_fields,
                                  label: '${puzzle.wordLength} letters',
                                ),
                                const SizedBox(width: 12),
                                _InfoChip(
                                  icon: Icons.linear_scale,
                                  label: '${puzzle.stepCount} words',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '${puzzle.startWord}  →  ${puzzle.endWord}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            if (hasCompletedToday)
                              Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Completed!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.green),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () => context.push('/play'),
                                    icon: const Icon(Icons.replay),
                                    label: const Text('Play Again'),
                                  ),
                                ],
                              )
                            else
                              FilledButton.icon(
                                onPressed: () => context.push('/play'),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Play Today\'s Puzzle'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, _) => Column(
                          children: [
                            const Icon(Icons.cloud_off, size: 48),
                            const SizedBox(height: 8),
                            Text('Unable to load puzzle'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(todaysPuzzleProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Archive button
              OutlinedButton.icon(
                onPressed: () => context.push('/archive'),
                icon: const Icon(Icons.archive),
                label: const Text('Browse Archive'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}
