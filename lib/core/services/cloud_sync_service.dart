import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pyq_item.dart';
import 'tracker_service.dart';

class CloudSyncService extends ChangeNotifier {
  static final CloudSyncService instance = CloudSyncService._();
  CloudSyncService._();

  static const String _defaultApiUrl = 'https://jam-cloud-sync.vaibhav27182.workers.dev/api/sync';
  static const String _storageSyncCode = 'jam_cloud_sync_code';
  static const String _storageLastSync = 'jam_cloud_sync_last_time';
  static const String _storageAutoSync = 'jam_cloud_sync_auto_enabled';

  String? _syncCode;
  String? _lastSyncTime;
  bool _autoSyncEnabled = true;
  bool _isSyncing = false;
  String _statusMessage = '';

  String? get syncCode => _syncCode;
  String? get lastSyncTime => _lastSyncTime;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get isSyncing => _isSyncing;
  bool get isLinked => _syncCode != null && _syncCode!.isNotEmpty;
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _syncCode = prefs.getString(_storageSyncCode);
    _lastSyncTime = prefs.getString(_storageLastSync);
    _autoSyncEnabled = prefs.getBool(_storageAutoSync) ?? true;
    notifyListeners();
  }

  /// Generate canonical 6-digit alphanumeric code: JAM-XXX-XXX
  String generateRandomCode() {
    const chars = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
    final rand = Random.secure();
    String part1 = '';
    String part2 = '';
    for (int i = 0; i < 3; i++) {
      part1 += chars[rand.nextInt(chars.length)];
      part2 += chars[rand.nextInt(chars.length)];
    }
    return 'JAM-$part1-$part2';
  }

  /// Normalize user input to canonical JAM-XXX-XXX
  String normalizeCode(String raw) {
    String cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.startsWith('JAM') && cleaned.length > 3) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.length == 6) {
      return 'JAM-${cleaned.substring(0, 3)}-${cleaned.substring(3)}';
    }
    return cleaned.isNotEmpty ? 'JAM-$cleaned' : '';
  }

  String getCleanCodeKey(String code) {
    return code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Helper to merge cloud questions into local tracker without losing progress
  Future<void> _mergeAndApplyCloudData(
    Map<String, dynamic> cloudQuestions,
    TrackerService tracker,
  ) async {
    final localProgress = tracker.progressMap;
    final mergedQuestions = <String, QuestionProgress>{...localProgress};

    for (final entry in cloudQuestions.entries) {
      final qId = entry.key;
      final cQ = entry.value as Map<String, dynamic>;

      final lQ = mergedQuestions[qId];
      final bool cSolved = cQ['solved'] == true;
      final String cDiff = cQ['difficulty']?.toString() ?? 'medium';
      final bool cUnnecessary = cQ['unnecessary'] == true;
      final String? cSolvedAt = cQ['solvedAt']?.toString() ?? cQ['solvedDate']?.toString();

      if (lQ == null) {
        mergedQuestions[qId] = QuestionProgress(
          solved: cSolved,
          difficulty: cDiff,
          unnecessary: cUnnecessary,
          solvedDate: cSolvedAt,
        );
      } else {
        final bool isSolved = lQ.solved || cSolved;
        // Keep timestamp: if both solved, prefer whichever has a non-null timestamp
        final String? finalDate = (lQ.solvedDate != null && lQ.solvedDate!.isNotEmpty)
            ? lQ.solvedDate
            : cSolvedAt;
        final String finalDiff = (lQ.difficulty.isNotEmpty && lQ.difficulty != 'medium')
            ? lQ.difficulty
            : cDiff;

        mergedQuestions[qId] = lQ.copyWith(
          solved: isSolved,
          difficulty: finalDiff,
          unnecessary: lQ.unnecessary || cUnnecessary,
          solvedDate: finalDate,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final trackerData = {
      'questions': mergedQuestions.map((k, v) => MapEntry(k, v.toJson())),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await prefs.setString('jam_pyq_user_tracker_v1', json.encode(trackerData));
    await tracker.reload();
  }

  /// Two-way sync: Pull latest cloud updates, merge, and push merged progress back
  Future<bool> syncNow() async {
    if (_syncCode == null || _syncCode!.isEmpty) {
      _syncCode = generateRandomCode();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageSyncCode, _syncCode!);
    }

    _isSyncing = true;
    _statusMessage = 'Syncing with cloud...';
    notifyListeners();

    try {
      final tracker = TrackerService.instance;
      final codeKey = getCleanCodeKey(_syncCode!);
      final endpoint = Uri.parse('$_defaultApiUrl/$codeKey');

      // 1. PULL latest questions from cloud and merge
      try {
        final getResp = await http.get(endpoint, headers: {'Accept': 'application/json'});
        if (getResp.statusCode == 200) {
          final Map<String, dynamic> cloudData = json.decode(getResp.body);
          final cloudQuestions = cloudData['questions'] as Map<String, dynamic>? ?? {};
          await _mergeAndApplyCloudData(cloudQuestions, tracker);
        }
      } catch (getErr) {
        debugPrint('[Cloud Sync] Pull step warning: $getErr');
      }

      // 2. PUSH merged dataset back to cloud
      final payload = _buildPayload(tracker);
      final resp = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _lastSyncTime = DateTime.now().toIso8601String();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageLastSync, _lastSyncTime!);

        _statusMessage = 'Synced successfully!';
        _isSyncing = false;
        notifyListeners();
        return true;
      } else {
        _statusMessage = 'Sync failed (HTTP ${resp.statusCode})';
        _isSyncing = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        _statusMessage = 'Offline: sync will resume when internet is connected.';
      } else {
        _statusMessage = 'Sync error: $e';
      }
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Link an existing device using its 6-digit sync code and merge progress
  Future<bool> linkDevice(String inputCode) async {
    final normCode = normalizeCode(inputCode);
    final codeKey = getCleanCodeKey(normCode);
    if (codeKey.length != 9 && codeKey.length != 6) {
      _statusMessage = 'Invalid sync code format';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _statusMessage = 'Fetching cloud data...';
    notifyListeners();

    try {
      final endpoint = Uri.parse('$_defaultApiUrl/$codeKey');
      final resp = await http.get(endpoint, headers: {'Accept': 'application/json'});

      if (resp.statusCode == 404) {
        _statusMessage = 'Sync code not found or expired';
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      if (resp.statusCode != 200) {
        _statusMessage = 'Error connecting to cloud server';
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> cloudData = json.decode(resp.body);
      final cloudQuestions = cloudData['questions'] as Map<String, dynamic>? ?? {};

      // Smart Merge: combine cloud questions with local questions
      final tracker = TrackerService.instance;
      await _mergeAndApplyCloudData(cloudQuestions, tracker);

      _syncCode = normCode;
      _lastSyncTime = DateTime.now().toIso8601String();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageSyncCode, _syncCode!);
      await prefs.setString(_storageLastSync, _lastSyncTime!);

      // Also push merged data back up so cloud has both
      final payload = _buildPayload(tracker);
      await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      _statusMessage = 'Device linked & synced successfully!';
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        _statusMessage = 'No internet connection. Please check your network and try again.';
      } else {
        _statusMessage = 'Failed to link device: $e';
      }
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> unlink() async {
    _syncCode = null;
    _lastSyncTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageSyncCode);
    await prefs.remove(_storageLastSync);
    _statusMessage = 'Device unlinked from cloud';
    notifyListeners();
  }

  Future<void> setAutoSync(bool enabled) async {
    _autoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageAutoSync, enabled);
    notifyListeners();
  }

  Map<String, dynamic> _buildPayload(TrackerService tracker) {
    final questions = tracker.progressMap;
    final solvedCount = tracker.solvedCount;

    return {
      'app': 'IIT_JAM_Mathematics_MA_PYQ_Tracker',
      'version': '1.2',
      'syncCode': _syncCode,
      'lastUpdated': DateTime.now().toIso8601String(),
      'stats': {
        'totalOfficialPYQs': 885,
        'solvedCount': solvedCount,
        'oosMarkedUnnecessary': tracker.unnecessaryCount > 0,
      },
      'oosMarkedUnnecessary': tracker.unnecessaryCount > 0,
      'questions': questions.map((k, v) => MapEntry(k, {
            'solved': v.solved,
            'solvedAt': v.solvedDate,
            'difficulty': v.difficulty,
            'unnecessary': v.unnecessary,
            'notes': v.notes,
          })),
    };
  }
}
