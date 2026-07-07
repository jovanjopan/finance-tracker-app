import 'package:uuid/uuid.dart';

import '../../features/categories/domain/category_entity.dart';
import '../../features/categories/domain/category_repository.dart';

/// Mengisi kategori bawaan sekali saja saat aplikasi pertama kali dipakai,
/// supaya dropdown kategori di form transaksi tidak kosong sebelum UI
/// kelola-kategori sungguhan dibangun. Tidak melakukan apa-apa jika
/// sudah ada kategori tersimpan (dicek lewat watchAllCategories().first).
class DefaultCategorySeeder {
  DefaultCategorySeeder._();

  static Future<void> seedIfNeeded(CategoryRepository repository) async {
    final existing = await repository.watchAllCategories().first;
    if (existing.isNotEmpty) {
      return;
    }

    const uuid = Uuid();
    final defaults = <CategoryEntity>[
      CategoryEntity(id: uuid.v4(), name: 'gaji', transactionType: 'income'),
      CategoryEntity(
        id: uuid.v4(),
        name: 'makan & minum',
        transactionType: 'expense',
        expenseClassification: 'needs',
      ),
      CategoryEntity(
        id: uuid.v4(),
        name: 'transportasi',
        transactionType: 'expense',
        expenseClassification: 'needs',
      ),
      CategoryEntity(
        id: uuid.v4(),
        name: 'hiburan',
        transactionType: 'expense',
        expenseClassification: 'wants',
      ),
    ];

    for (final category in defaults) {
      await repository.createCategory(category);
    }
  }
}