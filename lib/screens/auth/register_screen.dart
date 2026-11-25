import 'package:flutter/material.dart';

import 'auth_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialMode: AuthMode.register);
  }
}
