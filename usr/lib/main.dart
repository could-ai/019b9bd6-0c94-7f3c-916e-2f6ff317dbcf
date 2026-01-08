import 'package:flutter/material.dart';
import 'screens/flashcard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vim Muscle Memory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        fontFamily: 'Inter', // Modern font if available, falls back gracefully
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const FlashcardScreen(),
      },
    );
  }
}
