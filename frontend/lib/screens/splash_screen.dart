import 'package:flutter/material.dart';
import 'dart:async';

// 스플래시 화면 위젯
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 4초 후 로그인 화면으로 자동 이동
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 취소하여 메모리 누수 방지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // 중앙에 로고 이미지 표시
      body: Center(
        child: Image(
          image: AssetImage('assets/images/logo.png'), // 로고 경로
          width: 140,
          height: 140,
        ),
      ),
    );
  }
}
