import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경색 (필요하면 다른 색으로 변경 가능)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40), // 화면 좌우/상하 여백
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이메일과 비밀번호를\n입력해주세요.',
                style: TextStyle(
                  fontSize: 22, // 타이틀 글씨 크기
                  fontWeight: FontWeight.bold, // 굵기
                ),
              ),
              const SizedBox(height: 32), // 타이틀 아래 여백

              // 이메일 입력창
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'sample@gmail.com', // 입력창 안의 예시 텍스트
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // 모서리 둥글기 조정
                    borderSide: const BorderSide(
                      color: Colors.grey, // 테두리 색상 (변경 가능)
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, // 내부 좌우 여백
                    vertical: 14,   // 내부 위아래 여백
                  ),
                ),
              ),

              const SizedBox(height: 16), // 이메일과 비밀번호 입력창 사이 간격

              // 비밀번호 입력창
              TextField(
                controller: passwordController,
                obscureText: true, // 비밀번호 마스킹 처리
                decoration: InputDecoration(
                  hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.grey, // 테두리 색상
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 24), // 입력창과 버튼 사이 간격

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 48, // 버튼 높이
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 로그인 로직
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300], // 버튼 배경색 (현재는 비활성화 스타일)
                    foregroundColor: Colors.white,     // 버튼 텍스트 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 둥근 버튼 모양
                    ),
                  ),
                  child: const Text('로그인'),
                ),
              ),

              const SizedBox(height: 16), // 버튼과 하단 텍스트 사이 여백

              // 하단 링크들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 가로로 균등 정렬
                children: const [
                  Text('회원가입', style: TextStyle(fontSize: 12)), // 각 항목 글씨 크기
                  Text('|', style: TextStyle(fontSize: 12)),
                  Text('자동 로그인', style: TextStyle(fontSize: 12)),
                  Text('|', style: TextStyle(fontSize: 12)),
                  Text('비밀번호 재설정', style: TextStyle(fontSize: 12)),
                ],
              ),

              const Spacer(), // 아래 카카오 버튼을 화면 하단으로 밀어내기

              // 카카오 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 카카오 로그인 연동
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE812), // 카카오톡 노란색
                    foregroundColor: Colors.black,            // 글자색 검정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/images/kakao_icon.png', // 아이콘 이미지 경로 (assets 폴더에 있어야 함)
                    height: 24,
                  ),
                  label: const Text('카카오 로그인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
