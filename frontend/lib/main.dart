import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_result_screen.dart';
import 'screens/review_place_search_screen.dart';
import 'screens/review_second_screen.dart';

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
        useMaterial3: true,
        fontFamily: 'Inter',
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16.0),
          bodyMedium: TextStyle(fontSize: 14.0),
          titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        } else if (settings.name == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        } else if (settings.name == '/register') {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        } else if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        } else if (settings.name == '/search_result') {
          final args = settings.arguments;
          String initialQuery = '';
          if (args is String) {
            initialQuery = args;
          }
          return MaterialPageRoute(
            builder: (_) => SearchResultScreen(initialQuery: initialQuery),
          );
        } else if (settings.name == '/review_place_search') {
          final args = settings.arguments;
          String? keyword;
          if (args is String) {
            keyword = args;
          }
          // 반드시 ReviewPlaceSearchScreen에 keyword 파라미터가 정의되어 있어야 함!
          return MaterialPageRoute(
            builder: (_) => ReviewPlaceSearchScreen(keyword: keyword),
          );
        } else if (settings.name == '/review_second') {
          final args = settings.arguments;
          // place는 null이 아니어야 하므로 체크
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => ReviewSecondScreen(place: args),
            );
          } else {
            // 잘못된 arguments 전달 시 에러 안내 화면 (예시)
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text('잘못된 접근입니다.'),
                ),
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
