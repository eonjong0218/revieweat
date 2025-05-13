import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isFormValid = false;
  
  // 포커스 노드 추가
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  // 오류 메시지 상태 관리
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // 텍스트 필드 변경 감지하여 버튼 활성화 상태 업데이트
    emailController.addListener(() {
      _updateFormState();
      _validateEmail();
    });
    
    passwordController.addListener(() {
      _updateFormState();
      _validatePassword();
    });
    
    // 포커스 리스너 추가
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && emailController.text.isNotEmpty) {
        _validateEmail();
      }
    });
    
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && passwordController.text.isNotEmpty) {
        _validatePassword();
      }
    });
  }

  // 이메일 유효성 검사 함수
  void _validateEmail() {
    setState(() {
      if (emailController.text.isEmpty) {
        _emailError = null;
        if (kDebugMode) {
          print("이메일 필드 비어있음: 오류 메시지 없음");
        }
      } else if (!emailController.text.contains('@')) {
        _emailError = '이메일 형식이 올바르지 않습니다.';
        if (kDebugMode) {
          print("이메일 형식 오류: $_emailError");
        }
      } else {
        _emailError = null;
        if (kDebugMode) {
          print("이메일 유효함: 오류 메시지 없음");
        }
      }
    });
  }

  // 비밀번호 유효성 검사 함수
  void _validatePassword() {
    setState(() {
      if (passwordController.text.isEmpty) {
        _passwordError = null;
        if (kDebugMode) {
          print("비밀번호 필드 비어있음: 오류 메시지 없음");
        }
      } else if (passwordController.text.length < 8) {
        _passwordError = '비밀번호는 8자 이상이어야 합니다.';
        if (kDebugMode) {
          print("비밀번호 길이 오류: $_passwordError");
        }
      } else {
        _passwordError = null;
        if (kDebugMode) {
          print("비밀번호 유효함: 오류 메시지 없음");
        }
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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

  // 로그인 처리 함수
  void _handleLogin() {
    // 유효성 검사
    _validateEmail();
    _validatePassword();
    
    if (_emailError == null && _passwordError == null && _isFormValid) {
      // 유효성 검사 통과 시 동작
      if (kDebugMode) {
        print('로그인 성공: ${emailController.text}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 성공!'),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 2),
        ),
      );
      
      // 로그인 성공 후 홈 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
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
              const Text(
                '이메일과 비밀번호를\n입력해주세요.',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),

              const Text(
                '이메일',
                style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
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
                ),
              ),
              // 이메일 오류 메시지
              if (_emailError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                  child: Text(
                    _emailError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              const Text(
                '비밀번호',
                style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),

              // 비밀번호 입력 필드
              TextField(
                controller: passwordController,
                focusNode: _passwordFocusNode,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              // 비밀번호 오류 메시지
              if (_passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                  child: Text(
                    _passwordError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 26),

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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // 카카오 로그인 처리 후 홈 화면으로 이동
                      Navigator.pushReplacementNamed(context, '/home');
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
