import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import 'order_model.dart';
import 'order_service.dart';
import '../../../widgets/app_bottom_navigation.dart';
import 'order_checkout_screen.dart';
import 'order_list_screen.dart';

/// Pintu masuk DEMO / presentasi fitur Pesanan.
///
/// Jalankan:
///   flutter run -t lib/screens/customer/order/order_demo.dart
///
/// Aplikasi langsung terbuka di halaman Checkout (isian sudah terisi), lalu:
///   Checkout -> Proses Checkout -> Status Pesanan -> kembali ke daftar Pesanan.
/// File ini hanya untuk demo dan tidak memengaruhi main.dart.
void main() => runApp(const OrderDemoApp());

class OrderDemoApp extends StatelessWidget {
  const OrderDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Djajan - Demo Pesanan',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConfig.backgroundColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primaryColor),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const _DemoRoot(),
    );
  }
}

/// Dasar navigasi: tab Pesanan. Checkout langsung dibuka di atasnya.
class _DemoRoot extends StatefulWidget {
  const _DemoRoot();

  @override
  State<_DemoRoot> createState() => _DemoRootState();
}

class _DemoRootState extends State<_DemoRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OrderCheckoutScreen(
            cartLines: SampleData.cart,
            initialPurpose: 'Rapat Desa RT 02',
            initialNote:
                'Sambal dipisah, kemangi dipacking rapi untuk bapak-bapak lurah',
            initialMethod: PaymentMethod.qris,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Djajan')),
      body: const OrderListScreen(),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onDestinationSelected: (_) {},
      ),
    );
  }
}
