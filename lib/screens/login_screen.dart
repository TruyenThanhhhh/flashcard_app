import 'package:flutter/material.dart';
// 1. IMPORT DỊCH VỤ MỚI VÀ FIREBASE AUTH
import '../services/auth_service.dart'; // Thay thế 'sample_auth.dart'
import 'package:firebase_auth/firebase_auth.dart'; // Cần cho kiểu 'User' và xử lý lỗi
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const LoginScreen({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Dùng cho đăng ký
  final _emailController = TextEditingController(); // Chỉ dùng cho đăng ký
  final _usernameController = TextEditingController(); // Dùng cho đăng nhập và đăng ký
  
  // 3. SỬ DỤNG AUTHSERVICE THAY VÌ SAMPLEAUTH
  final AuthService _auth = AuthService();
  
  bool _isLogin = true; // Toggle between login and sign up
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    // 4. CẬP NHẬT HÀM DISPOSE
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // 5. CẬP NHẬT HÀM _handleSubmit VỚI LOGIC FIREBASE
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user; // Đổi từ SampleUser sang User? (của Firebase)
      final username = _usernameController.text.trim();

      if (_isLogin) {
        String? emailForUsername = await _auth.getEmailByUsername(username);
        final looksLikeEmail = username.contains('@') && username.contains('.');
        if (emailForUsername == null && looksLikeEmail) {
          emailForUsername = username;
        }
        if (emailForUsername == null) {
          setState(() {
            _errorMessage = 'Không tìm thấy tài khoản này.';
            _isLoading = false;
          });
          return;
        }
        user = await _auth.signInWithEmailAndPassword(
          emailForUsername,
          _passwordController.text,
        );
      } else {
        final email = _emailController.text.trim();

        final usernameTaken = await _auth.isUsernameTaken(username);
        if (usernameTaken) {
          setState(() {
            _errorMessage = 'Tài khoản này đã tồn tại. Vui lòng chọn tên khác.';
            _isLoading = false;
          });
          return;
        }

        user = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
          username: username,
          displayName: _nameController.text.trim().isNotEmpty 
              ? _nameController.text.trim() 
              : null,
        );
      }

      if (mounted && user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              onToggleTheme: widget.onToggleTheme,
              isDark: widget.isDark,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        // Dịch mã lỗi Firebase sang tiếng Việt (ví dụ)
        String rawError = e.toString().replaceAll('Exception: ', '');
        if (_isLogin) {
          _errorMessage = 'Sai tài khoản hoặc mật khẩu.';
        } else {
          switch (rawError) {
            case 'invalid-email':
              _errorMessage = 'Địa chỉ email không hợp lệ.';
              break;
            case 'wrong-password':
            case 'invalid-credential':
              _errorMessage = 'Sai tài khoản hoặc mật khẩu.';
              break;
            case 'email-already-in-use':
              _errorMessage = 'Email này đã được sử dụng.';
              break;
            case 'weak-password':
              _errorMessage = 'Mật khẩu quá yếu (cần ít nhất 6 ký tự).';
              break;
            case 'user-not-found':
              _errorMessage = 'Không tìm thấy tài khoản với email này.';
              break;
            default:
              _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
          }
        }
        _isLoading = false;
      });
    }
  }

  // 6. CẬP NHẬT HÀM _handleGoogleSignIn
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _auth.signInWithGoogle();

      if (mounted && user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              onToggleTheme: widget.onToggleTheme,
              isDark: widget.isDark,
            ),
          ),
        );
      } else if (mounted) {
        // Người dùng có thể đã hủy
        setState(() {
          _isLoading = false;
          _errorMessage = null; // Don't show error if user cancelled
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('network') || errorString.contains('connection')) {
            _errorMessage = 'Lỗi kết nối. Vui lòng kiểm tra internet và thử lại.';
          } else if (errorString.contains('sign_in_canceled') || errorString.contains('cancelled')) {
            _errorMessage = null; // User cancelled, don't show error
          } else {
            _errorMessage = 'Đăng nhập Google thất bại: ${e.toString().replaceAll('Exception: ', '')}';
          }
          _isLoading = false;
        });
      }
    }
  }

  // 7. CẬP NHẬT HÀM _handleFacebookSignIn
  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _auth.signInWithFacebook();

      if (mounted && user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              onToggleTheme: widget.onToggleTheme,
              isDark: widget.isDark,
            ),
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('unimplemented')) {
            _errorMessage = 'Đăng nhập Facebook hiện không khả dụng trên Windows. Vui lòng sử dụng Email hoặc Google để đăng nhập.';
          } else {
            _errorMessage = 'Đăng nhập Facebook thất bại: ${e.toString().replaceAll('Exception: ', '')}';
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo
                Center(
                  child: Image.asset(
                    'images/StudyMateRemoveBG.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  _isLogin ? 'Chào mừng trở lại!' : 'Tạo tài khoản mới',
                  // ... giữ nguyên ...
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin 
                    ? 'Đăng nhập để tiếp tục học tập'
                    : 'Bắt đầu hành trình học tập của bạn',
                  // ... giữ nguyên ...
                ),
                const SizedBox(height: 40),
                
                // Name field (only for sign up)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: isDark ? Color(0xFF1E293B) : Colors.white,
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Color(0xFF1E293B)),
                    validator: (value) {
                      if (!_isLogin && (value == null || value.trim().isEmpty)) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Tài khoản',
                    hintText: 'Nhập tài khoản',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  ),
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tài khoản';
                    }
                    if (value.contains(' ')) {
                      return 'Tài khoản không được chứa dấu cách';
                    }
                    if (value.length < 3) {
                      return 'Tài khoản phải có ít nhất 3 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    autofillHints: const [AutofillHints.email],
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Email đăng ký',
                      hintText: 'vidu@studymate.com',
                      prefixIcon: const Icon(Icons.mail_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    ),
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    validator: (value) {
                      if (_isLogin) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Password field (Giữ nguyên)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: isDark ? Color(0xFF1E293B) : Colors.white,
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Color(0xFF1E293B)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (!_isLogin && value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Error message (Giữ nguyên)
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),
                
                // Submit button (Giữ nguyên)
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isLogin ? 'Đăng nhập' : 'Đăng ký',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                
                // Divider (Giữ nguyên)
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Hoặc',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Google Sign-In button (Giữ nguyên)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Image.asset(
                    'images/google_logo.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.g_mobiledata,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 24,
                      );
                    },
                  ),
                  label: Text(
                    'Tiếp tục với Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Facebook Sign-In button (Giữ nguyên)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleFacebookSignIn,
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(0xFF1877F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        'f',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  label: Text(
                    'Tiếp tục với Facebook',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Toggle between login and sign up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _errorMessage = null;
                          _passwordController.clear();
                          _usernameController.clear();
                          _emailController.clear();
                          if (_isLogin) {
                            _nameController.clear();
                          }
                        });
                      },
                      child: Text(
                        _isLogin ? 'Đăng ký' : 'Đăng nhập',
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}