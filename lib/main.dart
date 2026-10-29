import 'package:djajan_mobile/config/app_config.dart';
import 'package:djajan_mobile/routes/app_routes.dart';
import 'package:djajan_mobile/services/umkm_data_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/catalog_service.dart';
import 'services/order_service.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/home/customer_home_screen.dart';
import 'screens/customer/cart/cart.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/umkm/dashboard_umkm_screen.dart';
import 'screens/umkm/pengaturan_screen.dart';
import 'screens/umkm/tambah_produk_screen.dart';
import 'screens/umkm/detail_pesanan_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi data locale untuk Intl (Indonesia)
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  runApp(const DjajanApp());
}

class DjajanApp extends StatelessWidget {
  const DjajanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CategoryService()),
        ChangeNotifierProvider(create: (_) => CatalogService()..load()),
        ChangeNotifierProvider(create: (_) => UmkmDataService()..muatSemua()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Djajan',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppConfig.backgroundColor,
          colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primaryColor),
          appBarTheme: const AppBarTheme(centerTitle: true),
        ),

        initialRoute: AppRoutes.login,

        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.customerHome: (context) => const CustomerHomeScreen(),
          AppRoutes.cart: (context) => const CartScreen(),

          // --- ROUTES UMKM (owner/seller) ---
          AppRoutes.umkmDashboard: (context) => DashboardUmkmScreen(),
          AppRoutes.umkmTambahProduk: (context) => TambahProdukScreen(),
          AppRoutes.umkmDetailPesanan: (context) =>
              DetailPesananScreen(idPesanan: ''),
          AppRoutes.umkmPengaturan: (context) => PengaturanScreen(),
        },
      ),
    );
  }
}
