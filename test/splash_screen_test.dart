import 'dart:convert';

import 'package:djajan_mobile/routes/app_routes.dart';
import 'package:djajan_mobile/screens/splash/splash_screen.dart';
import 'package:djajan_mobile/services/api_service.dart';
import 'package:djajan_mobile/services/auth_service.dart';
import 'package:djajan_mobile/services/order_service.dart';
import 'package:djajan_mobile/services/umkm_data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'djajan_auth_token': 'saved-token',
      'djajan_auth_role': 'pelanggan',
    });
    ApiService.setToken(null);
  });

  tearDown(() {
    ApiService.setToken(null);
    ApiService.onUnauthorized = null;
    ApiService.clientForTesting = http.Client();
  });

  testWidgets('without a saved session, splash displays briefly then opens home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider(create: (_) => UmkmDataService()),
          ChangeNotifierProvider(create: (_) => OrderService()),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.customerHome: (_) =>
                const Scaffold(body: Text('Beranda')),
          },
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Beranda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Splash explains a connection issue and retries session loading',
    (tester) async {
      var requests = 0;
      ApiService.clientForTesting = MockClient((_) async {
        requests++;
        return http.Response(
          jsonEncode({
            'sukses': false,
            'pesan':
                'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
            'data': null,
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final auth = AuthService();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: auth),
            ChangeNotifierProvider(create: (_) => UmkmDataService()),
            ChangeNotifierProvider(create: (_) => OrderService()),
          ],
          child: MaterialApp(
            routes: {
              AppRoutes.customerHome: (_) =>
                  const Scaffold(body: Text('Beranda')),
            },
            home: const SplashScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Belum dapat terhubung'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(
        find.text(
          'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
        ),
        findsOneWidget,
      );
      expect(requests, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(requests, 2);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
