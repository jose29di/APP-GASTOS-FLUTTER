import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/services/auth_service.dart';
import 'package:gastos_erp_tracker/features/home/home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCon = TextEditingController();
  final _passwordCon = TextEditingController();
  final _nameCon = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isRegister) {
        final user = await AuthService.register(
          _nameCon.text.trim(),
          _emailCon.text.trim(),
          _passwordCon.text,
        );
        if (user == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El correo ya está registrado o datos inválidos'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _loading = false);
          return;
        }
      }

      final user = await AuthService.login(_emailCon.text.trim(), _passwordCon.text);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credenciales inválidas'), behavior: SnackBarBehavior.floating),
          );
        }
        setState(() => _loading = false);
        return;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const HomeShell(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCon.dispose();
    _passwordCon.dispose();
    _nameCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text('Caja & Tributos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Control financiero para profesionales', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 36),
                  if (_isRegister)
                    TextFormField(
                      controller: _nameCon,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  if (_isRegister) const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCon,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCon,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (v.length < 4) return 'Mínimo 4 caracteres';
                      if (_isRegister && v.length < 6) return 'Mínimo 6 caracteres para registro';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isRegister ? 'Crear cuenta' : 'Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
