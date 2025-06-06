import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'search_screen.dart';
import 'review_place_search_screen.dart';
import 'profile_screen.dart';
import 'search_result_screen.dart';

/// 홈 화면 StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  bool _mapControllerReady = false;

  // 초기 위치 (부산대학교)
  LatLng _initialPosition = const LatLng(35.3350, 129.0089);

  // 지도 마커 모음
  final Set<Marker> _markers = {};

  // 현재 선택된 하단 네비게이션 인덱스
  int _selectedIndex = 0;

  // 음식 관련 카테고리 목록 (아이콘과 색상 개선)
  static const List<Map<String, dynamic>> _foodCategories = [
    {
      'name': '한식',
      'icon': Icons.rice_bowl,
      'color': Color(0xFF4285F4),
      'types': ['korean_restaurant', 'restaurant'],
      'keywords': '한식 한국음식 김치찌개 불고기 비빔밥'
    },
    {
      'name': '중식',
      'icon': Icons.ramen_dining,
      'color': Color(0xFFEA4335),
      'types': ['chinese_restaurant', 'restaurant'],
      'keywords': '중식 중국음식 짜장면 짬뽕 탕수육'
    },
    {
      'name': '일식',
      'icon': Icons.set_meal,
      'color': Color(0xFF34A853),
      'types': ['japanese_restaurant', 'restaurant'],
      'keywords': '일식 일본음식 초밥 라멘 우동'
    },
    {
      'name': '양식',
      'icon': Icons.dinner_dining,
      'color': Color(0xFFFBBC04),
      'types': ['italian_restaurant', 'restaurant'],
      'keywords': '양식 서양음식 파스타 스테이크 피자'
    },
    {
      'name': '카페',
      'icon': Icons.coffee,
      'color': Color(0xFF9C27B0),
      'types': ['cafe', 'coffee_shop'],
      'keywords': '카페 커피 아메리카노 라떼 디저트'
    },
    {
      'name': '치킨',
      'icon': Icons.lunch_dining,
      'color': Color(0xFFFF9800),
      'types': ['restaurant', 'meal_delivery'],
      'keywords': '치킨 닭 후라이드 양념치킨'
    },
    {
      'name': '피자',
      'icon': Icons.local_pizza,
      'color': Color(0xFFE91E63),
      'types': ['restaurant', 'meal_delivery'],
      'keywords': '피자 페퍼로니 치즈피자'
    },
    {
      'name': '햄버거',
      'icon': Icons.fastfood,
      'color': Color(0xFF795548),
      'types': ['restaurant', 'meal_delivery'],
      'keywords': '햄버거 버거 패스트푸드'
    },
    {
      'name': '술집',
      'icon': Icons.sports_bar,
      'color': Color(0xFF607D8B),
      'types': ['bar', 'night_club'],
      'keywords': '술집 맥주 소주 안주 호프'
    }
  ];

  @override
  void initState() {
    super.initState();
    // 현재 위치 요청 및 지도 초기 위치 설정
    _determinePosition().then((position) {
      final userLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _initialPosition = userLocation;
      });
      // 위치 받아온 뒤 지도 이동
      if (_mapControllerReady) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 14),
        ));
      }
    }).catchError((e) {
      debugPrint('현재 위치 가져오기 실패: $e');
    });
  }

  /// 현재 위치 권한 및 정보 요청
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되어 있습니다.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되었습니다.');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// 지도 생성 시 호출되는 콜백
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapControllerReady = true;
  }

  /// 지도에 마커 추가
  void _addMarker(LatLng position) {
    final String markerId = 'marker_${_markers.length}';
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
          infoWindow: const InfoWindow(
            title: '마커 제목',
            snippet: '마커 설명',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  /// 하단 네비게이션 아이템 선택 처리
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  /// 현재 위치로 지도 이동
  void _moveToCurrentLocation() async {
    try {
      final Position position = await _determinePosition();
      final LatLng userLocation = LatLng(position.latitude, position.longitude);
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: userLocation, zoom: 15),
      ));
    } catch (e) {
      debugPrint('현재 위치를 가져오는데 실패했습니다: $e');
    }
  }

  /// 장소 리뷰 등록 화면으로 이동
  void _goToReviewPlaceSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReviewPlaceSearchScreen()),
    );
  }

  /// 카테고리 Modal Bottom Sheet 표시 (개선된 디자인)
  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // 상단 핸들 (더 모던하게)
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 제목 섹션 (개선된 디자인)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '카테고리 선택',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '원하는 음식 종류를 선택해보세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 카테고리 그리드 (개선된 레이아웃)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _foodCategories.length,
                  itemBuilder: (context, index) {
                    final category = _foodCategories[index];
                    return _buildModernCategoryCard(category);
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 모던한 카테고리 카드 위젯
  Widget _buildModernCategoryCard(Map<String, dynamic> category) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: (category['color'] as Color).withValues(alpha: 0.1),
          highlightColor: (category['color'] as Color).withValues(alpha: 0.05),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResultScreen(
                  initialQuery: category['name'],
                  isSpecificPlace: false,
                  placeId: null,
                  categoryFilter: {
                    'name': category['name'],
                    'types': category['types'],
                    'keywords': category['keywords'],
                  },
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘 컨테이너 (그라데이션 효과)
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (category['color'] as Color).withValues(alpha: 0.8),
                        (category['color'] as Color).withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (category['color'] as Color).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 카테고리 이름
                Text(
                  category['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 지도 표시
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onTap: _addMarker,
          ),

          // 현재 위치 이동 버튼
          Positioned(
            right: 12,
            top: 620,
            child: GestureDetector(
              onTap: _moveToCurrentLocation,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.navigation,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // 검색창 및 필터 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 검색창
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '장소 및 주소 검색',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Icon(Icons.mic, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 필터 버튼 목록
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('카테고리'),
                        _buildFilterButton('방문상태'),
                        _buildFilterButton('동반여부'),
                        _buildFilterButton('평점'),
                        _buildFilterButton('찜'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // 리뷰 작성 이동 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _goToReviewPlaceSearchScreen,
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
            const SizedBox(width: 48), // FAB 위치
            _buildNavItem(Icons.person_rounded, 'Profile', 2),
            _buildNavItem(Icons.settings_rounded, 'Settings', 3),
          ],
        ),
      ),
    );
  }

  /// 필터 버튼 생성 (수정됨)
  Widget _buildFilterButton(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () {
          if (label == '카테고리') {
            _showCategoryBottomSheet(); // Modal Bottom Sheet 표시
          }
          // 다른 필터 기능은 추후 구현 가능
        },
        child: Container(
          width: 68,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// 하단 네비게이션 아이템 생성
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
