import 'package:flutter/material.dart';
import '../services/auth_service.dart';
// SỬA: Xóa import LoginScreen vì StreamBuilder sẽ tự điều hướng
// import 'login_screen.dart'; 

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const SettingsScreen({super.key, this.onToggleTheme, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    // SỬA: Lấy isDark từ widget.isDark, không phải Theme.of(context)
    // vì theme có thể đang ở 'system'.
    final isDark = widget.isDark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: const Text(
          'Cài đặt',
          // SỬA: Không cần style vì nó sẽ lấy từ theme
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            // SỬA: Không cần màu vì AppBar theme sẽ xử lý
            // color: isDark ? Colors.white : Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Tài khoản', isDark),
          _buildSettingsCard(
            context,
            isDark,
            children: [
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.person,
                title: 'Thông tin cá nhân',
                subtitle: 'Xem và chỉnh sửa thông tin tài khoản',
                onTap: () {
                  _showComingSoon(context);
                },
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.lock,
                title: 'Bảo mật',
                subtitle: 'Đổi mật khẩu và quản lý bảo mật',
                onTap: () {
                  _showComingSoon(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Cài đặt ứng dụng', isDark),
          _buildSettingsCard(
            context,
            isDark,
            children: [
               _buildSettingsTile(
                context,
                isDark,
                icon: isDark ? Icons.dark_mode : Icons.light_mode,
                title: 'Chế độ hiển thị',
                subtitle: isDark ? 'Đang ở chế độ tối' : 'Đang ở chế độ sáng',
                onTap: onToggleTheme, // Gán hàm
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.notifications,
                title: 'Thông báo',
                subtitle: 'Quản lý thông báo và nhắc nhở',
                onTap: () {
                  _showComingSoon(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Về ứng dụng', isDark),
          _buildSettingsCard(
            context,
            isDark,
            children: [
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.info,
                title: 'Phiên bản',
                subtitle: '1.0.0',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Khác', isDark),
          _buildSettingsCard(
            context,
            isDark,
            children: [
              _buildSettingsTile(
                context,
                isDark,
                icon: Icons.logout,
                title: 'Đăng xuất',
                subtitle: 'Đăng xuất khỏi tài khoản',
                textColor: Colors.red,
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      // SỬA: Dùng ClipRRect để bo góc
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? Colors.indigo).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? Colors.indigo,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? (isDark ? Colors.white : Color(0xFF1E293B)),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            )
          : null,
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sắp ra mắt'),
        content: const Text('Tính năng này đang được phát triển và sẽ sớm có mặt!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final auth = AuthService(); 
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                //
                // ==================================================
                // SỬA LỖI: Chỉ cần gọi signOut.
                // StreamBuilder trong splash_screen sẽ tự động
                // điều hướng về LoginScreen.
                // ==================================================
                //
                await auth.signOut();
                
                //
                // SỬA: XÓA TOÀN BỘ LOGIC NAVIGATOR.PUSHANDREMOVEUNTIL
                //
                
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi đăng xuất: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}