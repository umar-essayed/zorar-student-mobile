import 'package:intl/intl.dart';

class NumericUtils {
  static String formatCurrency(dynamic amount, {String symbol = 'ج.م'}) {
    if (amount == null) return '0 $symbol';
    final parsed = parseDouble(amount);
    final formatter = NumberFormat('#,##0', 'ar');
    return '${formatter.format(parsed)} $symbol';
  }
}

double parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

int parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}
