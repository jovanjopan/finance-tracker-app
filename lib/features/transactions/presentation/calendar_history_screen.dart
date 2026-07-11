import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/transaction_date_grouping.dart';
import '../domain/transaction_entity.dart';
import 'transaction_list_tile.dart';
import 'transaction_providers.dart';

const List<String> _monthNames = [
  'januari', 'februari', 'maret', 'april', 'mei', 'juni',
  'juli', 'agustus', 'september', 'oktober', 'november', 'desember',
];

const List<String> _weekdayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

class CalendarHistoryScreen extends ConsumerStatefulWidget {
  const CalendarHistoryScreen({super.key});

  @override
  ConsumerState<CalendarHistoryScreen> createState() => _CalendarHistoryScreenState();
}

class _CalendarHistoryScreenState extends ConsumerState<CalendarHistoryScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
      _selectedDate = null;
    });
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_selectedDate != null && _isSameDay(_selectedDate!, day)) {
        _selectedDate = null;
      } else {
        _selectedDate = day;
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
child: Text(
                'riwayat',
                style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                data: (allTransactions) {
                  final monthTransactions = allTransactions.where((t) {
                    return t.transactionDate.year == _visibleMonth.year &&
                        t.transactionDate.month == _visibleMonth.month;
                  }).toList();

                  var listSource = _selectedDate == null
                      ? monthTransactions
                      : monthTransactions.where((t) => _isSameDay(t.transactionDate, _selectedDate!)).toList();

                  if (_typeFilter != 'all') {
                    listSource = listSource.where((t) => t.type == _typeFilter).toList();
                  }

                  final groups = groupTransactionsByDate(listSource, referenceDate: DateTime.now());

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _MonthCalendar(
                        visibleMonth: _visibleMonth,
                        selectedDate: _selectedDate,
                        monthTransactions: monthTransactions,
                        onPrevMonth: () => _changeMonth(-1),
                        onNextMonth: () => _changeMonth(1),
                        onDayTap: _onDayTap,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _FilterChip(
                            label: 'semua',
                            isActive: _typeFilter == 'all',
                            onTap: () => setState(() => _typeFilter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'masuk',
                            isActive: _typeFilter == 'income',
                            onTap: () => setState(() => _typeFilter = 'income'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'keluar',
                            isActive: _typeFilter == 'expense',
                            onTap: () => setState(() => _typeFilter = 'expense'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'transfer',
                            isActive: _typeFilter == 'transfer',
                            onTap: () => setState(() => _typeFilter = 'transfer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (groups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'tidak ada transaksi pada periode ini',
                              style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        for (final group in groups) ...[
                          Text(
                            group.label,
                            style: GoogleFonts.vt323(
                              fontSize: 16,
                              color: group.label.startsWith('hari ini')
                                  ? AppColors.accentGamify
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...group.transactions.map(
                            (transaction) => TransactionListTile(transaction: transaction),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 20),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'gagal memuat riwayat',
                    style: GoogleFonts.vt323(fontSize: 16, color: AppColors.negative),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.monthTransactions,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
  });

  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final List<TransactionEntity> monthTransactions;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDayTap;

  Map<int, Set<String>> get _typesByDay {
    final map = <int, Set<String>>{};
    for (final transaction in monthTransactions) {
      final day = transaction.transactionDate.day;
      map.putIfAbsent(day, () => {}).add(transaction.type);
    }
    return map;
  }

  Color _dotColor(String type) {
    switch (type) {
      case 'income':
        return AppColors.positive;
      case 'expense':
        return AppColors.negative;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstDayOfMonth.weekday - 1;

    final typesByDay = _typesByDay;

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(visibleMonth.year, visibleMonth.month, day);
      final isToday = date == today;
      final isSelected = selectedDate != null &&
          date.year == selectedDate!.year &&
          date.month == selectedDate!.month &&
          date.day == selectedDate!.day;
      final types = typesByDay[day] ?? const <String>{};

      cells.add(
        InkWell(
          onTap: () => onDayTap(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: isToday ? Border.all(color: AppColors.accentGamify, width: 1.5) : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: GoogleFonts.vt323(
                    fontSize: 14,
                    color: isSelected ? AppColors.background : AppColors.textSecondary,
                  ),
                ),
                if (types.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: types.take(3).map((type) {
                        return Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: _dotColor(type),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left, color: AppColors.textMuted),
              ),
              Text(
                '${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
                style: GoogleFonts.vt323(fontSize: 17, color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ),
            ],
          ),
          Row(
            children: _weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.vt323(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGamify : AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Text(
          label,
          style: GoogleFonts.vt323(
            fontSize: 14,
            color: isActive ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}