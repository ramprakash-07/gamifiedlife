// ─────────────────────────────────────────────────────────────────────────────
//  GameProvider — Cross-tab reactive state for Credits, Quests & Rewards
//  Uses ChangeNotifier so Provider propagates updates to all tabs instantly
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class GameProvider extends ChangeNotifier {
  int _credits = 0;
  List<Quest> _quests = [];
  List<Reward> _rewards = [];
  List<Stat> _stats = [];

  int get credits => _credits;
  List<Quest> get quests => _quests;
  List<Reward> get rewards => _rewards;
  List<Stat> get stats => _stats;

  // ── Load everything on startup ──────────────────────────────────────────

  Future<void> loadAll() async {
    _credits = await DatabaseHelper.instance.getCredits();
    _quests = await DatabaseHelper.instance.getActiveQuests();
    _rewards = await DatabaseHelper.instance.getRewards();
    _stats = await DatabaseHelper.instance.getStats();
    notifyListeners();
  }

  Future<void> refreshStats() async {
    _stats = await DatabaseHelper.instance.getStats();
    notifyListeners();
  }

  Future<void> refreshCredits() async {
    _credits = await DatabaseHelper.instance.getCredits();
    notifyListeners();
  }

  // ── Quests ──────────────────────────────────────────────────────────────

  Future<void> addQuest({
    required String title,
    required String difficulty,
    required int statId,
  }) async {
    final quest = Quest(title: title, difficulty: difficulty, statId: statId);
    await DatabaseHelper.instance.insertQuest(quest);
    _quests = await DatabaseHelper.instance.getActiveQuests();
    notifyListeners();
  }

  /// Complete a quest: grants XP to the assigned stat + awards credits.
  /// Returns the XP gained for UI feedback.
  Future<int> completeQuest(int questId) async {
    final idx = _quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return 0;
    final quest = _quests[idx];
    final xp = quest.xpReward;

    // Mark quest as completed
    await DatabaseHelper.instance.completeQuest(questId);

    // Apply XP to the assigned stat (with rollover logic)
    await _applyXpToStat(quest.statId, xp);

    // Award credits: 10 per XP point
    final creditsEarned = xp * 10;
    await DatabaseHelper.instance.addCredits(creditsEarned);
    _credits = await DatabaseHelper.instance.getCredits();

    // Refresh
    _quests = await DatabaseHelper.instance.getActiveQuests();
    _stats = await DatabaseHelper.instance.getStats();
    notifyListeners();
    return xp;
  }

  Future<void> deleteQuest(int questId) async {
    await DatabaseHelper.instance.deleteQuest(questId);
    _quests = await DatabaseHelper.instance.getActiveQuests();
    notifyListeners();
  }

  // ── Rewards ─────────────────────────────────────────────────────────────

  Future<void> addReward({required String title, required int cost}) async {
    final reward = Reward(title: title, cost: cost);
    await DatabaseHelper.instance.insertReward(reward);
    _rewards = await DatabaseHelper.instance.getRewards();
    notifyListeners();
  }

  /// Buy a reward: deducts credits. Returns true if successful.
  Future<bool> buyReward(int rewardId) async {
    final idx = _rewards.indexWhere((r) => r.id == rewardId);
    if (idx == -1) return false;
    final reward = _rewards[idx];
    if (reward.isRedeemed) return false;

    final success = await DatabaseHelper.instance.deductCredits(reward.cost);
    if (!success) return false;

    await DatabaseHelper.instance.redeemReward(rewardId);
    _credits = await DatabaseHelper.instance.getCredits();
    _rewards = await DatabaseHelper.instance.getRewards();
    notifyListeners();
    return true;
  }

  Future<void> deleteReward(int rewardId) async {
    await DatabaseHelper.instance.deleteReward(rewardId);
    _rewards = await DatabaseHelper.instance.getRewards();
    notifyListeners();
  }

  // ── Focus Bonus ─────────────────────────────────────────────────────────

  /// Apply +2 XP focus bonus to a stat + 20 credits
  Future<void> applyFocusBonus(int statId) async {
    await _applyXpToStat(statId, 2);
    await DatabaseHelper.instance.addCredits(20);
    _credits = await DatabaseHelper.instance.getCredits();
    _stats = await DatabaseHelper.instance.getStats();
    notifyListeners();
  }

  // ── Internal: Apply XP with 0–9 rollover ────────────────────────────────

  Future<void> _applyXpToStat(int statId, int xpAmount) async {
    final statsList = await DatabaseHelper.instance.getStats();
    final idx = statsList.indexWhere((s) => s.id == statId);
    if (idx == -1) return;
    final stat = statsList[idx];

    stat.value += xpAmount;
    while (stat.value >= 10) {
      stat.value -= 10;
      stat.level++;
    }

    await DatabaseHelper.instance.updateStat(stat);
  }
}
