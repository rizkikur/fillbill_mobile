import '../../../core/config/app_config.dart';
import '../../wallet/data/mock_wallet_store.dart';
import '../domain/product_entity.dart';
import 'product_remote_data_source.dart';

class ProductRepository {
  final ProductRemoteDataSource _remoteSource;

  ProductRepository(this._remoteSource);

  Future<HomeDashboardData> getHomeDashboard() async {
    if (AppConfig.isMockupEnabled) {
      final mockWallet = MockWalletStore.instance;
      // Mock Fallback jika mode mockup aktif
      return HomeDashboardData(
        balanceCents: mockWallet.balanceCents,
        balanceDisplay: mockWallet.balanceDisplay,
        categories: const [
          ProductCategoryEntity(id: 1, name: 'Pulsa', code: 'pulsa'),
          ProductCategoryEntity(id: 2, name: 'Paket Data', code: 'paket_data'),
          ProductCategoryEntity(id: 3, name: 'Token PLN', code: 'token_listrik'),
          ProductCategoryEntity(id: 4, name: 'Tagihan PLN', code: 'tagihan_listrik'),
          ProductCategoryEntity(id: 5, name: 'E-Wallet', code: 'emoney'),
          ProductCategoryEntity(id: 6, name: 'PDAM Air', code: 'pdam'),
          ProductCategoryEntity(id: 7, name: 'BPJS', code: 'bpjs'),
          ProductCategoryEntity(id: 8, name: 'Game', code: 'game'),
        ],
        recentTransactions: const [
          HomeRecentTransaction(
            id: 101,
            skuCode: 'TLS-10000',
            productName: 'Telkomsel 10.000',
            customerNumber: '081234567890',
            amountCents: 1000000,
            amountDisplay: 'Rp 10.000,00',
            sellPriceCents: 1085000,
            sellPriceDisplay: 'Rp 10.850,00',
            status: 'success',
            providerRef: 'SN-0041000180894618',
          ),
        ],
      );
    }

    try {
      final res = await _remoteSource.getHomeDashboard();
      if (res.data != null) {
        return res.data!;
      }
    } catch (_) {}

    // Default Prod: kembalikan dashboard kosong/dasar
    return const HomeDashboardData(
      balanceCents: 0,
      balanceDisplay: 'Rp 0',
      categories: [
        ProductCategoryEntity(id: 1, name: 'Pulsa', code: 'pulsa'),
        ProductCategoryEntity(id: 2, name: 'Paket Data', code: 'paket_data'),
        ProductCategoryEntity(id: 3, name: 'Token PLN', code: 'token_listrik'),
        ProductCategoryEntity(id: 4, name: 'Tagihan PLN', code: 'tagihan_listrik'),
        ProductCategoryEntity(id: 5, name: 'E-Wallet', code: 'emoney'),
        ProductCategoryEntity(id: 6, name: 'PDAM Air', code: 'pdam'),
        ProductCategoryEntity(id: 7, name: 'BPJS', code: 'bpjs'),
        ProductCategoryEntity(id: 8, name: 'Game', code: 'game'),
      ],
      recentTransactions: [],
    );
  }

  Future<List<ProductEntity>> getProductsByOperatorPrefix(String phone, String operatorName, {String? category}) async {
    try {
      final res = await _remoteSource.getProductsByOperatorPrefix(phone, category: category);
      if (res.data != null && res.data!.isNotEmpty) {
        return res.data!;
      }
    } catch (_) {}

    // Fallback Mock Dinamis HANYA jika mode mockup aktif
    if (AppConfig.isMockupEnabled) {
      if (category == 'paket_data') {
        return _generateMockDataPackages(operatorName);
      }
      return _generateMockProducts(operatorName);
    }
    return [];
  }

  Future<List<ProductEntity>> getProducts({
    String? category,
    String? provider,
    String? type,
  }) async {
    try {
      final res = await _remoteSource.getProducts(
        category: category,
        provider: provider,
        type: type,
      );
      if (res.data != null && res.data!.isNotEmpty) {
        return res.data!;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> inquirePostpaid({
    required String skuCode,
    required String customerNumber,
  }) async {
    try {
      final res = await _remoteSource.inquirePostpaid(
        skuCode: skuCode,
        customerNumber: customerNumber,
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }

  List<ProductEntity> _generateMockDataPackages(String operatorName) {
    final lower = operatorName.toLowerCase();
    if (lower.contains('indosat')) {
      return [
        ProductEntity(
          id: 201,
          skuCode: 'ISAT_DATA_3GB',
          name: 'Freedom internet 3GB/1hr',
          description: 'Kuota utama 3GB 24 jam',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 800000,
          sellPriceDisplay: 'Rp. 8.000',
          provider: operatorName,
          isActive: true,
        ),
        ProductEntity(
          id: 202,
          skuCode: 'ISAT_DATA_9GB',
          name: 'Freedom internet 9GB/1hr',
          description: 'Kuota utama 9GB 24 jam',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 1200000,
          sellPriceDisplay: 'Rp. 12.000',
          provider: operatorName,
          isActive: true,
        ),
        ProductEntity(
          id: 203,
          skuCode: 'ISAT_DATA_15GB',
          name: 'Freedom internet 15GB/30hr',
          description: 'Kuota utama 15GB semua jaringan 30 hari',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 3500000,
          sellPriceDisplay: 'Rp. 35.000',
          provider: operatorName,
          isActive: true,
        ),
        ProductEntity(
          id: 204,
          skuCode: 'ISAT_DATA_25GB',
          name: 'Freedom Combo 25GB/30hr',
          description: 'Kuota utama 20GB + 5GB kuota malam/lokal',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 5500000,
          sellPriceDisplay: 'Rp. 55.000',
          provider: operatorName,
          isActive: true,
        ),
      ];
    } else if (lower.contains('telkomsel')) {
      return [
        ProductEntity(
          id: 205,
          skuCode: 'DATA_TSEL_3GB',
          name: 'InternetMAX 3GB/3hr',
          description: 'Kuota utama 3GB semua jaringan 3 hari',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 1500000,
          sellPriceDisplay: 'Rp. 15.000',
          provider: operatorName,
          isActive: true,
        ),
        ProductEntity(
          id: 206,
          skuCode: 'DATA_TSEL_10GB',
          name: 'InternetMAX 10GB/30hr',
          description: 'Kuota utama 10GB 24 jam 30 hari',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 4500000,
          sellPriceDisplay: 'Rp. 45.000',
          provider: operatorName,
          isActive: true,
        ),
        ProductEntity(
          id: 207,
          skuCode: 'DATA_TSEL_25GB',
          name: 'GigaMAX 25GB/30hr',
          description: 'Kuota utama 20GB + 5GB MAXstream',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 7500000,
          sellPriceDisplay: 'Rp. 75.000',
          provider: operatorName,
          isActive: true,
        ),
        ProductEntity(
          id: 208,
          skuCode: 'DATA_TSEL_40GB',
          name: 'Combo SAKTI 40GB/30hr',
          description: 'Kuota utama 35GB + Nelpon & SMS',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 10000000,
          sellPriceDisplay: 'Rp. 100.000',
          provider: operatorName,
          isActive: true,
        ),
      ];
    } else {
      return [
        ProductEntity(
          id: 209,
          skuCode: 'XL_DATA_5GB',
          name: 'Xtra Combo Flex 5GB/30hr',
          description: 'Kuota utama 5GB 24 jam 30 hari',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 2200000,
          sellPriceDisplay: 'Rp. 22.000',
          provider: operatorName,
          isActive: true,
        ),
        ProductEntity(
          id: 210,
          skuCode: 'XL_DATA_15GB',
          name: 'Xtra Combo Flex 15GB/30hr',
          description: 'Kuota utama 15GB + Bonus Flex',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 4500000,
          sellPriceDisplay: 'Rp. 45.000',
          provider: operatorName,
          isActive: true,
        ),
        ProductEntity(
          id: 211,
          skuCode: 'XL_DATA_30GB',
          name: 'Xtra Combo Flex 30GB/30hr',
          description: 'Kuota utama 30GB + Unlimited Apps',
          productType: 'prepaid',
          categoryCode: 'paket_data',
          sellPriceCents: 7800000,
          sellPriceDisplay: 'Rp. 78.000',
          provider: operatorName,
          isActive: true,
        ),
      ];
    }
  }

  List<ProductEntity> _generateMockProducts(String operatorName) {
    final prefix = operatorName.toLowerCase().contains('telkomsel')
        ? 'TSEL'
        : (operatorName.toLowerCase().contains('indosat') ? 'ISAT' : 'XL');
    return [
      ProductEntity(
        id: 1,
        skuCode: '${prefix}5K',
        name: '$operatorName 5.000',
        description: 'Masa aktif 7 hari',
        productType: 'prepaid',
        categoryCode: 'pulsa',
        sellPriceCents: 550000,
        sellPriceDisplay: 'Rp. 5.500',
        provider: operatorName,
        isActive: true,
      ),
      ProductEntity(
        id: 2,
        skuCode: '${prefix}10K',
        name: '$operatorName 10.000',
        description: 'Masa aktif 15 hari',
        productType: 'prepaid',
        categoryCode: 'pulsa',
        sellPriceCents: 1075000,
        sellPriceDisplay: 'Rp. 10.750',
        provider: operatorName,
        isActive: true,
      ),
      ProductEntity(
        id: 3,
        skuCode: '${prefix}20K',
        name: '$operatorName 20.000',
        description: 'Masa aktif 30 hari',
        productType: 'prepaid',
        categoryCode: 'pulsa',
        sellPriceCents: 2150000,
        sellPriceDisplay: 'Rp. 21.500',
        provider: operatorName,
        isActive: true,
      ),
      ProductEntity(
        id: 4,
        skuCode: '${prefix}25K',
        name: '$operatorName 25.000',
        description: 'Masa aktif 30 hari',
        productType: 'prepaid',
        categoryCode: 'pulsa',
        sellPriceCents: 2600000,
        sellPriceDisplay: 'Rp. 26.000',
        provider: operatorName,
        isActive: true,
      ),
      ProductEntity(
        id: 5,
        skuCode: '${prefix}50K',
        name: '$operatorName 50.000',
        description: 'Masa aktif 30 hari',
        productType: 'prepaid',
        categoryCode: 'pulsa',
        sellPriceCents: 5025000,
        sellPriceDisplay: 'Rp. 50.250',
        provider: operatorName,
        isActive: true,
      ),
      ProductEntity(
        id: 6,
        skuCode: '${prefix}100K',
        name: '$operatorName 100.000',
        description: 'Masa aktif 60 hari',
        productType: 'prepaid',
        categoryCode: 'pulsa',
        sellPriceCents: 9950000,
        sellPriceDisplay: 'Rp. 99.500',
        provider: operatorName,
        isActive: true,
      ),
    ];
  }
}

