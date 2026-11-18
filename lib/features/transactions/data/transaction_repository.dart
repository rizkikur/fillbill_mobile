import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_config.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/transaction_entity.dart';
import 'transaction_remote_data_source.dart';

class TransactionRepository {
  final TransactionRemoteDataSource _remoteSource;
  final SecureStorageService _storageService;
  final Uuid _uuid = const Uuid();

  TransactionRepository(this._remoteSource, this._storageService);

  String generateIdempotencyKey() => _uuid.v4();

  /// Step 1 & 2 Challenge PIN Otorisasi
  Future<String> obtainPinToken(String pin) async {
    try {
      final challengeId = await _remoteSource.requestPinChallenge();
      final pinToken = await _remoteSource.verifyPin(
        challengeId: challengeId,
        pin: pin,
        purpose: 'transaction',
      );
      return pinToken;
    } catch (e) {
      // Jika PIN salah (422) dari backend, rethrow pesan error agar user tahu
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('tidak sesuai') || errorStr.contains('pin salah') || errorStr.contains('422')) {
        throw Exception('PIN transaksi tidak sesuai. Silakan coba lagi.');
      }
      if (AppConfig.isMockupEnabled) {
        // Jika mode demo / offline / unauthenticated pada local testing:
        return 'PIN-TOKEN-DEMO-${DateTime.now().millisecondsSinceEpoch}';
      }
      rethrow;
    }
  }

  /// Otorisasi Biometrik (Mengambil PIN terenkripsi dari Android Keystore)
  Future<String> obtainBiometricPinToken() async {
    final encryptedPin = await _storageService.getEncryptedPin();
    if (encryptedPin == null || encryptedPin.isEmpty) {
      throw Exception('PIN biometrik belum diatur');
    }
    return await obtainPinToken(encryptedPin);
  }

  /// Eksekusi Pembayaran Finansial
  Future<TransactionEntity> executePayment({
    required String skuCode,
    required String customerNumber,
    int? inquiryId,
    int? amount,
    required String idempotencyKey,
    required String pinToken,
  }) async {
    final res = await _remoteSource.executePayment(
      skuCode: skuCode,
      customerNumber: customerNumber,
      inquiryId: inquiryId,
      amount: amount,
      idempotencyKey: idempotencyKey,
      pinToken: pinToken,
    );
    return res.data!;
  }

  /// Polling Tangga Berjenjang (2s ➜ 3s ➜ 5s ➜ 8s ➜ 12s ➜ 15s)
  Stream<TransactionEntity> pollTransactionStatus(int transactionId) async* {
    final intervals = [
      const Duration(seconds: 2),
      const Duration(seconds: 3),
      const Duration(seconds: 5),
      const Duration(seconds: 8),
      const Duration(seconds: 12),
      const Duration(seconds: 15),
    ];

    for (final interval in intervals) {
      await Future.delayed(interval);
      try {
        final res = await _remoteSource.getTransactionDetail(transactionId);
        final tx = res.data;
        if (tx != null) {
          yield tx;
          // Terminal status: berhenti polling jika sudah final
          if (tx.status == 'success' || tx.status == 'failed' || tx.status == 'refunded') {
            return;
          }
        }
      } catch (_) {
        // Abaikan kegagalan transient saat polling jaringan, coba lagi di interval berikutnya
      }
    }
  }

  /// Ambil riwayat transaksi
  Future<List<TransactionEntity>> getHistory({String? status, int page = 1}) async {
    final res = await _remoteSource.getTransactionHistory(status: status, page: page);
    return res.data ?? [];
  }

  /// Ambil detail transaksi by ID
  Future<TransactionEntity?> getDetail(int transactionId) async {
    final res = await _remoteSource.getTransactionDetail(transactionId);
    return res.data;
  }
}

