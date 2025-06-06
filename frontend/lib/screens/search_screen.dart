import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'search_result_screen.dart';

// 검색 화면 위젯
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // 검색어 입력 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // 장소 자동완성 결과
  List<dynamic> _places = [];

  // 로딩 상태
  bool _isLoading = false;

  // 디바운스 타이머
  Timer? _debounce;

  // 최근 검색 목록
  List<Map<String, dynamic>> _recentSearches = [];

  // .env에서 가져온 환경 변수
  late final String _googleApiKey;
  late final String _baseUrl;

  // 음식 관련 타입들 (더 엄격한 필터링)
  static const Set<String> _foodRelatedTypes = {
    'restaurant',
    'food',
    'meal_delivery',
    'meal_takeaway',
    'bakery',
    'cafe',
    'bar',
    'night_club',
    'liquor_store',
  };

  // 제외할 타입들 (음식과 무관한 장소들)
  static const Set<String> _excludedTypes = {
    'university',
    'school',
    'hospital',
    'bank',
    'atm',
    'gas_station',
    'pharmacy',
    'post_office',
    'police',
    'fire_station',
    'local_government_office',
    'courthouse',
    'embassy',
    'library',
    'museum',
    'church',
    'mosque',
    'synagogue',
    'hindu_temple',
    'cemetery',
    'funeral_home',
    'car_dealer',
    'car_rental',
    'car_repair',
    'car_wash',
    'beauty_salon',
    'hair_care',
    'spa',
    'gym',
    'dentist',
    'doctor',
    'veterinary_care',
    'real_estate_agency',
    'insurance_agency',
    'lawyer',
    'accounting',
    'travel_agency',
    'lodging',
    'campground',
    'rv_park',
    'tourist_attraction',
    'amusement_park',
    'aquarium',
    'zoo',
    'park',
    'stadium',
    'movie_theater',
    'bowling_alley',
    'casino',
    'shopping_mall',
    'department_store',
    'electronics_store',
    'furniture_store',
    'hardware_store',
    'home_goods_store',
    'jewelry_store',
    'shoe_store',
    'clothing_store',
    'book_store',
    'bicycle_store',
    'pet_store',
  };

  @override
  void initState() {
    super.initState();
    _initializeEnvironmentVariables();
    _loadSearchHistory();
  }

  // 환경 변수 초기화
  void _initializeEnvironmentVariables() {
    _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    _baseUrl = dotenv.env['API_URL'] ?? '';
    
    if (_googleApiKey.isEmpty || _baseUrl.isEmpty) {
      throw Exception('환경 변수가 설정되지 않았습니다. .env 파일을 확인해주세요.');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // 서버에서 최근 검색 기록 불러오기
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null) {
      return;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/search-history/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      if (mounted) {
        setState(() {
          _recentSearches = data.map((item) => {
            'id': item['id'],
            'query': item['query'],
            'name': item['name'],
            'is_place': item['is_place'] ?? false,
            'created_at': item['created_at'],
          }).toList();
        });
      }
    } else if (response.statusCode == 401) {
      await prefs.remove('access_token');
    }
  }

  // 검색어를 서버에 저장
  Future<void> _saveSearchToServer(String query, {bool isPlace = false, String? placeName}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null) {
      return;
    }

    final Map<String, dynamic> requestBody = {
      'query': query,
      'is_place': isPlace,
      'name': isPlace ? placeName : null,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/search-history/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      
      setState(() {
        _recentSearches.removeWhere((item) => 
          item['query'] == query && item['is_place'] == isPlace);
        
        _recentSearches.insert(0, {
          'id': responseData['id'],
          'query': responseData['query'],
          'name': responseData['name'],
          'is_place': responseData['is_place'],
          'created_at': responseData['created_at'],
        });
        
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  // 특정 검색 기록 삭제
  Future<void> _deleteSearchHistory(int id, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('$_baseUrl/search-history/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 && mounted) {
      setState(() {
        _recentSearches.removeAt(index);
      });
    }
  }

  // 전체 검색 기록 삭제
  Future<void> _deleteAllSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('$_baseUrl/search-history/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 && mounted) {
      setState(() {
        _recentSearches.clear();
      });
    }
  }

  // 음식 관련 장소인지 확인하는 함수 (더 엄격한 필터링)
  bool _isFoodRelatedPlace(dynamic place) {
    final List<dynamic> types = place['types'] ?? [];
    
    // 먼저 제외할 타입이 있는지 확인
    for (String type in types) {
      if (_excludedTypes.contains(type)) {
        return false; // 제외 타입이 하나라도 있으면 제외
      }
    }
    
    // 음식 관련 타입이 있는지 확인
    bool hasValidType = false;
    for (String type in types) {
      if (_foodRelatedTypes.contains(type)) {
        hasValidType = true;
        break;
      }
    }
    
    // 타입으로 확인되지 않으면 키워드로 확인
    if (!hasValidType) {
      final String mainText = (place['structured_formatting']?['main_text'] ?? '').toLowerCase();
      final String secondaryText = (place['structured_formatting']?['secondary_text'] ?? '').toLowerCase();
      final String description = place['description']?.toLowerCase() ?? '';
      
      // 음식 관련 키워드들 (더 구체적으로)
      const List<String> foodKeywords = [
        '음식점', '레스토랑', '식당', '카페', '커피숍', '커피전문점',
        '베이커리', '빵집', '제과점', '치킨', '피자', '햄버거', '분식',
        '한식', '중식', '일식', '양식', '이탈리안', '멕시칸', '태국',
        '술집', '바', '펍', '호프', '맥주', '소주', '와인', '칵테일',
        '디저트', '아이스크림', '케이크', '도넛', '마카롱', '와플',
        '배달', '테이크아웃', '포장', '치킨집', '피자집', '족발',
        '보쌈', '삼겹살', '갈비', '불고기', '냉면', '라면', '우동',
        '파스타', '스테이크', '샐러드', '샌드위치', '버거', '타코',
        'restaurant', 'cafe', 'coffee', 'bakery', 'bar', 'pub',
        'pizza', 'chicken', 'burger', 'food', 'dining', 'bistro',
        'grill', 'kitchen', 'eatery', 'diner', 'tavern'
      ];
      
      // 제외할 키워드들
      const List<String> excludeKeywords = [
        '대학교', '대학', '학교', '병원', '은행', '주유소', '약국',
        '우체국', '경찰서', '소방서', '시청', '구청', '도서관',
        '박물관', '교회', '성당', '절', '사찰', '공원', '놀이터',
        '마트', '백화점', '쇼핑몰', '편의점', '미용실', '헬스장',
        'university', 'college', 'school', 'hospital', 'bank',
        'station', 'pharmacy', 'office', 'library', 'museum',
        'church', 'temple', 'park', 'mall', 'market'
      ];
      
      // 제외 키워드가 있으면 제외
      for (String keyword in excludeKeywords) {
        if (mainText.contains(keyword) || 
            secondaryText.contains(keyword) || 
            description.contains(keyword)) {
          return false;
        }
      }
      
      // 음식 키워드가 있으면 포함
      for (String keyword in foodKeywords) {
        if (mainText.contains(keyword) || 
            secondaryText.contains(keyword) || 
            description.contains(keyword)) {
          hasValidType = true;
          break;
        }
      }
    }
    
    return hasValidType;
  }

  // Google API를 사용한 장소 자동완성 검색 (음식 관련만 엄격 필터링)
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _places = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 음식 관련 키워드를 쿼리에 추가하여 더 정확한 결과 얻기
    final String enhancedQuery = '$query 음식점 OR $query 카페 OR $query 레스토랑';
    
    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}' // 원본 쿼리 사용
        '&key=$_googleApiKey'
        '&language=ko'
        '&components=country:kr';
        // types 파라미터 제거 - 더 넓은 범위에서 검색 후 필터링

    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final List<dynamic> allPlaces = data['predictions'] ?? [];
        
        // 음식 관련 장소만 필터링
        final List<dynamic> foodPlaces = [];
        
        for (var place in allPlaces) {
          // Place Details API로 타입 정보 가져와서 확인
          final placeId = place['place_id'];
          final details = await _getPlaceTypesOnly(placeId);
          
          if (details != null) {
            place['types'] = details['types'];
            if (_isFoodRelatedPlace(place)) {
              foodPlaces.add(place);
            }
          }
          
          // 최대 10개까지만 표시
          if (foodPlaces.length >= 10) {
            break;
          }
        }
        
        if (mounted) {
          setState(() {
            _places = foodPlaces;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _places = [];
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _places = [];
          _isLoading = false;
        });
      }
    }
  }

  // 장소의 타입 정보만 빠르게 가져오기
  Future<Map<String, dynamic>?> _getPlaceTypesOnly(String placeId) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$_googleApiKey'
        '&fields=types';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      }
    }
    return null;
  }

  // 장소 세부 정보 가져오기
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$_googleApiKey'
        '&language=ko'
        '&fields=name,formatted_address,geometry,place_id,types';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      }
    }
    return null;
  }

  // 검색어 변경 시 호출 (디바운싱 적용)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  // 키보드에서 검색 제출 시
  void _onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) return;
    
    await _saveSearchToServer(query.trim(), isPlace: false);
    
    setState(() {
      _places = [];
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultScreen(
            initialQuery: query.trim(),
            isSpecificPlace: false,
            placeId: null,
          ),
        ),
      );
    }
  }

  // 장소 자동완성 항목 탭 시
  void _onPlaceTap(dynamic place) async {
    final placeId = place['place_id'];
    final details = await _getPlaceDetails(placeId);

    if (!mounted) return;

    if (details != null && details['geometry'] != null) {
      final location = details['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];
      final placeName = details['name'] ?? place['structured_formatting']?['main_text'] ?? '';
      final address = details['formatted_address'] ?? '';

      if (placeName.isNotEmpty) {
        await _saveSearchToServer(placeName, isPlace: true, placeName: placeName);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultScreen(
              initialQuery: placeName,
              isSpecificPlace: true,
              placeId: placeId,
              placeDetails: {
                'name': placeName,
                'address': address,
                'lat': lat,
                'lng': lng,
              },
            ),
          ),
        );
      }
    }
  }

  // 최근 검색 항목 탭 시
  void _onRecentSearchTap(Map<String, dynamic> searchItem) {
    final query = searchItem['is_place'] == true 
        ? (searchItem['name'] ?? searchItem['query']) 
        : searchItem['query'];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          initialQuery: query,
          isSpecificPlace: searchItem['is_place'] == true,
          placeId: null,
        ),
      ),
    );
  }

  // 전체 삭제 확인 다이얼로그 표시
  Future<void> _showDeleteAllConfirmDialog() async {
    if (_recentSearches.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('검색 기록 전체 삭제'),
          content: const Text('모든 검색 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteAllSearchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 검색창 UI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 35),
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
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchSubmitted,
                        textInputAction: TextInputAction.search,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: '맛집, 카페, 음식점 검색',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Icon(Icons.mic, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 검색 결과 또는 최근 검색 표시
            Expanded(
              child: _searchController.text.isNotEmpty && _places.isNotEmpty
                  ? _buildPlacesList()
                  : _searchController.text.isNotEmpty && _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _searchController.text.isNotEmpty && _places.isEmpty && !_isLoading
                          ? _buildNoResults()
                          : _buildRecentSearches(),
            ),
          ],
        ),
      ),
    );
  }

  // 검색 결과 없음 위젯
  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '음식점 검색 결과가 없습니다',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 키워드로 검색해보세요',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 자동완성된 장소 리스트 빌더
  Widget _buildPlacesList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _places.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final place = _places[index];
        final mainText = place['structured_formatting']?['main_text'] ?? '';
        final secondaryText = place['structured_formatting']?['secondary_text'] ?? '';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant, color: Colors.orange, size: 20),
          ),
          title: Text(
            mainText,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            secondaryText,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _onPlaceTap(place),
        );
      },
    );
  }

  // 최근 검색 리스트 빌더
  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 영역
        if (_recentSearches.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 5, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 검색',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: _showDeleteAllConfirmDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '전체 삭제',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        // 검색 항목 리스트
        Expanded(child: _buildRecentSearchList()),
      ],
    );
  }

  // 최근 검색 항목 리스트 빌더
  Widget _buildRecentSearchList() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '최근 검색 기록이 없습니다',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '맛집이나 카페를 검색해보세요',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _recentSearches.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final searchItem = _recentSearches[index];
        final isPlace = searchItem['is_place'] == true;
        final displayText = isPlace 
            ? (searchItem['name'] ?? searchItem['query']) 
            : searchItem['query'];
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPlace ? Colors.orange[50] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlace ? Icons.restaurant : Icons.history,
              color: isPlace ? Colors.orange : Colors.grey[600],
              size: 18,
            ),
          ),
          title: Text(
            displayText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
            onPressed: () => _deleteSearchHistory(searchItem['id'], index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          onTap: () => _onRecentSearchTap(searchItem),
        );
      },
    );
  }
}
