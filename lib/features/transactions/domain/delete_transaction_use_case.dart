import '../../budgets/domain/allocate_income_use_case.dart';
import 'transaction_repository.dart';

class DeleteTransactionUseCase {
  DeleteTransactionUseCase({
    required TransactionRepository transactionRepository,
    required AllocateIncomeUseCase allocateIncomeUseCase,
  })  : _transactionRepository = transactionRepository,
        _allocateIncomeUseCase = allocateIncomeUseCase;

  final TransactionRepository _transactionRepository;
  final AllocateIncomeUseCase _allocateIncomeUseCase;

  Future<void> execute(String transactionId) async {
    final transaction = await _transactionRepository.getTransactionById(transactionId);

    if (transaction != null &&
        transaction.type == 'income' &&
        transaction.allocationType != null) {
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

    await _transactionRepository.deleteTransaction(transactionId);
  }
}