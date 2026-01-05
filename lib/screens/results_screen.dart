import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/date_utils.dart';
import '../core/utils/scoring_utils.dart';
import '../providers/providers.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final stats = ref.watch(userStatsProvider);

    if (gameState == null) {
      // No game state, redirect to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final puzzleAsync = ref.watch(puzzleProvider(gameState.puzzleIndex));
    final wasSuccessful = gameState.wasSuccessful;
    final score = gameState.finalScore ?? 0;
    final breakdown = ScoringUtils.getBreakdown(
      timeTaken: gameState.elapsedTime,
      incorrectSubmissions: gameState.incorrectSubmissions,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Result icon
              Icon(
                wasSuccessful ? Icons.celebration : Icons.sentiment_dissatisfied,
                size: 80,
                color: wasSuccessful ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 16),

              // Result text
              Text(
                wasSuccessful ? 'Congratulations!' : 'Better luck next time!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),

              // Score card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$score',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(score),
                            ),
                      ),
                      Text(
                        'out of 100',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Breakdown
                      _BreakdownRow(
                        label: 'Base score',
                        value: '+${breakdown.baseScore}',
                        color: Colors.green,
                      ),
                      if (breakdown.timePenalty > 0)
                        _BreakdownRow(
                          label: 'Time penalty (${breakdown.formattedTime})',
                          value: '-${breakdown.timePenalty}',
                          color: Colors.red,
                        ),
                      if (breakdown.accuracyPenalty > 0)
                        _BreakdownRow(
                          label:
                              'Mistakes (${breakdown.incorrectSubmissions})',
                          value: '-${breakdown.accuracyPenalty}',
                          color: Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Streak card (only for daily)
              if (gameState.isDailyPuzzle)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          icon: Icons.local_fire_department,
                          value: '${stats.currentStreak}',
                          label: 'Current Streak',
                          color: Colors.orange,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Theme.of(context).dividerColor,
                        ),
                        _StatItem(
                          icon: Icons.emoji_events,
                          value: '${stats.longestStreak}',
                          label: 'Best Streak',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Solution reveal (if failed)
              if (!wasSuccessful)
                puzzleAsync.when(
                  data: (puzzle) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solution',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ...puzzle.ladder.map((word) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  word,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        letterSpacing: 4,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              const SizedBox(height: 24),

              // Share button
              OutlinedButton.icon(
                onPressed: () => _shareResult(context, gameState, score),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              const SizedBox(height: 16),

              // Home button
              FilledButton.icon(
                onPressed: () {
                  ref.read(gameStateProvider.notifier).clearGame();
                  context.go('/');
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  void _shareResult(BuildContext context, gameState, int score) {
    final puzzleNumber = gameState.isDailyPuzzle
        ? PuzzleDateUtils.getTodaysPuzzleNumber()
        : gameState.puzzleIndex + 1;

    // Dynamic emoji based on score
    final String scoreEmoji;
    final String message;
    if (!gameState.wasSuccessful) {
      scoreEmoji = '😢';
      message = 'I gave up...';
    } else if (score == 100) {
      scoreEmoji = '🏆✨';
      message = 'PERFECT SCORE!';
    } else if (score >= 90) {
      scoreEmoji = '🔥🔥🔥';
      message = 'On fire!';
    } else if (score >= 80) {
      scoreEmoji = '⭐⭐';
      message = 'Great job!';
    } else if (score >= 60) {
      scoreEmoji = '👍';
      message = 'Not bad!';
    } else if (score >= 40) {
      scoreEmoji = '😅';
      message = 'Room for improvement';
    } else {
      scoreEmoji = '🐢';
      message = 'Slow and steady...';
    }

    // Create score bar visualization
    final filledBlocks = (score / 10).round();
    final scoreBar = '🟩' * filledBlocks + '⬜' * (10 - filledBlocks);

    final text = '''
Daily Doublet #$puzzleNumber $scoreEmoji

$message

$scoreBar $score/100

https://doublet-a7665.web.app
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
