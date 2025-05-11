import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
// register_screen.dart import는 직접 RegisterScreen을 참조할 때만 필요합니다

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // 폼 유효성 검사용 키
  final emailController = TextEditingController(); // 이메일 입력 컨트롤러
  final passwordController = TextEditingController(); // 비밀번호 입력 컨트롤러
  bool _isFormValid = false; // 폼 유효성 상태 추적

  @override
  void initState() {
    super.initState();
    // 텍스트 필드 변경 감지하여 버튼 활성화 상태 업데이트
    emailController.addListener(_updateFormState);
    passwordController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    emailController.dispose();
    passwordController.dispose();
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
    if (_formKey.currentState!.validate()) {
      // 유효성 검사 통과 시 동작
      // 실제 앱에서는 여기에 로그인 API 호출 코드가 들어갑니다
      if (kDebugMode) {
        // 디버그 모드에서만 로그 출력
        print('로그인 성공: ${emailController.text}');
      }
      
      // 로그인 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 성공!'),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 2),
        ),
      );
      
      // 로그인 후 홈 화면으로 이동 (실제 앱에서 구현)
      // Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 90),
          child: Form(
            key: _formKey,
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
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),

                // 이메일 입력 필드
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'sample@gmail.com',
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    errorStyle: const TextStyle(height: 0.8),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요.';
                    }
                    if (!value.contains('@')) {
                      return '이메일 형식이 올바르지 않습니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 라벨
                const Text(
                  '비밀번호',
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),

                // 비밀번호 입력 필드
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    errorStyle: const TextStyle(height: 0.8),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }
                    if (value.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 26),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? _handleLogin : null, // 폼 유효성에 따라 활성화/비활성화
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid ? Colors.black : Colors.white,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      disabledBackgroundColor: Colors.grey[300],
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
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
