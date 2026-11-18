class ProductEntity {
  final int id;
  final String skuCode;
  final String name;
  final String? description;
  final String productType; // 'prepaid' or 'postpaid'
  final int sellPriceCents;
  final String sellPriceDisplay;
  final int adminFeeCents;
  final String adminFeeDisplay;
  final String provider;
  final String? categoryCode;
  final bool isActive;

  const ProductEntity({
    required this.id,
    required this.skuCode,
    required this.name,
    this.description,
    required this.productType,
    required this.sellPriceCents,
    required this.sellPriceDisplay,
    this.adminFeeCents = 0,
    this.adminFeeDisplay = 'Rp 0',
    required this.provider,
    this.categoryCode,
    required this.isActive,
  });

  factory ProductEntity.fromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'] as int? ?? 0,
      skuCode: json['sku_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      productType: json['product_type'] as String? ?? 'prepaid',
      sellPriceCents: json['sell_price'] as int? ?? 0,
      sellPriceDisplay: json['sell_price_display'] as String? ?? '',
      adminFeeCents: json['admin_fee'] as int? ?? 0,
      adminFeeDisplay: json['admin_fee_display'] as String? ?? 'Rp 0',
      provider: json['provider'] as String? ?? '',
      categoryCode: json['category'] != null
          ? (json['category'] is Map ? json['category']['code'] as String? : null)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class ProductCategoryEntity {
  final int id;
  final String name;
  final String code;
  final String? iconUrl;

  const ProductCategoryEntity({
    required this.id,
    required this.name,
    required this.code,
    this.iconUrl,
  });

  factory ProductCategoryEntity.fromJson(Map<String, dynamic> json) {
    return ProductCategoryEntity(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
    );
  }
}

class HomeRecentTransaction {
  final int id;
  final String? referenceNo;
  final String skuCode;
  final String productName;
  final String customerNumber;
  final int amountCents;
  final String amountDisplay;
  final int sellPriceCents;
  final String sellPriceDisplay;
  final String status;
  final String? providerRef;
  final DateTime? createdAt;

  const HomeRecentTransaction({
    required this.id,
    this.referenceNo,
    required this.skuCode,
    required this.productName,
    required this.customerNumber,
    required this.amountCents,
    required this.amountDisplay,
    required this.sellPriceCents,
    required this.sellPriceDisplay,
    required this.status,
    this.providerRef,
    this.createdAt,
  });

  String get displayId => referenceNo ?? '#$id';

  factory HomeRecentTransaction.fromJson(Map<String, dynamic> json) {
    return HomeRecentTransaction(
      id: json['id'] as int? ?? 0,
      referenceNo: json['reference_no']?.toString(),
      skuCode: json['sku_code'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      customerNumber: json['customer_number'] as String? ?? '',
      amountCents: json['amount_cents'] as int? ?? 0,
      amountDisplay: json['amount_display'] as String? ?? '',
      sellPriceCents: json['sell_price_cents'] as int? ?? 0,
      sellPriceDisplay: json['sell_price_display'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      providerRef: json['provider_ref'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class HomeDashboardData {
  final int balanceCents;
  final String balanceDisplay;
  final List<ProductCategoryEntity> categories;
  final List<HomeRecentTransaction> recentTransactions;

  const HomeDashboardData({
    required this.balanceCents,
    required this.balanceDisplay,
    required this.categories,
    required this.recentTransactions,
  });

  factory HomeDashboardData.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] as Map<String, dynamic>? ?? {};
    final categoriesList = (json['categories'] as List? ?? [])
        .map((e) => ProductCategoryEntity.fromJson(e as Map<String, dynamic>))
        .toList();
    final transactionsList = (json['recent_transactions'] as List? ?? [])
        .map((e) => HomeRecentTransaction.fromJson(e as Map<String, dynamic>))
        .toList();

    return HomeDashboardData(
      balanceCents: wallet['balance_cents'] as int? ?? 0,
      balanceDisplay: wallet['balance_display'] as String? ?? 'Rp 0',
      categories: categoriesList,
      recentTransactions: transactionsList,
    );
  }
}

