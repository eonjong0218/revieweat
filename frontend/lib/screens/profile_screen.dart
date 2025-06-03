import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// 프로필 화면 StatefulWidget
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 하단 네비게이션 인덱스 (Profile이 기본 선택)
  int _selectedIndex = 2;
  // 필터: 선택된 날짜, 평점, 동반인
  DateTime? selectedDate;
  String? selectedRating;
  String? selectedCompanion;

  // 평점, 동반인 옵션 리스트
  static const List<String> ratingOptions = [
    '★☆☆☆☆', '★★☆☆☆', '★★★☆☆', '★★★★☆', '★★★★★'
  ];
  static const List<String> companionOptions = [
    '혼자', '친구', '연인', '가족', '기타'
  ];

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
              // 평점 옵션 리스트
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
              // 동반인 옵션 리스트
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
        child: Column(
          children: [
            // 상단 여백만 추가
            const SizedBox(height: 40),
            _buildProfileHeader(),
            _buildFilterChips(),
            Expanded(
              child: _buildMyReviews(),
            ),
          ],
        ),
      ),
      // 리뷰 작성 플로팅 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/review_place_search');
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // 하단 네비게이션 바
      bottomNavigationBar: BottomAppBar(
        height: 64,
        color: Colors.white,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.event_rounded, 'History', 1),
            const SizedBox(width: 48),
            _buildNavItem(Icons.person_rounded, 'Profile', 2),
            _buildNavItem(Icons.settings_rounded, 'Settings', 3),
          ],
        ),
      ),
    );
  }

  // 프로필 헤더 UI
  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.black87, Colors.black54],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
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
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User name',
                  style: TextStyle(
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
                  child: const Text(
                    '234 Posts',
                    style: TextStyle(
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

  // 필터 칩(날짜, 장소, 동반여부, 평점, 찜) UI
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

  // 개별 필터 칩 위젯
  Widget _buildFilterChip(String label) {
    bool hasSelection = false;
    if (label == '날짜' && selectedDate != null) hasSelection = true;
    if (label == '평점' && selectedRating != null) hasSelection = true;
    if (label == '동반여부' && selectedCompanion != null) hasSelection = true;

    return GestureDetector(
      onTap: () {
        if (hasSelection) {
          // X 아이콘 클릭: 선택 해제
          setState(() {
            if (label == '날짜') selectedDate = null;
            if (label == '평점') selectedRating = null;
            if (label == '동반여부') selectedCompanion = null;
          });
        } else {
          // 필터 선택 모달 표시
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

  // 필터 칩에 표시될 텍스트 반환
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

  // 내 리뷰 리스트 빌드
  Widget _buildMyReviews() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '맛집 리뷰 #${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(5, (i) => Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: i < 4 ? Colors.amber : Colors.grey[300],
                              )),
                              const SizedBox(width: 8),
                              Text(
                                '2024.05.${20 + index}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 하단 네비게이션 아이템 클릭 시 동작
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
        // 현재 화면 (Profile)
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  // 하단 네비게이션 아이템 UI
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
