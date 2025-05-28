import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class ReviewPlaceSearchScreen extends StatefulWidget {
  const ReviewPlaceSearchScreen({super.key});

  @override
  State<ReviewPlaceSearchScreen> createState() => _ReviewPlaceSearchScreenState();
}

class _ReviewPlaceSearchScreenState extends State<ReviewPlaceSearchScreen> {
  GoogleMapController? _mapController;
  List<dynamic> _predictions = [];
  LatLng _initialPosition = const LatLng(35.3350, 129.0089);
  final TextEditingController _searchController = TextEditingController();
  final String _googleApiKey = 'AIzaSyAufgjB4H_wW06l9FtmFz8wPTiq15ALKuU';
  Set<Marker> _markers = {};
  Map<String, dynamic>? _selectedPlace;

  Position? _currentPosition; // 현재 위치 저장
  Map<String, LatLng> _predictionLocations = {}; // place_id -> 좌표 저장

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setInitialLocation() async {
    final position = await _determinePosition();
    setState(() {
      _currentPosition = position;
      _initialPosition = LatLng(position.latitude, position.longitude);
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

  void _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        _predictions = [];
        _predictionLocations.clear();
      });
      return;
    }

    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(value)}'
        '&key=$_googleApiKey'
        '&language=ko'
        '&components=country:kr';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          _predictions = data['predictions'] ?? [];
          _predictionLocations.clear();
        });
      }
    }
  }

  // place details API 호출해서 장소 좌표 받아오기 + 지도 이동 + 마커 생성
  void _onPredictionTap(dynamic prediction) async {
    final placeId = prediction['place_id'];

    final String url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$_googleApiKey'
        '&language=ko'
        '&fields=name,formatted_address,geometry,place_id';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final place = data['result'];
        final location = place['geometry']['location'];
        final latLng = LatLng(location['lat'], location['lng']);

        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
        }

        // 선택한 장소 정보, 마커 세팅
        setState(() {
          _selectedPlace = place;

          // place_id -> 좌표 저장해서 거리 계산에 사용
          _predictionLocations[placeId] = latLng;

          // 기존 마커 교체
          _markers = {
            Marker(
              markerId: const MarkerId('selected_place'),
              position: latLng,
              infoWindow: InfoWindow(
                title: place['name'] ?? '',
                snippet: place['formatted_address'] ?? '',
              ),
            ),
          };

          _searchController.text = place['name'] ?? '';
        });
      }
    }
  }

  void _onPlaceSelected() {
    if (_selectedPlace != null) {
      Navigator.pop(context, _selectedPlace);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await _determinePosition();
      final userLocation = LatLng(position.latitude, position.longitude);
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: userLocation, zoom: 16),
          ),
        );
      }
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('현재 위치를 가져오는데 실패했습니다: $e');
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 20), // 🔽 전체를 아래로 살짝 내림
        child: SafeArea(
          child: Column(
            children: [
              // 검색 바
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: '장소 및 주소 검색',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 검색 바와 지도 사이 간격 (유지)
              const SizedBox(height: 0),

              // 지도 영역 + 현재 위치 버튼을 Stack으로 묶음
              Stack(
                children: [
                  Container(
                    height: 320,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GoogleMap(
                        onMapCreated: (controller) => _mapController = controller,
                        initialCameraPosition: CameraPosition(
                          target: _initialPosition,
                          zoom: 14,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        markers: _markers,
                      ),
                    ),
                  ),

                  // 현재 위치 버튼 (우측 하단 확대/축소 버튼 위)
                  Positioned(
                    bottom: 100,
                    right: 30,
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
                ],
              ),

              // 핸들
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 검색 결과 or 빈 상태
              Expanded(
                child: _predictions.isNotEmpty
                    ? _buildSearchResults()
                    : _buildEmptyState(),
              ),

              // 장소 선택 버튼
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _selectedPlace != null ? _onPlaceSelected : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedPlace != null
                          ? Colors.black
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '이 장소 선택',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _predictions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        final mainText = prediction['structured_formatting']?['main_text'] ?? '';
        final secondaryText =
            prediction['structured_formatting']?['secondary_text'] ?? '';

        bool isSelected = _selectedPlace != null &&
            _selectedPlace!['place_id'] == prediction['place_id'];

        double? distanceMeters;
        if (_currentPosition != null) {
          final placeId = prediction['place_id'];
          if (_predictionLocations.containsKey(placeId)) {
            distanceMeters = _calculateDistance(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              _predictionLocations[placeId]!,
            );
          }
        }

        return Container(
          color: isSelected ? Colors.grey[200] : Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, color: Colors.red, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    mainText,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (distanceMeters != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${distanceMeters.toInt()}m',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              secondaryText,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _onPredictionTap(prediction),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '장소를 검색해보세요',
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '검색어를 입력하세요',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
