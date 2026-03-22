// ─────────────────────────────────────────────────────────────────────────────
//  Personal OS v2.0 — Life Is Game
//  App shell: BottomNavigationBar + IndexedStack (state-preserving tabs)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
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
  runApp(const LifeIsGameApp());
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
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
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
              icon: Icon(Icons.notifications_none_rounded),
              activeIcon: Icon(Icons.notifications_active),
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
