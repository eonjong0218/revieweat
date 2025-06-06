import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReviewDetailScreen extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewDetailScreen({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    // 이미지 경로 파싱 및 서버 URL 처리
    List<String> imagePaths = [];
    if (review['image_paths'] != null && review['image_paths'].toString().isNotEmpty) {
      final rawPaths = review['image_paths'].toString().split(',')
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
    if (review['rating'] != null) {
      final ratingStr = review['rating'].toString();
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
        child: Column(
          children: [
            // 상단 헤더 (X 버튼)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
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
                ],
              ),
            ),

            // 스크롤 가능한 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 장소 정보 섹션
                    _buildInfoSection(
                      review['place_name'] ?? '장소명 없음',
                      review['place_address'] ?? '',
                      review['review_date'] != null
                          ? DateFormat('yyyy.MM.dd').format(DateTime.parse(review['review_date']))
                          : '',
                      rating.toString(),
                      review['companion'] ?? '',
                    ),
                    const SizedBox(height: 32),

                    // 이미지 섹션 (매우 크게)
                    if (imagePaths.isNotEmpty) ...[
                      _buildImageSection(imagePaths),
                      const SizedBox(height: 32),
                    ],

                    // 리뷰 텍스트
                    _buildReviewText(),
                    const SizedBox(height: 40),
                  ],
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
          const SizedBox(height: 8),
          if (address.isNotEmpty)
            Text(address, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 날짜
              if (date.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.lightBlue),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              // 별점 (별 아이콘으로 표시)
              Row(
                children: [
                  const Icon(Icons.star_border, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
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
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 4),
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

  // 이미지 섹션 위젯 (서버 이미지 URL 처리 개선)
  Widget _buildImageSection(List<String> imagePaths) {
    if (imagePaths.length == 1) {
      // 이미지가 하나인 경우
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imagePaths.first,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 300,
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
            print('이미지 로드 실패: ${imagePaths.first}, 에러: $error');
            return Container(
              width: double.infinity,
              height: 300,
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
                  const SizedBox(height: 8),
                  Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    imagePaths.first,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // 이미지가 여러 개인 경우
      return Column(
        children: [
          // 메인 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imagePaths.first,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 300,
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
                return Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 추가 이미지들 (썸네일)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length - 1,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imagePaths[index + 1],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            size: 24,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  // 리뷰 텍스트 위젯
  Widget _buildReviewText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '리뷰',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        if (review['review_text'] != null && review['review_text'].toString().isNotEmpty)
          Text(
            review['review_text'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          )
        else
          Text(
            '작성된 리뷰가 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}
