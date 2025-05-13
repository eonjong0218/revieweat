import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  // 카카오맵 컨트롤러
  KakaoMapController? mapController;
  
  // 현재 위치
  LatLng? currentLocation;
  
  // 지도 초기 위치 (서울 중심)
  final LatLng defaultPosition = LatLng(37.5665, 126.9780);
  
  // 선택된 탭 인덱스
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // 위치 권한 요청 및 현재 위치 가져오기
    _getCurrentLocation();
  }
  
  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // 위치 서비스가 활성화되어 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스가 비활성화된 경우 처리
      return;
    }
    
    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 권한이 거부된 경우 처리
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // 권한이 영구적으로 거부된 경우 처리
      return;
    }
    
    // 현재 위치 가져오기
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      
      // 지도 컨트롤러가 초기화된 경우 현재 위치로 이동
      if (mapController != null && currentLocation != null) {
        mapController!.setCenter(currentLocation!);
      }
    });
  }
  
  // 탭 선택 처리
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 검색 바
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '장소 및 주소 검색',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.mic),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            
            // 카테고리 필터 (가로 스크롤)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildFilterChip('전체'),
                  _buildFilterChip('주차장'),
                  _buildFilterChip('음식점'),
                  _buildFilterChip('카페'),
                  _buildFilterChip('편의점'),
                  _buildFilterChip('공원'),
                  _buildFilterChip('병원'),
                ],
              ),
            ),
            
            // 카카오맵
            Expanded(
              child: KakaoMap(
                onMapCreated: ((controller) {
                  mapController = controller;
                  
                  // 현재 위치가 있으면 해당 위치로, 없으면 기본 위치로 이동
                  if (currentLocation != null) {
                    controller.setCenter(currentLocation!);
                  } else {
                    controller.setCenter(defaultPosition);
                  }
                  
                  // 컨트롤러를 통해 줌 레벨 설정
                  try {
                    controller.setLevel(3);
                  } catch (e) {
                    print('줌 레벨 설정 오류: $e');
                  }
                }),
                center: currentLocation ?? defaultPosition,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 현재 위치로 이동
          if (currentLocation != null && mapController != null) {
            mapController!.setCenter(currentLocation!);
          } else {
            _getCurrentLocation();
          }
        },
        mini: true,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.black),
      ),
    );
  }
  
  // 필터 칩 위젯
  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        onSelected: (bool selected) {
          // 필터 선택 처리
        },
        backgroundColor: Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
  
  // 커스텀 하단 네비게이션 바
  Widget _buildCustomBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, '홈'),
              _buildNavItem(1, Icons.history_outlined, Icons.history, '히스토리'),
              _buildCenterButton(),
              _buildNavItem(3, Icons.bookmark_border_outlined, Icons.bookmark, '북마크'),
              _buildNavItem(4, Icons.person_outline, Icons.person, '내 정보'),
            ],
          ),
        ),
      ),
    );
  }
  
  // 네비게이션 아이템 위젯
  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final bool isSelected = _selectedIndex == index;
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: isSelected ? Colors.black : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  // 가운데 버튼 위젯
  Widget _buildCenterButton() {
    return InkWell(
      onTap: () => _onItemTapped(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
