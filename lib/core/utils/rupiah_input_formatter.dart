import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Dynamic Indonesian Rupiah input formatter for currency and nominal fields.
/// Converts typed digits into formatted 'Rp X.XXX.XXX' strings in real time.
class RupiahInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Extract only digits
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Cap at 11 digits to prevent integer overflow
    final safeDigits = digits.length > 11 ? digits.substring(0, 11) : digits;
    final int value = int.tryParse(safeDigits) ?? 0;
    final String formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Extracts integer Rupiah value from a formatted string (e.g. 'Rp 50.000' -> 50000)
  static int parseRupiah(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// Formats an integer rupiah value into 'Rp X.XXX' (e.g. 50000 -> 'Rp 50.000')
  static String format(int rupiah) {
    return _formatter.format(rupiah);
  }
}
