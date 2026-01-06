import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../core/utils/date_utils.dart';
import '../models/puzzle.dart';
import '../providers/providers.dart';
import '../widgets/about_dialog.dart';
import '../widgets/word_input_tile.dart';

class GameScreen extends ConsumerStatefulWidget {
  final bool isDaily;
  final int? puzzleIndex;

  const GameScreen({
    super.key,
    required this.isDaily,
    this.puzzleIndex,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _endWordKey = GlobalKey();
  bool _isSubmitting = false;
  String? _errorMessage;

  int get _effectiveIndex =>
      widget.puzzleIndex ?? ref.read(todaysPuzzleIndexProvider);

  @override
  void initState() {
    super.initState();
    // Load puzzle and start game after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    final puzzleAsync = await ref.read(puzzleProvider(_effectiveIndex).future);
    _setupControllers(puzzleAsync.inputCount);

    ref.read(gameStateProvider.notifier).startGame(
          puzzleAsync,
          widget.isDaily,
        );
  }

  void _setupControllers(int count) {
    // Clear existing
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();

    // Create new
    for (int i = 0; i < count; i++) {
      _controllers.add(TextEditingController());
      final focusNode = FocusNode();
      focusNode.addListener(_onFocusChange);
      _focusNodes.add(focusNode);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    // When any field gets focus, scroll to ensure end word is visible
    final hasFocus = _focusNodes.any((node) => node.hasFocus);
    if (hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToShowEndWord();
      });
    }
  }

  void _scrollToShowEndWord() {
    if (_endWordKey.currentContext != null && _scrollController.hasClients) {
      // Small delay to let keyboard fully appear
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _onWordChanged(int index, String value, Puzzle puzzle) {
    ref.read(gameStateProvider.notifier).setWord(index, value);

    // Auto-advance to next field when word is complete
    if (value.length == puzzle.wordLength && index < _controllers.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _submitSolution(Puzzle puzzle) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final gameNotifier = ref.read(gameStateProvider.notifier);
    final result = await gameNotifier.submitSolution(puzzle);

    setState(() => _isSubmitting = false);

    if (result.isCorrect) {
      if (mounted) {
        context.go('/results');
      }
    } else {
      setState(() => _errorMessage = result.reason);

      // Haptic feedback for error
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _giveUp(Puzzle puzzle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Give up?'),
        content: const Text(
          'You will see the solution but your streak will not increase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Give Up'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(gameStateProvider.notifier).giveUp(puzzle);
      if (mounted) {
        context.go('/results');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzleAsync = ref.watch(puzzleProvider(_effectiveIndex));
    final gameState = ref.watch(gameStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Get puzzle date
    final puzzleDate = widget.isDaily
        ? DateTime.now().toUtc()
        : PuzzleDateUtils.getFirstReleaseDateForPuzzle(_effectiveIndex);
    final dateStr = DateFormat('MMMM d, yyyy').format(puzzleDate);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'DAILY DOUBLET',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(gameStateProvider.notifier).clearGame();
            context.go('/');
          },
        ),
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
      body: puzzleAsync.when(
        data: (puzzle) => _buildGameContent(puzzle, gameState, dateStr),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Failed to load puzzle'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(puzzleProvider(_effectiveIndex)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent(Puzzle puzzle, gameState, String dateStr) {
    if (_controllers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final validator = ref.read(gameValidatorProvider);
    final puzzleNumber = widget.isDaily
        ? PuzzleDateUtils.getTodaysPuzzleNumber()
        : _effectiveIndex + 1;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Puzzle date header
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        'Puzzle #$puzzleNumber',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Start word (fixed)
                      _WordDisplay(
                        word: puzzle.startWord,
                        isFixed: true,
                        label: 'Start',
                      ),
                      const SizedBox(height: 6),

                      // Input fields
                      ...List.generate(puzzle.inputCount, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: WordInputTile(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            wordLength: puzzle.wordLength,
                            onChanged: (value) =>
                                _onWordChanged(index, value, puzzle),
                            onSubmitted: () {
                              if (index < _controllers.length - 1) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                _submitSolution(puzzle);
                              }
                            },
                            validator: validator,
                            stepNumber: index + 2,
                          ),
                        );
                      }),

                      const SizedBox(height: 6),

                      // End word (fixed)
                      _WordDisplay(
                        key: _endWordKey,
                        word: puzzle.endWord,
                        isFixed: true,
                        label: 'End',
                      ),

                      // Error message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color:
                                      Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Extra padding at bottom to ensure end word is visible above keyboard
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => _giveUp(puzzle),
                      child: const Text('Give Up'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : () => _submitSolution(puzzle),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordDisplay extends StatelessWidget {
  final String word;
  final bool isFixed;
  final String label;

  const _WordDisplay({
    super.key,
    required this.word,
    required this.isFixed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Text(
            word,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the label
        ],
      ),
    );
  }
}
