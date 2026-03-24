// ─────────────────────────────────────────────────────────────────────────────
//  Nucleus Screen — Profile, Rewards Shop & Data Export
//  Glassmorphism cards · Orbitron/Inter fonts · 8pt grid
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
import '../theme/app_theme.dart';

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
          content: Text('Export failed: $e',
              style: interStyle(color: Colors.white, fontSize: 13)),
          backgroundColor: kHardRed.withOpacity(0.3),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        backgroundColor: glassDialogBg,
        shape: glassDialogShape,
        title: Text('NEW REWARD',
            style: orbitronStyle(fontSize: 16, letterSpacing: 3)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: interStyle(color: Colors.white),
              cursorColor: kNeonCyan,
              decoration: glassInputDecoration(hintText: 'Reward name...'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              style: interStyle(color: Colors.white),
              cursorColor: kGold,
              decoration: InputDecoration(
                hintText: 'Cost in credits...',
                hintStyle: interStyle(color: kDimText, fontSize: 14),
                prefixIcon: Icon(Icons.monetization_on,
                    color: kGold.withOpacity(0.6), size: 20),
                enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: kGold.withOpacity(0.3))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: kGold, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: interStyle(color: kDimText, fontSize: 12)),
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
            child: Text('CREATE',
                style: orbitronStyle(fontSize: 12, color: kNeonCyan)),
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
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profile Card ──
              GlassCard(
                padding: const EdgeInsets.all(24),
                borderColor: kNeonCyan,
                borderOpacity: 0.2,
                extraShadows: [
                  BoxShadow(
                      color: kNeonCyan.withOpacity(0.08),
                      blurRadius: 24,
                      spreadRadius: 4)
                ],
                child: Column(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: kNeonCyan.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: kNeonCyan.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('GEMINI',
                      style: orbitronStyle(
                          fontSize: 20,
                          color: Colors.white,
                          letterSpacing: 4)),
                  const SizedBox(height: 8),
                  Text('USER PROFILE',
                      style: orbitronStyle(
                          fontSize: 10,
                          color: kNeonCyan.withOpacity(0.6),
                          letterSpacing: 3)),
                  const SizedBox(height: 24),
                  _profileRow(Icons.school, 'College', 'Sri Sairam'),
                  const SizedBox(height: 12),
                  _profileRow(Icons.devices, 'Device', 'Vivo Y200'),
                  const SizedBox(height: 12),
                  _profileRow(Icons.code, 'Version', '3.0.0'),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Rewards Shop ──
              const SectionHeader(title: 'REWARDS SHOP', icon: Icons.store),
              const SizedBox(height: 8),
              // Credits banner
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: kGold,
                borderOpacity: 0.15,
                extraShadows: [
                  BoxShadow(
                      color: kGold.withOpacity(0.06),
                      blurRadius: 16,
                      spreadRadius: 1)
                ],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: kGold, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '${gp.credits}',
                      style: orbitronStyle(
                        fontSize: 28,
                        color: kGold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CREDITS',
                      style: orbitronStyle(
                        fontSize: 10,
                        color: kGold.withOpacity(0.6),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Reward items
              if (gp.rewards.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No rewards yet. Create your first reward!',
                      style: interStyle(
                          color: kDimText.withOpacity(0.7), fontSize: 13),
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
                              style: interStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                            backgroundColor: kGold.withOpacity(0.2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ));
                        } else if (mounted && !success) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text(
                              'Not enough credits!',
                              style: interStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                            backgroundColor: kHardRed.withOpacity(0.2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
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
                    foregroundColor: kNeonCyan,
                    side: BorderSide(color: kNeonCyan.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _showAddRewardDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('ADD REWARD',
                      style: orbitronStyle(
                          fontSize: 11,
                          letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Export Card ──
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DATA EXPORT',
                          style: orbitronStyle(
                              fontSize: 13,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                          'Export all stats and expenses to an Excel file.',
                          style: interStyle(
                              color: kDimText.withOpacity(0.7),
                              fontSize: 12)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kNeonCyan.withOpacity(0.15),
                            foregroundColor: kNeonCyan,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: kNeonCyan.withOpacity(0.3)),
                            ),
                          ),
                          onPressed: _exporting ? null : _exportData,
                          icon: _exporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: kNeonCyan))
                              : const Icon(
                                  Icons.file_download_outlined),
                          label: Text(
                              _exporting
                                  ? 'EXPORTING...'
                                  : 'EXPORT AS XLSX',
                              style: orbitronStyle(
                                  fontSize: 11,
                                  letterSpacing: 2)),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(height: 24),

              // ── App Info ──
              Center(
                  child: Text('PERSONAL OS v3.0',
                      style: orbitronStyle(
                          fontSize: 9,
                          color: kDimText.withOpacity(0.3),
                          letterSpacing: 3))),
              const SizedBox(height: 4),
              Center(
                  child: Text('Life Is Game',
                      style: interStyle(
                          color: kDimText.withOpacity(0.2),
                          fontSize: 10))),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: kNeonCyan.withOpacity(0.5), size: 18),
      const SizedBox(width: 12),
      Text('$label:',
          style: interStyle(color: kDimText, fontSize: 12)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style: interStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
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

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: reward.isRedeemed ? Colors.white : kGold,
      borderOpacity: reward.isRedeemed ? 0.05 : 0.12,
      extraShadows: reward.isRedeemed
          ? null
          : [
              BoxShadow(
                  color: kGold.withOpacity(0.04),
                  blurRadius: 12,
                  spreadRadius: 1)
            ],
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (reward.isRedeemed ? kDimText : kGold)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              reward.isRedeemed ? Icons.check_circle : Icons.card_giftcard,
              color: reward.isRedeemed
                  ? kDimText.withOpacity(0.4)
                  : kGold,
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
                  style: interStyle(
                    color: reward.isRedeemed ? kDimText : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    decoration: reward.isRedeemed
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: kDimText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.monetization_on,
                        color: reward.isRedeemed
                            ? kDimText.withOpacity(0.3)
                            : kGold.withOpacity(0.7),
                        size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.cost}',
                      style: orbitronStyle(
                        fontSize: 12,
                        color: reward.isRedeemed
                            ? kDimText.withOpacity(0.4)
                            : kGold,
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
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CLAIMED',
                style: interStyle(
                  color: kDimText.withOpacity(0.5),
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
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: canAfford ? onBuy : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? kGold.withOpacity(0.12)
                          : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canAfford
                            ? kGold.withOpacity(0.3)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      'BUY',
                      style: orbitronStyle(
                        fontSize: 10,
                        color: canAfford
                            ? kGold
                            : kDimText.withOpacity(0.3),
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
