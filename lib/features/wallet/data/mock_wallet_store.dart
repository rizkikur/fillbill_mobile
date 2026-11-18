import 'package:intl/intl.dart';
import '../domain/wallet_entity.dart';

/// In-memory stateful singleton managing simulated wallet balance and mutations
/// during mockup / demo mode (`AppConfig.isMockupEnabled`).
class MockWalletStore {
  static final MockWalletStore _instance = MockWalletStore._internal();

  /// Global singleton instance
  static MockWalletStore get instance => _instance;

  static const int defaultInitialBalanceCents = 25000000; // Rp 250.000,00

  int _balanceCents = defaultInitialBalanceCents;
  final List<WalletMutationEntity> _mutations = [];

  MockWalletStore._internal() {
    reset();
  }

  /// Current simulated balance in cents (e.g. 25000000 = Rp 250.000)
  int get balanceCents => _balanceCents;

  /// Formatted balance display matching the app's standard (e.g. 'Rp 250.000,00')
  String get balanceDisplay => formatCurrency(_balanceCents);

  /// Unmodifiable view of all mutations, newest first
  List<WalletMutationEntity> get mutations => List.unmodifiable(_mutations);

  /// Simulate a top-up credit: increments balance and prepends a new mutation record
  void addTopup({
    required int amountCents,
    required String channelCode,
    required String channelName,
  }) {
    _balanceCents += amountCents;
    final now = DateTime.now();
    final newMutation = WalletMutationEntity(
      id: now.millisecondsSinceEpoch,
      type: 'credit',
      amountCents: amountCents,
      amountDisplay: formatCurrency(amountCents),
      balanceAfterCents: _balanceCents,
      balanceAfterDisplay: formatCurrency(_balanceCents),
      referenceType: 'topup',
      note: 'Top Up Deposit via $channelName',
      createdAt: now,
    );
    _mutations.insert(0, newMutation);
  }

  /// Reset the store to its initial state (25,000,000 cents and 3 default mutations)
  void reset() {
    _balanceCents = defaultInitialBalanceCents;
    _mutations.clear();
    final now = DateTime.now();
    _mutations.addAll([
      WalletMutationEntity(
        id: 301,
        type: 'credit',
        amountCents: 10000000,
        amountDisplay: 'Rp 100.000,00',
        balanceAfterCents: 25000000,
        balanceAfterDisplay: 'Rp 250.000,00',
        referenceType: 'topup',
        note: 'Top Up Deposit via BCA Virtual Account',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      WalletMutationEntity(
        id: 302,
        type: 'debit',
        amountCents: 1085000,
        amountDisplay: 'Rp 10.850,00',
        balanceAfterCents: 23915000,
        balanceAfterDisplay: 'Rp 239.150,00',
        referenceType: 'transaction',
        note: 'Pembelian Telkomsel 10.000 ke 081234567890',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      WalletMutationEntity(
        id: 303,
        type: 'credit',
        amountCents: 1085000,
        amountDisplay: 'Rp 10.850,00',
        balanceAfterCents: 25000000,
        balanceAfterDisplay: 'Rp 250.000,00',
        referenceType: 'refund',
        note: 'Pengembalian dana transaksi #TRX-99: Gangguan Biller',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  /// Standard currency formatting helper (cents -> 'Rp X.XXX.XXX,00')
  static String formatCurrency(int cents) {
    final int rupiah = cents ~/ 100;
    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(rupiah);
    return 'Rp $formatted,00';
  }
}
