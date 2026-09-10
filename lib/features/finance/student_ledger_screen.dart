import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';
import '../../core/utils/group_utils.dart';

class StudentLedgerScreen extends ConsumerWidget {
  const StudentLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final finance = ref.watch(liveStudentFinanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final transactions = (finance['transactions'] as List?) ?? [];
    final monthlySubs = (finance['monthlySubs'] as List?) ?? [];
    final summary = (finance['summary'] as Map?) ?? {};

    final totalPaid = summary['totalPaid'] ?? 0;
    final walletBalance = summary['walletBalance'] ?? 0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'الاشتراكات والمدفوعات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: RefreshIndicator(
        color: branding.primaryColor,
        onRefresh: () async {
          ref.invalidate(liveStudentProfileProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            // Financial Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إجمالي المدفوعات المسجلة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalPaid ج.م',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 24),
                      ),
                    ],
                  ),
                  if (walletBalance != 0) ...[
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          walletBalance < 0 ? 'المستحق الحالي للدفع' : 'رصيد المحفظة الزائد',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${walletBalance.abs()} ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: walletBalance < 0 ? Colors.redAccent : branding.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section 1: Monthly Subscriptions Status
            Text(
              'الاشتراكات الشهرية للمجموعات',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            if (monthlySubs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Text(
                    'لا توجد اشتراكات شهرية مسجلة',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...monthlySubs.map((sub) {
                final groupName = GroupUtils.getName(sub['group'] ?? sub);
                final month = sub['monthNumber'] ?? sub['month'] ?? 1;
                final year = sub['year'] ?? DateTime.now().year;
                final fee = sub['fee'] ?? sub['amount'] ?? sub['group']?['monthlyFee'] ?? 0;
                final isPaid = sub['isPaid'] ?? (sub['status'] == 'PAID');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPaid ? LucideIcons.checkCircle : LucideIcons.clock,
                        color: isPaid ? const Color(0xFF10B981) : Colors.orangeAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupName,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'شهر $month / $year • القيمة: $fee ج.م',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : Colors.orangeAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid ? 'تم السداد' : 'غير مسدد',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? const Color(0xFF10B981) : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Section 2: Recent Receipts / Transactions
            Text(
              'إيصالات الدفع الأخيرة',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            if (transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Text(
                    'لا توجد عمليات دفع مسجلة حتى الآن',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...transactions.map((tx) {
                final amount = tx['amount'] ?? 0;
                final assistantName = tx['assistant']?['name']?.toString() ?? 'السنتر';
                final note = tx['notes']?.toString() ?? 'سداد رسوم';

                DateTime? date;
                if (tx['createdAt'] != null) {
                  date = DateTime.tryParse(tx['createdAt'].toString());
                }
                final dateStr = date != null
                    ? DateFormat('d MMM yyyy - hh:mm a', 'ar').format(date)
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.receipt, color: Color(0xFF10B981), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'المستلم: $assistantName ${dateStr.isNotEmpty ? "• $dateStr" : ""}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+$amount ج.م',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
