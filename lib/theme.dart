import 'package:flutter/material.dart';

class AppTheme {
  // ExamVault Brand Colors
  static const Color primary = Color(0xFF0D47A1); // Deep Blue
  static const Color primaryDark = Color(0xFF002171); // Darker Blue
  static const Color primaryLight = Color(0xFF5472D3); // Lighter Blue
  static const Color accent = Color(0xFFFF8F00); // Amber Gold
  static const Color accentLight = Color(0xFFFFBF47); // Light Gold
  static const Color success = Color(0xFF1B5E20);
  static const Color successLight = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB71C1C);
  static const Color surface = Color(0xFFF0F4FF); // Soft blue-white
  static const Color cardBg = Colors.white;

  // Subject colors
  static Color subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'current_affairs':
        return const Color(0xFF0D47A1);
      case 'history':
        return const Color(0xFF4A148C);
      case 'geography':
        return const Color(0xFF1B5E20);
      case 'mathematics':
        return const Color(0xFF006064);
      case 'polity':
        return const Color(0xFFBF360C);
      case 'general_science':
        return const Color(0xFF004D40);
      case 'mixed':
        return const Color(0xFF263238);
      default:
        return const Color(0xFF37474F);
    }
  }

  static String subjectLabel(String subject) {
    switch (subject.toLowerCase()) {
      case 'current_affairs':
        return 'Current Affairs';
      case 'history':
        return 'History';
      case 'geography':
        return 'Geography';
      case 'mathematics':
        return 'Mathematics';
      case 'polity':
        return 'Polity';
      case 'general_science':
        return 'General Science';
      case 'mixed':
        return 'Mixed';
      default:
        return subject.replaceAll('_', ' ');
    }
  }

  static IconData subjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'current_affairs':
        return Icons.newspaper_rounded;
      case 'history':
        return Icons.history_edu_rounded;
      case 'geography':
        return Icons.public_rounded;
      case 'mathematics':
        return Icons.calculate_rounded;
      case 'polity':
        return Icons.account_balance_rounded;
      case 'general_science':
        return Icons.science_rounded;
      case 'mixed':
        return Icons.grid_view_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  static String difficultyLabel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '🟢 Easy';
      case 'medium':
        return '🟡 Medium';
      case 'hard':
        return '🔴 Hard';
      default:
        return difficulty;
    }
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
