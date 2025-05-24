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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      print('Loading search history...');
      print('Token exists: ${token != null}');
      
      if (token == null) {
        print('No token found, skipping search history load');
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/search-history/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Search history response status: ${response.statusCode}');
      print('Search history response body: ${response.body}');

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
          print('Loaded ${_recentSearches.length} search history items');
        }
      } else if (response.statusCode == 401) {
        print('Token expired, removing from storage');
        await prefs.remove('access_token');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인이 만료되었습니다. 다시 로그인해주세요.')),
          );
        }
      } else {
        print('Failed to load search history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading search history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 기록을 불러오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _saveSearchToServer(String query, {bool isPlace = false, String? placeName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      print('Saving search to server...');
      print('Query: $query, isPlace: $isPlace, placeName: $placeName');
      
      if (token == null) {
        print('No token found, cannot save search');
        return;
      }

      final Map<String, dynamic> requestBody = {
        'query': query,
        'is_place': isPlace,
        'name': isPlace ? placeName : null,
      };

      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/search-history/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Save search response status: ${response.statusCode}');
      print('Save search response body: ${response.body}');

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
        print('Search saved successfully');
      } else {
        print('Failed to save search: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('검색 기록 저장에 실패했습니다: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Error saving search: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 기록 저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deleteSearchHistory(int id, int index) async {
    try {
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

      print('Delete search response status: ${response.statusCode}');

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _recentSearches.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 기록이 삭제되었습니다.')),
        );
      }
    } catch (e) {
      print('Error deleting search history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 기록 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllSearchHistory() async {
    try {
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

      print('Delete all search history response status: ${response.statusCode}');

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _recentSearches.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 검색 기록이 삭제되었습니다.')),
        );
      }
    } catch (e) {
      print('Error deleting all search history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 기록 전체 삭제 중 오류가 발생했습니다: $e')),
        );
      }
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

    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$_googleApiKey'
          '&language=ko'
          '&components=country:kr';

      final response = await http.get(Uri.parse(url));
      
      print('Places API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Places API response: ${data['status']}');
        
        if (data['status'] == 'OK') {
          if (mounted) {
            setState(() {
              _places = data['predictions'] ?? [];
              _isLoading = false;
            });
          }
        } else {
          print('Places API error: ${data['error_message']}');
          if (mounted) {
            setState(() {
              _places = [];
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('장소 검색 오류: ${data['error_message']}')),
            );
          }
        }
      } else {
        print('Places API HTTP error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _places = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장소 검색에 실패했습니다. API 키를 확인해주세요.')),
          );
        }
      }
    } catch (e) {
      print('Error searching places: $e');
      if (mounted) {
        setState(() {
          _places = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('장소 검색 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    try {
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
        } else {
          print('Place details API error: ${data['error_message']}');
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
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
    
    print('Search submitted: ${query.trim()}');
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장소 상세 정보를 불러오지 못했습니다.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제할 검색 기록이 없습니다.')),
      );
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '검색어를 입력하세요',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_searchController.text.isNotEmpty && _places.isNotEmpty)
            Expanded(child: _buildPlacesList())
          else if (_searchController.text.isNotEmpty && _isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(child: _buildRecentSearches()),
        ],
      ),
    );
  }

  Widget _buildPlacesList() {
    return ListView.builder(
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        final mainText = place['structured_formatting']?['main_text'] ?? '';
        final secondaryText = place['structured_formatting']?['secondary_text'] ?? '';

        return ListTile(
          leading: const Icon(Icons.location_on, color: Colors.red),
          title: Text(
            mainText,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            secondaryText,
            style: const TextStyle(color: Colors.grey),
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최근 검색',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _showDeleteAllConfirmDialog,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('전체 삭제'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildRecentSearchList()),
      ],
    );
  }

  Widget _buildRecentSearchList() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '최근 검색 기록이 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '검색어를 입력하거나 장소를 선택해보세요.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _recentSearches.length,
      itemBuilder: (context, index) {
        final searchItem = _recentSearches[index];
        final isPlace = searchItem['is_place'] == true;
        final displayText = isPlace 
            ? (searchItem['name'] ?? searchItem['query']) 
            : searchItem['query'];
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isPlace ? Icons.location_on : Icons.search,
              size: 20,
              color: isPlace ? Colors.red : Colors.grey,
            ),
            title: Text(
              displayText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            onTap: () => _onRecentSearchTap(searchItem),
            trailing: IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: () {
                _deleteSearchHistory(searchItem['id'], index);
              },
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 22),
        child: Divider(color: Colors.grey, height: 1),
      ),
    );
  }
}
