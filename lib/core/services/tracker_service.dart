import 'dart:convert';
import 'dart:math';
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

  Future<void> reload() async {
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

    notifyListeners();
  }

  QuestionProgress getProgress(String questionId, {String defaultDiff = 'medium'}) {
    return _progressMap[questionId] ??
        QuestionProgress(difficulty: defaultDiff);
  }

  Future<void> toggleSolved(String questionId, List<PyqItem> allQuestions) async {
    final current = getProgress(questionId);
    final newSolved = !current.solved;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final nowIso = now.toIso8601String();

    _progressMap[questionId] = current.copyWith(
      solved: newSolved,
      solvedDate: newSolved ? nowIso : null,
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

  String? _parseDateKey(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      if (dateStr.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(dateStr)) {
        return dateStr.substring(0, 10);
      }
      return null;
    }
  }

  Map<String, int> get dailyLogs {
    final map = <String, int>{};
    // 1. Group all solved questions by their local date (matching website's stats.js)
    for (final p in _progressMap.values) {
      if (p.solved && p.solvedDate != null) {
        final key = _parseDateKey(p.solvedDate);
        if (key != null) {
          map[key] = (map[key] ?? 0) + 1;
        }
      }
    }
    // 2. Incorporate any explicit daily logs recorded locally
    for (final e in _dailyLogs.entries) {
      map[e.key] = max(map[e.key] ?? 0, e.value);
    }
    return map;
  }

  int get solvedTodayCount {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return dailyLogs[today] ?? 0;
  }

  int get solvedThisWeekCount {
    final now = DateTime.now();
    final logs = dailyLogs;
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      sum += (logs[key] ?? 0);
    }
    return sum;
  }

  int get activeStreakDays {
    final now = DateTime.now();
    final logs = dailyLogs;
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    // Like stats.js: streak is active if there is activity today or yesterday
    final hasToday = (logs[todayKey] ?? 0) > 0;
    final hasYesterday = (logs[yesterdayKey] ?? 0) > 0;

    if (!hasToday && !hasYesterday) return 0;

    int streak = 0;
    DateTime checkDay = hasToday ? now : now.subtract(const Duration(days: 1));

    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(checkDay);
      if ((logs[key] ?? 0) > 0) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

