import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_text_field.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              hint: 'Ketik nomor HP (contoh: 0812...)',
              label: 'Nomor Tujuan',
              keyboardType: TextInputType.phone,
              prefix: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text('Pilihan Denominasi', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildProductCard('Telkomsel 5.000', 'Masa aktif 7 hari', 'Rp 5.850'),
            const SizedBox(height: 10),
            _buildProductCard('Telkomsel 10.000', 'Masa aktif 15 hari', 'Rp 10.850'),
            const SizedBox(height: 10),
            _buildProductCard('Telkomsel 20.000', 'Masa aktif 30 hari', 'Rp 20.500'),
            const SizedBox(height: 10),
            _buildProductCard('Telkomsel 50.000', 'Masa aktif 30 hari', 'Rp 50.250'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(String name, String desc, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.titleMedium),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall),
            ],
          ),
          Text(
            price,
            style: AppTypography.labelLarge.copyWith(color: AppColors.accentEmeraldDark),
          ),
        ],
      ),
    );
  }
}

