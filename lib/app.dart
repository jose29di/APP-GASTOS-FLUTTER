import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/theme/app_theme.dart';
import 'package:gastos_erp_tracker/core/services/auth_service.dart';
import 'package:gastos_erp_tracker/features/auth/login_screen.dart';
import 'package:gastos_erp_tracker/features/home/home_shell.dart';

class ExpenseErpApp extends StatelessWidget {
  const ExpenseErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Caja & Tributos',
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final loggedIn = await AuthService.validateSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => loggedIn ? const HomeShell() : const LoginScreen(),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error al iniciar:\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() => _error = null);
                  _checkAuth();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
