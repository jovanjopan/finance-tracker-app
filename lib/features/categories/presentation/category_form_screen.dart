import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/category_entity.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.existingCategory});

  final CategoryEntity? existingCategory;

  bool get isEditMode => existingCategory != null;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late String _transactionType;
  String? _expenseClassification;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCategory;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _transactionType = existing?.transactionType ?? 'expense';
    _expenseClassification = existing?.expenseClassification;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onTransactionTypeChanged(String type) {
    setState(() {
      _transactionType = type;
      if (type == 'income') {
        _expenseClassification = null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.isEditMode) {
        final updated = CategoryEntity(
          id: widget.existingCategory!.id,
          name: name,
          transactionType: _transactionType,
          expenseClassification: _transactionType == 'expense' ? _expenseClassification : null,
        );
        await ref.read(updateCategoryUseCaseProvider).execute(updated);
      } else {
        final created = CategoryEntity(
          id: const Uuid().v4(),
          name: name,
          transactionType: _transactionType,
          expenseClassification: _transactionType == 'expense' ? _expenseClassification : null,
        );
        await ref.read(categoryRepositoryProvider).createCategory(created);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('gagal menyimpan kategori, coba lagi')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.isEditMode ? 'edit kategori' : 'tambah kategori',
                      style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('nama kategori', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'misal: transportasi',
                    hintStyle: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'nama kategori wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('jenis', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _TypeOption(
                        label: 'pemasukan',
                        isActive: _transactionType == 'income',
                        activeColor: AppColors.positive,
                        onTap: () => _onTransactionTypeChanged('income'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TypeOption(
                        label: 'pengeluaran',
                        isActive: _transactionType == 'expense',
                        activeColor: AppColors.negative,
                        onTap: () => _onTransactionTypeChanged('expense'),
                      ),
                    ),
                  ],
                ),
                if (_transactionType == 'expense') ...[
                  const SizedBox(height: 16),
                  Text(
                    'kelompok 50/30/20 (opsional)',
                    style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _expenseClassification,
                        isExpanded: true,
                        hint: Text('tidak ditentukan', style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted)),
                        dropdownColor: AppColors.surface,
                        style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textPrimary),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                        items: const [
                          DropdownMenuItem(value: 'needs', child: Text('kebutuhan')),
                          DropdownMenuItem(value: 'wants', child: Text('keinginan')),
                        ],
                        onChanged: (value) => setState(() => _expenseClassification = value),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'menentukan kelompok ini membuat pengeluaran di kategori ini dihitung ke progress Health Point.',
                      style: GoogleFonts.vt323(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGamify,
                      foregroundColor: AppColors.background,
                      shadowColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                            ),
                          )
                        : Text(
                            widget.isEditMode ? 'simpan perubahan' : 'simpan',
                            style: GoogleFonts.vt323(fontSize: 22, color: AppColors.background),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor : AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.vt323(
            fontSize: 15,
            color: isActive ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}