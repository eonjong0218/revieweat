import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  KakaoMapController? mapController;
  LatLng? currentLocation;
  final LatLng defaultPosition = LatLng(37.5665, 126.9780); // 서울시청
  int _selectedIndex = 0;
  String? selectedMainFilter;

  List<Marker> markers = [];
  List<Map<String, dynamic>> places = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('위치 서비스 비활성화');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('위치 정보 가져오기 실패: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    const String apiKey = 'c4598299cedc1620be6be800ae88e0bf';
    final String url = 'https://dapi.kakao.com/v2/local/search/keyword.json?query=$query';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'KakaoAK $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List documents = data['documents'];

      return documents.map<Map<String, dynamic>>((doc) {
        return {
          'position': LatLng(double.parse(doc['y']), double.parse(doc['x'])),
          'name': doc['place_name'],
        };
      }).toList();
    } else {
      throw Exception('장소 검색 실패');
    }
  }

  void updateMarkers(List<Map<String, dynamic>> newPlaces) {
    setState(() {
      places = newPlaces;
      markers = places.map((place) {
        return Marker(
          markerId: UniqueKey().toString(),
          latLng: place['position'],
          width: 40,
          height: 40,
        );
      }).toList();
    });
  }

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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '장소 및 주소 검색',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onSubmitted: (value) async {
                  final results = await searchPlaces(value);
                  updateMarkers(results);

                  if (results.isNotEmpty) {
                    mapController?.setCenter(results.first['position']);
                  }
                },
              ),
            ),
            _buildFilterSection(),
            Expanded(
              child: currentLocation != null
                  ? KakaoMap(
                      onMapCreated: (controller) {
                        mapController = controller;
                        controller.setCenter(currentLocation!);
                        controller.setLevel(3);
                      },
                      center: currentLocation!,
                      markers: markers,
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (currentLocation != null) {
            mapController?.setCenter(currentLocation!);
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

  Widget _buildFilterSection() {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildMainFilterChip('중심점'),
              _buildMainFilterChip('카테고리'),
              _buildMainFilterChip('방문상태'),
              _buildMainFilterChip('평점'),
              _buildMainFilterChip('동반여부'),
            ],
          ),
        ),
        if (selectedMainFilter != null) _buildSubFilter(selectedMainFilter!),
      ],
    );
  }

  Widget _buildMainFilterChip(String label) {
    final bool isSelected = selectedMainFilter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            selectedMainFilter = selected ? label : null;
          });
        },
      ),
    );
  }

  Widget _buildSubFilter(String mainFilter) {
    List<String> subFilters = [];
    switch (mainFilter) {
      case '중심점':
        subFilters = ['현재 위치', '지도 중심'];
        break;
      case '카테고리':
        subFilters = ['한식', '중식', '일식', '양식', '아시안', '디저트', '분식', '패스트푸드', '고기', '해산물', '샐러드', '브런치', '카페', '주점', '베이커리', '뷔페'];
        break;
      case '방문상태':
        subFilters = ['방문 완료', '방문 전', '즐겨찾기'];
        break;
      case '평점':
        subFilters = ['★1 이상', '★2 이상', '★3 이상', '★4 이상', '★5'];
        break;
      case '동반여부':
        subFilters = ['혼밥', '가족', '연인', '친구'];
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        children: subFilters.map((sub) {
          return FilterChip(
            label: Text(sub),
            onSelected: (bool selected) {
              debugPrint('$mainFilter → $sub 선택됨');
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
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
