// ─────────────────────────────────────────────────────────────────────────────
//  Focus Screen — Daily Quest Reminders with timed notifications
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../notification_service.dart';

const Color _kBg = Color(0xFF0A0A0A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kCardBg = Color(0xFF141414);
const Color _kTextDim = Color(0xFF888888);
const String _kFont = 'Courier';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  List<Reminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await DatabaseHelper.instance.getReminders();
    if (mounted) setState(() { _reminders = reminders; _loading = false; });
  }

  Future<void> _requestPerms() async {
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.requestExactAlarmPermission();
  }

  void _showAddDialog({Reminder? existing}) {
    final ctrl = TextEditingController(text: existing?.title ?? '');
    TimeOfDay time = existing != null
        ? TimeOfDay(hour: existing.hour, minute: existing.minute)
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          backgroundColor: _kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing != null ? 'EDIT QUEST' : 'NEW QUEST',
              style: const TextStyle(color: _kAccent, fontFamily: _kFont, letterSpacing: 3, fontSize: 18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl, autofocus: true,
              style: const TextStyle(color: Colors.white, fontFamily: _kFont),
              cursorColor: _kAccent,
              decoration: const InputDecoration(
                hintText: 'Quest name...', hintStyle: TextStyle(color: _kTextDim),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _kAccent)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _kAccent, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final p = await showTimePicker(context: context, initialTime: time,
                  builder: (c, child) => Theme(data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: _kAccent, surface: _kCardBg)), child: child!));
                if (p != null) setSt(() => time = p);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: _kAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kAccent.withOpacity(0.3))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.access_time, color: _kAccent, size: 20), const SizedBox(width: 10),
                  Text(time.format(context), style: const TextStyle(color: _kAccent, fontFamily: _kFont, fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: _kTextDim))),
            TextButton(
              onPressed: () async {
                final title = ctrl.text.trim();
                if (title.isEmpty) return;
                await _requestPerms();
                if (existing != null) {
                  existing.title = title; existing.hour = time.hour; existing.minute = time.minute; existing.enabled = true;
                  await DatabaseHelper.instance.updateReminder(existing);
                  await NotificationService.instance.cancelReminder(existing.id!);
                  await NotificationService.instance.scheduleDailyReminder(id: existing.id!, title: title, hour: time.hour, minute: time.minute);
                } else {
                  final id = await DatabaseHelper.instance.insertReminder(
                      Reminder(title: title, hour: time.hour, minute: time.minute));
                  await NotificationService.instance.scheduleDailyReminder(id: id, title: title, hour: time.hour, minute: time.minute);
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

  Future<void> _toggle(Reminder r) async {
    r.enabled = !r.enabled;
    await DatabaseHelper.instance.updateReminder(r);
    if (r.enabled) {
      await _requestPerms();
      await NotificationService.instance.scheduleDailyReminder(id: r.id!, title: r.title, hour: r.hour, minute: r.minute);
    } else {
      await NotificationService.instance.cancelReminder(r.id!);
    }
    _loadReminders();
  }

  Future<void> _delete(Reminder r) async {
    await NotificationService.instance.cancelReminder(r.id!);
    await DatabaseHelper.instance.deleteReminder(r.id!);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kAccent));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _reminders.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_none_rounded, color: _kAccent.withOpacity(0.3), size: 64),
              const SizedBox(height: 16),
              const Text('No quests scheduled.\nTap + to set a reminder.', textAlign: TextAlign.center, style: TextStyle(color: _kTextDim, fontSize: 16)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final r = _reminders[index];
                return Dismissible(
                  key: Key('reminder_${r.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.delete_outline, color: Colors.red)),
                  onDismissed: (_) => _delete(r),
                  child: GestureDetector(
                    onTap: () => _showAddDialog(existing: r),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: r.enabled ? _kAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05)),
                          boxShadow: r.enabled ? [BoxShadow(color: _kAccent.withOpacity(0.06), blurRadius: 12, spreadRadius: 1)] : null),
                      child: Row(children: [
                        Container(width: 44, height: 44,
                            decoration: BoxDecoration(color: _kAccent.withOpacity(r.enabled ? 0.1 : 0.03), borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.flag_rounded, color: r.enabled ? _kAccent : _kTextDim.withOpacity(0.4), size: 22)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.title.toUpperCase(), style: TextStyle(color: r.enabled ? Colors.white : _kTextDim, fontFamily: _kFont, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(r.timeString, style: TextStyle(color: r.enabled ? _kAccent : _kTextDim.withOpacity(0.5), fontFamily: _kFont, fontSize: 20, fontWeight: FontWeight.bold)),
                        ])),
                        Switch(value: r.enabled, activeColor: _kAccent, inactiveTrackColor: Colors.white.withOpacity(0.1), onChanged: (_) => _toggle(r)),
                      ]),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(heroTag: 'focus_fab', backgroundColor: _kAccent,
          onPressed: () => _showAddDialog(), child: const Icon(Icons.add, color: _kBg, size: 28)),
    );
  }
}
