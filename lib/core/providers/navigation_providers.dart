import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Class Notifier untuk mengelola state tab index
class SelectedTabIndex extends Notifier<int> {
  @override
  int build() {
    return 0; // Nilai awal (0 = Beranda)
  }

  /// Method untuk mengubah index tab
  void changeIndex(int index) {
    state = index;
  }
}

/// Index tab aktif di MainNavigationScreen.
/// 0 = Beranda, 1 = Riwayat, 2 = Anggaran, 3 = Lainnya.
final selectedTabIndexProvider = NotifierProvider<SelectedTabIndex, int>(
  SelectedTabIndex.new,
);