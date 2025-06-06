import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String initialQuery;
  final bool isSpecificPlace;
  final String? placeId;
  final Map<String, dynamic>? placeDetails;
  final Map<String, dynamic>? categoryFilter; // 추가

  const SearchResultScreen({
    super.key, 
    required this.initialQuery,
    this.isSpecificPlace = false,
    this.placeId,
    this.placeDetails,
    this.categoryFilter, // 추가
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late TextEditingController _searchController;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  double _sheetPosition = 0.35;

  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    
    // 카테고리 필터가 있는 경우 카테고리 기반 검색 수행
    if (widget.categoryFilter != null) {
      _performCategoryBasedSearch();
    } else if (widget.isSpecificPlace) {
      if (widget.placeId != null) {
        _getPlaceDetailsFromId(widget.placeId!);
      } else if (widget.placeDetails != null) {
        _displaySpecificPlace();
      }
    } else {
      _performLocationBasedSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 구글 맵 컨트롤러 초기화 콜백
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // 현재 위치 권한 및 위치 서비스 상태 확인 후 위치 정보 가져오기
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

  // 카테고리 기반 검색 함수 추가
  Future<void> _performCategoryBasedSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Position position = await _determinePosition();
      final double lat = position.latitude;
      final double lng = position.longitude;

      await _searchByCategory(lat, lng, widget.categoryFilter!);
    } catch (e) {
      // 위치 권한이 없거나 실패한 경우 기본 위치 사용 (부산)
      const double defaultLat = 35.2271;
      const double defaultLng = 129.0790;
      await _searchByCategory(defaultLat, defaultLng, widget.categoryFilter!);
    }
  }

  // 카테고리별 장소 검색 함수
  Future<void> _searchByCategory(double lat, double lng, Map<String, dynamic> category) async {
    final List<String> types = List<String>.from(category['types']);
    final String keywords = category['keywords'];
    
    final places = <Map<String, dynamic>>[];
    final markers = <Marker>{};

    // 각 타입별로 검색 수행
    for (String type in types) {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$lat,$lng'
          '&radius=3000'
          '&type=$type'
          '&keyword=${Uri.encodeComponent(keywords)}'
          '&key=$_apiKey'
          '&language=ko';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;

          for (int i = 0; i < results.length && places.length < 20; i++) {
            final place = results[i];
            final location = place['geometry']?['location'];
            
            if (location != null) {
              final placeLat = location['lat']?.toDouble() ?? 0.0;
              final placeLng = location['lng']?.toDouble() ?? 0.0;
              
              // 중복 제거를 위해 place_id 확인
              final placeId = place['place_id'];
              if (!places.any((p) => p['place_id'] == placeId)) {
                places.add({
                  'title': place['name'] ?? '',
                  'desc': place['vicinity'] ?? '',
                  'phone': '',
                  'tags': category['name'],
                  'rating': place['rating']?.toString() ?? '4.0',
                  'lat': placeLat,
                  'lng': placeLng,
                  'place_id': placeId,
                });

                markers.add(
                  Marker(
                    markerId: MarkerId('category_${places.length}'),
                    position: LatLng(placeLat, placeLng),
                    infoWindow: InfoWindow(
                      title: place['name'] ?? '',
                      snippet: place['vicinity'] ?? '',
                    ),
                  ),
                );
              }
            }
          }
        }
      }
    }

    setState(() {
      _searchResults = places;
      _markers = markers;
      _isLoading = false;
    });

    // 검색 결과가 있으면 해당 위치로 카메라 이동
    if (places.isNotEmpty && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          13.0,
        ),
      );
    }
  }

  // 현재 위치로 카메라 이동
  void _moveToCurrentLocation() async {
    final Position position = await _determinePosition();
    final LatLng userLocation = LatLng(position.latitude, position.longitude);
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: userLocation, zoom: 15),
      ));
    }
  }

  // 지도 확대
  void _zoomIn() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.zoomIn());
    }
  }

  // 지도 축소
  void _zoomOut() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.zoomOut());
    }
  }

  // placeId를 이용해 구글 플레이스 API에서 장소 상세 정보 조회
  Future<void> _getPlaceDetailsFromId(String placeId) async {
    setState(() {
      _isLoading = true;
    });

    final String url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$_apiKey'
        '&language=ko'
        '&fields=name,formatted_address,geometry,place_id,rating,vicinity';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final place = data['result'];
        final location = place['geometry']?['location'];
        
        if (location != null) {
          final lat = location['lat']?.toDouble() ?? 35.2271;
          final lng = location['lng']?.toDouble() ?? 129.0790;

          // 상세 장소 정보 및 마커 상태 업데이트
          setState(() {
            _searchResults = [{
              'title': place['name'] ?? '',
              'desc': place['formatted_address'] ?? place['vicinity'] ?? '',
              'phone': '',
              'tags': '',
              'rating': place['rating']?.toString() ?? '4.0',
              'lat': lat,
              'lng': lng,
            }];
            
            _markers = {
              Marker(
                markerId: const MarkerId('selected_place'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: place['name'] ?? '',
                  snippet: place['formatted_address'] ?? place['vicinity'] ?? '',
                ),
              ),
            };
          });

          // 맵 카메라를 해당 위치로 이동 및 확대
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
              );
            }
          });
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 이미 전달받은 특정 장소 상세 정보로 화면 및 마커 업데이트
  void _displaySpecificPlace() {
    if (widget.placeDetails == null) return;

    final place = widget.placeDetails!;
    final lat = place['lat']?.toDouble() ?? 35.2271;
    final lng = place['lng']?.toDouble() ?? 129.0790;

    setState(() {
      _searchResults = [{
        'title': place['name'] ?? '',
        'desc': place['address'] ?? '',
        'phone': '',
        'tags': '',
        'rating': '4.0',
        'lat': lat,
        'lng': lng,
      }];
      
      _markers = {
        Marker(
          markerId: const MarkerId('selected_place'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: place['name'] ?? '',
            snippet: place['address'] ?? '',
          ),
        ),
      };
    });

    // 맵 카메라를 해당 위치로 이동 및 확대
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
        );
      }
    });
  }

  // 위치 기반 키워드 검색 수행 (기본 위치: defaultLat, defaultLng)
  Future<void> _performLocationBasedSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    const double defaultLat = 35.2271;
    const double defaultLng = 129.0790;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$defaultLat,$defaultLng&radius=5000&keyword=${Uri.encodeComponent(query)}&key=$_apiKey&language=ko';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final results = data['results'] as List;

        final places = <Map<String, dynamic>>[];
        final markers = <Marker>{};

        for (int i = 0; i < results.length; i++) {
          final place = results[i];
          final location = place['geometry']?['location'];
          
          if (location != null) {
            final lat = location['lat']?.toDouble() ?? 0.0;
            final lng = location['lng']?.toDouble() ?? 0.0;
            
            places.add({
              'title': place['name'] ?? '',
              'desc': place['vicinity'] ?? '',
              'phone': '',
              'tags': _getPlaceTypes(place['types']),
              'rating': place['rating']?.toString() ?? '4.0',
              'lat': lat,
              'lng': lng,
            });

            markers.add(
              Marker(
                markerId: MarkerId('place_$i'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: place['name'] ?? '',
                  snippet: place['vicinity'] ?? '',
                ),
              ),
            );
          }
        }

        setState(() {
          _searchResults = places;
          _markers = markers;
        });

        if (places.isNotEmpty && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(defaultLat, defaultLng),
              12.0,
            ),
          );
        }
      } else {
        setState(() {
          _searchResults = [];
          _markers = {};
        });
      }
    } else {
      setState(() {
        _searchResults = [];
        _markers = {};
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 구글 플레이스 타입 코드를 한글 태그로 변환
  String _getPlaceTypes(List<dynamic>? types) {
    if (types == null || types.isEmpty) return '';
    
    final typeMap = {
      'restaurant': '음식점',
      'cafe': '카페',
      'tourist_attraction': '관광지',
      'shopping_mall': '쇼핑몰',
      'hospital': '병원',
      'school': '학교',
      'gas_station': '주유소',
      'bank': '은행',
      'pharmacy': '약국',
      'convenience_store': '편의점',
    };
    
    for (final type in types) {
      if (typeMap.containsKey(type)) {
        return typeMap[type]!;
      }
    }
    
    return '';
  }

  // 필터 버튼 UI 빌더
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
          child: Text(label, style: const TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

  // 현재 화면 중심 위치 기준 재검색 버튼 UI 빌더
  Widget _buildRefreshLocationButton() {
    return GestureDetector(
      onTap: () async {
        if (_mapController == null) return;

        final center = await _mapController!.getLatLng(
          ScreenCoordinate(
            x: MediaQuery.of(context).size.width ~/ 2,
            y: MediaQuery.of(context).size.height ~/ 2,
          ),
        );

        _performNearbySearch(center.latitude, center.longitude);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 16, color: Colors.black87),
            SizedBox(width: 4),
            Text('현 위치 기준 재검색', style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // 주어진 위경도 기준 근처 장소 검색 수행
  Future<void> _performNearbySearch(double lat, double lng) async {
    setState(() {
      _isLoading = true;
    });

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=2000&keyword=${Uri.encodeComponent(_searchController.text)}&key=$_apiKey&language=ko';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final results = data['results'] as List;

        final places = <Map<String, dynamic>>[];
        final markers = <Marker>{};

        for (int i = 0; i < results.length; i++) {
          final place = results[i];
          final location = place['geometry']?['location'];
          
          if (location != null) {
            final placeLat = location['lat']?.toDouble() ?? 0.0;
            final placeLng = location['lng']?.toDouble() ?? 0.0;
            
            places.add({
              'title': place['name'] ?? '',
              'desc': place['vicinity'] ?? '',
              'phone': '',
              'tags': _getPlaceTypes(place['types']),
              'rating': place['rating']?.toString() ?? '4.0',
              'lat': placeLat,
              'lng': placeLng,
            });

            markers.add(
              Marker(
                markerId: MarkerId('nearby_$i'),
                position: LatLng(placeLat, placeLng),
                infoWindow: InfoWindow(
                  title: place['name'] ?? '',
                  snippet: place['vicinity'] ?? '',
                ),
              ),
            );
          }
        }

        setState(() {
          _searchResults = places;
          _markers = markers;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 구글 지도 위젯
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(35.2271, 129.0790),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
          ),

          // 상단 검색 바
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 22, color: Colors.black45),
                    splashRadius: 20,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '장소 및 주소 검색',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (query) => _performLocationBasedSearch(query),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.mic, color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        },
                        child: const Icon(Icons.close, color: Colors.black54, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 재검색 버튼
          Positioned(
            top: 116,
            left: 0,
            right: 0,
            child: Center(child: _buildRefreshLocationButton()),
          ),

          // 검색 결과를 표시하는 드래그 가능한 시트
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    _sheetPosition = notification.extent;
                  });
                  return true;
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(top: 16),
                    children: [
                      Center(
                        child: Container(
                          width: 70,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFilterButton('카테고리'),
                            _buildFilterButton('방문상태'),
                            _buildFilterButton('동반여부'),
                            _buildFilterButton('평점'),
                            _buildFilterButton('찜'),
                          ],
                        ),
                      ),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_searchResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '검색 결과가 없습니다',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._searchResults.map((place) => _buildPlaceCard(
                              title: place['title'],
                              desc: place['desc'],
                              phone: place['phone'],
                              tags: place['tags'],
                              rating: place['rating'],
                            )),
                    ],
                  ),
                ),
              );
            },
          ),

          // 지도 제어 버튼들
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).size.height * _sheetPosition + 20,
            child: Column(
              children: [
                GestureDetector(
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
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _zoomIn,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey, width: 0.5),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add,
                              color: Colors.black54,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _zoomOut,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: Icon(
                              Icons.remove,
                              color: Colors.black54,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 장소 카드 위젯 생성
  Widget _buildPlaceCard({
    required String title,
    required String desc,
    required String phone,
    required String tags,
    required String rating,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.orange[600]),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.bookmark_border, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            desc,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tags,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],

          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              phone,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
