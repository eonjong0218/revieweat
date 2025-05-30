import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'search_screen.dart';
import 'review_place_search_screen.dart';
import 'profile_screen.dart';

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
                      color: Colors.black.withAlpha((0.1 * 255).round()),
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
                            color: Colors.black.withAlpha((0.12 * 255).round()),
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
                        _buildFilterButton('중심점'),
                        _buildFilterButton('카테고리'),
                        _buildFilterButton('방문상태'),
                        _buildFilterButton('평점'),
                        _buildFilterButton('동반여부'),
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

  /// 필터 버튼 생성
  Widget _buildFilterButton(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () {}, // 필터 기능 추후 구현 가능
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