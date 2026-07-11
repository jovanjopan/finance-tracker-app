import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/navigation_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../budgets/presentation/anggaran_tab_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../settings/presentation/lainnya_tab_screen.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../transactions/presentation/calendar_history_screen.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  static const List<Widget> _tabs = [
    DashboardScreen(),
    CalendarHistoryScreen(),
    AnggaranTabScreen(),
    LainnyaTabScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: selectedIndex, children: _tabs),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentGamify,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(selectedTabIndexProvider.notifier).state = index,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accentGamify,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'anggaran'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'lainnya'),
        ],
      ),
    );
  }
}