import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';

class GroupAnalyticsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupAnalyticsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupAnalyticsScreen> createState() => _GroupAnalyticsScreenState();
}

class _GroupAnalyticsScreenState extends ConsumerState<GroupAnalyticsScreen> {
  String _selectedFilter = 'الكل'; // 'الكل', 'آخر شهر', 'آخر 4 أسابيع'

  String _maskStudentName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length <= 2) return fullName;
    final firstTwo = parts.take(2).join(' ');
    final maskedRemaining = parts.skip(2).map((p) {
      if (p.isEmpty) return '';
      final firstLetter = p[0];
      return '$firstLetter***';
    }).join(' ');
    return '$firstTwo $maskedRemaining';
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final analyticsAsync = ref.watch(groupAnalyticsProvider(widget.groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'تحليلاتي والترتيب • ${widget.groupName}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(groupAnalyticsProvider(widget.groupId)),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: branding.primaryColor)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                Text('تعذر تحميل إحصائيات المجموعة', style: GoogleFonts.cairo(fontSize: 15)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(groupAnalyticsProvider(widget.groupId)),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('لا توجد بيانات متاحة حالياً'));
          }

          final myRank = data['myRank'] ?? 1;
          final totalStudents = data['totalStudents'] ?? 1;
          final avgScore = data['avgScore'] ?? 100;
          final attendanceRate = data['attendanceRate'] ?? 100;
          final rawProgress = List<Map<String, dynamic>>.from(data['weeklyProgress'] ?? []);
          final leaderboard = List<Map<String, dynamic>>.from(data['topLeaderboard'] ?? []);

          // Filter weekly progress
          List<Map<String, dynamic>> filteredProgress = rawProgress;
          if (_selectedFilter == 'آخر 4 أسابيع' && rawProgress.length > 4) {
            filteredProgress = rawProgress.sublist(rawProgress.length - 4);
          } else if (_selectedFilter == 'آخر شهر' && rawProgress.length > 5) {
            filteredProgress = rawProgress.sublist(rawProgress.length - 5);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // 1. Top Metrics Cards (Rank, Avg Score, Attendance)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ترتيبي بالمجموعة',
                      value: '#$myRank',
                      subtitle: 'من أصل $totalStudents طالب',
                      icon: LucideIcons.trophy,
                      color: myRank == 1 ? Colors.amber : branding.primaryColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'متوسط الدرجات',
                      value: '$avgScore%',
                      subtitle: 'مستوى متميز',
                      icon: LucideIcons.lineChart,
                      color: Colors.green,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'نسبة الحضور',
                      value: '$attendanceRate%',
                      subtitle: 'الالتزام بالحضور',
                      icon: LucideIcons.calendarCheck,
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Weekly Progress Chart
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.trendingUp, size: 20, color: branding.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'تقدم',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        // Filter Pills
                        Row(
                          children: ['الكل', 'آخر 4 أسابيع'].map((filter) {
                            final isSel = _selectedFilter == filter;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedFilter = filter),
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? branding.primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? branding.primaryColor : (isDark ? Colors.white24 : Colors.grey[300]!),
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (filteredProgress.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Text(
                            'لم يتم رصد كويزات أو امتحانات بعد في هذه المجموعة 🌴',
                            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 190,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 25,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.12),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 25,
                                  getTitlesWidget: (val, meta) => Text(
                                    '${val.toInt()}%',
                                    style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx < 0 || idx >= filteredProgress.length) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        filteredProgress[idx]['weekLabel'] ?? 'أسبوع ${idx + 1}',
                                        style: GoogleFonts.cairo(fontSize: 9.5, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: filteredProgress.asMap().entries.map((e) {
                                  final p = num.tryParse(e.value['percentage']?.toString() ?? '0') ?? 0;
                                  return FlSpot(e.key.toDouble(), p.toDouble());
                                }).toList(),
                                isCurved: true,
                                color: branding.primaryColor,
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 4,
                                    color: branding.primaryColor,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: branding.primaryColor.withOpacity(0.12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Group Leaderboard (لوحة الشرف)
              Row(
                children: [
                  Icon(LucideIcons.medal, size: 20, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    'لوحة الشرف للمجموعة 🏆',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (leaderboard.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('لا توجد بيانات ترتيب بعد', style: GoogleFonts.cairo(color: Colors.grey)),
                  ),
                )
              else
                ...leaderboard.map((item) {
                  final rank = item['rank'] ?? 1;
                  final name = item['name']?.toString() ?? 'طالب';
                  final points = item['points'] ?? 0;
                  final isMe = item['isMe'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? branding.primaryColor.withOpacity(0.1)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMe
                            ? branding.primaryColor
                            : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        width: isMe ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Medal or Rank Badge
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rank == 1
                                ? Colors.amber
                                : rank == 2
                                    ? Colors.grey[300]
                                    : rank == 3
                                        ? Colors.brown[300]
                                        : (isDark ? Colors.white10 : Colors.grey[100]),
                          ),
                          child: Text(
                            rank == 1
                                ? '🥇'
                                : rank == 2
                                    ? '🥈'
                                    : rank == 3
                                        ? '🥉'
                                        : '$rank',
                            style: GoogleFonts.cairo(
                              fontSize: rank <= 3 ? 14 : 12,
                              fontWeight: FontWeight.bold,
                              color: rank <= 3 ? Colors.black : Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Student Name
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isMe ? name : _maskStudentName(name),
                                  style: GoogleFonts.cairo(
                                    fontSize: 13.5,
                                    fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                                    color: isMe
                                        ? branding.primaryColor
                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: branding.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'أنت',
                                    style: GoogleFonts.cairo(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Points
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '$points نقطة',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: 9.5,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
