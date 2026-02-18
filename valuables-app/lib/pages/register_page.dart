import 'package:flutter/material.dart';
import 'package:valuables/auth/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Authentication service instance
  final authService = AuthService();

  // User personal email controller
  final _emailController = TextEditingController();
  // User password controller
  final _passwordController = TextEditingController();
  // Controller for ensuring the same password
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Confirm the password
    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password don't match")));
      return;
    }

    try {
      await authService.signUpWithEmailPassword(email, password);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $err")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: ListView(
        children: [
          TextField(controller: _emailController),
          TextField(controller: _passwordController, obscureText: true),
          TextField(controller: _confirmPasswordController, obscureText: true),
          ElevatedButton(onPressed: signUp, child: const Text("Sign Up")),
        ],
      ),
    );
  }
}
