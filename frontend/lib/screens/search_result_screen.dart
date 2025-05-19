import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_screen.dart'; // home_screen 경로에 맞게 조정하세요

class SearchResultScreen extends StatefulWidget {
  final String initialQuery;
  const SearchResultScreen({super.key, required this.initialQuery});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late TextEditingController _searchController;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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

  Widget _buildRefreshLocationButton() {
    return GestureDetector(
      onTap: () async {
        final center = await _mapController.getLatLng(
          ScreenCoordinate(
            x: MediaQuery.of(context).size.width ~/ 2,
            y: MediaQuery.of(context).size.height ~/ 2,
          ),
        );
        // TODO: center 기준 재검색 로직 구현
        print('현 위치 기준 재검색: ${center.latitude}, ${center.longitude}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(35.2271, 129.0790), // 부산대 근처
              zoom: 14,
            ),
            myLocationEnabled: true,
          ),

          // 검색바 (search_screen과 동일한 위치)
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
                      decoration: const InputDecoration(
                        hintText: '장소 및 주소 검색',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (query) {
                        print('검색어 제출: $query');
                        // 재검색 기능 등 추가 가능
                      },
                    ),
                  ),

                  // 아이콘들 Row 수정: 마이크 왼쪽으로 이동 + 오른쪽에 X 아이콘 추가
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8), // 마이크 왼쪽으로 이동 효과
                        child: Icon(Icons.mic, color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () {
                          // home_screen으로 이동 (기존 경로에 맞게 import 조정 필요)
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

          // 재검색 버튼 - 검색창 바로 아래 중앙에 위치
          Positioned(
            top: 60 + 48 + 8, // 116
            left: 0,
            right: 0,
            child: Center(child: _buildRefreshLocationButton()),
          ),

          // DraggableScrollableSheet - 내부 컨텐츠 위쪽 여백 및 필터 패딩 줄임
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
                  padding: const EdgeInsets.only(top: 12), // 상단 여백 줄임
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // 필터 버튼 패딩 줄임
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
                    // 샘플 장소 카드들
                    _buildPlaceCard(
                      title: '민들레 식당',
                      desc: '부산 부산진구 동성로87번길 28 2층',
                      phone: '0507-1354-0094',
                      tags: '혼자 방문',
                    ),
                    _buildPlaceCard(
                      title: '부산대학교',
                      desc: '부산광역시 양산시 물금읍 부산대학교 49 양산캠퍼스',
                      phone: '051-512-0311',
                      tags: '미방문',
                    ),
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
  }) {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 14),
              const Text(' 4.0', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(tags, style: const TextStyle(fontSize: 12)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc),
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
