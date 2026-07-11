import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/category_entity.dart';
import 'category_form_screen.dart';
import 'category_providers.dart';
import '../../../core/widgets/pixel_page_route.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pixel_loading_indicator.dart';


class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentGamify,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: () {
          Navigator.of(context).push(
            PixelPageRoute<void>(
              builder: (_) => const CategoryFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'kelola kategori',
                    style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
if (categories.isEmpty) {
                    return const EmptyState(
                      icon: Icons.label_outline,
                      message: 'belum ada kategori',
                    );
                  }
                  final incomeCategories = categories.where((c) => c.transactionType == 'income').toList();
                  final expenseCategories = categories.where((c) => c.transactionType == 'expense').toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (incomeCategories.isNotEmpty) ...[
                        _SectionLabel('pemasukan'),
                        ...incomeCategories.map((c) => _CategoryTile(category: c)),
                        const SizedBox(height: 12),
                      ],
                      if (expenseCategories.isNotEmpty) ...[
                        _SectionLabel('pengeluaran'),
                        ...expenseCategories.map((c) => _CategoryTile(category: c)),
                      ],
                    ],
                  );
                },
loading: () => const Center(child: PixelLoadingIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'gagal memuat kategori',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final CategoryEntity category;

  String? get _classificationLabel {
    switch (category.expenseClassification) {
      case 'needs':
        return 'kebutuhan';
      case 'wants':
        return 'keinginan';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          PixelPageRoute<void>(
            builder: (_) => CategoryFormScreen(existingCategory: category),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: GoogleFonts.vt323(fontSize: 17, color: AppColors.textPrimary),
                  ),
                  if (_classificationLabel != null)
                    Text(
                      _classificationLabel!,
                      style: GoogleFonts.vt323(fontSize: 13, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}