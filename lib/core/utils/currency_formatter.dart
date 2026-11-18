import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  /// Membersihkan string harga dari desimal (,00 atau .00) dan memastikan prefix "Rp. "
  static String clean(String raw) {
    if (raw.isEmpty) return 'Rp. 0';
    String cleaned = raw.replaceAll(RegExp(r'[,.]00$'), '').trim();

    if (cleaned.startsWith('Rp. ')) {
      return cleaned;
    } else if (cleaned.startsWith('Rp.')) {
      return cleaned.replaceFirst('Rp.', 'Rp. ');
    } else if (cleaned.startsWith('Rp ')) {
      return cleaned.replaceFirst('Rp ', 'Rp. ');
    } else if (cleaned.startsWith('Rp')) {
      return cleaned.replaceFirst('Rp', 'Rp. ');
    }
    return 'Rp. $cleaned';
  }

  /// Format angka integer rupiah murni ke format baku: "Rp. 10.000"
  static String format(num amount) {
    return _rupiahFormat.format(amount);
  }

  /// Mengonversi nilai Cents (satuan sen integer dari backend) ke format Rupiah baku (tanpa ,00)
  /// Contoh: 1000000 cents -> "Rp. 10.000"
  static String formatCents(int cents, {bool withSymbol = true}) {
    final int rupiah = cents ~/ 100;
    if (!withSymbol) {
      return NumberFormat('#,###', 'id_ID').format(rupiah);
    }
    return _rupiahFormat.format(rupiah);
  }

  /// Mengonversi nominal Rupiah murni ke Cents integer untuk dikirim ke backend
  /// Contoh: 10000 Rupiah -> 1000000 Cents
  static int rupiahToCents(int rupiah) {
    return rupiah * 100;
  }
}

