import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/utils/web_utils.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/results_screen.dart';

const String kAppTitle = 'Daily Doublet - Word Ladder Puzzle';

/// Maximum content width for better readability on wide screens
const double kMaxContentWidth = 600.0;

/// App router configuration
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/play',
      builder: (context, state) => const GameScreen(isDaily: true),
    ),
    GoRoute(
      path: '/play/:puzzleIndex',
      builder: (context, state) {
        final indexStr = state.pathParameters['puzzleIndex']!;
        final index = int.parse(indexStr);
        return GameScreen(isDaily: false, puzzleIndex: index);
      },
    ),
    GoRoute(
      path: '/archive',
      builder: (context, state) => const ArchiveScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
  ],
);

/// Main application widget
class DoubletApp extends ConsumerStatefulWidget {
  const DoubletApp({super.key});

  @override
  ConsumerState<DoubletApp> createState() => _DoubletAppState();
}

class _DoubletAppState extends ConsumerState<DoubletApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await initializeServices(ref);
      setPageTitle(kAppTitle);
      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    final textTheme = GoogleFonts.robotoSlabTextTheme();

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    // Set page title on every build to ensure it stays correct
    setPageTitle(kAppTitle);

    return MaterialApp.router(
      title: kAppTitle,
      onGenerateTitle: (_) => kAppTitle,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: lightColorScheme.surface,
        textTheme: textTheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: darkColorScheme.surface,
        textTheme: textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      routerConfig: _router,
      builder: (context, child) {
        if (_error != null) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to initialize app',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _initialized = false;
                          });
                          _initialize();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (!_initialized) {
          return MaterialApp(
            theme: Theme.of(context),
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            ),
          );
        }

        return child!;
      },
    );
  }
}
