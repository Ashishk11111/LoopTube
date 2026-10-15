import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LoopTubeApp());
}

class LoopTubeApp extends StatelessWidget {
  const LoopTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🫵🧪',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFFF0000),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF272727),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}