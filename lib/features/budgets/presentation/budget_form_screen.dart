import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../categories/presentation/category_providers.dart';
import '../domain/budget_entity.dart';
import '../domain/budget_validator.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.existingBudget});

  final BudgetEntity? existingBudget;

  bool get isEditMode => existingBudget != null;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  late final TextEditingController _amountController;

  String? _selectedCategoryId;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBudget;

    _selectedCategoryId = existing?.categoryId;
    _amountController = TextEditingController(
      text: existing == null ? '' : _formatAmountForInput(existing.targetAmount),
    );

    final now = DateTime.now();
    _startDate = existing?.startDate ?? DateTime(now.year, now.month, 1);
    _endDate = existing?.endDate ?? DateTime(now.year, now.month + 1, 0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatAmountForInput(double amount) {
    final raw = amount.round().toString();
    final buffer = StringBuffer();
    final length = raw.length;
    for (var i = 0; i < length; i++) {
      buffer.write(raw[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    final amount = CurrencyInputFormatter.parse(_amountController.text);

    if (_selectedCategoryId == null) {
      _showError('pilih kategori');
      return;
    }
    if (amount <= 0) {
      _showError('target budget harus lebih dari 0');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      _showError('tanggal akhir tidak boleh sebelum tanggal mulai');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final budget = BudgetEntity(
        id: widget.existingBudget?.id ?? const Uuid().v4(),
        categoryId: _selectedCategoryId,
        targetAmount: amount,
        startDate: _startDate,
        endDate: _endDate,
      );

      BudgetValidator.validate(budget);

      if (widget.isEditMode) {
        await ref.read(budgetRepositoryProvider).updateBudget(budget);
      } else {
        await ref.read(budgetRepositoryProvider).createBudget(budget);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError('gagal menyimpan budget, coba lagi');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('hapus budget?', style: GoogleFonts.vt323(fontSize: 20, color: AppColors.textPrimary)),
        content: Text(
          'budget ini akan dihapus permanen.',
          style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('batal', style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('hapus', style: GoogleFonts.vt323(fontSize: 16, color: AppColors.negative)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await ref.read(budgetRepositoryProvider).deleteBudget(widget.existingBudget!.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError('gagal menghapus budget, coba lagi');
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                  Expanded(
                    child: Text(
                      widget.isEditMode ? 'edit budget' : 'tambah budget',
                      style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                  if (widget.isEditMode)
                    IconButton(
                      onPressed: _isDeleting ? null : _confirmDelete,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.negative),
                            )
                          : const Icon(Icons.delete_outline, color: AppColors.negative),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('kategori', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              categoriesAsync.when(
                data: (categories) {
                  final expenseCategories = categories.where((c) => c.transactionType == 'expense').toList();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        hint: Text('pilih kategori', style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted)),
                        dropdownColor: AppColors.surface,
                        style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textPrimary),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                        items: expenseCategories
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: widget.isEditMode
                            ? null
                            : (value) => setState(() => _selectedCategoryId = value),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              if (widget.isEditMode)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'kategori tidak dapat diubah saat edit. hapus dan buat baru jika perlu.',
                    style: GoogleFonts.vt323(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: 16),
              Text('target budget', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  style: GoogleFonts.vt323(fontSize: 18, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: GoogleFonts.vt323(fontSize: 18, color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('mulai', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickStartDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Text(
                              DateFormatter.format(_startDate),
                              style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('sampai', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickEndDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Text(
                              DateFormatter.format(_endDate),
                              style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    );
  }
}