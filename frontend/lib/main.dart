import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ReviewEatApp());
}

class ReviewEatApp extends StatelessWidget {
  const ReviewEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REVIEWEAT',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
