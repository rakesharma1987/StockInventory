import 'package:intl/intl.dart';

/// Shared currency formatter for the whole app - Indian Rupees, with
/// Indian-style digit grouping (e.g. ₹1,00,000 rather than ₹100,000).
final NumberFormat _rupeeFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹', // ₹
  decimalDigits: 2,
);

String formatCurrency(double value) => _rupeeFormat.format(value);
