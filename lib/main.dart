import 'package:exam_vault/models/pdf_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
// এই import যোগ করুন
import 'screens/main_screen.dart';
import 'theme.dart';

// ↓ নতুন import যোগ করুন
import 'models/note_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.primaryDark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive local database
  await DatabaseService.init();

  // ↓ এই ২ লাইন যোগ করুন DatabaseService.init() এর পরে
  Hive.registerAdapter(PdfDocumentAdapter());
  await Hive.openBox<PdfDocument>('pdf_library');

  // ↓ নতুন যোগ করুন:
  Hive.registerAdapter(NoteModelAdapter());
  await Hive.openBox<NoteModel>('notes_box');

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
