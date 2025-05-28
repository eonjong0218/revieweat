import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'search_screen.dart'; 
import 'review_place_search_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  bool _mapControllerReady = false;

  LatLng _initialPosition = const LatLng(35.3350, 129.0089); // 부산대 양산캠퍼스
  final Set<Marker> _markers = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _determinePosition().then((position) {
      final userLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _initialPosition = userLocation;
      });
      if (_mapControllerReady) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 14),
        ));
      }
    }).catchError((e) {
      debugPrint('현재 위치 가져오기 실패: $e');
    });
  }

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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapControllerReady = true;
  }

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

  // 추가: FloatingActionButton 누르면 review_place_search_screen으로 이동
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
                      color: Colors.black.withAlpha((0.1 * 255).round()), // 변경됨
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            color: Colors.black.withAlpha((0.12 * 255).round()), // 그림자 약간 더 진하게
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
      floatingActionButton: FloatingActionButton(
        onPressed: _goToReviewPlaceSearchScreen,
        shape: const CircleBorder(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.edit, color: Colors.white),
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

  Widget _buildFilterButton(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () {},
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
