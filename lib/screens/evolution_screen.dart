// ─────────────────────────────────────────────────────────────────────────────
//  Evolution Screen — RPG Stat Tracker + Quest Board
//  Stats with 0–9 rollover · Quest system with difficulty-based XP · Credits
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../game_provider.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const Color kBackground = Color(0xFF0A0A0A);
const Color kAccent = Color(0xFF00E5FF);
const Color kCardBg = Color(0xFF141414);
const Color kTextDim = Color(0xFF888888);
const String kFontFamily = 'Courier';
const String kAndroidWidgetName = 'StatWidgetProvider';

// Difficulty colors
const Color kEasyColor = Color(0xFF4CAF50);
const Color kMediumColor = Color(0xFFFF9800);
const Color kHardColor = Color(0xFFFF1744);

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
      backgroundColor: kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: kAccent.withOpacity(0.3),
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
            const SizedBox(height: 12),
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
                  context.read<GameProvider>().refreshStats();
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
            backgroundColor: kCardBg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('NEW QUEST',
                style: TextStyle(
                    color: kAccent,
                    fontFamily: kFontFamily,
                    letterSpacing: 3,
                    fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: kFontFamily),
                    cursorColor: kAccent,
                    decoration: const InputDecoration(
                      hintText: 'Quest title...',
                      hintStyle: TextStyle(color: kTextDim),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kAccent)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kAccent, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Difficulty picker
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('DIFFICULTY',
                        style: TextStyle(
                            color: kTextDim,
                            fontFamily: kFontFamily,
                            fontSize: 11,
                            letterSpacing: 2)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _DifficultyChip(
                        label: 'EASY',
                        color: kEasyColor,
                        selected: difficulty == 'easy',
                        onTap: () => setSt(() => difficulty = 'easy'),
                      ),
                      const SizedBox(width: 8),
                      _DifficultyChip(
                        label: 'MED',
                        color: kMediumColor,
                        selected: difficulty == 'medium',
                        onTap: () => setSt(() => difficulty = 'medium'),
                      ),
                      const SizedBox(width: 8),
                      _DifficultyChip(
                        label: 'HARD',
                        color: kHardColor,
                        selected: difficulty == 'hard',
                        onTap: () => setSt(() => difficulty = 'hard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stat assignment
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('ASSIGN STAT',
                        style: TextStyle(
                            color: kTextDim,
                            fontFamily: kFontFamily,
                            fontSize: 11,
                            letterSpacing: 2)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kAccent.withOpacity(0.2)),
                    ),
                    child: DropdownButton<int>(
                      value: selectedStatId,
                      isExpanded: true,
                      dropdownColor: kCardBg,
                      underline: const SizedBox(),
                      hint: const Text('Select a stat...',
                          style: TextStyle(
                              color: kTextDim, fontFamily: kFontFamily)),
                      style: const TextStyle(
                          color: Colors.white, fontFamily: kFontFamily),
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
                child:
                    const Text('CANCEL', style: TextStyle(color: kTextDim)),
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
                child:
                    const Text('CREATE', style: TextStyle(color: kAccent)),
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
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : ValueListenableBuilder<List<Stat>>(
              valueListenable: _notifier,
              builder: (context, stats, _) {
                return Consumer<GameProvider>(
                  builder: (context, gp, _) {
                    return CustomScrollView(
                      slivers: [
                        // ─── Stats Section ───
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: _sectionHeader('STATS', Icons.auto_awesome),
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
                                        color: kAccent.withOpacity(0.3),
                                        size: 48),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No stats yet. Tap + to begin.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: kTextDim, fontSize: 14),
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: _sectionHeader(
                                'QUEST BOARD', Icons.flag_rounded),
                          ),
                        ),
                        if (gp.quests.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No active quests. Tap + to add one.',
                                  style: TextStyle(
                                      color: kTextDim.withOpacity(0.7),
                                      fontSize: 13,
                                      fontFamily: kFontFamily),
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
                                  // Find stat name
                                  final statName = stats
                                      .where((s) => s.id == quest.statId)
                                      .map((s) => s.name)
                                      .firstOrNull ?? '???';
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
                                            style: const TextStyle(
                                                fontFamily: kFontFamily),
                                          ),
                                          backgroundColor:
                                              kAccent.withOpacity(0.3),
                                          behavior: SnackBarBehavior.floating,
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
                        // Bottom padding
                        const SliverPadding(
                            padding: EdgeInsets.only(bottom: 80)),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'evolution_fab',
        backgroundColor: kAccent,
        onPressed: _showFabOptions,
        child: const Icon(Icons.add, color: kBackground, size: 28),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: kAccent.withOpacity(0.5), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: kAccent.withOpacity(0.7),
              fontFamily: kFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: kAccent.withOpacity(0.1),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(12),
        splashColor: kAccent.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAccent.withOpacity(0.15)),
            color: kAccent.withOpacity(0.04),
          ),
          child: Row(
            children: [
              Icon(icon, color: kAccent, size: 22),
              const SizedBox(width: 14),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : kTextDim.withOpacity(0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : kTextDim,
                fontFamily: kFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
        return kEasyColor;
      case 'medium':
        return kMediumColor;
      case 'hard':
        return kHardColor;
      default:
        return kEasyColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _diffColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: _diffColor.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          // Left: difficulty badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _diffColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '+${quest.xpReward}',
                style: TextStyle(
                  color: _diffColor,
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Middle: quest info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: kFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _diffColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        quest.difficulty.toUpperCase(),
                        style: TextStyle(
                          color: _diffColor,
                          fontFamily: kFontFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.auto_awesome,
                        color: kAccent.withOpacity(0.4), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      statName.toUpperCase(),
                      style: TextStyle(
                        color: kAccent.withOpacity(0.6),
                        fontFamily: kFontFamily,
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _diffColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _diffColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    'DONE',
                    style: TextStyle(
                      color: _diffColor,
                      fontFamily: kFontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
