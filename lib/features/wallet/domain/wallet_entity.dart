class WalletMutationEntity {
  final int id;
  final String type; // 'credit' or 'debit'
  final int amountCents;
  final String amountDisplay;
  final int balanceAfterCents;
  final String balanceAfterDisplay;
  final String referenceType; // 'topup', 'transaction', 'refund', 'adjustment'
  final int? referenceId;
  final String? note;
  final DateTime? createdAt;

  const WalletMutationEntity({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.amountDisplay,
    required this.balanceAfterCents,
    required this.balanceAfterDisplay,
    required this.referenceType,
    this.referenceId,
    this.note,
    this.createdAt,
  });

  factory WalletMutationEntity.fromJson(Map<String, dynamic> json) {
    return WalletMutationEntity(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'credit',
      amountCents: json['amount'] as int? ?? json['amount_cents'] as int? ?? 0,
      amountDisplay: json['amount_display'] as String? ?? '',
      balanceAfterCents: json['balance_after'] as int? ?? json['balance_after_cents'] as int? ?? 0,
      balanceAfterDisplay: json['balance_after_display'] as String? ?? '',
      referenceType: json['reference_type'] as String? ?? 'transaction',
      referenceId: json['reference_id'] as int?,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class TopupChannelEntity {
  final String code;
  final String name;
  final String method;
  final String paymentGateway;
  final int minAmountCents;
  final int maxAmountCents;
  final int feeCents;
  final String feeDisplay;
  final String feeType;
  final bool isActive;
  final String? accountNumber;
  final String? accountName;
  final String? iconAsset;

  const TopupChannelEntity({
    required this.code,
    required this.name,
    required this.method,
    required this.paymentGateway,
    required this.minAmountCents,
    required this.maxAmountCents,
    required this.feeCents,
    required this.feeDisplay,
    required this.feeType,
    required this.isActive,
    this.accountNumber,
    this.accountName,
    this.iconAsset,
  });

  /// Calculate fee in cents for a given nominal
  int calculateFeeCents(int nominalCents) {
    if (feeType == 'percentage') {
      return (nominalCents * 0.007).round(); // 0.7% standard
    }
    return feeCents;
  }

  /// Calculate total payment in cents (nominal + fee)
  int calculateTotalCents(int nominalCents) {
    return nominalCents + calculateFeeCents(nominalCents);
  }

  factory TopupChannelEntity.fromJson(Map<String, dynamic> json) {
    return TopupChannelEntity(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      method: json['method'] as String? ?? 'payment_gateway',
      paymentGateway: json['payment_gateway'] as String? ?? 'midtrans',
      minAmountCents: json['min_amount_cents'] as int? ?? 1000000,
      maxAmountCents: json['max_amount_cents'] as int? ?? 1000000000,
      feeCents: json['fee_cents'] as int? ?? 0,
      feeDisplay: json['fee_display'] as String? ?? 'Gratis',
      feeType: json['fee_type'] as String? ?? 'flat',
      isActive: json['is_active'] as bool? ?? true,
      accountNumber: json['account_number'] as String?,
      accountName: json['account_name'] as String?,
      iconAsset: json['icon_asset'] as String?,
    );
  }
}

class TopupGroupEntity {
  final String groupName;
  final List<TopupChannelEntity> items;

  const TopupGroupEntity({
    required this.groupName,
    required this.items,
  });

  factory TopupGroupEntity.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List? ?? [])
        .map((e) => TopupChannelEntity.fromJson(e as Map<String, dynamic>))
        .toList();

    return TopupGroupEntity(
      groupName: json['group'] as String? ?? json['group_name'] as String? ?? 'Saluran Pembayaran',
      items: list,
    );
  }
}

class TopupResultEntity {
  final int id;
  final int amountCents;
  final String amountDisplay;
  final String method;
  final String paymentGateway;
  final String? gatewayRef;
  final String paymentUrl;
  final String status;
  final DateTime? createdAt;

  const TopupResultEntity({
    required this.id,
    required this.amountCents,
    required this.amountDisplay,
    required this.method,
    required this.paymentGateway,
    this.gatewayRef,
    required this.paymentUrl,
    required this.status,
    this.createdAt,
  });

  factory TopupResultEntity.fromJson(Map<String, dynamic> json) {
    return TopupResultEntity(
      id: json['id'] as int? ?? 0,
      amountCents: json['amount'] as int? ?? json['amount_cents'] as int? ?? 0,
      amountDisplay: json['amount_display'] as String? ?? '',
      method: json['method'] as String? ?? 'payment_gateway',
      paymentGateway: json['payment_gateway'] as String? ?? 'midtrans',
      gatewayRef: json['gateway_ref'] as String?,
      paymentUrl: json['payment_url'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

