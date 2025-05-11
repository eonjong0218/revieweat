import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revieweat/main.dart';

void main() {
  testWidgets('앱이 정상적으로 렌더링되는지 확인', (WidgetTester tester) async {
    await tester.pumpWidget(const ReviewEatApp());

    // Splash 화면의 로고가 잘 보이는지 확인 (텍스트나 위젯 등으로 판별)
    expect(find.byType(Image), findsOneWidget);
  });
}
