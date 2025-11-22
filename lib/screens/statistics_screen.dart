import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../services/firestore_service.dart';

class StatisticsScreen extends StatefulWidget {
  final Map<String, dynamic> userStats;
  const StatisticsScreen({super.key, required this.userStats});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirestoreService _db = FirestoreService();
  late Future<List<Map<String, dynamic>>> _weeklyDataFuture;
  late Future<List<QueryDocumentSnapshot>> _recentSessionsFuture;
  
  // Biến lưu số lượng bộ đề (Sets)
  int _totalSets = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _weeklyDataFuture = _db.getWeeklyStudyData();
    _recentSessionsFuture = _db.getRecentSessions(5);
    
    // Gọi hàm đếm số lượng bộ đề từ FirestoreService
    _db.getFlashcardSetsCount().then((value) {
      if (mounted) {
        setState(() {
          _totalSets = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
        // Đợi một chút để UI cập nhật
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------------------
          // 1. HEADER TỔNG QUAN
          // ---------------------------
          Text(
            'Tổng quan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),

          // GridView Thống kê (Đã fix lỗi overflow)
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 120, // Cố định chiều cao thẻ
            ),
            children: [
              _buildStatCard('Chuỗi ngày', '${widget.userStats['streak'] ?? 0}',
                  Icons.local_fire_department, Colors.orange, isDark),
              
              _buildStatCard('Tổng giờ',
                  '${(widget.userStats['totalHours'] as num? ?? 0).toStringAsFixed(1)}h',
                  Icons.timer, Colors.green, isDark),
              
              // 🔥 Cập nhật: Hiển thị số Bộ đề thay vì Flashcards
              _buildStatCard('Bộ đề', 
                  '$_totalSets', 
                  Icons.folder_copy, // Icon folder
                  Colors.blue, isDark),
                  
              _buildStatCard('Ghi chú',
                  '${widget.userStats['totalNotes'] ?? 0}',
                  Icons.edit_note, Colors.purple, isDark),
            ],
          ),

          const SizedBox(height: 32),

          // ---------------------------
          // 2. BIỂU ĐỒ HOẠT ĐỘNG TUẦN
          // ---------------------------
          Text(
            'Hoạt động tuần này',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),

          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _weeklyDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Chưa có dữ liệu tuần này"));
                }

                double maxY = 5.0;
                try {
                  final maxData = snapshot.data!
                      .map((e) => (e['hours'] as num).toDouble())
                      .reduce(max);
                  maxY = maxData * 1.2;
                } catch (e) {
                  maxY = 5.0;
                }
                if (maxY == 0) maxY = 5.0;

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY + 0.5,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)}h',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= snapshot.data!.length) {
                              return const SizedBox();
                            }
                            final date = snapshot.data![index]['day'] as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('E').format(date),
                                style: TextStyle(color: subTextColor, fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: snapshot.data!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final hours = (data['hours'] as num).toDouble();

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: hours,
                            color: Colors.indigo,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // ---------------------------
          // 3. LỊCH SỬ HỌC TẬP
          // ---------------------------
          Text(
            'Lịch sử học tập',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _recentSessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 100, child: Center(child: CircularProgressIndicator()));
              }

              final docs = snapshot.data ?? [];

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text("Chưa có lịch sử học tập", style: TextStyle(color: subTextColor)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final isQuiz = data['type'] == 'quiz';
                  final timestamp = data['timestamp'];
                  final date = (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isQuiz ? Colors.orange : Colors.blue).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isQuiz ? Icons.quiz : Icons.school,
                          color: isQuiz ? Colors.orange : Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        data['categoryName'] ?? 'Không tên',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(date),
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isQuiz
                                ? '${data['quizScore']}/${data['totalQuestions']}'
                                : '${data['cardsLearned']} thẻ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isQuiz ? Colors.orange : Colors.blue),
                          ),
                          Text(
                            isQuiz ? 'Điểm' : 'Đã học',
                            style: TextStyle(fontSize: 10, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget thẻ thống kê đã tối ưu
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            title,
            style: TextStyle(
              fontSize: 12, 
              color: isDark ? Colors.grey[400] : Colors.grey[600]
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}