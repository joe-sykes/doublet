import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../providers/providers.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releasedIndices = PuzzleDateUtils.getReleasedPuzzleIndices();
    final storage = ref.watch(storageServiceProvider);
    final todayIndex = ref.watch(todaysPuzzleIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Archive'),
      ),
      body: releasedIndices.isEmpty
          ? const Center(
              child: Text('No puzzles available yet'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: releasedIndices.length,
              itemBuilder: (context, index) {
                // Show most recent first
                final puzzleIndex =
                    releasedIndices[releasedIndices.length - 1 - index];
                final releaseDate =
                    PuzzleDateUtils.getFirstReleaseDateForPuzzle(puzzleIndex);
                final puzzleNumber = puzzleIndex + 1;
                final isToday = puzzleIndex == todayIndex;

                // Check if played
                final result = storage.getResultForPuzzle(puzzleIndex);
                final wasPlayed = result != null;
                final wasSuccessful = result?.wasSuccessful ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isToday
                          ? Theme.of(context).colorScheme.primary
                          : wasSuccessful
                              ? Colors.green
                              : wasPlayed
                                  ? Colors.orange
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: isToday
                          ? Icon(
                              Icons.today,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : wasPlayed
                              ? Icon(
                                  wasSuccessful ? Icons.check : Icons.close,
                                  color: Colors.white,
                                )
                              : Text(
                                  '$puzzleNumber',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                    ),
                    title: Text(
                      'Puzzle #$puzzleNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isToday
                          ? 'Today'
                          : DateFormat('MMMM d, yyyy').format(releaseDate),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (wasPlayed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${result!.score}/100',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      if (isToday) {
                        context.push('/play');
                      } else {
                        context.push('/play/$puzzleIndex');
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
