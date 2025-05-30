import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class ReviewFinalScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  final DateTime selectedDate;
  final String selectedRating;
  final String selectedCompanion;

  const ReviewFinalScreen({
    super.key,
    required this.place,
    required this.selectedDate,
    required this.selectedRating,
    required this.selectedCompanion,
  });

  @override
  State<ReviewFinalScreen> createState() => _ReviewFinalScreenState();
}

class _ReviewFinalScreenState extends State<ReviewFinalScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  // 파일 크기 제한 (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'};

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> permissions = await [
        Permission.photos,
        Permission.camera,
      ].request();
      
      bool allGranted = permissions.values.every(
        (status) => status == PermissionStatus.granted || status == PermissionStatus.limited
      );
      
      if (!allGranted) {
        // 권한이 거부된 경우 설정으로 이동
        await openAppSettings();
        return false;
      }
      
      return true;
    }
    return true;
  }

  Future<void> _pickImages() async {
    // 권한 요청 먼저 실행
    bool hasPermission = await _requestPermissions();
    
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 접근 권한이 필요합니다.')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      if (kDebugMode) {
        developer.log('선택된 이미지 개수: ${images.length}', name: 'ImagePicker');
      }
      
      for (var image in images) {
        if (kDebugMode) {
          developer.log('선택된 이미지: ${image.path}', name: 'ImagePicker');
        }
      }
      
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
      
      if (kDebugMode) {
        developer.log('현재 총 이미지 개수: ${_selectedImages.length}', name: 'ImagePicker');
      }
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        developer.log('=== 리뷰 저장 시작 ===', name: 'ReviewSubmit');
        developer.log('선택된 이미지 개수: ${_selectedImages.length}', name: 'ReviewSubmit');
      }
      
      // 이미지 파일 검증
      for (int i = 0; i < _selectedImages.length; i++) {
        var imageFile = _selectedImages[i];
        
        if (kDebugMode) {
          developer.log('이미지 $i: ${imageFile.path}', name: 'ReviewSubmit');
          developer.log('파일 존재 여부: ${await imageFile.exists()}', name: 'ReviewSubmit');
        }
        
        // 파일 크기 확인
        int fileSize = await imageFile.length();
        if (kDebugMode) {
          developer.log('파일 크기: $fileSize bytes', name: 'ReviewSubmit');
        }
        
        if (fileSize > maxFileSize) {
          throw Exception('이미지 크기가 너무 큽니다 (최대 5MB)');
        }
        
        // 파일 확장자 확인
        String extension = imageFile.path.split('.').last.toLowerCase();
        if (!allowedExtensions.contains('.$extension')) {
          throw Exception('지원하지 않는 이미지 형식입니다');
        }
      }

      // 저장된 토큰 가져오기
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      
      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      var uri = Uri.parse('http://192.168.0.6:8000/api/reviews'); 
      var request = http.MultipartRequest('POST', uri);
      
      // Authorization 헤더 추가
      request.headers['Authorization'] = 'Bearer $token';

      // 장소 정보
      request.fields['place_name'] = widget.place['name']?.toString() ?? '';
      request.fields['place_address'] = widget.place['formatted_address']?.toString() ?? '';

      // 날짜, 평점, 동반자
      request.fields['review_date'] = widget.selectedDate.toIso8601String();
      request.fields['rating'] = widget.selectedRating;
      request.fields['companion'] = widget.selectedCompanion;

      // 리뷰 텍스트
      request.fields['review_text'] = _reviewController.text.trim();

      // 이미지 파일들 (멀티파트) - 필드명 수정
      if (kDebugMode) {
        developer.log('이미지 파일 추가 시작...', name: 'ReviewSubmit');
      }
      
      for (int i = 0; i < _selectedImages.length; i++) {
        var imageFile = _selectedImages[i];
        if (kDebugMode) {
          developer.log('처리 중인 이미지 $i: ${imageFile.path}', name: 'ReviewSubmit');
        }
        
        final String mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        final List<String> mimeSplit = mimeType.split('/');

        var multipartFile = await http.MultipartFile.fromPath(
          'images', // 백엔드에서 기대하는 필드명으로 수정
          imageFile.path,
          contentType: MediaType(mimeSplit[0], mimeSplit[1]),
        );
        
        request.files.add(multipartFile);
        
        if (kDebugMode) {
          developer.log('이미지 $i 추가 완료: ${multipartFile.filename}, 크기: ${multipartFile.length}', name: 'ReviewSubmit');
        }
      }
      
      if (kDebugMode) {
        developer.log('총 추가된 파일 개수: ${request.files.length}', name: 'ReviewSubmit');
      }

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          developer.log('✅ 리뷰 저장 성공', name: 'ReviewSubmit');
        }
        
        // 저장 성공 시 success 화면으로 이동
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/review_success',
          arguments: {
            'place': widget.place,
            'selectedDate': widget.selectedDate,
            'selectedRating': widget.selectedRating,
            'selectedCompanion': widget.selectedCompanion,
            'reviewText': _reviewController.text.trim(),
            'images': _selectedImages,
          },
        );
      } else if (response.statusCode == 401) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        // 응답 본문 읽기
        final responseBody = await response.stream.bytesToString();
        if (kDebugMode) {
          developer.log('❌ 서버 응답 오류: ${response.statusCode} - $responseBody', name: 'ReviewSubmit');
        }
        throw Exception('리뷰 저장 실패: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ 리뷰 저장 오류: $e', name: 'ReviewSubmit');
      }
      
      // 에러 처리
      if (!mounted) return;
      
      String errorMessage = '리뷰 저장 중 오류가 발생했습니다.';
      String errorString = e.toString();
      
      if (errorString.contains('SocketException')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      } else if (errorString.contains('TimeoutException')) {
        errorMessage = '서버 응답 시간이 초과되었습니다.';
      } else if (errorString.contains('로그인이 필요합니다')) {
        errorMessage = '로그인이 필요합니다.';
      } else if (errorString.contains('인증이 만료되었습니다')) {
        errorMessage = '인증이 만료되었습니다. 다시 로그인해주세요.';
      } else if (errorString.contains('이미지 크기가 너무 큽니다')) {
        errorMessage = '이미지 크기가 너무 큽니다 (최대 5MB)';
      } else if (errorString.contains('지원하지 않는 이미지 형식')) {
        errorMessage = '지원하지 않는 이미지 형식입니다 (JPG, PNG만 가능)';
      }
      
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha((0.26 * 255).round()),
        builder: (BuildContext context) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).round()),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((0.1 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> place = widget.place;
    final String name = place['name']?.toString() ?? '';
    final String address = place['formatted_address']?.toString() ?? '';
    final String date = DateFormat('yyyy.MM.dd').format(widget.selectedDate);
    final String rating = widget.selectedRating;
    final String companion = widget.selectedCompanion;

    final bool isReady = _reviewController.text.trim().isNotEmpty && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        centerTitle: true,
        title: null,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
              tooltip: '뒤로가기',
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(name, address, date, rating, companion),
              const SizedBox(height: 24),
              _buildImagePickerSection(),
              const SizedBox(height: 24),
              const Text(
                '리뷰 작성',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 8,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '내용을 입력해주세요...',
                  hintStyle: const TextStyle(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isReady ? _submitReview : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady ? Colors.black : Colors.grey[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text('리뷰 등록', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String name, String address, String date, String rating, String companion) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(address, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.lightBlue),
                  const SizedBox(width: 4),
                  Text(date, style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.star_border, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(rating, style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.group_outlined, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(companion, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '사진 첨부',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_selectedImages.length}/10)',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // 사진 추가 버튼
              if (_selectedImages.length < 10)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 150,
                    height: 150,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                ),
              // 선택된 이미지들
              ..._selectedImages.asMap().entries.map((entry) {
                int index = entry.key;
                File file = entry.value;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
