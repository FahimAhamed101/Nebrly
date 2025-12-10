import 'package:flutter/material.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/utils/enums.dart'; // Add this import

// Remove this line: enum RequestFilter { open, closed }

class RequestFilterTabs extends StatelessWidget {
  final RequestFilter currentFilter;
  final ValueChanged<RequestFilter> onFilterChanged; // Use ValueChanged
  final int openCount;
  final int closedCount;

  const RequestFilterTabs({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.openCount,
    required this.closedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Open tab
              Expanded(
                child: GestureDetector(
                  onTap: () => onFilterChanged(RequestFilter.open),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            'Open',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: currentFilter == RequestFilter.open
                                ? AppColors.primary
                                : AppColors.DarkGray,
                          ),
                          if (openCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppText(
                                openCount.toString(),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: currentFilter == RequestFilter.open
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Closed tab
              Expanded(
                child: GestureDetector(
                  onTap: () => onFilterChanged(RequestFilter.closed),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            'Closed',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: currentFilter == RequestFilter.closed
                                ? AppColors.primary
                                : AppColors.DarkGray,
                          ),
                          if (closedCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppText(
                                closedCount.toString(),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: currentFilter == RequestFilter.closed
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Full width divider
          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 8),
            color: AppColors.LightGray,
          ),
        ],
      ),
    );
  }
}