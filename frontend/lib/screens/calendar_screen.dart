import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // ==================== 상태 변수 ====================
  int _selectedIndex = 1;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ==================== 초기화 ====================
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  // ==================== 유틸리티 함수 ====================
  /// 두 날짜가 같은 날인지 확인
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 날짜 배경색 결정 (오늘 날짜 조건 제거)
  Color _getDateColor(bool isToday, bool isSelected) {
    if (isSelected) return Colors.lightBlue[500]!;
    // 오늘 날짜 조건 제거 - 파란 동그라미 없음
    return Colors.transparent;
  }

  /// 날짜 텍스트 색상 결정 (오늘 날짜 조건 제거)
  Color _getDateTextColor(bool isToday, bool isSelected) {
    if (isSelected) return Colors.white;
    // 오늘 날짜도 일반 텍스트 색상으로 표시
    return Colors.black87;
  }

  // ==================== 메인 빌드 ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildMainCalendar(),
              _buildPastCalendars(),
            ],
          ),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==================== 메인 달력 ====================
  /// 현재 포커스된 달의 메인 달력
  Widget _buildMainCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          _buildCalendarHeader(),
          _buildWeekdayHeader(),
          _buildDateGrid(_focusedDay),
        ],
      ),
    );
  }

  /// 달력 헤더 (년월 표시 및 네비게이션)
  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left, size: 24),
          ),
          Text(
            DateFormat('yyyy년 MM월').format(_focusedDay),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right, size: 24),
          ),
        ],
      ),
    );
  }

  /// 요일 헤더 (일~토)
  Widget _buildWeekdayHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: weekdays.map((weekday) => Expanded(
          child: Center(
            child: Text(
              weekday,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  /// 날짜 그리드 생성
  Widget _buildDateGrid(DateTime month) {
    DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    DateTime lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    
    int firstWeekday = firstDayOfMonth.weekday % 7;
    int daysInMonth = lastDayOfMonth.day;
    
    List<Widget> dateWidgets = [];
    
    // 이전 달의 빈 칸들
    for (int i = 0; i < firstWeekday; i++) {
      dateWidgets.add(const SizedBox());
    }
    
    // 현재 달의 날짜들
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDate = DateTime(month.year, month.month, day);
      bool isToday = _isSameDay(currentDate, DateTime.now());
      bool isSelected = _isSameDay(currentDate, _selectedDay);
      
      dateWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = currentDate;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _getDateColor(isToday, isSelected),
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: _getDateTextColor(isToday, isSelected),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: dateWidgets,
      ),
    );
  }

  // ==================== 과거 달력들 ====================
  /// 과거 20개월의 달력 목록 생성
  Widget _buildPastCalendars() {
    List<Widget> calendars = [];
    DateTime currentMonth = DateTime(_focusedDay.year, _focusedDay.month - 1);
    
    // 과거 20개월 달력 생성 (제한)
    for (int i = 0; i < 20; i++) {
      DateTime pastMonth = DateTime(currentMonth.year, currentMonth.month - i, 1);
      calendars.add(_buildSmallCalendar(pastMonth));
    }
    
    return Column(children: calendars);
  }

  /// 작은 달력 위젯 생성
  Widget _buildSmallCalendar(DateTime month) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSmallCalendarHeader(month),
          _buildSmallWeekdayHeader(),
          _buildSmallDateGrid(month),
        ],
      ),
    );
  }

  /// 작은 달력의 헤더 (년월 표시)
  Widget _buildSmallCalendarHeader(DateTime month) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        DateFormat('yyyy년 MM월').format(month),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// 작은 달력의 요일 헤더
  Widget _buildSmallWeekdayHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: weekdays.map((weekday) => Expanded(
          child: Center(
            child: Text(
              weekday,
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  /// 작은 달력의 날짜 그리드
  Widget _buildSmallDateGrid(DateTime month) {
    DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    DateTime lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    
    int firstWeekday = firstDayOfMonth.weekday % 7;
    int daysInMonth = lastDayOfMonth.day;
    
    List<Widget> dateWidgets = [];
    
    // 이전 달의 빈 칸들
    for (int i = 0; i < firstWeekday; i++) {
      dateWidgets.add(const SizedBox());
    }
    
    // 현재 달의 날짜들
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDate = DateTime(month.year, month.month, day);
      bool isSelected = _isSameDay(currentDate, _selectedDay);
      
      dateWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = currentDate;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.lightBlue[400] 
                  : Colors.transparent, // 오늘 날짜 조건 제거
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : Colors.black87, // 오늘 날짜도 일반 색상
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: dateWidgets,
      ),
    );
  }

  // ==================== 하단 네비게이션 ====================
  /// 하단 네비게이션 바
  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
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
          const SizedBox(width: 48), // FAB 공간
          _buildNavItem(Icons.person_rounded, '프로필', 2),
          _buildNavItem(Icons.settings_rounded, '환경설정', 3),
        ],
      ),
    );
  }

  /// 네비게이션 아이템 생성
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

  // ==================== 이벤트 핸들러 ====================
  /// 네비게이션 아이템 탭 처리
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/홈');
        break;
      case 1:
        // 현재 페이지 (달력)
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/프로필');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/환경설정');
        break;
    }
  }
}
