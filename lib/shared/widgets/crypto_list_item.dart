// File: lib/shared/widgets/crypto_list_item.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter/material.dart';

import '../../features/crypto/data/models/crypto_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// ✅ Crypto List Item Widget
/// 
/// Displays:
/// - Image
/// - Name/Symbol
/// - Price
/// - Price change %
class CryptoListItem extends StatelessWidget {

  final CryptoModel item;
  final VoidCallback onTap;
  final double ownedQuantity;

  const CryptoListItem({
    super.key,
    required this.item,
    required this.onTap,
    this.ownedQuantity = 0,
  });

  String _formatQuantity(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    final fixed = value.toStringAsFixed(8);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {

    /// ✅ Correct field usage
    final isPositive = item.priceChangePercentage >= 0;

    return InkWell(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(AppSizes.padding),

        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            ),
          ],
        ),

        child: Row(
          children: [

            /// ✅ Image
            CircleAvatar(
              backgroundImage: NetworkImage(item.image),
              backgroundColor: Colors.transparent,
            ),

            const SizedBox(width: 12),

            /// ✅ Name + Symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    item.symbol.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  if (ownedQuantity > 0)
                    Text(
                      "Owned: ${_formatQuantity(ownedQuantity)}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            /// ✅ Price + Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                /// ✅ FIXED
                Text(
                  "₹ ${item.currentPrice.toStringAsFixed(2)}",
                ),

                const SizedBox(height: 4),

                /// ✅ FIXED
                Text(
                  "${item.priceChangePercentage.toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: isPositive
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
