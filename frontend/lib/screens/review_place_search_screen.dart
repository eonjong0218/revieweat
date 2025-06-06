import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReviewPlaceSearchScreen extends StatefulWidget {
  final String? keyword; // 초기 검색어를 받아올 수 있음

  const ReviewPlaceSearchScreen({super.key, this.keyword});

  @override
  State<ReviewPlaceSearchScreen> createState() => _ReviewPlaceSearchScreenState();
}

class _ReviewPlaceSearchScreenState extends State<ReviewPlaceSearchScreen> {
  GoogleMapController? _mapController; // 구글맵 컨트롤러
  List<dynamic> _predictions = []; // 자동완성 검색 결과 저장 리스트
  LatLng _initialPosition = const LatLng(35.3350, 129.0089); // 초기 지도 위치 (부산 근처)
  final TextEditingController _searchController = TextEditingController(); // 검색창 컨트롤러
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? ''; // .env에서 API 키 읽기
  Set<Marker> _markers = {}; // 지도에 표시할 마커들
  Map<String, dynamic>? _selectedPlace; // 선택된 장소 정보 저장

  Position? _currentPosition; // 현재 위치 저장
  final Map<String, LatLng> _predictionLocations = {}; // 자동완성 결과 장소의 좌표 저장

  @override
  void initState() {
    super.initState();
    _setInitialLocation(); // 초기 위치 세팅 (현재 위치 기반)

    // 초기 keyword가 있으면 검색창에 세팅하고 검색 수행
    if (widget.keyword != null && widget.keyword!.isNotEmpty) {
      _searchController.text = widget.keyword!;
      _onSearchChanged(widget.keyword!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); // 텍스트 컨트롤러 해제
    super.dispose();
  }

  // 현재 위치를 얻어서 초기 위치로 설정
  Future<void> _setInitialLocation() async {
    final position = await _determinePosition();
    setState(() {
      _currentPosition = position;
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
  }

  // 위치 권한 체크 및 현재 위치 반환
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

  // 검색어 변경 시 자동완성 API 호출
  void _onSearchChanged(String value) async {
    if (value.isEmpty) {
      // 검색어가 비면 결과 초기화
      setState(() {
        _predictions = [];
        _predictionLocations.clear();
      });
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(value)}'
        '&key=$_googleApiKey'
        '&language=ko'
        '&components=country:kr'; // 한국 지역으로 제한

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          _predictions = data['predictions'] ?? [];
          _predictionLocations.clear(); // 위치 정보는 상세조회에서 받음
        });
      }
    }
  }

  // 자동완성 결과 선택 시 장소 상세정보 API 호출 및 지도 업데이트
  void _onPredictionTap(dynamic prediction) async {
    final placeId = prediction['place_id'];

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$_googleApiKey'
        '&language=ko'
        '&fields=name,formatted_address,geometry,place_id'; // 필요한 필드만 요청

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final place = data['result'];
        final location = place['geometry']['location'];
        final latLng = LatLng(location['lat'], location['lng']);

        // 선택한 위치로 지도 카메라 이동
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
        }

        setState(() {
          _selectedPlace = place;
          _predictionLocations[placeId] = latLng; // 위치 저장
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

  // 선택된 장소가 있을 때 다음 화면으로 이동
  void _onPlaceSelected() {
    if (_selectedPlace != null) {
      Navigator.pushNamed(
        context,
        '/review_second',
        arguments: _selectedPlace!,
      );
    }
  }

  // 현재 위치를 다시 받아와서 지도 이동
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

  // 두 좌표 사이 거리 계산 (미터 단위)
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
        padding: const EdgeInsets.only(top: 20),
        child: SafeArea(
          child: Column(
            children: [
              // 검색창 및 뒤로가기 버튼 영역
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // 뒤로가기
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
                          onChanged: _onSearchChanged, // 검색어 변경 콜백
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
              const SizedBox(height: 0),
              // 지도 영역 + 현재 위치 버튼
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
                          color: Colors.black.withValues(alpha: 0.05), // 그림자 효과
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
                        myLocationEnabled: true, // 현재 위치 표시
                        myLocationButtonEnabled: false, // 기본 위치 버튼 숨김
                        markers: _markers, // 마커 표시
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    right: 30,
                    child: GestureDetector(
                      onTap: _moveToCurrentLocation, // 현재 위치로 이동 버튼
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
                ],
              ),
              // 구분선 역할하는 작은 바
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 검색 결과 리스트 혹은 빈 상태 표시 영역
              Expanded(
                child: _predictions.isNotEmpty
                    ? _buildSearchResults()
                    : _buildEmptyState(),
              ),
              // 선택 완료 버튼 영역
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _selectedPlace != null ? _onPlaceSelected : null, // 선택 시만 활성화
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedPlace != null ? Colors.black : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '이 장소 선택',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  // 검색 결과 리스트 UI 빌드
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
                    style:
                        const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (distanceMeters != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
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
            onTap: () => _onPredictionTap(prediction), // 장소 선택 시 동작
          ),
        );
      },
    );
  }

  // 검색 결과 없을 때 빈 상태 UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
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
