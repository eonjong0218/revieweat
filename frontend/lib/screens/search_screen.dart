import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'search_result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _places = [];
  bool _isLoading = false;
  Timer? _debounce;

  List<Map<String, dynamic>> _recentSearches = [];
  final String _googleApiKey = 'AIzaSyAufgjB4H_wW06l9FtmFz8wPTiq15ALKuU';
  final String _baseUrl = 'http://192.168.0.6:8000';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

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
      final List<dynamic> data = json.decode(response.body);
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
      final responseData = json.decode(response.body);
      
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

    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=$_googleApiKey'
        '&language=ko'
        '&components=country:kr';

    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        if (mounted) {
          setState(() {
            _places = data['predictions'] ?? [];
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

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$_googleApiKey'
        '&language=ko'
        '&fields=name,formatted_address,geometry,place_id';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      }
    }
    return null;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

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
            // 상단 검색 바 영역 (뒤로가기 버튼을 오른쪽으로 이동)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          hintText: '장소 및 주소 검색',
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
            
            // 메인 콘텐츠 영역
            Expanded(
              child: _searchController.text.isNotEmpty && _places.isNotEmpty
                  ? _buildPlacesList()
                  : _searchController.text.isNotEmpty && _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildRecentSearches(),
            ),
          ],
        ),
      ),
    );
  }

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
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Colors.red, size: 20),
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

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 최근 검색 헤더
        if (_recentSearches.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
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
        
        // 검색 기록 리스트
        Expanded(child: _buildRecentSearchList()),
      ],
    );
  }

  Widget _buildRecentSearchList() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
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
              '장소나 주소를 검색해보세요',
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
              color: isPlace ? Colors.red[50] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlace ? Icons.location_on : Icons.history,
              color: isPlace ? Colors.red : Colors.grey[600],
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
