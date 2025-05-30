import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

// 리뷰 등록 성공 화면 StatefulWidget
class ReviewSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  final DateTime selectedDate;
  final String selectedRating;
  final String selectedCompanion;
  final String reviewText;
  final List<File> images;

  const ReviewSuccessScreen({
    super.key,
    required this.place,
    required this.selectedDate,
    required this.selectedRating,
    required this.selectedCompanion,
    required this.reviewText,
    required this.images,
  });

  @override
  State<ReviewSuccessScreen> createState() => _ReviewSuccessScreenState();
}

class _ReviewSuccessScreenState extends State<ReviewSuccessScreen> {
  Timer? _timer; // 자동 이동 타이머
  int _remainingSeconds = 5; // 남은 초

  @override
  void initState() {
    super.initState();
    _startCountdown(); // 타이머 시작
  }

  // 10초 뒤 자동 홈 이동 타이머 시작
  void _startCountdown() {
    const oneSecond = Duration(seconds: 1);
    _timer = Timer.periodic(oneSecond, (Timer timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          _navigateToHome(); // 타이머 종료 시 홈으로 이동
        }
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 해제
    super.dispose();
  }

  // 홈 화면으로 이동
  void _navigateToHome() {
    _timer?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
        settings: const RouteSettings(name: '/home'),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            // X 아이콘 (즉시 홈 이동)
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87, size: 24),
                onPressed: _navigateToHome,
              ),
            ),
            // 메인 콘텐츠
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSuccessHeader(), // 상단 완료 메시지 및 타이머
                  const SizedBox(height: 32),
                  _buildReviewCard(), // 등록한 리뷰 카드
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 완료 메시지 및 타이머 표시
  Widget _buildSuccessHeader() {
    return Center(
      child: Column(
        children: [
          // 체크 아이콘 원
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3), // 변경된 부분
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '리뷰 등록 완료!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          // 10초 뒤 홈 이동 안내
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              children: [
                TextSpan(
                  text: '$_remainingSeconds',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                const TextSpan(text: '초 뒤 홈화면으로 이동합니다'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 등록한 리뷰 카드 UI
  Widget _buildReviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), // 변경된 부분
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlaceInfo(), // 장소명, 주소
            const SizedBox(height: 20),
            _buildMetaInfo(), // 날짜, 평점, 동반자
            const SizedBox(height: 24),
            _buildImages(), // 첨부 사진
            const SizedBox(height: 24),
            _buildReviewText(), // 리뷰 내용
          ],
        ),
      ),
    );
  }

  // 장소명, 주소 표시
  Widget _buildPlaceInfo() {
    final name = widget.place['name'] ?? '';
    final address = widget.place['formatted_address'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          address,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 날짜, 평점, 동반자 정보 표시
  Widget _buildMetaInfo() {
    final date = DateFormat('yyyy.MM.dd').format(widget.selectedDate);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildMetaItem(
          Icons.calendar_today_rounded,
          date,
          Colors.blue[600]!,
        ),
        const SizedBox(width: 24),
        _buildMetaItem(
          Icons.star_rounded,
          widget.selectedRating,
          Colors.amber[600]!,
        ),
        const SizedBox(width: 24),
        _buildMetaItem(
          Icons.group_rounded,
          widget.selectedCompanion,
          Colors.purple[600]!,
        ),
      ],
    );
  }

  // 개별 메타 정보 아이템
  Widget _buildMetaItem(IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 첨부된 사진 리스트 표시
  Widget _buildImages() {
    final hasImages = widget.images.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 18,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              '첨부된 사진',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: hasImages
              // 사진 있을 때: 가로 스크롤 이미지
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            widget.images[index],
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                )
              // 사진 없을 때: 안내 메시지
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '첨부된 사진이 없습니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // 작성한 리뷰 텍스트 표시
  Widget _buildReviewText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 18,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              '작성한 리뷰',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            widget.reviewText.isNotEmpty ? widget.reviewText : '작성된 리뷰가 없습니다.',
            style: TextStyle(
              fontSize: 15,
              color: widget.reviewText.isNotEmpty ? Colors.black87 : Colors.grey[500],
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
