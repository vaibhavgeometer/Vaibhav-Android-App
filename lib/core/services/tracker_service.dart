import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pyq_item.dart';
import 'cloud_sync_service.dart';

class TrackerService extends ChangeNotifier {
  static final TrackerService instance = TrackerService._();
  TrackerService._();

  static const String _storageKey = 'jam_pyq_user_tracker_v1';
  static const String _dailyLogsKey = 'jam_daily_solving_logs_v1';

  Map<String, QuestionProgress> _progressMap = {};
  Map<String, int> _dailyLogs = {}; // 'YYYY-MM-DD' -> count
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Map<String, QuestionProgress> get progressMap => _progressMap;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();

    final rawJson = prefs.getString(_storageKey);
    if (rawJson != null) {
      try {
        final decoded = json.decode(rawJson) as Map<String, dynamic>;
        final questions = decoded['questions'] as Map<String, dynamic>? ?? {};
        _progressMap = questions.map((k, v) => MapEntry(
              k,
              QuestionProgress.fromJson(v as Map<String, dynamic>),
            ));
      } catch (e) {
        debugPrint('Error loading progress map: $e');
      }
    }

    final rawDaily = prefs.getString(_dailyLogsKey);
    if (rawDaily != null) {
      try {
        final decoded = json.decode(rawDaily) as Map<String, dynamic>;
        _dailyLogs = decoded.map((k, v) => MapEntry(k, v as int? ?? 0));
      } catch (e) {
        debugPrint('Error loading daily logs: $e');
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  QuestionProgress getProgress(String questionId, {String defaultDiff = 'medium'}) {
    return _progressMap[questionId] ??
        QuestionProgress(difficulty: defaultDiff);
  }

  Future<void> toggleSolved(String questionId, List<PyqItem> allQuestions) async {
    final current = getProgress(questionId);
    final newSolved = !current.solved;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _progressMap[questionId] = current.copyWith(
      solved: newSolved,
      solvedDate: newSolved ? today : null,
    );

    // Update daily logs
    if (newSolved) {
      _dailyLogs[today] = (_dailyLogs[today] ?? 0) + 1;
    } else {
      if ((_dailyLogs[today] ?? 0) > 0) {
        _dailyLogs[today] = _dailyLogs[today]! - 1;
      }
    }

    await _save();
    notifyListeners();
  }

  Future<void> setDifficulty(String questionId, String difficulty) async {
    final current = getProgress(questionId);
    _progressMap[questionId] = current.copyWith(difficulty: difficulty);
    await _save();
    notifyListeners();
  }

  Future<void> setUnnecessary(String questionId, bool unnecessary) async {
    final current = getProgress(questionId);
    _progressMap[questionId] = current.copyWith(unnecessary: unnecessary);
    await _save();
    notifyListeners();
  }

  Future<void> setNotes(String questionId, String notes) async {
    final current = getProgress(questionId);
    _progressMap[questionId] = current.copyWith(notes: notes);
    await _save();
    notifyListeners();
  }

  Future<void> markAllOosAsUnnecessary(List<PyqItem> allQuestions, bool value) async {
    for (final q in allQuestions) {
      if (q.isOutOfSyllabus) {
        final current = getProgress(q.id);
        _progressMap[q.id] = current.copyWith(unnecessary: value);
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> resetAll() async {
    _progressMap.clear();
    _dailyLogs.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'questions': _progressMap.map((k, v) => MapEntry(k, v.toJson())),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_storageKey, json.encode(data));
    await prefs.setString(_dailyLogsKey, json.encode(_dailyLogs));

    final sync = CloudSyncService.instance;
    if (sync.isLinked && sync.autoSyncEnabled) {
      sync.syncNow();
    }
  }

  // --- Statistics Helpers ---

  int get solvedCount => _progressMap.values.where((p) => p.solved).length;
  int get unnecessaryCount => _progressMap.values.where((p) => p.unnecessary).length;

  int get solvedTodayCount {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _dailyLogs[today] ?? 0;
  }

  int get solvedThisWeekCount {
    final now = DateTime.now();
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      sum += (_dailyLogs[key] ?? 0);
    }
    return sum;
  }

  int get activeStreakDays {
    final now = DateTime.now();
    int streak = 0;
    DateTime checkDay = now;

    // If today is 0, check if yesterday had solving to continue streak
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    if ((_dailyLogs[todayKey] ?? 0) == 0) {
      checkDay = now.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(checkDay);
      if ((_dailyLogs[key] ?? 0) > 0) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, int> get dailyLogs => _dailyLogs;
}

