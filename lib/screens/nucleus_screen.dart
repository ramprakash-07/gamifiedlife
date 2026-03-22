// ─────────────────────────────────────────────────────────────────────────────
//  Nucleus Screen — Profile & Data Export
//  User profile · Excel export with share_plus
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

const Color _kAccent = Color(0xFF00E5FF);
const Color _kCardBg = Color(0xFF141414);
const Color _kTextDim = Color(0xFF888888);
const String _kFont = 'Courier';

class NucleusScreen extends StatefulWidget {
  const NucleusScreen({super.key});

  @override
  State<NucleusScreen> createState() => _NucleusScreenState();
}

class _NucleusScreenState extends State<NucleusScreen> {
  bool _exporting = false;

  Future<void> _exportData() async {
    setState(() => _exporting = true);

    try {
      final excel = xl.Excel.createExcel();

      // ── Stats sheet ──
      final statsSheet = excel['Stats'];
      statsSheet.appendRow([
        xl.TextCellValue('Name'),
        xl.TextCellValue('Level'),
        xl.TextCellValue('XP'),
        xl.TextCellValue('Total XP'),
      ]);
      final stats = await DatabaseHelper.instance.getAllStatsForExport();
      for (final s in stats) {
        statsSheet.appendRow([
          xl.TextCellValue(s['name'] as String),
          xl.IntCellValue(s['level'] as int),
          xl.IntCellValue(s['value'] as int),
          xl.IntCellValue((s['level'] as int) * 10 + (s['value'] as int)),
        ]);
      }

      // ── Expenses sheet ──
      final expSheet = excel['Expenses'];
      expSheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Amount'),
      ]);
      final expenses = await DatabaseHelper.instance.getAllExpensesForExport();
      for (final e in expenses) {
        final date = DateTime.fromMillisecondsSinceEpoch(e['date_timestamp'] as int);
        expSheet.appendRow([
          xl.TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(date)),
          xl.TextCellValue(e['category'] as String),
          xl.DoubleCellValue((e['amount'] as num).toDouble()),
        ]);
      }

      // Remove default Sheet1
      excel.delete('Sheet1');

      // Save to temp directory
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/lifeisgame_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel');
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share
      await Share.shareXFiles([XFile(filePath)], text: 'Life Is Game — Data Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red.shade800,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Profile Card ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kCardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kAccent.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: _kAccent.withOpacity(0.08), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_kAccent, _kAccent.withOpacity(0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: const Icon(Icons.person, color: Color(0xFF0A0A0A), size: 40),
              ),
              const SizedBox(height: 16),
              const Text('GEMINI', style: TextStyle(color: Colors.white, fontFamily: _kFont, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4)),
              const SizedBox(height: 6),
              Text('USER PROFILE', style: TextStyle(color: _kAccent.withOpacity(0.6), fontFamily: _kFont, fontSize: 11, letterSpacing: 3)),
              const SizedBox(height: 20),
              _profileRow(Icons.school, 'College', 'Sri Sairam'),
              const SizedBox(height: 10),
              _profileRow(Icons.devices, 'Device', 'Vivo Y200'),
              const SizedBox(height: 10),
              _profileRow(Icons.code, 'Version', '2.0.0'),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Export Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kAccent.withOpacity(0.15)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DATA EXPORT', style: TextStyle(color: _kAccent, fontFamily: _kFont, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Export all stats and expenses to an Excel file with two sheets.',
                  style: TextStyle(color: _kTextDim.withOpacity(0.7), fontFamily: _kFont, fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent, foregroundColor: const Color(0xFF0A0A0A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _exporting ? null : _exportData,
                  icon: _exporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0A0A)))
                      : const Icon(Icons.file_download_outlined),
                  label: Text(_exporting ? 'EXPORTING...' : 'EXPORT AS XLSX',
                      style: const TextStyle(fontFamily: _kFont, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── App Info ──
          Center(child: Text('PERSONAL OS v2.0', style: TextStyle(color: _kTextDim.withOpacity(0.3), fontFamily: _kFont, fontSize: 10, letterSpacing: 3))),
          const SizedBox(height: 4),
          Center(child: Text('Life Is Game', style: TextStyle(color: _kTextDim.withOpacity(0.2), fontFamily: _kFont, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: _kAccent.withOpacity(0.5), size: 18),
      const SizedBox(width: 12),
      Text('$label:', style: TextStyle(color: _kTextDim, fontFamily: _kFont, fontSize: 12)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontFamily: _kFont, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
    ]);
  }
}
