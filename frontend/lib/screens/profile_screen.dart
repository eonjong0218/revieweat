import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'review_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Logger _logger = Logger();

  int _selectedIndex = 2;
  DateTime? selectedDate;
  String? selectedRating;
  String? selectedCompanion;

  // 프로필 및 리뷰 데이터
  String? _username;
  int _reviewCount = 0;
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  static const List<String> ratingOptions = [
    '★☆☆☆☆', '★★☆☆☆', '★★★☆☆', '★★★★☆', '★★★★★'
  ];
  static const List<String> companionOptions = [
    '혼자', '친구', '연인', '가족', '기타'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileAndReviews();
  }

  Future<void> _fetchProfileAndReviews() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. 사용자 정보 요청
      final userRes = await http.get(
        Uri.parse('$apiUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      String? username;
      if (userRes.statusCode == 200) {
        final data = json.decode(utf8.decode(userRes.bodyBytes));
        username = data['username'] ?? '';
      }

      // 2. 내 리뷰 목록 요청
      final reviewRes = await http.get(
        Uri.parse('$apiUrl/my-reviews'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      List<dynamic> reviews = [];
      if (reviewRes.statusCode == 200) {
        reviews = json.decode(utf8.decode(reviewRes.bodyBytes));
      }

      setState(() {
        _username = username;
        _reviews = reviews;
        _reviewCount = reviews.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 이미지 URL 생성 함수 추가
  String _getImageUrl(String imagePath) {
    final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    
    // 이미 완전한 URL인 경우
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // uploads/ 경로가 포함되어 있는 경우
    if (imagePath.startsWith('uploads/')) {
      return '$baseUrl/$imagePath';
    }
    
    // 파일명만 있는 경우
    return '$baseUrl/uploads/${imagePath.split('/').last}';
  }

  // 날짜 선택 모달 표시
  Future<void> _showDatePickerModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Localizations(
          locale: const Locale('ko', 'KR'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SfDateRangePickerTheme(
              data: SfDateRangePickerThemeData(
                backgroundColor: Colors.white,
                headerBackgroundColor: Colors.white,
                viewHeaderBackgroundColor: Colors.white,
                selectionColor: Colors.black,
                selectionTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                todayHighlightColor: Colors.grey[800],
                todayTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                cellTextStyle: const TextStyle(color: Colors.black87),
                rangeSelectionColor: Colors.grey[300],
                headerTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                viewHeaderTextStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                leadingDatesTextStyle: const TextStyle(color: Colors.grey),
                trailingDatesTextStyle: const TextStyle(color: Colors.grey),
                disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                disabledCellTextStyle: const TextStyle(color: Colors.grey),
                weekendDatesTextStyle: const TextStyle(color: Colors.grey),
              ),
              child: SfDateRangePicker(
                selectionMode: DateRangePickerSelectionMode.single,
                initialSelectedDate: selectedDate,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is DateTime) {
                    setState(() {
                      selectedDate = args.value;
                    });
                    Navigator.pop(context);
                  }
                },
                showActionButtons: false,
              ),
            ),
          ),
        );
      },
    );
  }

  // 평점 선택 모달 표시
  Future<void> _showRatingModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '평점 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...ratingOptions.map((rating) => ListTile(
                title: Text(rating),
                onTap: () {
                  setState(() {
                    selectedRating = rating;
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  // 동반인 선택 모달 표시
  Future<void> _showCompanionModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '동반인 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...companionOptions.map((companion) => ListTile(
                title: Text(companion),
                onTap: () {
                  setState(() {
                    selectedCompanion = companion;
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 40),
                  _buildProfileHeader(),
                  _buildFilterChips(),
                  Expanded(
                    child: _buildMyReviews(),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/review_place_search');
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.edit_square, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 64,
        color: Colors.white,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, '홈', 0),
            _buildNavItem(Icons.event_rounded, '달력', 1),
            const SizedBox(width: 48),
            _buildNavItem(Icons.person_rounded, '프로필', 2),
            _buildNavItem(Icons.settings_rounded, '환경설정', 3),
          ],
        ),
      ),
    );
  }

  // 프로필 헤더 UI (파란색 그라데이션으로 변경)
  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF2196F3)], // 파란색 그라데이션
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3), // 파란색 그림자
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username ?? 'User name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_reviewCount Posts',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 필터 칩 UI (기존과 동일)
  Widget _buildFilterChips() {
    final filters = ['날짜', '장소', '동반여부', '평점', '찜'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters
            .map((filter) => _buildFilterChip(filter))
            .toList(),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool hasSelection = false;
    if (label == '날짜' && selectedDate != null) hasSelection = true;
    if (label == '평점' && selectedRating != null) hasSelection = true;
    if (label == '동반여부' && selectedCompanion != null) hasSelection = true;

    return GestureDetector(
      onTap: () {
        if (hasSelection) {
          setState(() {
            if (label == '날짜') selectedDate = null;
            if (label == '평점') selectedRating = null;
            if (label == '동반여부') selectedCompanion = null;
          });
        } else {
          if (label == '날짜') {
            _showDatePickerModal(context);
          } else if (label == '평점') {
            _showRatingModal(context);
          } else if (label == '동반여부') {
            _showCompanionModal(context);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getDisplayText(label),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            if (label != '찜') ...[
              const SizedBox(width: 2),
              Icon(
                label == '장소' 
                    ? Icons.search 
                    : hasSelection 
                        ? Icons.close 
                        : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: Colors.grey[600],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDisplayText(String label) {
    switch (label) {
      case '날짜':
        return selectedDate != null 
            ? DateFormat('yyyy.MM.dd').format(selectedDate!)
            : '날짜';
      case '평점':
        return selectedRating ?? '평점';
      case '동반여부':
        return selectedCompanion ?? '동반여부';
      default:
        return label;
    }
  }

  // 내 리뷰 리스트: print 문을 logger로 교체
  Widget _buildMyReviews() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reviews.isEmpty) {
      return Center(
        child: Text(
          '작성한 리뷰가 없습니다.',
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          
          // 이미지 경로 파싱 및 서버 URL 처리 개선
          List<String> imagePaths = [];
          if (review['image_paths'] != null && review['image_paths'].toString().isNotEmpty) {
            final rawPaths = review['image_paths'].toString().split(',')
                .where((path) => path.trim().isNotEmpty)
                .toList();
            
            // 서버 URL과 결합하여 완전한 이미지 URL 생성
            imagePaths = rawPaths.map((path) => _getImageUrl(path.trim())).toList();
          }
          
          // 별점 안전하게 파싱
          int rating = 0;
          if (review['rating'] != null) {
            final ratingStr = review['rating'].toString();
            if (ratingStr.isNotEmpty) {
              // "★★★★★" 형태나 "5" 형태 모두 처리
              if (ratingStr.contains('★')) {
                rating = ratingStr.split('★').length - 1;
              } else {
                rating = int.tryParse(ratingStr) ?? 0;
              }
            }
          }
          
          // GestureDetector로 탭 기능 추가
          return GestureDetector(
            onTap: () {
              // 리뷰 상세 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewDetailScreen(review: review),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이미지 또는 아이콘 표시 (서버 이미지 처리 개선)
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: imagePaths.isNotEmpty ? Colors.transparent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: imagePaths.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imagePaths.first, // 첫 번째 이미지를 대표 이미지로 사용
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    // print 문을 logger.e로 교체
                                    _logger.e('이미지 로드 실패: ${imagePaths.first}\n에러: $error');
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[400]!),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[600],
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '이미지 로드 실패',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.restaurant_rounded,
                                color: Colors.grey[600],
                                size: 32,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 장소명과 날짜를 한 줄에 배치
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    review['place_name'] ?? '장소명 없음',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    // 줄바꿈을 허용하여 전체 장소명 표시
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 리뷰 날짜 (년도, 월, 일 모두 표시)
                                Text(
                                  review['review_date'] != null
                                      ? DateFormat('yyyy.MM.dd').format(DateTime.parse(review['review_date']))
                                      : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            // 장소 주소 (줄바꿈해서라도 다 보이게)
                            if (review['place_address'] != null && review['place_address'].toString().isNotEmpty)
                              Text(
                                review['place_address'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                // maxLines와 overflow 제거하여 전체 주소 표시
                              ),
                            const SizedBox(height: 6),
                            
                            // 동반인과 별점을 나란히 배치 (동반인 아이콘 보라색으로 변경)
                            Row(
                              children: [
                                // 동반인 정보 (아이콘 색상 보라색으로 변경)
                                if (review['companion'] != null && review['companion'].toString().isNotEmpty) ...[
                                  Icon(
                                    Icons.people_outline,
                                    size: 14,
                                    color: Colors.purple, // 보라색으로 변경
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${review['companion']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                
                                // 별점 표시
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: i < rating ? Colors.amber : Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 리뷰 내용 (2줄까지만 표시)
                  if (review['review_text'] != null && review['review_text'].toString().isNotEmpty)
                    Text(
                      review['review_text'],
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  // 이미지 개수 표시 부분 제거됨
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/홈');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/달력');
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/환경설정');
        break;
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.only(top: 2),
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.grey, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
