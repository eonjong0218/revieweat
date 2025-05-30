import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_result_screen.dart';
import 'screens/review_place_search_screen.dart';
import 'screens/review_second_screen.dart';
import 'screens/review_final_screen.dart';
import 'screens/review_success_screen.dart';
import 'screens/profile_screen.dart';

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
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
            settings: settings,
          );
        } else if (settings.name == '/login') {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: settings,
          );
        } else if (settings.name == '/register') {
          return MaterialPageRoute(
            builder: (_) => const RegisterScreen(),
            settings: settings,
          );
        } else if (settings.name == '/home') {
          return MaterialPageRoute(
            builder: (_) => const HomeScreen(),
            settings: settings,
          );
        } else if (settings.name == '/search_result') {
          final args = settings.arguments;
          String initialQuery = '';
          if (args is String) {
            initialQuery = args;
          }
          return MaterialPageRoute(
            builder: (_) => SearchResultScreen(initialQuery: initialQuery),
            settings: settings,
          );
        } else if (settings.name == '/review_place_search') {
          final args = settings.arguments;
          String? keyword;
          if (args is String) {
            keyword = args;
          }
          return MaterialPageRoute(
            builder: (_) => ReviewPlaceSearchScreen(keyword: keyword),
            settings: settings,
          );
        } else if (settings.name == '/review_second') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => ReviewSecondScreen(place: args),
              settings: settings,
            );
          } else {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('잘못된 접근입니다.')),
              ),
              settings: settings,
            );
          }
        } else if (settings.name == '/review_final') {
          final args = settings.arguments;
          if (args is Map<String, dynamic> &&
              args['place'] != null &&
              args['selectedDate'] != null &&
              args['selectedRating'] != null &&
              args['selectedCompanion'] != null) {
            return MaterialPageRoute(
              builder: (_) => ReviewFinalScreen(
                place: args['place'],
                selectedDate: args['selectedDate'],
                selectedRating: args['selectedRating'],
                selectedCompanion: args['selectedCompanion'],
              ),
              settings: settings,
            );
          } else {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('리뷰 최종화면 접근 오류')),
              ),
              settings: settings,
            );
          }
        } else if (settings.name == '/review_success') {
          final args = settings.arguments;
          if (args is Map<String, dynamic> &&
              args['place'] != null &&
              args['selectedDate'] != null &&
              args['selectedRating'] != null &&
              args['selectedCompanion'] != null &&
              args['reviewText'] != null &&
              args['images'] != null) {
            return MaterialPageRoute(
              builder: (_) => ReviewSuccessScreen(
                place: args['place'],
                selectedDate: args['selectedDate'],
                selectedRating: args['selectedRating'],
                selectedCompanion: args['selectedCompanion'],
                reviewText: args['reviewText'],
                images: args['images'],
              ),
              settings: settings,
            );
          } else {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('리뷰 완료화면 접근 오류')),
              ),
              settings: settings,
            );
          }
        } else if (settings.name == '/profile') {
          return MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
