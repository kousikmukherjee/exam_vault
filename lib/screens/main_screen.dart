import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'pdf/pdf_library_screen.dart';
// ↓ নতুন imports
import 'notes/notes_screen.dart';
import 'drawing/drawing_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PdfLibraryScreen(),
    NotesScreen(), // নতুন
    DrawingScreen(), // নতুন
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.primaryDark,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz_rounded),
            label: 'MCQ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf_outlined),
            activeIcon: Icon(Icons.picture_as_pdf_rounded),
            label: 'PDF',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note_rounded),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.draw_outlined),
            activeIcon: Icon(Icons.draw_rounded),
            label: 'Drawing',
          ),
        ],
      ),
    );
  }
}
