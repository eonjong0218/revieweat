import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String initialQuery;
  final bool isSpecificPlace;
  final Map<String, dynamic>? placeDetails;

  const SearchResultScreen({
    super.key, 
    required this.initialQuery,
    this.isSpecificPlace = false,
    this.placeDetails,
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

  static const String _apiKey = 'AIzaSyAufgjB4H_wW06l9FtmFz8wPTiq15ALKuU'; // 실제 키로 교체

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    
    if (widget.isSpecificPlace && widget.placeDetails != null) {
      // 특정 장소인 경우 해당 장소만 표시
      _displaySpecificPlace();
    } else {
      // 일반 검색인 경우 현재 위치 기준으로 검색
      _performLocationBasedSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

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

    // 지도를 선택된 장소로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
        );
      }
    });
  }

  Future<void> _performLocationBasedSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // 현재 위치를 기본값으로 설정 (부산 지역)
    const double defaultLat = 35.2271;
    const double defaultLng = 129.0790;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$defaultLat,$defaultLng&radius=5000&keyword=${Uri.encodeComponent(query)}&key=$_apiKey&language=ko';

    try {
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

          // 검색 결과가 있으면 첫 번째 결과로 지도 이동
          if (places.isNotEmpty && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(defaultLat, defaultLng),
                12.0,
              ),
            );
          }
        } else {
          debugPrint('Places API 오류: ${data['status']}');
          setState(() {
            _searchResults = [];
            _markers = {};
          });
        }
      } else {
        debugPrint('HTTP 요청 실패: ${response.statusCode}');
        setState(() {
          _searchResults = [];
          _markers = {};
        });
      }
    } catch (e) {
      debugPrint('예외 발생: $e');
      setState(() {
        _searchResults = [];
        _markers = {};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  Widget _buildFilterButton(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () {
          debugPrint('필터 선택: $label');
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
          child: Text(label, style: const TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

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

        debugPrint('현 위치 기준 재검색: ${center.latitude}, ${center.longitude}');
        // 현재 지도 중심점 기준으로 재검색
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.refresh, size: 16, color: Colors.black87),
            SizedBox(width: 4),
            Text('현 위치 기준 재검색', style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Future<void> _performNearbySearch(double lat, double lng) async {
    setState(() {
      _isLoading = true;
    });

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=2000&keyword=${Uri.encodeComponent(_searchController.text)}&key=$_apiKey&language=ko';

    try {
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
    } catch (e) {
      debugPrint('Nearby search 예외 발생: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(35.2271, 129.0790),
              zoom: 14,
            ),
            myLocationEnabled: true,
            markers: _markers,
          ),

          // 검색 바
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

          // 검색 결과 Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(top: 12),
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFilterButton('중심점'),
                          _buildFilterButton('카테고리'),
                          _buildFilterButton('방문상태'),
                          _buildFilterButton('평점'),
                          _buildFilterButton('동반여부'),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_searchResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('검색 결과가 없습니다.')),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard({
    required String title,
    required String desc,
    required String phone,
    required String tags,
    required String rating,
  }) {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    )),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 14),
              Text(' $rating', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(tags, style: const TextStyle(fontSize: 12)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc),
              if (phone.isNotEmpty)
                Text(phone, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          trailing: const Icon(Icons.bookmark_border),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        const Divider(height: 1),
      ],
    );
  }
}