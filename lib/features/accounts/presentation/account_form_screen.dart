import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../domain/account_entity.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.existingAccount});

  final AccountEntity? existingAccount;

  bool get isEditMode => existingAccount != null;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAccount;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _balanceController = TextEditingController(
      text: existing == null ? '' : _formatAmountForInput(existing.initialBalance),
    );
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final initialBalance = CurrencyInputFormatter.parse(_balanceController.text);

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.isEditMode) {
        final updated = AccountEntity(
          id: widget.existingAccount!.id,
          name: name,
          type: widget.existingAccount!.type,
          initialBalance: initialBalance,
          isActive: _isActive,
        );
        await ref.read(updateAccountUseCaseProvider).execute(updated);
      } else {
        final created = AccountEntity(
          id: const Uuid().v4(),
          name: name,
          type: 'cash',
          initialBalance: initialBalance,
          isActive: true,
        );
        await ref.read(accountRepositoryProvider).createAccount(created);
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
        const SnackBar(content: Text('gagal menyimpan akun, coba lagi')),
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
                      widget.isEditMode ? 'edit akun' : 'tambah akun',
                      style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('nama akun', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'misal: dompet tunai',
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
                      return 'nama akun wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('saldo awal', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _balanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '0',
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
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return null;
                    }
                    if (CurrencyInputFormatter.parse(trimmed) < 0) {
                      return 'saldo tidak boleh negatif';
                    }
                    return null;
                  },
                ),
                if (widget.isEditMode) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'akun aktif',
                          style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        activeColor: AppColors.positive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                  Text(
                    'akun nonaktif tidak muncul di pilihan transaksi baru, tapi riwayatnya tetap tersimpan.',
                    style: GoogleFonts.vt323(fontSize: 13, color: AppColors.textMuted),
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