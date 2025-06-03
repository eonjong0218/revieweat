import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 로그인 화면 StatefulWidget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 입력 컨트롤러 및 상태 변수
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isFormValid = false;

  // 포커스 노드 및 에러 메시지
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String? _emailError;
  String? _passwordError;

  // 비밀번호 표시 여부
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // 이메일 입력 감지 및 유효성 검사
    emailController.addListener(() {
      _updateFormState();
      _validateEmail();
    });

    // 비밀번호 입력 감지 및 유효성 검사
    passwordController.addListener(() {
      _updateFormState();
      _validatePassword();
    });

    // 이메일 포커스 해제 시 유효성 검사
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && emailController.text.isNotEmpty) {
        _validateEmail();
      }
    });

    // 비밀번호 포커스 해제 시 유효성 검사
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && passwordController.text.isNotEmpty) {
        _validatePassword();
      }
    });
  }

  // 이메일 형식 유효성 검사
  void _validateEmail() {
    setState(() {
      if (emailController.text.isEmpty) {
        _emailError = null;
      } else if (!emailController.text.contains('@')) {
        _emailError = '이메일 형식이 올바르지 않습니다.';
      } else {
        _emailError = null;
      }
    });
  }

  // 비밀번호 길이 유효성 검사
  void _validatePassword() {
    setState(() {
      if (passwordController.text.isEmpty) {
        _passwordError = null;
      } else if (passwordController.text.length < 8) {
        _passwordError = '비밀번호는 8자 이상이어야 합니다.';
      } else {
        _passwordError = null;
      }
    });
  }

  @override
  void dispose() {
    // 컨트롤러 및 포커스 노드 정리
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // 입력 폼 상태 업데이트
  void _updateFormState() {
    setState(() {
      _isFormValid = emailController.text.isNotEmpty &&
          emailController.text.contains('@') &&
          passwordController.text.length >= 8;
    });
  }

  // 커스텀 메시지 팝업 표시 함수
  void _showCustomMessage(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha((0.26 * 255).round()),
      builder: (BuildContext context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 아이콘 원형 박스
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSuccess 
                          ? const Color(0xFF3D02ED).withAlpha((0.1 * 255).round())
                          : Colors.red.withAlpha((0.1 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle : Icons.error,
                      color: isSuccess ? const Color(0xFF3D02ED) : Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 메시지 텍스트
                  Text(
                    message.replaceAll('이메일 또는 비밀번호가 올바르지 않습니다', '이메일 또는 비밀번호가\n올바르지 않습니다'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSuccess ? const Color(0xFF3D02ED) : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 일정 시간 후 자동 닫힘 및 성공 시 홈으로 이동
    Future.delayed(Duration(seconds: isSuccess ? 2 : 3), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
        if (isSuccess) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  // 로그인 처리 함수
  void _handleLogin() async {
    _validateEmail();
    _validatePassword();

    if (_emailError == null && _passwordError == null && _isFormValid) {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
      
      final response = await http.post(
        Uri.parse('$apiUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': emailController.text,
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // 로그인 성공 시 토큰 저장
        final data = json.decode(response.body);
        final token = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);

        if (!mounted) return;
        _showCustomMessage('로그인 성공!', true);
      } else {
        // 실패 시 에러 메시지 표시 (UTF-8 디코딩 적용)
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          _showCustomMessage(errorData['detail'] ?? '로그인 실패', false);
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
              // 제목 텍스트
              const Text(
                '이메일과 비밀번호를\n입력해주세요.',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),

              // 이메일 입력 필드
              const Text('이메일', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'sample@gmail.com',
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  errorText: _emailError,
                  errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

              const SizedBox(height: 16),

              // 비밀번호 입력 필드
              const Text('비밀번호', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
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

              // 회원가입 / 계정찾기 / 비밀번호재설정
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('회원가입', style: TextStyle(fontSize: 12)),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: const Text('계정 찾기', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {},
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
                    onPressed: () {},
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
