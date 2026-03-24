// ─────────────────────────────────────────────────────────────────────────────
//  Focus Screen — Pomodoro Focus Chrono + Daily Reminders
//  Glassmorphism cards · Neon glow ring · Orbitron/Inter · 8pt grid
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../game_provider.dart';
import '../notification_service.dart';
import '../theme/app_theme.dart';

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
            backgroundColor: glassDialogBg,
            shape: glassDialogShape,
            title: Column(
              children: [
                Text('⚡ FOCUS COMPLETE',
                    style: orbitronStyle(fontSize: 16, letterSpacing: 3)),
                const SizedBox(height: 8),
                Text('Pick a stat to receive +2 XP Focus Bonus',
                    textAlign: TextAlign.center,
                    style: interStyle(color: kDimText, fontSize: 12)),
              ],
            ),
            content: Container(
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
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _timerController!.reset();
                },
                child: Text('SKIP',
                    style: interStyle(color: kDimText, fontSize: 12)),
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
                            content: Text(
                              '⚡ Focus Bonus applied! +2 XP · +20 Credits',
                              style: interStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                            backgroundColor: kNeonCyan.withOpacity(0.2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ));
                        }
                      },
                child: Text('CLAIM',
                    style: orbitronStyle(
                        fontSize: 12,
                        color: selectedStatId == null
                            ? kDimText.withOpacity(0.4)
                            : kNeonCyan)),
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
          backgroundColor: glassDialogBg,
          shape: glassDialogShape,
          title: Text(
              existing != null ? 'EDIT REMINDER' : 'NEW REMINDER',
              style: orbitronStyle(fontSize: 16, letterSpacing: 3)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              style: interStyle(color: Colors.white),
              cursorColor: kNeonCyan,
              decoration: glassInputDecoration(hintText: 'Reminder name...'),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                final p = await showTimePicker(
                    context: context,
                    initialTime: time,
                    builder: (c, child) => Theme(
                        data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: kNeonCyan, surface: kCharcoal)),
                        child: child!));
                if (p != null) setSt(() => time = p);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                    color: kNeonCyan.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: kNeonCyan.withOpacity(0.2))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time,
                          color: kNeonCyan.withOpacity(0.7), size: 20),
                      const SizedBox(width: 12),
                      Text(time.format(context),
                          style: orbitronStyle(
                              fontSize: 22,
                              color: kNeonCyan)),
                    ]),
              ),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('CANCEL',
                    style: interStyle(color: kDimText, fontSize: 12))),
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
              child: Text('SAVE', style: orbitronStyle(fontSize: 12, color: kNeonCyan)),
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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SectionHeader(title: 'FOCUS CHRONO', icon: Icons.timer),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTimerSection(),
          ),
          // ── Reminders Section ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: SectionHeader(
                  title: 'DAILY REMINDERS',
                  icon: Icons.notifications_active),
            ),
          ),
          if (_loadingReminders)
            const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child:
                    CircularProgressIndicator(color: kNeonCyan, strokeWidth: 2),
              )),
            )
          else if (_reminders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No reminders. Tap + to add one.',
                    style: interStyle(
                        color: kDimText.withOpacity(0.7), fontSize: 13),
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
                              color: kHardRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24)),
                          child: Icon(Icons.delete_outline,
                              color: kHardRed)),
                      onDismissed: (_) => _deleteReminder(r),
                      child: GestureDetector(
                        onTap: () =>
                            _showAddReminderDialog(existing: r),
                        child: GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          borderColor: r.enabled ? kNeonCyan : Colors.white,
                          borderOpacity: r.enabled ? 0.15 : 0.05,
                          extraShadows: r.enabled
                              ? [
                                  BoxShadow(
                                      color: kNeonCyan.withOpacity(0.06),
                                      blurRadius: 16,
                                      spreadRadius: 1)
                                ]
                              : null,
                          child: Row(children: [
                            Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                    color: kNeonCyan.withOpacity(
                                        r.enabled ? 0.1 : 0.03),
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                child: Icon(Icons.flag_rounded,
                                    color: r.enabled
                                        ? kNeonCyan
                                        : kDimText.withOpacity(0.4),
                                    size: 22)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(r.title.toUpperCase(),
                                      style: interStyle(
                                          color: r.enabled
                                              ? Colors.white
                                              : kDimText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.5)),
                                  const SizedBox(height: 4),
                                  Text(r.timeString,
                                      style: orbitronStyle(
                                          fontSize: 18,
                                          color: r.enabled
                                              ? kNeonCyan
                                              : kDimText
                                                  .withOpacity(0.5))),
                                ])),
                            Switch(
                                value: r.enabled,
                                activeColor: kNeonCyan,
                                inactiveTrackColor:
                                    Colors.white.withOpacity(0.08),
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
      floatingActionButton: GlassFAB(
        heroTag: 'focus_fab',
        onPressed: () => _showAddReminderDialog(),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        borderColor: kNeonCyan,
        borderOpacity: 0.15,
        extraShadows: [
          BoxShadow(
            color: kNeonCyan.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
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
                      glowColor: kNeonCyan,
                    ),
                    child: Center(
                      child: Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: orbitronStyle(
                          fontSize: 36,
                          color: kNeonCyan,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Timer controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isTimerRunning)
                  _TimerButton(
                    label: 'START',
                    color: kNeonCyan,
                    onTap: _startTimer,
                  )
                else
                  _TimerButton(
                    label: 'CANCEL',
                    color: kHardRed,
                    onTap: _cancelTimer,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isTimerRunning
                  ? 'Focus session in progress...'
                  : '25 MIN DEEP FOCUS',
              style: interStyle(
                color: kDimText.withOpacity(0.6),
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            color: color.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            label,
            style: orbitronStyle(
              fontSize: 14,
              color: color,
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
      ..strokeWidth = strokeWidth + 10
      ..strokeCap = StrokeCap.round
      ..color = glowColor.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
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
