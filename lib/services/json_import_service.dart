import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/question.dart';
import '../models/question_set.dart';
import 'database_service.dart';

class ImportResult {
  final bool success;
  final String message;
  final int questionsImported;
  final String? setId;

  ImportResult({
    required this.success,
    required this.message,
    this.questionsImported = 0,
    this.setId,
  });
}

class JsonImportService {
  final DatabaseService _db;
  JsonImportService(this._db);

  Future<ImportResult> pickAndImportFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: 'No file selected');
      }

      final path = result.files.first.path;
      if (path == null) {
        return ImportResult(success: false, message: 'Could not access file');
      }

      return await _importFile(path);
    } catch (e) {
      return ImportResult(success: false, message: 'Error: $e');
    }
  }

  Future<ImportResult> _importFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(success: false, message: 'File not found');
      }

      final contents = await file.readAsString();
      final Map<String, dynamic> jsonData = json.decode(contents);

      if (!jsonData.containsKey('questions')) {
        return ImportResult(
            success: false,
            message: 'Invalid format: missing "questions" array');
      }

      final setName = jsonData['set_name']?.toString() ?? 'Imported Set';
      final subject = jsonData['subject']?.toString() ?? 'general';
      final uploadedOn =
          jsonData['uploaded_on']?.toString() ?? DateTime.now().toIso8601String();
      final List<dynamic> rawQuestions = jsonData['questions'];

      if (rawQuestions.isEmpty) {
        return ImportResult(success: false, message: 'No questions in file');
      }

      final setId = 'set_${DateTime.now().millisecondsSinceEpoch}';
      final List<Question> questions = [];

      for (final q in rawQuestions) {
        try {
          questions.add(Question.fromJson(q as Map<String, dynamic>, setName));
        } catch (_) {}
      }

      if (questions.isEmpty) {
        return ImportResult(
            success: false, message: 'Could not parse any valid questions');
      }

      await _db.saveQuestions(setId, questions);
      await _db.saveSet(QuestionSet(
        setId: setId,
        setName: setName,
        subject: subject,
        uploadedOn: uploadedOn,
        totalQuestions: questions.length,
        importedAt: DateTime.now(),
      ));

      return ImportResult(
        success: true,
        message: '✅ Imported ${questions.length} questions from "$setName"',
        questionsImported: questions.length,
        setId: setId,
      );
    } on FormatException catch (e) {
      return ImportResult(success: false, message: 'Invalid JSON: $e');
    } catch (e) {
      return ImportResult(success: false, message: 'Import failed: $e');
    }
  }
}
