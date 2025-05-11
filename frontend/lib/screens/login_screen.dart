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
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 90), // 화면 좌우/상하 여백
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이메일과 비밀번호를\n입력해주세요.',
                style: TextStyle(
                  fontSize: 25, // 타이틀 글씨 크기
                  fontWeight: FontWeight.w900, // 굵기
                ),
              ),
              const SizedBox(height: 20), // 타이틀 아래 여백

              // 이메일 입력 라벨
              const Text(
                '이메일',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey, // 회색 글자
                  fontWeight: FontWeight.w500, // 약간 굵게
                ),
              ),
              const SizedBox(height: 6), // 라벨과 입력창 간격

              // 이메일 입력창
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'sample@gmail.com', // 입력창 안의 예시 텍스트
                  hintStyle: TextStyle(
                    fontSize: 15,           // 🔹 글자 크기 줄이기 (예: 13 또는 12)
                    color: Colors.grey[500], // 🔹 회색 약하게
                        ),
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

              const SizedBox(height: 16), // 이메일과 비밀번호 입력 라벨 사이 간격

              // 비밀번호 입력 라벨
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey, // 회색 글자
                  fontWeight: FontWeight.w500, // 약간 굵게
                ),
              ),
              const SizedBox(height: 6), // 라벨과 입력창 간격

              // 비밀번호 입력창
              TextField(
                controller: passwordController,
                obscureText: true, // 비밀번호 마스킹 처리
                decoration: InputDecoration(
                  hintText: '영문, 숫자, 특수문자 포함 8자 이상', // 입력창 안의 예시 텍스트
                  hintStyle: TextStyle(
                    fontSize: 15,           // 🔹 글자 크기 줄이기 (예: 13 또는 12)
                    color: Colors.grey[500], // 🔹 회색 약하게
                        ), 

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

              const SizedBox(height: 26), // 입력창과 버튼 사이 간격

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 48, // 버튼 높이
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 로그인 로직
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400], // 버튼 배경색 (현재는 비활성화 스타일)
                    foregroundColor: Colors.white,     // 버튼 텍스트 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 둥근 버튼 모양
                    ),
                  ),
                  child: const Text('로그인'),
                ),
              ),

              const SizedBox(height: 12), // 버튼과 하단 텍스트 사이 여백

              // 하단 링크들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '회원가입',
                    style: TextStyle(fontSize: 12),
                  ),
                  Row(
                    children: const [
                      Text('계정 찾기', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 14), // 간격 조절
                      Text('비밀번호 재설정', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 80), // 비밀번호 재설정 아래 여백

              // 카카오 로그인 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // 🔹 버튼 가운데 정렬
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 카카오 로그인 연동
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE812),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40), // 🔹 양쪽 여백 줄이기
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 🔹 살짝만 둥글게
                    ),
                  ),
                  icon: Image.asset(
                    'assets/images/kakao_icon.png',
                    height: 20, // 🔹 아이콘도 작게
                  ),
                  label: const Text(
                    '카카오 로그인',
                    style: TextStyle(
                      fontSize: 13, // 🔹 글자 작게
                      fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ), // ← Row 닫힘
            ],
          ), // ← Column 닫힘
        ), // ← Padding 닫힘
      ), // ← SafeArea 닫힘
    ); // ← Scaffold 닫힘
  }
}