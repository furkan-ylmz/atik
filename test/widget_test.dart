import 'package:flutter_test/flutter_test.dart';
import 'package:atik/main.dart';
import 'package:atik/presentation/splash/splash_screen.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Uygulamayı başlat
    await tester.pumpWidget(const WasteDetectionApp());

    // SplashScreen'in render olduğunu doğrula
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Atık Tespit'), findsOneWidget);
    expect(find.text('Akıllı Geri Dönüşüm Asistanı'), findsOneWidget);
  });
}
