// ─────────────────────────────────────────────────────────────────────────────
//  Evolution Screen — RPG Stat Tracker (migrated from original HomePage)
//  Cyberpunk theme · 0–9 XP rollover · Android widget bridge
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../database_helper.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const Color kBackground = Color(0xFF0A0A0A);
const Color kAccent = Color(0xFF00E5FF);
const Color kCardBg = Color(0xFF141414);
const Color kTextDim = Color(0xFF888888);
const String kFontFamily = 'Courier';
const String kAndroidWidgetName = 'StatWidgetProvider';

// ─── State Notifier ──────────────────────────────────────────────────────────
class StatNotifier extends ValueNotifier<List<Stat>> {
  StatNotifier() : super([]);

  Future<void> loadStats() async {
    value = await DatabaseHelper.instance.getStats();
    notifyListeners();
  }

  Future<void> increment(int id) async {
    final idx = value.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final stat = value[idx];

    stat.value++;
    if (stat.value >= 10) {
      stat.value = 0;
      stat.level++;
    }

    await DatabaseHelper.instance.updateStat(stat);
    notifyListeners();
    await _pushWidget();
  }

  Future<void> decrement(int id) async {
    final idx = value.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final stat = value[idx];

    stat.value--;
    if (stat.value < 0) {
      if (stat.level > 0) {
        stat.level--;
        stat.value = 9;
      } else {
        stat.value = 0;
      }
    }

    await DatabaseHelper.instance.updateStat(stat);
    notifyListeners();
    await _pushWidget();
  }

  Future<void> addStat(String name) async {
    final newStat = Stat(name: name);
    final id = await DatabaseHelper.instance.insertStat(newStat);
    value.add(Stat(id: id, name: name));
    notifyListeners();
    await _pushWidget();
  }

  Future<void> removeStat(int id) async {
    await DatabaseHelper.instance.deleteStat(id);
    value.removeWhere((s) => s.id == id);
    notifyListeners();
    await _pushWidget();
  }

  Future<void> _pushWidget() async {
    await _updateWidget(value);
  }
}

// ─── Widget Bridge ───────────────────────────────────────────────────────────
Future<void> _updateWidget(List<Stat> stats) async {
  final sorted = List<Stat>.from(stats)
    ..sort(
        (a, b) => (b.level * 10 + b.value).compareTo(a.level * 10 + a.value));
  final top = sorted.take(3).toList();

  for (var i = 0; i < 3; i++) {
    if (i < top.length) {
      await HomeWidget.saveWidgetData<String>('stat_name_$i', top[i].name);
      await HomeWidget.saveWidgetData<int>('stat_value_$i', top[i].value);
      await HomeWidget.saveWidgetData<int>('stat_level_$i', top[i].level);
    } else {
      await HomeWidget.saveWidgetData<String>('stat_name_$i', '---');
      await HomeWidget.saveWidgetData<int>('stat_value_$i', 0);
      await HomeWidget.saveWidgetData<int>('stat_level_$i', 0);
    }
  }

  try {
    await HomeWidget.updateWidget(
      name: kAndroidWidgetName,
      androidName: kAndroidWidgetName,
    );
  } catch (_) {}
}

// ─── Evolution Screen ────────────────────────────────────────────────────────
class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  final StatNotifier _notifier = StatNotifier();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _notifier.loadStats();
    if (mounted) setState(() => _loading = false);

    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        _notifier.loadStats().then((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text('NEW STAT',
            style: TextStyle(
                color: kAccent,
                fontFamily: kFontFamily,
                letterSpacing: 3)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: kFontFamily),
          cursorColor: kAccent,
          decoration: const InputDecoration(
            hintText: 'Stat name...',
            hintStyle: TextStyle(color: kTextDim),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kAccent)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kAccent, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: kTextDim)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _notifier.addStat(name).then((_) {
                  if (mounted) setState(() {});
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('CREATE', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : ValueListenableBuilder<List<Stat>>(
              valueListenable: _notifier,
              builder: (context, stats, _) {
                if (stats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: kAccent.withOpacity(0.3), size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No stats yet.\nTap + to begin your journey.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kTextDim, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: stats.length,
                  itemBuilder: (context, index) => _StatCard(
                    stat: stats[index],
                    onIncrement: () =>
                        _notifier.increment(stats[index].id!).then((_) {
                      if (mounted) setState(() {});
                    }),
                    onDecrement: () =>
                        _notifier.decrement(stats[index].id!).then((_) {
                      if (mounted) setState(() {});
                    }),
                    onDelete: () =>
                        _notifier.removeStat(stats[index].id!).then((_) {
                      if (mounted) setState(() {});
                    }),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'evolution_fab',
        backgroundColor: kAccent,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: kBackground, size: 28),
      ),
    );
  }
}

// ─── Stat Card Widget ────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final Stat stat;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const _StatCard({
    required this.stat,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAccent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: kAccent.withOpacity(0.06),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: kFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kAccent.withOpacity(0.3)),
                ),
                child: Text(
                  'LVL ${stat.level}',
                  style: const TextStyle(
                    color: kAccent,
                    fontFamily: kFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close,
                    color: Colors.white.withOpacity(0.25), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: kAccent.withOpacity(0.25),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stat.value / 10.0,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${stat.value} / 10',
              style: TextStyle(
                color: kAccent.withOpacity(0.6),
                fontFamily: kFontFamily,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(icon: Icons.remove, onTap: onDecrement),
              const SizedBox(width: 24),
              _ActionButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Action Button ──────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: kAccent.withOpacity(0.2),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAccent.withOpacity(0.3)),
            color: kAccent.withOpacity(0.06),
          ),
          child: Icon(icon, color: kAccent, size: 28),
        ),
      ),
    );
  }
}
