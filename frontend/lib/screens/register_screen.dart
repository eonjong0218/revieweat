import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 입력 필드 컨트롤러 선언
  final emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 유효성 검사 에러 메시지 변수
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;

  // 로딩 상태 및 기타 상태 변수
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;           // 비밀번호 숨김 여부
  bool _obscureConfirmPassword = true;    // 비밀번호 확인 숨김 여부
  bool _isFormValid = false;               // 전체 폼 유효성 상태

  @override
  void initState() {
    super.initState();
    // 입력값 변경 리스너 등록: 각 필드 유효성 검사 및 상태 업데이트
    emailController.addListener(_validateEmail);
    _usernameController.addListener(_updateFormState);
    passwordController.addListener(() {
      _validatePassword();
      _validateConfirmPassword();
    });
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    emailController.dispose();
    _usernameController.dispose();
    passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 전체 폼 상태 갱신: 모든 필드가 유효하면 true
  void _updateFormState() {
    final isValid = emailController.text.isNotEmpty &&
        _usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _emailError == null;

    setState(() {
      _isFormValid = isValid;
    });
  }

  // 이메일 유효성 검사: '@' 포함 여부 확인
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
    _updateFormState();
  }

  // 비밀번호 유효성 검사: 최소 8자 이상인지 확인
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
    _updateFormState();
  }
  
  // 비밀번호 확인 필드 유효성 검사: 비밀번호와 일치 여부 확인
  void _validateConfirmPassword() {
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = null;
      } else if (_confirmPasswordController.text != passwordController.text) {
        _confirmPasswordError = '비밀번호가 일치하지 않습니다';
      } else {
        _confirmPasswordError = null;
      }
    });
    _updateFormState();
  }

  // 커스텀 오버레이 메시지 표시 및 성공 시 로그인 화면으로 이동
  void _showCustomMessage(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false, // 사용자가 임의로 닫지 못하도록 설정
      barrierColor: Colors.black26,
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
                    color: Colors.black.withAlpha((0.1 * 255).round()),  // withOpacity 대체
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D02ED).withAlpha((0.1 * 255).round()),  // withOpacity 대체
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF3D02ED),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D02ED),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 2초 후 다이얼로그 닫고 로그인 화면으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); // 다이얼로그 닫기
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  // 서버에 회원가입 요청 보내기
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;       // 로딩 시작
        _errorMessage = null;    // 에러 초기화
        _emailError = null;
        _usernameError = null;
      });

      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

      final response = await http.post(
        Uri.parse('$apiUrl/register'), // 서버 URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text,
          'username': _usernameController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        // 회원가입 성공 메시지 띄우기 및 로그인 화면으로 이동
        _showCustomMessage('회원가입 성공!', true);

      } else {
        // 실패 시 서버에서 받은 에러 메시지 파싱 및 화면에 표시
        final errorData = json.decode(response.body);
        final detail = errorData['detail'] ?? '회원가입에 실패했습니다.';

        setState(() {
          if (detail.contains('이메일')) {
            _emailError = detail;
          } else if (detail.contains('사용자 이름')) {
            _usernameError = detail;
          } else {
            _errorMessage = detail;
          }
        });
      }

      setState(() {
        _isLoading = false;  // 로딩 종료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 80),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 회원가입 타이틀
                  const Text(
                    '회원가입',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),

                  // 로그인 화면으로 이동 안내
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '이미 계정이 있으신가요?',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('여기로 ', style: TextStyle(fontSize: 14)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              '로그인하세요!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 61, 2, 237),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 이메일 입력 필드
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration('Enter Email').copyWith(
                      errorText: _emailError,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (_emailError != null) return _emailError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 사용자명 입력 필드
                  TextFormField(
                    controller: _usernameController,
                    decoration: _buildInputDecoration('Create User name').copyWith(
                      errorText: _usernameError,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '사용자 이름을 입력해주세요';
                      }
                      if (_usernameError != null) return _usernameError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력 필드
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: _buildPasswordInputDecoration('Password', _obscurePassword, () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    }).copyWith(
                      errorText: _passwordError,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (_passwordError != null) return _passwordError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 확인 입력 필드
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: _buildPasswordInputDecoration('Confirm Password', _obscureConfirmPassword, () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    }).copyWith(
                      errorText: _confirmPasswordError,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호 확인을 입력해주세요';
                      }
                      if (_confirmPasswordError != null) return _confirmPasswordError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 서버 에러 메시지 출력
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),

                  // 회원가입 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_isLoading ? _register : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('등록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 기본 입력 필드 데코레이션
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // 비밀번호 입력 필드 데코레이션 (보이기/숨기기 버튼 포함)
  InputDecoration _buildPasswordInputDecoration(String hint, bool obscure, VoidCallback toggle) {
    return _buildInputDecoration(hint).copyWith(
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
        onPressed: toggle,
      ),
    );
  }
}
