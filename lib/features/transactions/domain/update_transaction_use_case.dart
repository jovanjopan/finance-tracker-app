import '../../budgets/domain/allocate_income_use_case.dart';
import 'transaction_entity.dart';
import 'transaction_repository.dart';
import 'transaction_validator.dart';

class UpdateTransactionUseCase {
  UpdateTransactionUseCase({
    required TransactionRepository transactionRepository,
    required AllocateIncomeUseCase allocateIncomeUseCase,
  })  : _transactionRepository = transactionRepository,
        _allocateIncomeUseCase = allocateIncomeUseCase;

  final TransactionRepository _transactionRepository;
  final AllocateIncomeUseCase _allocateIncomeUseCase;

  Future<void> execute(TransactionEntity updatedTransaction) async {
    TransactionValidator.validate(updatedTransaction);

    final oldTransaction =
        await _transactionRepository.getTransactionById(updatedTransaction.id);

    if (oldTransaction != null) {
      await _reverseAllocationIfNeeded(oldTransaction);
    }

    await _transactionRepository.updateTransaction(updatedTransaction);

    await _applyAllocationIfNeeded(updatedTransaction);
  }

  Future<void> _reverseAllocationIfNeeded(TransactionEntity transaction) async {
    if (transaction.type != 'income' || transaction.allocationType == null) {
      return;
    }

    if (transaction.allocationType == 'auto') {
      await _allocateIncomeUseCase.reverseAutomaticAllocation(
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );
    } else {
      await _allocateIncomeUseCase.reverseManualAllocation(
        classification: transaction.allocationType!,
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );
    }
  }

  Future<void> _applyAllocationIfNeeded(TransactionEntity transaction) async {
    if (transaction.type != 'income' || transaction.allocationType == null) {
      return;
    }

    if (transaction.allocationType == 'auto') {
      await _allocateIncomeUseCase.allocateAutomatically(
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );
    } else {
      await _allocateIncomeUseCase.allocateManually(
        classification: transaction.allocationType!,
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );
    }
  }
}