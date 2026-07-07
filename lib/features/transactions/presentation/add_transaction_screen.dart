import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../categories/presentation/category_providers.dart';
import '../domain/transaction_entity.dart';
import '../domain/transaction_validator.dart';
import '../../budgets/domain/allocate_income_use_case.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _type = 'expense';
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _allocationChoice; // null, 'auto', 'needs', 'wants', 'savings'
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

@override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  Color get _typeColor {
    switch (_type) {
      case 'income':
        return AppColors.positive;
      case 'transfer':
        return AppColors.primary;
      default:
        return AppColors.negative;
    }
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _type = newType;
      if (_type == 'transfer') {
        _selectedCategoryId = null;
      } else {
        _selectedToAccountId = null;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

Future<void> _submit() async {
    final amount = CurrencyInputFormatter.parse(_amountController.text);

    if (amount <= 0) {
      _showError('jumlah harus lebih dari 0');
      return;
    }

    if (_selectedAccountId == null) {
      _showError('pilih akun');
      return;
    }

    if (_type == 'transfer') {
      if (_selectedToAccountId == null) {
        _showError('pilih akun tujuan');
        return;
      }
      if (_selectedToAccountId == _selectedAccountId) {
        _showError('akun tujuan harus berbeda dari akun asal');
        return;
      }
    } else {
      if (_selectedCategoryId == null) {
        _showError('pilih kategori');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_type == 'transfer') {
        await ref.read(transferMoneyUseCaseProvider).execute(
              sourceAccountId: _selectedAccountId!,
              destinationAccountId: _selectedToAccountId!,
              amount: amount,
              transactionDate: _selectedDate,
            );
      } else {
        final transaction = TransactionEntity(
          id: const Uuid().v4(),
          type: _type,
          amount: amount,
          transactionDate: _selectedDate,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );

        TransactionValidator.validate(transaction);
        await ref.read(transactionRepositoryProvider).createTransaction(transaction);

        if (_type == 'income' && _allocationChoice != null) {
          try {
            final allocateUseCase = ref.read(allocateIncomeUseCaseProvider);
            if (_allocationChoice == 'auto') {
              await allocateUseCase.allocateAutomatically(
                amount: amount,
                transactionDate: _selectedDate,
              );
            } else {
              await allocateUseCase.allocateManually(
                classification: _allocationChoice!,
                amount: amount,
                transactionDate: _selectedDate,
              );
            }
          } catch (_) {
            if (mounted) {
              _showError('transaksi tersimpan, tapi gagal mengalokasikan budget');
            }
          }
        }
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError('gagal menyimpan transaksi, coba lagi');
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
    final accountsAsync = ref.watch(accountsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'tambah transaksi',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _TypeTab(
                    label: 'masuk',
                    isActive: _type == 'income',
                    activeColor: AppColors.positive,
                    onTap: () => _onTypeChanged('income'),
                  ),
                  _TypeTab(
                    label: 'keluar',
                    isActive: _type == 'expense',
                    activeColor: AppColors.negative,
                    onTap: () => _onTypeChanged('expense'),
                  ),
                  _TypeTab(
                    label: 'transfer',
                    isActive: _type == 'transfer',
                    activeColor: AppColors.primary,
                    onTap: () => _onTypeChanged('transfer'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _FieldLabel('jumlah'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: _typeColor, width: 2),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  style: GoogleFonts.vt323(fontSize: 20, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: GoogleFonts.vt323(fontSize: 20, color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _FieldLabel('akun'),
              accountsAsync.when(
                data: (accounts) {
                  final activeAccounts = accounts.where((a) => a.isActive).toList();
                  return _DropdownField<String>(
                    value: _selectedAccountId,
                    hint: 'pilih akun',
                    items: activeAccounts
                        .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedAccountId = value),
                  );
                },
                loading: () => const _DropdownPlaceholder(text: 'memuat akun...'),
                error: (error, stackTrace) => const _DropdownPlaceholder(text: 'gagal memuat akun'),
              ),
              const SizedBox(height: 14),
              if (_type == 'transfer') ...[
                _FieldLabel('ke akun'),
                accountsAsync.when(
                  data: (accounts) {
                    final targetAccounts = accounts
                        .where((a) => a.isActive && a.id != _selectedAccountId)
                        .toList();
                    return _DropdownField<String>(
                      value: _selectedToAccountId,
                      hint: 'pilih akun tujuan',
                      items: targetAccounts
                          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedToAccountId = value),
                    );
                  },
                  loading: () => const _DropdownPlaceholder(text: 'memuat akun...'),
                  error: (error, stackTrace) => const _DropdownPlaceholder(text: 'gagal memuat akun'),
                ),
              ] else ...[
                _FieldLabel('kategori'),
                categoriesAsync.when(
                  data: (categories) {
                    final filtered = categories.where((c) => c.transactionType == _type).toList();
                    return _DropdownField<String>(
                      value: _selectedCategoryId,
                      hint: 'pilih kategori',
                      items: filtered
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                    );
                  },
                  loading: () => const _DropdownPlaceholder(text: 'memuat kategori...'),
                  error: (error, stackTrace) => const _DropdownPlaceholder(text: 'gagal memuat kategori'),
                ),
              ],
              if (_type == 'income') ...[
                const SizedBox(height: 14),
                _FieldLabel('alokasi 50/30/20 (opsional)'),
                _DropdownField<String>(
                  value: _allocationChoice,
                  hint: 'tidak dialokasikan',
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('otomatis (50/30/20)')),
                    DropdownMenuItem(value: 'needs', child: Text('manual: kebutuhan (50%)')),
                    DropdownMenuItem(value: 'wants', child: Text('manual: keinginan (30%)')),
                    DropdownMenuItem(value: 'savings', child: Text('manual: tabungan (20%)')),
                  ],
                  onChanged: (value) => setState(() => _allocationChoice = value),
                ),
              ],
              const SizedBox(height: 14),
              _FieldLabel('tanggal'),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.format(_selectedDate),
                        style: GoogleFonts.vt323(fontSize: 18, color: AppColors.textPrimary),
                      ),
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _FieldLabel('catatan (opsional)'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: TextField(
                  controller: _noteController,
                  style: GoogleFonts.vt323(fontSize: 18, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'misal: makan ayam geprek',
                    hintStyle: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
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
                          'simpan',
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

class _TypeTab extends StatelessWidget {
  const _TypeTab({
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
    return Expanded(
      child: InkWell(
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
              fontSize: 16,
              color: isActive ? AppColors.background : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted)),
          dropdownColor: AppColors.surface,
          style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textPrimary),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DropdownPlaceholder extends StatelessWidget {
  const _DropdownPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Text(text, style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted)),
    );
  }
}