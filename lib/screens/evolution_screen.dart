// ─────────────────────────────────────────────────────────────────────────────
//  Evolution Screen — RPG Stat Tracker + Quest Board
//  Glassmorphism cards · Glow XP bars · Orbitron/Inter fonts · 8pt grid
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../game_provider.dart';
import '../theme/app_theme.dart';

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

  void _showFabOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: glassDialogBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kNeonCyan.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _OptionTile(
              icon: Icons.auto_awesome,
              label: 'ADD NEW STAT',
              onTap: () {
                Navigator.pop(ctx);
                _showAddStatDialog();
              },
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.flag_rounded,
              label: 'ADD NEW QUEST',
              onTap: () {
                Navigator.pop(ctx);
                _showAddQuestDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStatDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: glassDialogBg,
        shape: glassDialogShape,
        title: Text('NEW STAT', style: orbitronStyle(fontSize: 16, letterSpacing: 3)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: interStyle(color: Colors.white),
          cursorColor: kNeonCyan,
          decoration: glassInputDecoration(hintText: 'Stat name...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: interStyle(color: kDimText, fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _notifier.addStat(name).then((_) {
                  context.read<GameProvider>().refreshStats();
                  if (mounted) setState(() {});
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('CREATE', style: orbitronStyle(fontSize: 12, color: kNeonCyan)),
          ),
        ],
      ),
    );
  }

  void _showAddQuestDialog() {
    final titleCtrl = TextEditingController();
    String difficulty = 'easy';
    int? selectedStatId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) {
          final stats = _notifier.value;
          return AlertDialog(
            backgroundColor: glassDialogBg,
            shape: glassDialogShape,
            title: Text('NEW QUEST',
                style: orbitronStyle(fontSize: 16, letterSpacing: 3)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: interStyle(color: Colors.white),
                    cursorColor: kNeonCyan,
                    decoration: glassInputDecoration(hintText: 'Quest title...'),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('DIFFICULTY',
                        style: orbitronStyle(
                            fontSize: 10,
                            color: kDimText,
                            letterSpacing: 2)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _DifficultyChip(
                        label: 'EASY',
                        color: kEasyGreen,
                        selected: difficulty == 'easy',
                        onTap: () => setSt(() => difficulty = 'easy'),
                      ),
                      const SizedBox(width: 8),
                      _DifficultyChip(
                        label: 'MED',
                        color: kMediumOrange,
                        selected: difficulty == 'medium',
                        onTap: () => setSt(() => difficulty = 'medium'),
                      ),
                      const SizedBox(width: 8),
                      _DifficultyChip(
                        label: 'HARD',
                        color: kHardRed,
                        selected: difficulty == 'hard',
                        onTap: () => setSt(() => difficulty = 'hard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('ASSIGN STAT',
                        style: orbitronStyle(
                            fontSize: 10,
                            color: kDimText,
                            letterSpacing: 2)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kNeonCyan.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kNeonCyan.withOpacity(0.15)),
                    ),
                    child: DropdownButton<int>(
                      value: selectedStatId,
                      isExpanded: true,
                      dropdownColor: glassDialogBg,
                      underline: const SizedBox(),
                      hint: Text('Select a stat...',
                          style: interStyle(color: kDimText, fontSize: 14)),
                      style: interStyle(color: Colors.white),
                      items: stats
                          .map((s) => DropdownMenuItem<int>(
                                value: s.id,
                                child: Text(s.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (v) => setSt(() => selectedStatId = v),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('CANCEL', style: interStyle(color: kDimText, fontSize: 12)),
              ),
              TextButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty || selectedStatId == null) return;
                  context.read<GameProvider>().addQuest(
                        title: title,
                        difficulty: difficulty,
                        statId: selectedStatId!,
                      );
                  Navigator.pop(ctx);
                },
                child: Text('CREATE', style: orbitronStyle(fontSize: 12, color: kNeonCyan)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: kNeonCyan,
                strokeWidth: 2,
              ),
            )
          : ValueListenableBuilder<List<Stat>>(
              valueListenable: _notifier,
              builder: (context, stats, _) {
                return Consumer<GameProvider>(
                  builder: (context, gp, _) {
                    return CustomScrollView(
                      slivers: [
                        // ─── Stats Section ───
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: const SliverToBoxAdapter(
                            child: SectionHeader(
                                title: 'STATS', icon: Icons.auto_awesome),
                          ),
                        ),
                        if (stats.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        color: kNeonCyan.withOpacity(0.3),
                                        size: 48),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No stats yet. Tap + to begin.',
                                      textAlign: TextAlign.center,
                                      style: interStyle(
                                          color: kDimText, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _StatCard(
                                  stat: stats[index],
                                  onIncrement: () {
                                    _notifier
                                        .increment(stats[index].id!)
                                        .then((_) {
                                      gp.refreshStats();
                                      gp.refreshCredits();
                                      if (mounted) setState(() {});
                                    });
                                  },
                                  onDecrement: () {
                                    _notifier
                                        .decrement(stats[index].id!)
                                        .then((_) {
                                      if (mounted) setState(() {});
                                    });
                                  },
                                  onDelete: () {
                                    _notifier
                                        .removeStat(stats[index].id!)
                                        .then((_) {
                                      gp.refreshStats();
                                      if (mounted) setState(() {});
                                    });
                                  },
                                ),
                                childCount: stats.length,
                              ),
                            ),
                          ),
                        // ─── Quest Board Section ───
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                          sliver: const SliverToBoxAdapter(
                            child: SectionHeader(
                                title: 'QUEST BOARD',
                                icon: Icons.flag_rounded),
                          ),
                        ),
                        if (gp.quests.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No active quests. Tap + to add one.',
                                  style: interStyle(
                                      color: kDimText.withOpacity(0.7),
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final quest = gp.quests[index];
                                  final statName = stats
                                      .where((s) => s.id == quest.statId)
                                      .map((s) => s.name)
                                      .firstOrNull ??
                                      '???';
                                  return _QuestCard(
                                    quest: quest,
                                    statName: statName,
                                    onComplete: () async {
                                      final xp =
                                          await gp.completeQuest(quest.id!);
                                      _notifier.loadStats();
                                      if (mounted) {
                                        setState(() {});
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                            '⚔️ Quest complete! +$xp XP to $statName · +${xp * 10} Credits',
                                            style: interStyle(
                                                color: Colors.white,
                                                fontSize: 13),
                                          ),
                                          backgroundColor:
                                              kNeonCyan.withOpacity(0.2),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                        ));
                                      }
                                    },
                                    onDelete: () {
                                      gp.deleteQuest(quest.id!);
                                    },
                                  );
                                },
                                childCount: gp.quests.length,
                              ),
                            ),
                          ),
                        const SliverPadding(
                            padding: EdgeInsets.only(bottom: 80)),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: GlassFAB(
        heroTag: 'evolution_fab',
        onPressed: _showFabOptions,
      ),
    );
  }
}

// ─── Option Tile for Bottom Sheet ────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: kNeonCyan.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kNeonCyan.withOpacity(0.15)),
            color: kNeonCyan.withOpacity(0.04),
          ),
          child: Row(
            children: [
              Icon(icon, color: kNeonCyan, size: 22),
              const SizedBox(width: 16),
              Text(label,
                  style: orbitronStyle(
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Difficulty Chip ─────────────────────────────────────────────────────────
class _DifficultyChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : kDimText.withOpacity(0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: orbitronStyle(
                fontSize: 10,
                color: selected ? color : kDimText,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quest Card Widget ───────────────────────────────────────────────────────
class _QuestCard extends StatelessWidget {
  final Quest quest;
  final String statName;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _QuestCard({
    required this.quest,
    required this.statName,
    required this.onComplete,
    required this.onDelete,
  });

  Color get _diffColor {
    switch (quest.difficulty) {
      case 'easy':
        return kEasyGreen;
      case 'medium':
        return kMediumOrange;
      case 'hard':
        return kHardRed;
      default:
        return kEasyGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: _diffColor,
      borderOpacity: 0.2,
      child: Row(
        children: [
          // Left: XP badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _diffColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _diffColor.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                '+${quest.xpReward}',
                style: orbitronStyle(
                  fontSize: 14,
                  color: _diffColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Middle: quest info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title.toUpperCase(),
                  style: interStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _diffColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quest.difficulty.toUpperCase(),
                        style: orbitronStyle(
                          fontSize: 8,
                          color: _diffColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.auto_awesome,
                        color: kNeonCyan.withOpacity(0.4), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statName.toUpperCase(),
                      style: interStyle(
                        color: kNeonCyan.withOpacity(0.6),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right: actions
          Column(
            children: [
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close,
                    color: Colors.white.withOpacity(0.2), size: 16),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _diffColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _diffColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    'DONE',
                    style: orbitronStyle(
                      fontSize: 9,
                      color: _diffColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      borderColor: kNeonCyan,
      borderOpacity: 0.15,
      extraShadows: [
        BoxShadow(
          color: kNeonCyan.withOpacity(0.06),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.name.toUpperCase(),
                  style: orbitronStyle(
                    fontSize: 14,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kNeonCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kNeonCyan.withOpacity(0.25)),
                ),
                child: Text(
                  'LVL ${stat.level}',
                  style: orbitronStyle(
                    fontSize: 11,
                    color: kNeonCyan,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close,
                    color: Colors.white.withOpacity(0.2), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Animated Glow XP Bar ──
          GlowProgressBar(
            value: stat.value / 10.0,
            color: kNeonCyan,
            glowColor: kNeonCyan,
            height: 10,
            borderRadius: 5,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${stat.value} / 10',
              style: interStyle(
                color: kNeonCyan.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(16),
        splashColor: kNeonCyan.withOpacity(0.2),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kNeonCyan.withOpacity(0.2)),
            color: kNeonCyan.withOpacity(0.05),
          ),
          child: Icon(icon, color: kNeonCyan, size: 28),
        ),
      ),
    );
  }
}
