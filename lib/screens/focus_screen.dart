// ─────────────────────────────────────────────────────────────────────────────
//  Focus Screen — Pomodoro Focus Chrono + Daily Reminders
//  Glowing neon cyan countdown ring · +2 XP focus bonus on completion
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../game_provider.dart';
import '../notification_service.dart';

const Color _kBg = Color(0xFF0A0A0A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kCardBg = Color(0xFF141414);
const Color _kTextDim = Color(0xFF888888);
const String _kFont = 'Courier';

const int _kFocusDurationSeconds = 25 * 60; // 25 minutes

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  // ── Reminders state ──
  List<Reminder> _reminders = [];
  bool _loadingReminders = true;

  // ── Timer state ──
  AnimationController? _timerController;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _initTimerController();
  }

  void _initTimerController() {
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _kFocusDurationSeconds),
    );
    _timerController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isTimerRunning = false);
        _showFocusCompleteDialog();
      }
    });
  }

  @override
  void dispose() {
    _timerController?.dispose();
    super.dispose();
  }

  // ── Timer controls ──

  void _startTimer() {
    _timerController!.forward(from: _timerController!.value);
    setState(() => _isTimerRunning = true);
  }

  void _cancelTimer() {
    _timerController!.stop();
    _timerController!.reset();
    setState(() => _isTimerRunning = false);
  }

  void _showFocusCompleteDialog() {
    final gp = context.read<GameProvider>();
    final stats = gp.stats;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int? selectedStatId;
        return StatefulBuilder(
          builder: (context, setSt) => AlertDialog(
            backgroundColor: _kCardBg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Column(
              children: [
                Text('⚡ FOCUS COMPLETE',
                    style: TextStyle(
                        color: _kAccent,
                        fontFamily: _kFont,
                        letterSpacing: 3,
                        fontSize: 18)),
                SizedBox(height: 8),
                Text('Pick a stat to receive +2 XP Focus Bonus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _kTextDim,
                        fontFamily: _kFont,
                        fontSize: 12)),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kAccent.withOpacity(0.2)),
              ),
              child: DropdownButton<int>(
                value: selectedStatId,
                isExpanded: true,
                dropdownColor: _kCardBg,
                underline: const SizedBox(),
                hint: const Text('Select a stat...',
                    style:
                        TextStyle(color: _kTextDim, fontFamily: _kFont)),
                style: const TextStyle(
                    color: Colors.white, fontFamily: _kFont),
                items: stats
                    .map((s) => DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(s.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setSt(() => selectedStatId = v),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _timerController!.reset();
                },
                child: const Text('SKIP',
                    style: TextStyle(color: _kTextDim)),
              ),
              TextButton(
                onPressed: selectedStatId == null
                    ? null
                    : () {
                        gp.applyFocusBonus(selectedStatId!);
                        Navigator.pop(ctx);
                        _timerController!.reset();
                        if (mounted) {
                          ScaffoldMessenger.of(this.context)
                              .showSnackBar(SnackBar(
                            content: const Text(
                              '⚡ Focus Bonus applied! +2 XP · +20 Credits',
                              style: TextStyle(fontFamily: _kFont),
                            ),
                            backgroundColor: _kAccent.withOpacity(0.3),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                child: Text('CLAIM',
                    style: TextStyle(
                        color: selectedStatId == null
                            ? _kTextDim.withOpacity(0.4)
                            : _kAccent)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Reminders ──

  Future<void> _loadReminders() async {
    final reminders = await DatabaseHelper.instance.getReminders();
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _loadingReminders = false;
      });
    }
  }

  Future<void> _requestPerms() async {
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.requestExactAlarmPermission();
  }

  void _showAddReminderDialog({Reminder? existing}) {
    final ctrl = TextEditingController(text: existing?.title ?? '');
    TimeOfDay time = existing != null
        ? TimeOfDay(hour: existing.hour, minute: existing.minute)
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          backgroundColor: _kCardBg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(existing != null ? 'EDIT REMINDER' : 'NEW REMINDER',
              style: const TextStyle(
                  color: _kAccent,
                  fontFamily: _kFont,
                  letterSpacing: 3,
                  fontSize: 18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(
                  color: Colors.white, fontFamily: _kFont),
              cursorColor: _kAccent,
              decoration: const InputDecoration(
                hintText: 'Reminder name...',
                hintStyle: TextStyle(color: _kTextDim),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final p = await showTimePicker(
                    context: context,
                    initialTime: time,
                    builder: (c, child) => Theme(
                        data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: _kAccent, surface: _kCardBg)),
                        child: child!));
                if (p != null) setSt(() => time = p);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _kAccent.withOpacity(0.3))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time,
                          color: _kAccent, size: 20),
                      const SizedBox(width: 10),
                      Text(time.format(context),
                          style: const TextStyle(
                              color: _kAccent,
                              fontFamily: _kFont,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ]),
              ),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL',
                    style: TextStyle(color: _kTextDim))),
            TextButton(
              onPressed: () async {
                final title = ctrl.text.trim();
                if (title.isEmpty) return;
                await _requestPerms();
                if (existing != null) {
                  existing.title = title;
                  existing.hour = time.hour;
                  existing.minute = time.minute;
                  existing.enabled = true;
                  await DatabaseHelper.instance.updateReminder(existing);
                  await NotificationService.instance
                      .cancelReminder(existing.id!);
                  await NotificationService.instance.scheduleDailyReminder(
                      id: existing.id!,
                      title: title,
                      hour: time.hour,
                      minute: time.minute);
                } else {
                  final id = await DatabaseHelper.instance.insertReminder(
                      Reminder(
                          title: title,
                          hour: time.hour,
                          minute: time.minute));
                  await NotificationService.instance.scheduleDailyReminder(
                      id: id,
                      title: title,
                      hour: time.hour,
                      minute: time.minute);
                }
                if (mounted) Navigator.pop(ctx);
                _loadReminders();
              },
              child: const Text('SAVE', style: TextStyle(color: _kAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReminder(Reminder r) async {
    r.enabled = !r.enabled;
    await DatabaseHelper.instance.updateReminder(r);
    if (r.enabled) {
      await _requestPerms();
      await NotificationService.instance.scheduleDailyReminder(
          id: r.id!, title: r.title, hour: r.hour, minute: r.minute);
    } else {
      await NotificationService.instance.cancelReminder(r.id!);
    }
    _loadReminders();
  }

  Future<void> _deleteReminder(Reminder r) async {
    await NotificationService.instance.cancelReminder(r.id!);
    await DatabaseHelper.instance.deleteReminder(r.id!);
    _loadReminders();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── Focus Chrono Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _sectionHeader('FOCUS CHRONO', Icons.timer),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTimerSection(),
          ),
          // ── Reminders Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _sectionHeader(
                  'DAILY REMINDERS', Icons.notifications_active),
            ),
          ),
          if (_loadingReminders)
            const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: _kAccent),
              )),
            )
          else if (_reminders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No reminders. Tap + to add one.',
                    style: TextStyle(
                        color: _kTextDim.withOpacity(0.7),
                        fontSize: 13,
                        fontFamily: _kFont),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final r = _reminders[index];
                    return Dismissible(
                      key: Key('reminder_${r.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.red)),
                      onDismissed: (_) => _deleteReminder(r),
                      child: GestureDetector(
                        onTap: () =>
                            _showAddReminderDialog(existing: r),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: r.enabled
                                      ? _kAccent.withOpacity(0.15)
                                      : Colors.white.withOpacity(0.05)),
                              boxShadow: r.enabled
                                  ? [
                                      BoxShadow(
                                          color:
                                              _kAccent.withOpacity(0.06),
                                          blurRadius: 12,
                                          spreadRadius: 1)
                                    ]
                                  : null),
                          child: Row(children: [
                            Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: _kAccent.withOpacity(
                                        r.enabled ? 0.1 : 0.03),
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                child: Icon(Icons.flag_rounded,
                                    color: r.enabled
                                        ? _kAccent
                                        : _kTextDim.withOpacity(0.4),
                                    size: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(r.title.toUpperCase(),
                                      style: TextStyle(
                                          color: r.enabled
                                              ? Colors.white
                                              : _kTextDim,
                                          fontFamily: _kFont,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5)),
                                  const SizedBox(height: 4),
                                  Text(r.timeString,
                                      style: TextStyle(
                                          color: r.enabled
                                              ? _kAccent
                                              : _kTextDim
                                                  .withOpacity(0.5),
                                          fontFamily: _kFont,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ])),
                            Switch(
                                value: r.enabled,
                                activeColor: _kAccent,
                                inactiveTrackColor:
                                    Colors.white.withOpacity(0.1),
                                onChanged: (_) =>
                                    _toggleReminder(r)),
                          ]),
                        ),
                      ),
                    );
                  },
                  childCount: _reminders.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'focus_fab',
        backgroundColor: _kAccent,
        onPressed: () => _showAddReminderDialog(),
        child: const Icon(Icons.add, color: _kBg, size: 28),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kAccent.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Circular timer
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _timerController!,
                builder: (context, child) {
                  final elapsed = _timerController!.value;
                  final remaining =
                      ((1.0 - elapsed) * _kFocusDurationSeconds).ceil();
                  final minutes = remaining ~/ 60;
                  final seconds = remaining % 60;

                  return CustomPaint(
                    painter: _TimerRingPainter(
                      progress: 1.0 - elapsed,
                      glowColor: _kAccent,
                    ),
                    child: Center(
                      child: Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: _kAccent,
                          fontFamily: _kFont,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Timer controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isTimerRunning)
                  _TimerButton(
                    label: 'START',
                    color: _kAccent,
                    onTap: _startTimer,
                  )
                else
                  _TimerButton(
                    label: 'CANCEL',
                    color: const Color(0xFFFF1744),
                    onTap: _cancelTimer,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isTimerRunning
                  ? 'Focus session in progress...'
                  : '25 MIN DEEP FOCUS',
              style: TextStyle(
                color: _kTextDim.withOpacity(0.6),
                fontFamily: _kFont,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _kAccent.withOpacity(0.5), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: _kAccent.withOpacity(0.7),
              fontFamily: _kFont,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: _kAccent.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timer Button ────────────────────────────────────────────────────────────
class _TimerButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TimerButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            color: color.withOpacity(0.1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontFamily: _kFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Circular Progress Ring Painter with Neon Glow ───────────────────────────
class _TimerRingPainter extends CustomPainter {
  final double progress; // 1.0 = full, 0.0 = empty
  final Color glowColor;

  _TimerRingPainter({required this.progress, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;
    const strokeWidth = 6.0;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withOpacity(0.06);
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = glowColor;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..color = glowColor.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
