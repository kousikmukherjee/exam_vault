import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'providers/app_provider.dart';
import 'models/pdf_document.dart';
import 'models/note_model.dart';
import 'screens/main_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.primaryDark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await DatabaseService.init();

  // PDF Library
  Hive.registerAdapter(PdfDocumentAdapter());
  await Hive.openBox<PdfDocument>('pdf_library');

  // Notes
  Hive.registerAdapter(NoteModelAdapter());
  await Hive.openBox<NoteModel>('notes_box');

  // ← Study Notes marked facts (নতুন)
  await Hive.openBox<bool>('marked_facts');

  runApp(const ExamVaultApp());
}

class ExamVaultApp extends StatelessWidget {
  const ExamVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'ExamVault',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainScreen(),
      ),
    );
  }
}
