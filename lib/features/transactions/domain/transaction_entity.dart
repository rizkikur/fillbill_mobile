class TransactionEntity {
  final int id;
  final String? referenceNo;
  final String skuCode;
  final String productName;
  final String customerNumber;
  final int amountCents;
  final String amountDisplay;
  final int sellPriceCents;
  final String sellPriceDisplay;
  final String status; // 'pending', 'processing', 'success', 'failed', 'refunded'
  final String? providerRef; // Serial Number / Token PLN
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionEntity({
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
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

  String get displayId => referenceNo ?? '#$id';

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    String pName = '';
    String sku = '';
    if (json['product'] is Map) {
      final pMap = json['product'] as Map;
      pName = pMap['name']?.toString() ?? '';
      sku = pMap['sku_code']?.toString() ?? '';
    } else {
      pName = json['product_name']?.toString() ?? '';
      sku = json['sku_code']?.toString() ?? '';
    }

    return TransactionEntity(
      id: json['id'] as int? ?? 0,
      referenceNo: json['reference_no']?.toString(),
      skuCode: sku,
      productName: pName,
      customerNumber: json['customer_number'] as String? ?? '',
      amountCents: json['amount'] as int? ?? json['amount_cents'] as int? ?? 0,
      amountDisplay: json['amount_display'] as String? ?? '',
      sellPriceCents: json['sell_price'] as int? ?? json['sell_price_cents'] as int? ?? 0,
      sellPriceDisplay: json['sell_price_display'] as String? ?? '',
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      providerRef: json['provider_ref'] as String?,
      failureReason: json['failure_reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  TransactionEntity copyWith({
    int? id,
    String? referenceNo,
    String? skuCode,
    String? productName,
    String? customerNumber,
    int? amountCents,
    String? amountDisplay,
    int? sellPriceCents,
    String? sellPriceDisplay,
    String? status,
    String? providerRef,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      referenceNo: referenceNo ?? this.referenceNo,
      skuCode: skuCode ?? this.skuCode,
      productName: productName ?? this.productName,
      customerNumber: customerNumber ?? this.customerNumber,
      amountCents: amountCents ?? this.amountCents,
      amountDisplay: amountDisplay ?? this.amountDisplay,
      sellPriceCents: sellPriceCents ?? this.sellPriceCents,
      sellPriceDisplay: sellPriceDisplay ?? this.sellPriceDisplay,
      status: status ?? this.status,
      providerRef: providerRef ?? this.providerRef,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InquiryEntity {
  final int id;
  final String skuCode;
  final String productName;
  final String customerNumber;
  final int amountCents;
  final String amountDisplay;
  final int adminFeeCents;
  final String adminFeeDisplay;
  final String status;
  final DateTime? expiresAt;

  const InquiryEntity({
    required this.id,
    required this.skuCode,
    required this.productName,
    required this.customerNumber,
    required this.amountCents,
    required this.amountDisplay,
    required this.adminFeeCents,
    required this.adminFeeDisplay,
    required this.status,
    this.expiresAt,
  });

  factory InquiryEntity.fromJson(Map<String, dynamic> json) {
    String pName = '';
    String sku = '';
    if (json['product'] is Map) {
      final pMap = json['product'] as Map;
      pName = pMap['name']?.toString() ?? '';
      sku = pMap['sku_code']?.toString() ?? '';
    }

    return InquiryEntity(
      id: json['id'] as int? ?? 0,
      skuCode: sku,
      productName: pName,
      customerNumber: json['customer_number'] as String? ?? '',
      amountCents: json['amount'] as int? ?? 0,
      amountDisplay: json['amount_display'] as String? ?? '',
      adminFeeCents: json['admin_fee'] as int? ?? 0,
      adminFeeDisplay: json['admin_fee_display'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
    );
  }
}

