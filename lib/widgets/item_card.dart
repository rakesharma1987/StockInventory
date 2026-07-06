import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lowStock = item.isLowStock;
    final quantityLabel = item.quantity.toStringAsFixed(
      item.quantity.truncateToDouble() == item.quantity ? 0 : 2,
    );
    final thresholdLabel = item.lowStockThreshold.toStringAsFixed(
      item.lowStockThreshold.truncateToDouble() == item.lowStockThreshold ? 0 : 2,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        // Built from a plain Row/Column instead of ListTile: ListTile
        // reserves a fixed height for its subtitle (assuming one line),
        // so the extra low-stock warning line didn't fit and bled into
        // the space below it. A plain layout always sizes to fit
        // whatever content is actually there, so it can't overlap.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: lowStock
                    ? AppTheme.danger.withOpacity(0.15)
                    : AppTheme.primary.withOpacity(0.15),
                child: Icon(
                  lowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                  color: lowStock ? AppTheme.danger : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (item.categoryName != null) item.categoryName!,
                        if (item.barcode != null) item.barcode!,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (lowStock) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 13, color: AppTheme.danger),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Low stock — at or below alert level of $thresholdLabel',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'IN STOCK',
                    style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.5),
                  ),
                  Text(
                    quantityLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: lowStock ? AppTheme.danger : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
