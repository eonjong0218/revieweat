import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReviewDetailScreen extends StatefulWidget {
  final Map<String, dynamic> review;

  const ReviewDetailScreen({
    super.key,
    required this.review,
  });

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  final PageController _pageController = PageController(); // final 추가
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이미지 경로 파싱 및 서버 URL 처리
    List<String> imagePaths = [];
    if (widget.review['image_paths'] != null && widget.review['image_paths'].toString().isNotEmpty) {
      final rawPaths = widget.review['image_paths'].toString().split(',')
          .where((path) => path.trim().isNotEmpty)
          .toList();
      
      // 서버 URL과 결합하여 완전한 이미지 URL 생성
      final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
      imagePaths = rawPaths.map((path) {
        // 경로가 이미 완전한 URL인지 확인
        if (path.startsWith('http')) {
          return path;
        }
        // uploads/ 경로가 포함되어 있는지 확인
        if (path.startsWith('uploads/')) {
          return '$baseUrl/$path';
        }
        // 파일명만 있는 경우
        return '$baseUrl/uploads/${path.split('/').last}';
      }).toList();
    }

    // 별점 파싱
    int rating = 0;
    if (widget.review['rating'] != null) {
      final ratingStr = widget.review['rating'].toString();
      if (ratingStr.isNotEmpty) {
        if (ratingStr.contains('★')) {
          rating = ratingStr.split('★').length - 1;
        } else {
          rating = int.tryParse(ratingStr) ?? 0;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 컨텐츠
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24), // 상단 패딩 증가
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 장소 정보 섹션 (위로 이동)
                  _buildInfoSection(
                    widget.review['place_name'] ?? '장소명 없음',
                    widget.review['place_address'] ?? '',
                    widget.review['review_date'] != null
                        ? DateFormat('yyyy.MM.dd').format(DateTime.parse(widget.review['review_date']))
                        : '',
                    rating.toString(),
                    widget.review['companion'] ?? '',
                  ),
                  const SizedBox(height: 10), // Container → SizedBox

                  // 이미지 섹션 (스와이프 가능)
                  if (imagePaths.isNotEmpty) ...[
                    _buildSwipeableImageSection(imagePaths),
                    const SizedBox(height: 24), // Container → SizedBox
                  ],

                  // 리뷰 텍스트 (배경 추가)
                  _buildReviewText(),
                  const SizedBox(height: 40), // Container → SizedBox
                ],
              ),
            ),

            // 상단 X 버튼 (위치 고정)
            Positioned(
              top: 30,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black54,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 장소, 날짜, 평점, 동반자 정보 표시 영역
  Widget _buildInfoSection(
      String name, String address, String date, String rating, String companion) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8), // Container → SizedBox
          if (address.isNotEmpty)
            Text(address, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16), // Container → SizedBox
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 날짜
              if (date.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.lightBlue),
                    const SizedBox(width: 4), // Container → SizedBox
                    Text(date, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 16), // Container → SizedBox
              ],
              // 별점 (별 아이콘으로 표시)
              Row(
                children: [
                  const Icon(Icons.star_border, size: 18, color: Colors.amber),
                  const SizedBox(width: 4), // Container → SizedBox
                  // 별점을 별 아이콘으로 표시
                  ...List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 16,
                      color: i < (int.tryParse(rating) ?? 0) ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                ],
              ),
              // 동반인
              if (companion.isNotEmpty) ...[
                const SizedBox(width: 16), // Container → SizedBox
                Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 18, color: Colors.purple),
                    const SizedBox(width: 4), // Container → SizedBox
                    Text(companion, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 스와이프 가능한 이미지 섹션
  Widget _buildSwipeableImageSection(List<String> imagePaths) {
    return Column(
      children: [
        // 메인 이미지 (스와이프 가능)
        SizedBox( // Container → SizedBox
          height: 300,
          width: double.infinity,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: imagePaths.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      imagePaths[index],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // print 문 제거 (debugPrint 사용)
                        debugPrint('이미지 로드 실패: ${imagePaths[index]}, 에러: $error');
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8), // Container → SizedBox
                              Text(
                                '이미지를 불러올 수 없습니다',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 이미지 인디케이터 (여러 장인 경우만 표시)
              if (imagePaths.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imagePaths.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),

              // 페이지 번호 표시 (여러 장인 경우만)
              if (imagePaths.length > 1)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${imagePaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 리뷰 텍스트 위젯 (배경 추가)
  Widget _buildReviewText() {
    return Container(
      width: double.infinity, // 사진 크기와 같은 가로 폭
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50], // 매우 옅은 회색 배경
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: widget.review['review_text'] != null && widget.review['review_text'].toString().isNotEmpty
          ? Text(
              widget.review['review_text'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            )
          : Text(
              '작성된 리뷰가 없습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }
}
