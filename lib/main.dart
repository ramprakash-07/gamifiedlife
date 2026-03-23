// ─────────────────────────────────────────────────────────────────────────────
//  Personal OS v3.0 — Life Is Game
//  App shell: Provider + BottomNavigationBar + IndexedStack
//  Stat decay runs on startup
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'game_provider.dart';
import 'notification_service.dart';
import 'screens/evolution_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/nucleus_screen.dart';

// ─── Theme Constants ─────────────────────────────────────────────────────────
const Color kBackground = Color(0xFF0A0A0A);
const Color kAccent = Color(0xFF00E5FF);
const Color kCardBg = Color(0xFF141414);
const String kFontFamily = 'Courier';

// ─── Entry Point ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  // Apply stat decay on every app launch (deducts 1 XP if 48h+ since update)
  await DatabaseHelper.instance.applyStatDecay();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider()..loadAll(),
      child: const LifeIsGameApp(),
    ),
  );
}

class LifeIsGameApp extends StatelessWidget {
  const LifeIsGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Is Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackground,
        fontFamily: kFontFamily,
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          secondary: kAccent,
          surface: kCardBg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kAccent,
            letterSpacing: 4,
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

// ─── App Shell with BottomNavigationBar ──────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _titles = ['EVOLUTION', 'FINANCE', 'FOCUS', 'NUCLEUS'];

  final List<Widget> _screens = const [
    EvolutionScreen(),
    FinanceScreen(),
    FocusScreen(),
    NucleusScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Credits badge in the app bar
    final credits = context.watch<GameProvider>().credits;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 4),
                Text(
                  '$credits',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: kAccent.withOpacity(0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: kBackground,
          selectedItemColor: kAccent,
          unselectedItemColor: Colors.white.withOpacity(0.3),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(
            fontFamily: kFontFamily,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: kFontFamily,
            letterSpacing: 1,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'EVOLVE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'FINANCE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'FOCUS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'NUCLEUS',
            ),
          ],
        ),
      ),
    );
  }
}
