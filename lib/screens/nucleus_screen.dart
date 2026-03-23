// ─────────────────────────────────────────────────────────────────────────────
//  Nucleus Screen — Profile, Rewards Shop & Data Export
//  Credits-based reward system · Excel export with share_plus
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../game_provider.dart';

const Color _kBg = Color(0xFF0A0A0A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kGold = Color(0xFFFFD700);
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
        final date =
            DateTime.fromMillisecondsSinceEpoch(e['date_timestamp'] as int);
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
      final filePath =
          '${dir.path}/lifeisgame_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel');
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share
      await Share.shareXFiles([XFile(filePath)],
          text: 'Life Is Game — Data Export');
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

  void _showAddRewardDialog() {
    final titleCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('NEW REWARD',
            style: TextStyle(
                color: _kAccent,
                fontFamily: _kFont,
                letterSpacing: 3,
                fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style:
                  const TextStyle(color: Colors.white, fontFamily: _kFont),
              cursorColor: _kAccent,
              decoration: const InputDecoration(
                hintText: 'Reward name...',
                hintStyle: TextStyle(color: _kTextDim),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccent, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              style:
                  const TextStyle(color: Colors.white, fontFamily: _kFont),
              cursorColor: _kGold,
              decoration: InputDecoration(
                hintText: 'Cost in credits...',
                hintStyle: const TextStyle(color: _kTextDim),
                prefixIcon: Icon(Icons.monetization_on,
                    color: _kGold.withOpacity(0.6), size: 20),
                enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _kGold)),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _kGold, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: _kTextDim)),
          ),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final cost = int.tryParse(costCtrl.text.trim()) ?? 0;
              if (title.isEmpty || cost <= 0) return;
              context
                  .read<GameProvider>()
                  .addReward(title: title, cost: cost);
              Navigator.pop(ctx);
            },
            child: const Text('CREATE', style: TextStyle(color: _kAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<GameProvider>(
        builder: (context, gp, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Profile Card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kAccent.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: _kAccent.withOpacity(0.08),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: Column(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [_kAccent, _kAccent.withOpacity(0.4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                    ),
                    child: const Icon(Icons.person,
                        color: _kBg, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('GEMINI',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: _kFont,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                  const SizedBox(height: 6),
                  Text('USER PROFILE',
                      style: TextStyle(
                          color: _kAccent.withOpacity(0.6),
                          fontFamily: _kFont,
                          fontSize: 11,
                          letterSpacing: 3)),
                  const SizedBox(height: 20),
                  _profileRow(Icons.school, 'College', 'Sri Sairam'),
                  const SizedBox(height: 10),
                  _profileRow(Icons.devices, 'Device', 'Vivo Y200'),
                  const SizedBox(height: 10),
                  _profileRow(Icons.code, 'Version', '3.0.0'),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Rewards Shop ──
              _sectionHeader('REWARDS SHOP', Icons.store),
              const SizedBox(height: 8),
              // Credits banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGold.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: _kGold.withOpacity(0.06),
                        blurRadius: 12,
                        spreadRadius: 1)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: _kGold, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      '${gp.credits}',
                      style: const TextStyle(
                        color: _kGold,
                        fontFamily: _kFont,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CREDITS',
                      style: TextStyle(
                        color: _kGold.withOpacity(0.6),
                        fontFamily: _kFont,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Reward items
              if (gp.rewards.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No rewards yet. Create your first reward!',
                      style: TextStyle(
                          color: _kTextDim.withOpacity(0.7),
                          fontSize: 13,
                          fontFamily: _kFont),
                    ),
                  ),
                )
              else
                ...gp.rewards.map((reward) => _RewardCard(
                      reward: reward,
                      credits: gp.credits,
                      onBuy: () async {
                        final success = await gp.buyReward(reward.id!);
                        if (mounted && success) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text(
                              '🎁 Redeemed: ${reward.title}',
                              style: const TextStyle(fontFamily: _kFont),
                            ),
                            backgroundColor: _kGold.withOpacity(0.3),
                            behavior: SnackBarBehavior.floating,
                          ));
                        } else if (mounted && !success) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: const Text(
                              'Not enough credits!',
                              style: TextStyle(fontFamily: _kFont),
                            ),
                            backgroundColor: Colors.red.withOpacity(0.3),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      onDelete: () => gp.deleteReward(reward.id!),
                    )),
              const SizedBox(height: 8),
              // Add Reward button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAccent,
                    side: BorderSide(color: _kAccent.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showAddRewardDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('ADD REWARD',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Export Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kAccent.withOpacity(0.15)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATA EXPORT',
                          style: TextStyle(
                              color: _kAccent,
                              fontFamily: _kFont,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                          'Export all stats and expenses to an Excel file.',
                          style: TextStyle(
                              color: _kTextDim.withOpacity(0.7),
                              fontFamily: _kFont,
                              fontSize: 12)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kAccent,
                            foregroundColor: _kBg,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _exporting ? null : _exportData,
                          icon: _exporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _kBg))
                              : const Icon(
                                  Icons.file_download_outlined),
                          label: Text(
                              _exporting
                                  ? 'EXPORTING...'
                                  : 'EXPORT AS XLSX',
                              style: const TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(height: 24),

              // ── App Info ──
              Center(
                  child: Text('PERSONAL OS v3.0',
                      style: TextStyle(
                          color: _kTextDim.withOpacity(0.3),
                          fontFamily: _kFont,
                          fontSize: 10,
                          letterSpacing: 3))),
              const SizedBox(height: 4),
              Center(
                  child: Text('Life Is Game',
                      style: TextStyle(
                          color: _kTextDim.withOpacity(0.2),
                          fontFamily: _kFont,
                          fontSize: 10))),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
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
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: _kAccent.withOpacity(0.5), size: 18),
      const SizedBox(width: 12),
      Text('$label:',
          style: TextStyle(
              color: _kTextDim, fontFamily: _kFont, fontSize: 12)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: _kFont,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.right)),
    ]);
  }
}

// ─── Reward Card Widget ──────────────────────────────────────────────────────
class _RewardCard extends StatelessWidget {
  final Reward reward;
  final int credits;
  final VoidCallback onBuy;
  final VoidCallback onDelete;

  const _RewardCard({
    required this.reward,
    required this.credits,
    required this.onBuy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = credits >= reward.cost && !reward.isRedeemed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reward.isRedeemed
              ? Colors.white.withOpacity(0.05)
              : _kGold.withOpacity(0.15),
        ),
        boxShadow: reward.isRedeemed
            ? null
            : [
                BoxShadow(
                    color: _kGold.withOpacity(0.04),
                    blurRadius: 8,
                    spreadRadius: 1)
              ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (reward.isRedeemed ? _kTextDim : _kGold)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              reward.isRedeemed ? Icons.check_circle : Icons.card_giftcard,
              color: reward.isRedeemed
                  ? _kTextDim.withOpacity(0.4)
                  : _kGold,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title.toUpperCase(),
                  style: TextStyle(
                    color: reward.isRedeemed ? _kTextDim : Colors.white,
                    fontFamily: _kFont,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    decoration: reward.isRedeemed
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: _kTextDim,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.monetization_on,
                        color: reward.isRedeemed
                            ? _kTextDim.withOpacity(0.3)
                            : _kGold.withOpacity(0.7),
                        size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.cost}',
                      style: TextStyle(
                        color: reward.isRedeemed
                            ? _kTextDim.withOpacity(0.4)
                            : _kGold,
                        fontFamily: _kFont,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          if (reward.isRedeemed)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'CLAIMED',
                style: TextStyle(
                  color: _kTextDim.withOpacity(0.5),
                  fontFamily: _kFont,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close,
                      color: Colors.white.withOpacity(0.2), size: 16),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: canAfford ? onBuy : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? _kGold.withOpacity(0.15)
                          : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: canAfford
                            ? _kGold.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      'BUY',
                      style: TextStyle(
                        color: canAfford
                            ? _kGold
                            : _kTextDim.withOpacity(0.3),
                        fontFamily: _kFont,
                        fontSize: 11,
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
