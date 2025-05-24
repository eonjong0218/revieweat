import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:developer';

import 'search_result_screen.dart'; // 결과 페이지 import 추가

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

  final List<String> _recentSearches = [];
  final String _googleApiKey = 'AIzaSyAufgjB4H_wW06l9FtmFz8wPTiq15ALKuU';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterTap(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('필터 "$label" 기능은 준비중입니다.')),
    );
  }

  void _onSearchChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      if (input.trim().isEmpty) {
        setState(() {
          _places = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final encodedInput = Uri.encodeComponent(input);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&key=$_googleApiKey&language=ko&components=country:kr');

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['status'] == 'OK') {
            setState(() {
              _places = json['predictions'];
            });
          } else {
            setState(() {
              _places = [];
            });
            log('Places API 오류: ${json['status']}');
          }
        } else {
          log('HTTP 오류: ${response.statusCode}');
        }
      } catch (e, stacktrace) {
        log('예외 발생: $e', stackTrace: stacktrace);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey&language=ko&fields=geometry,name,formatted_address');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          return json['result'];
        } else {
          log('Place Details API 오류: ${json['status']}');
        }
      } else {
        log('HTTP 오류 (place details): ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      log('예외 발생 (place details): $e', stackTrace: stacktrace);
    }
    return null;
  }

  void _onPlaceTap(dynamic place) async {
    final placeId = place['place_id'];
    final details = await _getPlaceDetails(placeId);

    if (!mounted) return;

    if (details != null && details['geometry'] != null) {
      final location = details['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];
      final name = place['description'] ?? details['name'] ?? '';
      final address = details['formatted_address'] ?? '';

      if (name.isNotEmpty) {
        setState(() {
          _addToRecentSearches(name);
        });
      }

      // 특정 장소 선택 시 해당 장소만 표시
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultScreen(
            initialQuery: details['name'] ?? name,
            isSpecificPlace: true,
            placeDetails: {
              'name': details['name'] ?? name,
              'address': address,
              'lat': lat,
              'lng': lng,
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소 상세 정보를 불러오지 못했습니다.')),
      );
    }
  }

  void _addToRecentSearches(String query) {
    _recentSearches.removeWhere((element) => element == query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _addToRecentSearches(query.trim());
      _places = [];
    });

    // 일반 검색어로 결과 화면으로 이동 (현재 위치 기준 검색)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          initialQuery: query.trim(),
          isSpecificPlace: false,
        ),
      ),
    );
  }

  void _onRecentSearchTap(String query) {
    // 최근 검색어 클릭 시 결과 화면으로 이동 (일반 검색)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          initialQuery: query,
          isSpecificPlace: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 22,
                        color: Colors.black45,
                      ),
                      splashRadius: 20,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: '장소 및 주소 검색',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchSubmitted,
                      ),
                    ),
                    Icon(Icons.mic, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterButton(label: '중심점', onTap: _onFilterTap),
                    FilterButton(label: '카테고리', onTap: _onFilterTap),
                    FilterButton(label: '방문상태', onTap: _onFilterTap),
                    FilterButton(label: '평점', onTap: _onFilterTap),
                    FilterButton(label: '동반여부', onTap: _onFilterTap),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _searchController.text.trim().isEmpty
                  ? _buildRecentSearchList()
                  : _buildPlacesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchList() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text(
          '최근 검색 기록이 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _recentSearches.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, size: 20),
          title: Text(
            _recentSearches[index],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          onTap: () => _onRecentSearchTap(_recentSearches[index]),
          trailing: IconButton(
            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
            onPressed: () {
              setState(() {
                _recentSearches.removeAt(index);
              });
            },
          ),
        ),
      ),
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 22),
        child: Divider(color: Colors.grey, height: 1),
      ),
    );
  }

  Widget _buildPlacesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_places.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(place['description'] ?? ''),
          onTap: () => _onPlaceTap(place),
        );
      },
      separatorBuilder: (_, __) => const Divider(),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final void Function(String) onTap;

  const FilterButton({required this.label, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => onTap(label),
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
}