import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; // MỚI: Import NotificationService

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const SettingsScreen({super.key, this.onToggleTheme, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    // Lấy trạng thái theme hiện tại từ hệ thống để hiển thị đúng màu
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Cài đặt',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === PHẦN TÀI KHOẢN ===
          _buildSectionHeader('Tài khoản', isDarkTheme),
          _buildSettingsCard(
            context,
            isDarkTheme,
            children: [
              _buildSettingsTile(
                context,
                isDarkTheme,
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
                isDarkTheme,
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
          
          // === PHẦN CÀI ĐẶT ỨNG DỤNG ===
          _buildSectionHeader('Cài đặt ứng dụng', isDarkTheme),
          _buildSettingsCard(
            context,
            isDarkTheme,
            children: [
               _buildSettingsTile(
                context,
                isDarkTheme,
                // Icon thay đổi tùy theo theme
                icon: isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                title: 'Chế độ hiển thị',
                subtitle: isDarkTheme ? 'Đang ở chế độ tối' : 'Đang ở chế độ sáng',
                onTap: onToggleTheme,
              ),
              const Divider(height: 1),
              
              // MỚI: TÍCH HỢP NOTIFICATION SERVICE
              _buildSettingsTile(
                context,
                isDarkTheme,
                icon: Icons.notifications_active,
                title: 'Nhắc nhở học tập',
                subtitle: 'Nhắc học bài lúc 20:00 hàng ngày',
                onTap: () async {
                  // 1. Lên lịch thông báo
                  await NotificationService().scheduleDailyNotification();
                  
                  // 2. (Tùy chọn) Gửi thử 1 thông báo ngay lập tức để test
                  // await NotificationService().showInstantNotification(
                  //   title: "Đã bật nhắc nhở!", 
                  //   body: "Bạn sẽ nhận được thông báo vào 20:00 mỗi ngày."
                  // );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã đặt lịch nhắc nhở hàng ngày!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // === PHẦN VỀ ỨNG DỤNG ===
          _buildSectionHeader('Về ứng dụng', isDarkTheme),
          _buildSettingsCard(
            context,
            isDarkTheme,
            children: [
               _buildSettingsTile(
                context,
                isDarkTheme,
                icon: Icons.info,
                title: 'Phiên bản',
                subtitle: '1.0.0',
                onTap: null, // Không làm gì khi bấm vào
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // === PHẦN KHÁC (ĐĂNG XUẤT) ===
          _buildSectionHeader('Khác', isDarkTheme),
          _buildSettingsCard(
            context,
            isDarkTheme,
            children: [
              _buildSettingsTile(
                context,
                isDarkTheme,
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

  // --- CÁC WIDGET PHỤ TRỢ GIỮ NGUYÊN ---

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
      clipBehavior: Clip.antiAlias, // Bo góc cho nội dung bên trong
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
          color: textColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
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
                await auth.signOut();
                // Không cần làm gì thêm, StreamBuilder ở AuthWrapper sẽ tự điều hướng về LoginScreen
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