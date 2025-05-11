import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // 회원가입 화면 import 추가

void main() {
  runApp(const ReviewEatApp());
}

class ReviewEatApp extends StatelessWidget {
  const ReviewEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REVIEWEAT',
      debugShowCheckedModeBanner: false, // 상단 debug 배너 제거
      theme: ThemeData(
        fontFamily: 'Inter', // ✅ 전체 글꼴을 Inter로 설정
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
        '/register': (context) => const RegisterScreen(), // 회원가입 화면 라우트 추가
      },
    );
  }
}

