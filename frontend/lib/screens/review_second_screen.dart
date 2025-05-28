import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ReviewSecondScreen extends StatefulWidget {
  final Map<String, dynamic> place;

  const ReviewSecondScreen({super.key, required this.place});

  @override
  State<ReviewSecondScreen> createState() => _ReviewSecondScreenState();
}

class _ReviewSecondScreenState extends State<ReviewSecondScreen> {
  DateTime? selectedDate;
  String? selectedRating;
  String? selectedCompanion;

  static const List<String> ratingOptions = [
    '★☆☆☆☆', '★★☆☆☆', '★★★☆☆', '★★★★☆', '★★★★★'
  ];
  static const List<String> companionOptions = [
    '혼자', '친구', '연인', '가족', '기타'
  ];

  Future<void> _showDatePickerModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Localizations(
          locale: const Locale('ko', 'KR'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SfDateRangePickerTheme(
              data: SfDateRangePickerThemeData(
                backgroundColor: Colors.white,
                headerBackgroundColor: Colors.white,
                viewHeaderBackgroundColor: Colors.white,
                selectionColor: Colors.black,
                selectionTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                todayHighlightColor: Colors.grey[800],
                todayTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                cellTextStyle: const TextStyle(color: Colors.black87),
                rangeSelectionColor: Colors.grey[300],
                headerTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                viewHeaderTextStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                leadingDatesTextStyle: const TextStyle(color: Colors.grey),
                trailingDatesTextStyle: const TextStyle(color: Colors.grey),
                disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                disabledCellTextStyle: const TextStyle(color: Colors.grey),
                weekendDatesTextStyle: const TextStyle(color: Colors.grey),
              ),
              child: SfDateRangePicker(
                selectionMode: DateRangePickerSelectionMode.single,
                initialSelectedDate: selectedDate,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is DateTime) {
                    setState(() {
                      selectedDate = args.value;
                    });
                    Navigator.pop(context);
                  }
                },
                showActionButtons: false,
              ),
            ),
          ),
        );
      },
    );
  }

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
        toolbarHeight: 80,
        leading: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 30.0),
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
              Container(height: 1, color: Colors.black),
              const SizedBox(height: 16),
              _buildCompactSelectors(context),
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
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(address, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildCompactSelectors(BuildContext context) {
    return Row(
      children: [
        // 날짜 선택
        Expanded(
          child: GestureDetector(
            onTap: () => _showDatePickerModal(context),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (selectedDate == null)
                        const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.lightBlue),
                      if (selectedDate == null) const SizedBox(width: 4),
                      Text(
                        selectedDate != null
                            ? DateFormat('yyyy.MM.dd').format(selectedDate!)
                            : '날짜',
                        style: TextStyle(
                          fontSize: 13,
                          color: selectedDate != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.expand_more),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 평점 선택
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRating,
                hint: Row(
                  children: const [
                    Icon(Icons.star_border, size: 18, color: Colors.amber),
                    SizedBox(width: 2),
                    Text('평점', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                items: ratingOptions.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text(v, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedRating = v),
                isExpanded: true,
                icon: const Icon(Icons.expand_more),
                style: const TextStyle(color: Colors.black87),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 동반인 선택
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCompanion,
                hint: Row(
                  children: const [
                    Icon(Icons.group_outlined, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 2),
                    Text('동반인', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                items: companionOptions.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text(v, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedCompanion = v),
                isExpanded: true,
                icon: const Icon(Icons.expand_more),
                style: const TextStyle(color: Colors.black87),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
                // 완료 처리 로직
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
}
