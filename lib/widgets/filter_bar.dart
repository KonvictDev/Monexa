import 'package:flutter/material.dart';
import '../utils/date_filter.dart'; // <-- 1. CHANGE THIS IMPORT
import 'package:intl/intl.dart';

class FilterBar extends StatelessWidget {
  final DateFilter selectedFilter;
  final bool isLoading;
  final void Function(DateFilter) onFilterChanged;
  final VoidCallback onExport;
  final DateTime startDate;
  final DateTime endDate;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.isLoading,
    required this.onFilterChanged,
    required this.onExport,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    // ... (rest of the file is identical) ...
// ... (omitted for brevity) ...
    final DateFormat customDateFormat = DateFormat('MMM dd');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced vertical padding
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),

      ),
      // ✅ CHANGED: Replaced Column with a Row
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔽 Dropdown
          Expanded( // Makes the dropdown take up the available space
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateFilter>(
                value: selectedFilter,
                isExpanded: true, // Ensures it fills the space
                borderRadius: BorderRadius.circular(8),
                dropdownColor: Theme.of(context).cardColor,
                onChanged: (value) {
                  if (value != null) onFilterChanged(value);
                },
                items: DateFilter.values.map((filter) {
                  String text;

                  // Check if the item being built is 'custom'
                  if (filter == DateFilter.custom) {
                    // If 'custom' is also the *currently selected* filter,
                    // display the date range.
                    if (selectedFilter == DateFilter.custom) {
                      final start = customDateFormat.format(startDate);
                      final end = customDateFormat.format(endDate);
                      text = (start == end) ? start : '$start - $end';
                    } else {
                      // Otherwise, just show the word "Custom" in the list
                      text = 'Custom';
                    }
                  } else {
                    // For all other items, show their standard name
                    text = _filterToString(filter);
                  }

                  return DropdownMenuItem(
                    value: filter,
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 12), // Spacing between dropdown and button

          // ✅ MOVED: Export Button is now the second child of the Row
          ElevatedButton.icon(
            onPressed: isLoading ? null : onExport,
            icon: isLoading
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.file_download_rounded, size: 20),
            label: const Text('Export'), // Shortened label for better fit
            style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  // This helper function remains unchanged
  String _filterToString(DateFilter f) {
    switch (f) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.yesterday:
        return 'Yesterday';
      case DateFilter.last7Days:
        return 'Last 7 Days';
      case DateFilter.last30Days:
        return 'Last 30 Days';
      case DateFilter.custom:
      // This is the default text for the 'custom' option in the list
        return 'Custom';
    }
  }
}