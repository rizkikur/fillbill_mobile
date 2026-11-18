import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PinDotsDisplay extends StatelessWidget {
  final int length;
  final int enteredLength;
  final bool hasError;

  const PinDotsDisplay({
    super.key,
    this.length = 6,
    required this.enteredLength,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < enteredLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.error
                : isFilled
                    ? AppColors.primaryNavy
                    : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : isFilled
                      ? AppColors.primaryNavy
                      : AppColors.borderLight,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

