import 'package:flutter/foundation.dart';
import '../models/question_set.dart';
import '../services/database_service.dart';
import '../services/json_import_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService db = DatabaseService();
  late final JsonImportService _importService;

  List<QuestionSet> _sets = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  AppProvider() {
    _importService = JsonImportService(db);
    _loadSets();
  }

  List<QuestionSet> get sets => _sets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  Map<String, int> get overallStats => db.getOverallStats();

  void _loadSets() {
    _sets = db.getAllSets();
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> importJsonFile() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _importService.pickAndImportFile();

    _isLoading = false;
    if (result.success) {
      _successMessage = result.message;
      _loadSets();
    } else {
      _errorMessage = result.message;
      notifyListeners();
    }
  }

  Future<void> deleteSet(String setId) async {
    await db.deleteSet(setId);
    _loadSets();
  }

  Future<void> updateProgress(String setId, int index, int readCount) async {
    await db.saveProgress(setId, index);
    await db.updateReadCount(setId, readCount);
    _loadSets();
  }
}
