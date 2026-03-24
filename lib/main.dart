// ─────────────────────────────────────────────────────────────────────────────
//  Personal OS v3.0 — Life Is Game
//  Premium Gamified Dashboard with Glassmorphism UI
//  MeshGradient background · Glass bottom nav · Orbitron + Inter fonts
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'game_provider.dart';
import 'notification_service.dart';
import 'screens/evolution_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/nucleus_screen.dart';
import 'theme/app_theme.dart';

// ─── Entry Point ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
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
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: kNeonCyan,
          secondary: kNeonCyan,
          surface: kDeepNavy,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: orbitronStyle(
            fontSize: 18,
            color: kNeonCyan,
            letterSpacing: 4,
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const AppShell(),
    );
  }
}

// ─── App Shell with Glass Bottom Navigation ──────────────────────────────────
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
    final credits = context.watch<GameProvider>().credits;

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logo/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(_titles[_currentIndex]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kGold.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: kGold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$credits',
                      style: orbitronStyle(
                        fontSize: 13,
                        color: kGold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildGlassBottomNav(),
      ),
    );
  }

  Widget _buildGlassBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: kDeepNavy.withOpacity(0.6),
            border: Border(
              top: BorderSide(color: kNeonCyan.withOpacity(0.1), width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'EVOLVE', 0),
                  _navItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'FINANCE', 1),
                  _navItem(Icons.timer_outlined, Icons.timer, 'FOCUS', 2),
                  _navItem(Icons.person_outline, Icons.person, 'NUCLEUS', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kNeonCyan.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: kNeonCyan.withOpacity(0.2))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? kNeonCyan : Colors.white.withOpacity(0.3),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: orbitronStyle(
                fontSize: 8,
                color: isSelected ? kNeonCyan : Colors.white.withOpacity(0.3),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
