import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart'; // ✅ 홈 화면 import

void main() {
  runApp(const ReviewEatApp());
}

class ReviewEatApp extends StatelessWidget {
  const ReviewEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REVIEWEAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16.0),
          bodyMedium: TextStyle(fontSize: 14.0),
          titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(), // ✅ 홈 라우트 추가
      },
    );
  }
}
