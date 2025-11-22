import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  // SỬA: Xóa các tham số theme (vì AuthWrapper sẽ quản lý)
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_loginIdController.text.isEmpty || _passwordController.text.isEmpty)
      return;
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailOrUsername(
        _loginIdController.text.trim(),
        _passwordController.text.trim(),
      );
      // AuthWrapper sẽ tự điều hướng
    } catch (e) {
      // SỬA: Thêm kiểm tra 'mounted'
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    // SỬA: Thêm kiểm tra 'mounted'
    if (mounted) setState(() => _isLoading = false);
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // AuthWrapper sẽ tự điều hướng
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi Google Sign in: $e")));
      }
    } finally {
      // SỬA: Dùng 'finally' để đảm bảo _isLoading luôn là false
      // ngay cả khi người dùng hủy (hàm signIn trả về null)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                          Icons.login, // Bạn có thể thay bằng logo Google
                          color: Colors.red,
                        ),
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