// ─────────────────────────────────────────────────────────────────────────────
//  DatabaseHelper — Singleton managing all app tables
//  Migrates v1→v2 (expenses + reminders) → v3 (quests, rewards, currency,
//  stat decay via last_updated)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// ─── Data Models ─────────────────────────────────────────────────────────────

class Stat {
  final int? id;
  final String name;
  int value; // 0–9
  int level; // 0+
  int lastUpdated; // millisecondsSinceEpoch

  Stat({
    this.id,
    required this.name,
    this.value = 0,
    this.level = 0,
    int? lastUpdated,
  }) : lastUpdated =
           lastUpdated ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'value': value,
        'level': level,
        'last_updated': lastUpdated,
      };

  factory Stat.fromMap(Map<String, dynamic> m) => Stat(
        id: m['id'] as int,
        name: m['name'] as String,
        value: m['value'] as int,
        level: m['level'] as int,
        lastUpdated: m['last_updated'] as int? ??
            DateTime.now().millisecondsSinceEpoch,
      );
}

class Expense {
  final int? id;
  final double amount;
  final String category;
  final int dateTimestamp; // millisecondsSinceEpoch

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.dateTimestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'date_timestamp': dateTimestamp,
      };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as int,
        amount: (m['amount'] as num).toDouble(),
        category: m['category'] as String,
        dateTimestamp: m['date_timestamp'] as int,
      );

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateTimestamp);
}

class Reminder {
  final int? id;
  String title;
  int hour;
  int minute;
  bool enabled;

  Reminder({
    this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'hour': hour,
        'minute': minute,
        'enabled': enabled ? 1 : 0,
      };

  factory Reminder.fromMap(Map<String, dynamic> m) => Reminder(
        id: m['id'] as int,
        title: m['title'] as String,
        hour: m['hour'] as int,
        minute: m['minute'] as int,
        enabled: (m['enabled'] as int) == 1,
      );

  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class Quest {
  final int? id;
  final String title;
  final String difficulty; // 'easy', 'medium', 'hard'
  final int statId;
  bool isCompleted;

  Quest({
    this.id,
    required this.title,
    required this.difficulty,
    required this.statId,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'difficulty': difficulty,
        'stat_id': statId,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory Quest.fromMap(Map<String, dynamic> m) => Quest(
        id: m['id'] as int,
        title: m['title'] as String,
        difficulty: m['difficulty'] as String,
        statId: m['stat_id'] as int,
        isCompleted: (m['is_completed'] as int) == 1,
      );

  int get xpReward {
    switch (difficulty) {
      case 'easy':
        return 1;
      case 'medium':
        return 3;
      case 'hard':
        return 5;
      default:
        return 1;
    }
  }
}

class Reward {
  final int? id;
  final String title;
  final int cost;
  bool isRedeemed;

  Reward({
    this.id,
    required this.title,
    required this.cost,
    this.isRedeemed = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'cost': cost,
        'is_redeemed': isRedeemed ? 1 : 0,
      };

  factory Reward.fromMap(Map<String, dynamic> m) => Reward(
        id: m['id'] as int,
        title: m['title'] as String,
        cost: m['cost'] as int,
        isRedeemed: (m['is_redeemed'] as int) == 1,
      );
}

// ─── Database Helper (Singleton) ─────────────────────────────────────────────

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'lifeisgame.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE stats (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            name         TEXT    NOT NULL,
            value        INTEGER NOT NULL DEFAULT 0,
            level        INTEGER NOT NULL DEFAULT 0,
            last_updated INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE expenses (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            amount         REAL    NOT NULL,
            category       TEXT    NOT NULL,
            date_timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE reminders (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            title   TEXT    NOT NULL,
            hour    INTEGER NOT NULL,
            minute  INTEGER NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE quests (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            title        TEXT    NOT NULL,
            difficulty   TEXT    NOT NULL DEFAULT 'easy',
            stat_id      INTEGER NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE rewards (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            title       TEXT    NOT NULL,
            cost        INTEGER NOT NULL DEFAULT 0,
            is_redeemed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE currency (
            id      INTEGER PRIMARY KEY,
            credits INTEGER NOT NULL DEFAULT 0
          )
        ''');
        // Seed currency row
        await db.insert('currency', {'id': 1, 'credits': 0});
        // Seed 5 default stats on first install
        final now = DateTime.now().millisecondsSinceEpoch;
        const defaults = [
          'Strength',
          'Agility',
          'Intellect',
          'Charisma',
          'Endurance'
        ];
        for (final n in defaults) {
          await db.insert(
              'stats', {'name': n, 'value': 0, 'level': 0, 'last_updated': now});
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS expenses (
              id             INTEGER PRIMARY KEY AUTOINCREMENT,
              amount         REAL    NOT NULL,
              category       TEXT    NOT NULL,
              date_timestamp INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reminders (
              id      INTEGER PRIMARY KEY AUTOINCREMENT,
              title   TEXT    NOT NULL,
              hour    INTEGER NOT NULL,
              minute  INTEGER NOT NULL,
              enabled INTEGER NOT NULL DEFAULT 1
            )
          ''');
        }
        if (oldVersion < 3) {
          // Add last_updated column to stats (default to now)
          final now = DateTime.now().millisecondsSinceEpoch;
          await db.execute(
              'ALTER TABLE stats ADD COLUMN last_updated INTEGER NOT NULL DEFAULT $now');
          // Create new v3 tables
          await db.execute('''
            CREATE TABLE IF NOT EXISTS quests (
              id           INTEGER PRIMARY KEY AUTOINCREMENT,
              title        TEXT    NOT NULL,
              difficulty   TEXT    NOT NULL DEFAULT 'easy',
              stat_id      INTEGER NOT NULL,
              is_completed INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS rewards (
              id          INTEGER PRIMARY KEY AUTOINCREMENT,
              title       TEXT    NOT NULL,
              cost        INTEGER NOT NULL DEFAULT 0,
              is_redeemed INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS currency (
              id      INTEGER PRIMARY KEY,
              credits INTEGER NOT NULL DEFAULT 0
            )
          ''');
          // Seed currency if empty
          final count = await db
              .rawQuery('SELECT COUNT(*) as c FROM currency');
          if ((count.first['c'] as int) == 0) {
            await db.insert('currency', {'id': 1, 'credits': 0});
          }
        }
      },
    );
  }

  // ─── Stats CRUD ────────────────────────────────────────────────────────────

  Future<List<Stat>> getStats() async {
    final db = await database;
    final rows = await db.query('stats', orderBy: 'id ASC');
    return rows.map(Stat.fromMap).toList();
  }

  Future<int> insertStat(Stat stat) async {
    final db = await database;
    return db.insert('stats', stat.toMap()..remove('id'));
  }

  Future<void> updateStat(Stat stat) async {
    final db = await database;
    stat.lastUpdated = DateTime.now().millisecondsSinceEpoch;
    await db
        .update('stats', stat.toMap(), where: 'id = ?', whereArgs: [stat.id]);
  }

  Future<void> deleteStat(int id) async {
    final db = await database;
    await db.delete('stats', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Stat Decay ────────────────────────────────────────────────────────────

  /// Deduct 1 XP from every stat not updated in 48+ hours. Clamps at 0.
  Future<void> applyStatDecay() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - (48 * 60 * 60 * 1000); // 48 hours in ms
    final rows = await db.query('stats',
        where: 'last_updated < ?', whereArgs: [cutoff]);
    for (final row in rows) {
      final stat = Stat.fromMap(row);
      // Deduct 1 XP with rollover-aware clamping
      stat.value--;
      if (stat.value < 0) {
        if (stat.level > 0) {
          stat.level--;
          stat.value = 9;
        } else {
          stat.value = 0;
        }
      }
      stat.lastUpdated = now;
      await db.update('stats', stat.toMap(),
          where: 'id = ?', whereArgs: [stat.id]);
    }
  }

  // ─── Expenses CRUD ────────────────────────────────────────────────────────

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final rows =
        await db.query('expenses', orderBy: 'date_timestamp DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    final rows = await db.query(
      'expenses',
      where: 'date_timestamp >= ? AND date_timestamp < ?',
      whereArgs: [start, end],
      orderBy: 'date_timestamp ASC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Reminders CRUD ───────────────────────────────────────────────────────

  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return db.insert('reminders', reminder.toMap()..remove('id'));
  }

  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final rows = await db.query('reminders', orderBy: 'hour ASC, minute ASC');
    return rows.map(Reminder.fromMap).toList();
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update('reminders', reminder.toMap(),
        where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<void> deleteReminder(int id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Quests CRUD ──────────────────────────────────────────────────────────

  Future<int> insertQuest(Quest quest) async {
    final db = await database;
    return db.insert('quests', quest.toMap()..remove('id'));
  }

  Future<List<Quest>> getActiveQuests() async {
    final db = await database;
    final rows = await db.query('quests',
        where: 'is_completed = 0', orderBy: 'id DESC');
    return rows.map(Quest.fromMap).toList();
  }

  Future<void> completeQuest(int id) async {
    final db = await database;
    await db.update('quests', {'is_completed': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteQuest(int id) async {
    final db = await database;
    await db.delete('quests', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Rewards CRUD ─────────────────────────────────────────────────────────

  Future<int> insertReward(Reward reward) async {
    final db = await database;
    return db.insert('rewards', reward.toMap()..remove('id'));
  }

  Future<List<Reward>> getRewards() async {
    final db = await database;
    final rows = await db.query('rewards', orderBy: 'is_redeemed ASC, id DESC');
    return rows.map(Reward.fromMap).toList();
  }

  Future<void> redeemReward(int id) async {
    final db = await database;
    await db.update('rewards', {'is_redeemed': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteReward(int id) async {
    final db = await database;
    await db.delete('rewards', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Currency ──────────────────────────────────────────────────────────────

  Future<int> getCredits() async {
    final db = await database;
    final rows = await db.query('currency', where: 'id = 1');
    if (rows.isEmpty) return 0;
    return rows.first['credits'] as int;
  }

  Future<void> addCredits(int amount) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE currency SET credits = credits + ? WHERE id = 1', [amount]);
  }

  Future<bool> deductCredits(int amount) async {
    final db = await database;
    final current = await getCredits();
    if (current < amount) return false;
    await db.rawUpdate(
        'UPDATE currency SET credits = credits - ? WHERE id = 1', [amount]);
    return true;
  }

  // ─── Export Helpers ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllStatsForExport() async {
    final db = await database;
    return db.query('stats', orderBy: 'id ASC');
  }

  Future<List<Map<String, dynamic>>> getAllExpensesForExport() async {
    final db = await database;
    return db.query('expenses', orderBy: 'date_timestamp DESC');
  }
}
