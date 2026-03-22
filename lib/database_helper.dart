// ─────────────────────────────────────────────────────────────────────────────
//  DatabaseHelper — Singleton managing stats, expenses & reminders tables
//  Migrates from v1 (stats only) to v2 (+ expenses + reminders)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// ─── Data Models ─────────────────────────────────────────────────────────────

class Stat {
  final int? id;
  final String name;
  int value; // 0–9
  int level; // 0+

  Stat({this.id, required this.name, this.value = 0, this.level = 0});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'value': value,
        'level': level,
      };

  factory Stat.fromMap(Map<String, dynamic> m) => Stat(
        id: m['id'] as int,
        name: m['name'] as String,
        value: m['value'] as int,
        level: m['level'] as int,
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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE stats (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            name  TEXT    NOT NULL,
            value INTEGER NOT NULL DEFAULT 0,
            level INTEGER NOT NULL DEFAULT 0
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
        // Seed 5 default stats on first install
        const defaults = [
          'Strength',
          'Agility',
          'Intellect',
          'Charisma',
          'Endurance'
        ];
        for (final n in defaults) {
          await db.insert('stats', {'name': n, 'value': 0, 'level': 0});
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
    await db
        .update('stats', stat.toMap(), where: 'id = ?', whereArgs: [stat.id]);
  }

  Future<void> deleteStat(int id) async {
    final db = await database;
    await db.delete('stats', where: 'id = ?', whereArgs: [id]);
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
