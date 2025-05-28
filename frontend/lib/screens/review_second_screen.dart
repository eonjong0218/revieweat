import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReviewSecondScreen extends StatefulWidget {
  final Map<String, dynamic> place;

  const ReviewSecondScreen({Key? key, required this.place}) : super(key: key);

  @override
  State<ReviewSecondScreen> createState() => _ReviewSecondScreenState();
}

class _ReviewSecondScreenState extends State<ReviewSecondScreen> {
  String? selectedDate;
  String? selectedRating;
  String? selectedCompanion;

  static const List<String> dateOptions = ['2025-05-27', '2025-05-28', '2025-05-29'];
  static const List<String> ratingOptions = ['★☆☆☆☆', '★★☆☆☆', '★★★☆☆', '★★★★☆', '★★★★★'];
  static const List<String> companionOptions = ['혼자', '친구', '연인', '가족', '기타'];

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final name = place['name'] ?? '';
    final address = place['formatted_address'] ?? '';
    final lat = place['geometry']?['location']?['lat'] ?? 35.3350;
    final lng = place['geometry']?['location']?['lng'] ?? 129.0089;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: SizedBox.shrink(), // ← 왼쪽 상단 뒤로가기 버튼 완전 삭제
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMap(lat, lng, name),
              _buildPlaceInfo(name, address),
              const SizedBox(height: 16),
              _buildDropdowns(),
              const SizedBox(height: 32),
              _buildCompleteButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(double lat, double lng, String name) {
    return Container(
      height: 320,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('selected_place'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          liteModeEnabled: true,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildPlaceInfo(String name, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Row(
          children: const [
            Text(
              '카페',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            SizedBox(width: 8),
            Text(
              '150m',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          address,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDropdowns() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedDate,
            decoration: _dropdownDecoration('날짜 선택'),
            items: dateOptions.map(_buildMenuItem).toList(),
            onChanged: (v) => setState(() => selectedDate = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedRating,
            decoration: _dropdownDecoration('평점 선택'),
            items: ratingOptions.map(_buildMenuItem).toList(),
            onChanged: (v) => setState(() => selectedRating = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedCompanion,
            decoration: _dropdownDecoration('동반인'),
            items: companionOptions.map(_buildMenuItem).toList(),
            onChanged: (v) => setState(() => selectedCompanion = v),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildMenuItem(String value) {
    return DropdownMenuItem(
      value: value,
      child: Text(value),
    );
  }

  Widget _buildCompleteButton() {
    final isEnabled = selectedDate != null &&
        selectedRating != null &&
        selectedCompanion != null;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                // TODO: 완료 후 처리 로직 추가
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.black : Colors.grey[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '선택 완료',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }
}
