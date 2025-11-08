import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
// import 'home_screen.dart'; // Không cần import vì main.dart đã xử lý

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Đổi tên controller cho rõ nghĩa
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_loginIdController.text.isEmpty || _passwordController.text.isEmpty)
      return;
    setState(() => _isLoading = true);
    try {
      // GỌI HÀM ĐĂNG NHẬP MỚI
      await _authService.signInWithEmailOrUsername(
        _loginIdController.text.trim(),
        _passwordController.text.trim(),
      );
      // Đăng nhập thành công thì StreamBuilder ở main.dart sẽ tự chuyển trang
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // Tự động chuyển trang nhờ Stream ở main.dart
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi Google Sign in: $e")));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _loginIdController,
              decoration: const InputDecoration(
                labelText: "Email hoặc Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Mật khẩu",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text("Đăng nhập"),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _handleGoogleLogin,
                        icon: const Icon(
                          Icons.login,
                          color: Colors.red,
                        ), // Bạn có thể thay icon Google xịn hơn
                        label: const Text("Đăng nhập bằng Google"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text("Chưa có tài khoản? Đăng ký ngay"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
//new login