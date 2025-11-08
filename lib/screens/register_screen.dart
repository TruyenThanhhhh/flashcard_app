import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController(); // THÊM MỚI
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleRegister() async {
    // THÊM ĐIỀU KIỆN KIỂM TRA USERNAME
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // GỌI HÀM signUpWithEmail VỚI 4 THAM SỐ
      await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _usernameController.text.trim() // GỬI USERNAME
          );
      if (mounted) Navigator.pop(context); // Đăng ký xong thì quay lại
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Thêm SingleChildScrollView để tránh lỗi tràn màn hình
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: "Họ và tên (Ví dụ: An Nguyễn)",
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              // THÊM Ô NHẬP USERNAME
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    labelText: "Username (Ví dụ: annguyen123)",
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: "Email", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: "Mật khẩu", border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      child: const Text("Đăng ký"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}