import 'package:flutter/material.dart';

import '../../../../core/utils/year_month_utils.dart';

/// A Material 3 dialog for selecting a specific month and year.
class MonthPickerDialog extends StatefulWidget {
  final String initialYearMonth;
  final int minYear;
  final int maxYear;

  const MonthPickerDialog({
    super.key,
    required this.initialYearMonth,
    this.minYear = 2020,
    this.maxYear = 2035,
  });

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    final (year, month) = YearMonthUtils.parse(widget.initialYearMonth);
    _selectedYear = year;
    _selectedMonth = month;
  }

  void _previousYear() {
    if (_selectedYear > widget.minYear) {
      setState(() {
        _selectedYear--;
      });
    }
  }

  void _nextYear() {
    if (_selectedYear < widget.maxYear) {
      setState(() {
        _selectedYear++;
      });
    }
  }

  void _selectMonth(int month) {
    final yearMonth =
        '$_selectedYear-${month.toString().padLeft(2, '0')}';
    Navigator.of(context).pop(yearMonth);
  }

  void _selectCurrentMonth() {
    final (currentYear, currentMonth) =
        YearMonthUtils.parse(YearMonthUtils.currentYearMonth());
    setState(() {
      _selectedYear = currentYear;
      _selectedMonth = currentMonth;
    });
    _selectMonth(currentMonth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (currentRealYear, currentRealMonth) =
        YearMonthUtils.parse(YearMonthUtils.currentYearMonth());

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Year Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _selectedYear > widget.minYear ? _previousYear : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Previous year',
                  ),
                  Text(
                    '$_selectedYear',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: _selectedYear < widget.maxYear ? _nextYear : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next year',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3x4 Month Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final monthNumber = index + 1;
                  final monthName = _monthNames[index];
                  final isSelected = _selectedYear ==
                          YearMonthUtils.parse(widget.initialYearMonth).$1 &&
                      monthNumber == _selectedMonth;
                  final isRealCurrentMonth = _selectedYear == currentRealYear &&
                      monthNumber == currentRealMonth;

                  if (isSelected) {
                    return FilledButton(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _selectMonth(monthNumber),
                      child: Text(
                        monthName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  if (isRealCurrentMonth) {
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _selectMonth(monthNumber),
                      child: Text(
                        monthName,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _selectMonth(monthNumber),
                    child: Text(monthName),
                  );
                },
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Dialog Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _selectCurrentMonth,
                    icon: const Icon(Icons.today_rounded, size: 18),
                    label: const Text('This Month'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
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

/// Helper function to display the [MonthPickerDialog].
Future<String?> showMonthPickerDialog({
  required BuildContext context,
  required String initialYearMonth,
  int minYear = 2020,
  int maxYear = 2035,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => MonthPickerDialog(
      initialYearMonth: initialYearMonth,
      minYear: minYear,
      maxYear: maxYear,
    ),
  );
}
