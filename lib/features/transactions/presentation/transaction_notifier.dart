import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/transaction_remote_data_source.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_entity.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return TransactionRepository(TransactionRemoteDataSourceImpl(client), storage);
});

enum ExecutionStatus {
  idle,
  authenticatingPin,
  executing,
  polling,
  success,
  failed,
}

class TransactionExecutionState {
  final ExecutionStatus status;
  final TransactionEntity? transaction;
  final String? errorMessage;
  final String? idempotencyKey;

  const TransactionExecutionState({
    this.status = ExecutionStatus.idle,
    this.transaction,
    this.errorMessage,
    this.idempotencyKey,
  });

  TransactionExecutionState copyWith({
    ExecutionStatus? status,
    TransactionEntity? transaction,
    String? errorMessage,
    String? idempotencyKey,
  }) {
    return TransactionExecutionState(
      status: status ?? this.status,
      transaction: transaction ?? this.transaction,
      errorMessage: errorMessage,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}

final transactionExecutionProvider =
    StateNotifierProvider<TransactionExecutionNotifier, TransactionExecutionState>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return TransactionExecutionNotifier(repo);
});

class TransactionExecutionNotifier extends StateNotifier<TransactionExecutionState> {
  final TransactionRepository _repo;

  TransactionExecutionNotifier(this._repo) : super(const TransactionExecutionState());

  void initNewIntent() {
    state = TransactionExecutionState(
      idempotencyKey: _repo.generateIdempotencyKey(),
    );
  }

  /// Eksekusi pembayaran langsung me-return TransactionEntity untuk diteruskan ke ReceiptScreen
  Future<TransactionEntity> submitPayment({
    required String skuCode,
    required String customerNumber,
    int? inquiryId,
    int? amount,
    required String pin,
  }) async {
    final key = state.idempotencyKey ?? _repo.generateIdempotencyKey();
    state = state.copyWith(status: ExecutionStatus.authenticatingPin, errorMessage: null);

    try {
      // 1. Dapatkan token otorisasi PIN (Single-use TTL 5m)
      final pinToken = await _repo.obtainPinToken(pin);

      // 2. Kirim transaksi dengan Idempotency-Key
      state = state.copyWith(status: ExecutionStatus.executing);
      final initialTx = await _repo.executePayment(
        skuCode: skuCode,
        customerNumber: customerNumber,
        inquiryId: inquiryId,
        amount: amount,
        idempotencyKey: key,
        pinToken: pinToken,
      );

      state = state.copyWith(
        status: initialTx.status == 'success' ? ExecutionStatus.success : ExecutionStatus.polling,
        transaction: initialTx,
      );

      return initialTx;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(status: ExecutionStatus.failed, errorMessage: msg);
      rethrow;
    }
  }

  Future<void> executeWithPin({
    required String skuCode,
    required String customerNumber,
    int? inquiryId,
    required String pin,
  }) async {
    final key = state.idempotencyKey ?? _repo.generateIdempotencyKey();
    state = state.copyWith(status: ExecutionStatus.authenticatingPin, errorMessage: null);

    try {
      // 1. Dapatkan token otorisasi PIN (Single-use TTL 5m)
      final pinToken = await _repo.obtainPinToken(pin);

      // 2. Kirim transaksi dengan Idempotency-Key
      state = state.copyWith(status: ExecutionStatus.executing);
      final initialTx = await _repo.executePayment(
        skuCode: skuCode,
        customerNumber: customerNumber,
        inquiryId: inquiryId,
        idempotencyKey: key,
        pinToken: pinToken,
      );

      // 3. Jika status sudah terminal (success/failed), langsung update
      if (initialTx.status == 'success') {
        state = state.copyWith(status: ExecutionStatus.success, transaction: initialTx);
        return;
      } else if (initialTx.status == 'failed') {
        state = state.copyWith(
          status: ExecutionStatus.failed,
          transaction: initialTx,
          errorMessage: initialTx.failureReason ?? 'Transaksi gagal diproses',
        );
        return;
      }

      // 4. Jika pending/processing, jalankan polling berjenjang
      state = state.copyWith(status: ExecutionStatus.polling, transaction: initialTx);
      await for (final polledTx in _repo.pollTransactionStatus(initialTx.id)) {
        if (polledTx.status == 'success') {
          state = state.copyWith(status: ExecutionStatus.success, transaction: polledTx);
          return;
        } else if (polledTx.status == 'failed') {
          state = state.copyWith(
            status: ExecutionStatus.failed,
            transaction: polledTx,
            errorMessage: polledTx.failureReason ?? 'Transaksi gagal diproses',
          );
          return;
        }
      }

      // Jika timeout polling tetap pending, tampilkan ke user bahwa transaksi sedang diproses
      state = state.copyWith(status: ExecutionStatus.success, transaction: initialTx);
    } catch (e) {
      state = state.copyWith(
        status: ExecutionStatus.failed,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

// Transaction History State & Notifier
class TransactionHistoryState {
  final bool isLoading;
  final String activeFilter; // 'all', 'success', 'pending', 'failed'
  final List<TransactionEntity> transactions;
  final String? errorMessage;

  const TransactionHistoryState({
    this.isLoading = false,
    this.activeFilter = 'all',
    this.transactions = const [],
    this.errorMessage,
  });

  TransactionHistoryState copyWith({
    bool? isLoading,
    String? activeFilter,
    List<TransactionEntity>? transactions,
    String? errorMessage,
  }) {
    return TransactionHistoryState(
      isLoading: isLoading ?? this.isLoading,
      activeFilter: activeFilter ?? this.activeFilter,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
    );
  }
}

final transactionHistoryProvider =
    StateNotifierProvider<TransactionHistoryNotifier, TransactionHistoryState>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return TransactionHistoryNotifier(repo);
});

class TransactionHistoryNotifier extends StateNotifier<TransactionHistoryState> {
  final TransactionRepository _repo;

  TransactionHistoryNotifier(this._repo) : super(const TransactionHistoryState()) {
    fetchHistory();
  }

  Future<void> fetchHistory({String? filter}) async {
    final status = filter ?? state.activeFilter;
    state = state.copyWith(isLoading: true, activeFilter: status, errorMessage: null);

    try {
      final list = await _repo.getHistory(status: status == 'all' ? null : status);
      state = state.copyWith(isLoading: false, transactions: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

