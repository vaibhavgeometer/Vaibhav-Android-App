import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/mock_test.dart';
import '../models/pyq_item.dart';

class DataService {
  static final DataService instance = DataService._();
  DataService._();

  Map<String, MockTest>? _mockTestsCache;
  List<PyqItem>? _pyqsCache;

  /// Load and cache all mock test suites
  Future<Map<String, MockTest>> loadMockTests() async {
    if (_mockTestsCache != null) return _mockTestsCache!;

    final jsonString = await rootBundle.loadString('assets/data/mock_tests_data.json');
    final Map<String, dynamic> rawMap = json.decode(jsonString);

    final result = <String, MockTest>{};
    for (final entry in rawMap.entries) {
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = MockTest.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    _mockTestsCache = result;
    return result;
  }

  /// Load and cache all 885 categorized PYQs
  Future<List<PyqItem>> loadCategorizedPyqs() async {
    if (_pyqsCache != null) return _pyqsCache!;

    final jsonString = await rootBundle.loadString('assets/data/pyqs_categorized.json');
    final List<dynamic> rawList = json.decode(jsonString);

    _pyqsCache = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => PyqItem.fromJson(item))
        .toList();

    return _pyqsCache!;
  }

  /// Get specific mock test by ID (e.g. '2026', '2015')
  Future<MockTest?> getMockTest(String id) async {
    final tests = await loadMockTests();
    return tests[id];
  }
}

