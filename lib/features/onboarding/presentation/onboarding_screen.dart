import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../accounts/domain/account_entity.dart';
import '../../navigation/presentation/main_navigation_screen.dart';
import '../../../core/widgets/pixel_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'buat akun pertama',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'setiap transaksi butuh akun. mulai dari satu dulu, kamu bisa tambah lagi nanti.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.vt323(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'nama akun',
                        hintText: 'dompet tunai',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'nama akun wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _balanceController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: _inputDecoration(
                        label: 'saldo awal',
                        hintText: '0',
                      ).copyWith(prefixText: 'Rp '),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return null;
                        }
                        final parsed = CurrencyInputFormatter.parse(trimmed);
                        if (parsed < 0) {
                          return 'saldo tidak boleh negatif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    PixelButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.background),
                              ),
                            )
                          : Text(
                              'simpan',
                              style: GoogleFonts.vt323(
                                fontSize: 22,
                                color: AppColors.background,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      errorStyle: const TextStyle(color: AppColors.negative),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.negative),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.negative, width: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final initialBalance = CurrencyInputFormatter.parse(_balanceController.text);

    final account = AccountEntity(
      id: const Uuid().v4(),
      name: name,
      type: 'cash',
      initialBalance: initialBalance,
      isActive: true,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(accountRepositoryProvider).createAccount(account);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
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
}