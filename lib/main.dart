import 'package:flutter/material.dart';

import 'screens/input_screen.dart';

void main() {
  runApp(const BloglyzerApp());
}

class BloglyzerApp extends StatelessWidget {
  const BloglyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloglyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF03C75A),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const InputScreen(),
    );
  }
}
