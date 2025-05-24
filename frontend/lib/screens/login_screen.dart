import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController(); // 이메일 입력 컨트롤러
  final passwordController = TextEditingController(); // 비밀번호 입력 컨트롤러
  bool _isFormValid = false; // 폼 유효성 상태 추적

  // 포커스 노드 추가
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // 오류 메시지 상태 관리
  String? _emailError;
  String? _passwordError;

  // 비밀번호 보이기/숨기기 상태 변수 추가
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // 텍스트 필드 변경 감지하여 버튼 활성화 상태 업데이트
    emailController.addListener(() {
      _updateFormState();
      _validateEmail(); // 이메일 값이 변경될 때마다 유효성 검사
    });

    passwordController.addListener(() {
      _updateFormState();
      _validatePassword(); // 비밀번호 값이 변경될 때마다 유효성 검사
    });

    // 포커스 리스너 추가
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && emailController.text.isNotEmpty) {
        _validateEmail(); // 포커스를 잃고 텍스트가 비어있지 않을 때 검증
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && passwordController.text.isNotEmpty) {
        _validatePassword(); // 포커스를 잃고 텍스트가 비어있지 않을 때 검증
      }
    });
  }

  // 이메일 유효성 검사 함수
  void _validateEmail() {
    setState(() {
      if (emailController.text.isEmpty) {
        _emailError = null; // 빈 값이면 오류 메시지 제거
      } else if (!emailController.text.contains('@')) {
        _emailError = '이메일 형식이 올바르지 않습니다.';
      } else {
        _emailError = null; // 유효한 이메일이면 오류 메시지 제거
      }
    });
  }

  // 비밀번호 유효성 검사 함수
  void _validatePassword() {
    setState(() {
      if (passwordController.text.isEmpty) {
        _passwordError = null; // 빈 값이면 오류 메시지 제거
      } else if (passwordController.text.length < 8) {
        _passwordError = '비밀번호는 8자 이상이어야 합니다.';
      } else {
        _passwordError = null; // 유효한 비밀번호면 오류 메시지 제거
      }
    });
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    emailController.dispose();
    passwordController.dispose();

    // 포커스 노드 해제
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  // 폼 상태 업데이트 함수
  void _updateFormState() {
    setState(() {
      _isFormValid = emailController.text.isNotEmpty &&
          emailController.text.contains('@') &&
          passwordController.text.length >= 8;
    });
  }

  // 로그인 처리 함수 (토큰 저장 기능 추가)
  void _handleLogin() async {
    _validateEmail();
    _validatePassword();

    if (_emailError == null && _passwordError == null && _isFormValid) {
      try {
        final response = await http.post(
          Uri.parse('http://192.168.0.6:8000/token'), // URL 통일
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'username': emailController.text,
            'password': passwordController.text,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final token = data['access_token']; // 백엔드에서 받은 토큰

          if (kDebugMode) {
            print('로그인 성공: $token');
          }

          // 토큰 저장 기능 추가
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('access_token', token);
            print('토큰 저장 완료: $token');
          } catch (e) {
            print('토큰 저장 실패: $e');
          }

          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          final errorData = json.decode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorData['detail'] ?? '로그인 실패')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 오류: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀 텍스트
              const Text(
                '이메일과 비밀번호를\n입력해주세요.',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),

              // 이메일 라벨
              const Text(
                '이메일',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),

              // 이메일 입력 필드
              TextField(
                controller: emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'sample@gmail.com',
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  errorText: _emailError, // 오류 메시지 표시
                  errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호 라벨
              const Text(
                '비밀번호',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),

              // 비밀번호 입력 필드 (보이기/숨기기 기능 추가)
              TextField(
                controller: passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  errorText: _passwordError,
                  errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 26),

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _handleLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid ? Colors.black : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    disabledForegroundColor: Colors.grey[500],
                  ),
                  child: const Text('로그인'),
                ),
              ),
              const SizedBox(height: 12),

              // 하단 링크들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // 회원가입 페이지로 이동
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('회원가입', style: TextStyle(fontSize: 12)),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // 계정 찾기 기능
                        },
                        child: const Text('계정 찾기', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {
                          // 비밀번호 재설정 기능
                        },
                        child: const Text('비밀번호 재설정', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 80),

              // 카카오 로그인 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // 카카오 로그인 연동 예정
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE812),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Image.asset('assets/images/kakao_icon.png', height: 20),
                    label: const Text(
                      '카카오 로그인',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
