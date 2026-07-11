import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/navigation_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pixel_fab.dart';
import '../../budgets/presentation/anggaran_tab_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../settings/presentation/lainnya_tab_screen.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../transactions/presentation/calendar_history_screen.dart';
import 'pixel_bottom_nav.dart';
import '../../../core/widgets/pixel_page_route.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  static const List<Widget> _tabs = [
    DashboardScreen(),
    CalendarHistoryScreen(),
    AnggaranTabScreen(),
    LainnyaTabScreen(),
  ];

  static const List<PixelBottomNavItem> _navItems = [
    PixelBottomNavItem(icon: Icons.home_outlined, label: 'beranda'),
    PixelBottomNavItem(icon: Icons.calendar_today_outlined, label: 'riwayat'),
    PixelBottomNavItem(icon: Icons.pie_chart_outline, label: 'anggaran'),
    PixelBottomNavItem(icon: Icons.menu, label: 'lainnya'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: selectedIndex, children: _tabs),
      floatingActionButton: PixelFab(
        icon: Icons.add,
        onPressed: () {
          Navigator.of(context).push(
            PixelPageRoute<void>(builder: (_) => const AddTransactionScreen()),
          );
        },
      ),
      bottomNavigationBar: PixelBottomNav(
        items: _navItems,
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(selectedTabIndexProvider.notifier).state = index,
      ),
    );
  }
}