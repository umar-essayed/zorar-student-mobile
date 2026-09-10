import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/student_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/theme/student_theme.dart';

class StudentLedgerScreen extends ConsumerWidget {
  const StudentLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final finance = ref.watch(liveStudentFinanceProvider);

    final transactions = (finance['transactions'] as List?) ?? [];
    final monthlySubs = (finance['monthlySubs'] as List?) ?? [];
    final summary = (finance['summary'] as Map?) ?? {};

    final totalPaid = summary['totalPaid'] ?? 0;
    final walletBalance = summary['walletBalance'] ?? 0;

    return Scaffold(
      backgroundColor: StudentTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'الاشتراكات والمدفوعات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: StudentTheme.surfaceCard,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: branding.accentColor,
        onRefresh: () async {
          ref.invalidate(liveStudentProfileProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            // Financial Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    StudentTheme.surfaceCard,
                    StudentTheme.surfaceLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: StudentTheme.borderDark),
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
                              color: StudentTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.circleCheck, color: Color(0xFF10B981), size: 26),
                      ),
                    ],
                  ),
                  if (walletBalance != 0) ...[
                    const Divider(color: StudentTheme.borderDark, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          walletBalance < 0 ? 'المبلغ المتبقي والمستحق للدفع' : 'رصيد المحفظة الزائد',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: StudentTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${walletBalance.abs()} ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: walletBalance < 0 ? Colors.redAccent : branding.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Monthly Subscriptions Status
            Text(
              'حالة الاشتراكات الشهرية',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: StudentTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            if (monthlySubs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StudentTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: StudentTheme.borderDark),
                ),
                child: Center(
                  child: Text(
                    'لا توجد اشتراكات شهرية مسجلة',
                    style: GoogleFonts.cairo(color: StudentTheme.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              ...monthlySubs.map((sub) {
                final groupName = sub['group']?['name']?.toString() ?? 'مجموعة دراسية';
                final month = sub['monthNumber'] ?? sub['month'] ?? 1;
                final year = sub['year'] ?? DateTime.now().year;
                final fee = sub['fee'] ?? sub['amount'] ?? sub['group']?['monthlyFee'] ?? 0;
                final isPaid = sub['isPaid'] ?? (sub['status'] == 'PAID');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StudentTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudentTheme.borderDark),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPaid ? LucideIcons.checkCircle2 : LucideIcons.clock,
                            color: isPaid ? const Color(0xFF10B981) : Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$groupName - شهر $month / $year',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: StudentTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'قيمة الاشتراك: $fee ج.م',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: StudentTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid ? 'تم السداد' : 'غير مسدد',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? const Color(0xFF10B981) : Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Section 2: Recent Receipts / Transactions
            Text(
              'إيصالات الدفع الأخيرة',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: StudentTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            if (transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StudentTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: StudentTheme.borderDark),
                ),
                child: Center(
                  child: Text(
                    'لا توجد عمليات دفع مسجلة حتى الآن',
                    style: GoogleFonts.cairo(color: StudentTheme.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              ...transactions.map((tx) {
                final amount = tx['amount'] ?? 0;
                final assistantName = tx['assistant']?['name']?.toString() ?? 'إدارة السنتر';
                final note = tx['notes']?.toString() ?? 'سداد رسوم';
                
                DateTime? date;
                if (tx['createdAt'] != null) {
                  date = DateTime.tryParse(tx['createdAt'].toString());
                }
                final dateStr = date != null
                    ? DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(date)
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StudentTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudentTheme.borderDark),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.receipt, color: Color(0xFF10B981), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: StudentTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'المستلم: $assistantName ${dateStr.isNotEmpty ? "• $dateStr" : ""}',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: StudentTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
