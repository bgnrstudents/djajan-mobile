import 'package:djajan_mobile/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'routes/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/home/customer_home_screen.dart'; 

void main() {
  runApp(const DjajanApp());
}

class DjajanApp extends StatelessWidget {
  const DjajanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Djajan',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConfig.backgroundColor,

        colorScheme: ColorScheme.fromSeed(seedColor: AppConfig.primaryColor),

        appBarTheme: const AppBarTheme(centerTitle: true),
      ),

      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.customerHome: (context) => const CustomerHomeScreen(),
      },
    );
  }
}
