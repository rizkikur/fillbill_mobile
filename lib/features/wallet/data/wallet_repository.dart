import 'package:uuid/uuid.dart';
import '../../../core/config/app_config.dart';
import '../domain/wallet_entity.dart';
import 'mock_wallet_store.dart';
import 'wallet_remote_data_source.dart';

class WalletRepository {
  final WalletRemoteDataSource _remoteSource;
  final Uuid _uuid = const Uuid();

  WalletRepository(this._remoteSource);

  static const List<TopupGroupEntity> standardChannelGroups = [
    TopupGroupEntity(
      groupName: 'Virtual Account Bank',
      items: [
        TopupChannelEntity(
          code: 'bca_va',
          name: 'BCA Virtual Account',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 1000000,
          maxAmountCents: 2000000000,
          feeCents: 250000,
          feeDisplay: 'Rp 2.500',
          feeType: 'flat',
          isActive: true,
        ),
        TopupChannelEntity(
          code: 'mandiri_va',
          name: 'Mandiri Virtual Account',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 1000000,
          maxAmountCents: 2000000000,
          feeCents: 250000,
          feeDisplay: 'Rp 2.500',
          feeType: 'flat',
          isActive: true,
        ),
        TopupChannelEntity(
          code: 'bni_va',
          name: 'BNI Virtual Account',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 1000000,
          maxAmountCents: 2000000000,
          feeCents: 250000,
          feeDisplay: 'Rp 2.500',
          feeType: 'flat',
          isActive: true,
        ),
        TopupChannelEntity(
          code: 'bri_va',
          name: 'BRI Virtual Account',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 1000000,
          maxAmountCents: 2000000000,
          feeCents: 250000,
          feeDisplay: 'Rp 2.500',
          feeType: 'flat',
          isActive: true,
        ),
      ],
    ),
    TopupGroupEntity(
      groupName: 'E-Wallet & QRIS',
      items: [
        TopupChannelEntity(
          code: 'qris',
          name: 'QRIS Instant (Semua E-Wallet & M-Banking)',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 500000,
          maxAmountCents: 500000000,
          feeCents: 0,
          feeDisplay: '0.7%',
          feeType: 'percentage',
          isActive: true,
        ),
        TopupChannelEntity(
          code: 'gopay',
          name: 'GoPay',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 1000000,
          maxAmountCents: 200000000,
          feeCents: 100000,
          feeDisplay: 'Rp 1.000',
          feeType: 'flat',
          isActive: true,
        ),
        TopupChannelEntity(
          code: 'ovo',
          name: 'OVO',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 1000000,
          maxAmountCents: 200000000,
          feeCents: 100000,
          feeDisplay: 'Rp 1.000',
          feeType: 'flat',
          isActive: true,
        ),
        TopupChannelEntity(
          code: 'dana',
          name: 'DANA',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 1000000,
          maxAmountCents: 200000000,
          feeCents: 100000,
          feeDisplay: 'Rp 1.000',
          feeType: 'flat',
          isActive: true,
        ),
        TopupChannelEntity(
          code: 'shopeepay',
          name: 'ShopeePay',
          method: 'payment_gateway',
          paymentGateway: 'midtrans',
          minAmountCents: 1000000,
          maxAmountCents: 200000000,
          feeCents: 100000,
          feeDisplay: 'Rp 1.000',
          feeType: 'flat',
          isActive: true,
        ),
      ],
    ),
    TopupGroupEntity(
      groupName: 'Transfer Bank Manual',
      items: [
        TopupChannelEntity(
          code: 'manual_bca',
          name: 'Transfer Bank BCA (Konfirmasi Manual)',
          method: 'manual_transfer',
          paymentGateway: 'none',
          accountNumber: '1234567890',
          accountName: 'PT PPOB INDONESIA SEJAHTERA',
          minAmountCents: 5000000,
          maxAmountCents: 10000000000,
          feeCents: 0,
          feeDisplay: 'Gratis',
          feeType: 'flat',
          isActive: true,
        ),
      ],
    ),
  ];

  Future<List<TopupGroupEntity>> getChannels() async {
    if (AppConfig.isMockupEnabled) {
      return standardChannelGroups;
    }

    try {
      final res = await _remoteSource.getTopupChannels();
      if (res.data != null && res.data!.isNotEmpty) {
        return res.data!;
      }
    } catch (_) {}

    return const [];
  }

  Future<TopupResultEntity> requestTopup({
    required int amountCents,
    String method = 'payment_gateway',
    String paymentGateway = 'midtrans',
    String? channelCode,
    String? channelName,
  }) async {
    // Jika mockup mode aktif, langsung catat ke MockWalletStore dan kembalikan result
    if (AppConfig.isMockupEnabled) {
      MockWalletStore.instance.addTopup(
        amountCents: amountCents,
        channelCode: channelCode ?? method,
        channelName: channelName ?? (method == 'payment_gateway' ? 'Virtual Account' : method),
      );

      final amountRp = amountCents ~/ 100;
      return TopupResultEntity(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amountCents: amountCents,
        amountDisplay: 'Rp $amountRp',
        method: method,
        paymentGateway: paymentGateway,
        gatewayRef: 'SNAP-MOCK-${DateTime.now().millisecondsSinceEpoch}',
        paymentUrl: 'https://app.sandbox.midtrans.com/snap/v2/vtweb/SNAP-MOCK-DEMO',
        status: 'pending',
        createdAt: DateTime.now(),
      );
    }

    final idempotencyKey = _uuid.v4();
    final res = await _remoteSource.requestTopup(
      amountCents: amountCents,
      method: method,
      paymentGateway: paymentGateway,
      idempotencyKey: idempotencyKey,
    );
    return res.data!;
  }

  Future<List<WalletMutationEntity>> getMutations({String? type, int page = 1}) async {
    if (AppConfig.isMockupEnabled) {
      final all = MockWalletStore.instance.mutations;
      if (type != null && type.isNotEmpty && type != 'all') {
        return all.where((m) => m.type.toLowerCase() == type.toLowerCase()).toList();
      }
      return all;
    }

    try {
      final res = await _remoteSource.getMutations(type: type, page: page);
      return res.data ?? [];
    } catch (_) {
      return [];
    }
  }
}

