import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/categories/domain/category_entity.dart';
import 'package:myfinancetracker/features/categories/domain/category_validation_exception.dart';
import 'package:myfinancetracker/features/categories/domain/category_validator.dart';

void main() {
  group('CategoryValidator', () {
    test('accepts income category without expenseClassification', () {
      final category = CategoryEntity(
        id: 'cat-1',
        name: 'Salary',
        transactionType: 'income',
      );

      expect(() => CategoryValidator.validate(category), returnsNormally);
    });

    test('throws for income category with expenseClassification', () {
      final category = CategoryEntity(
        id: 'cat-2',
        name: 'Salary',
        transactionType: 'income',
        expenseClassification: 'needs',
      );

      expect(
        () => CategoryValidator.validate(category),
        throwsA(isA<CategoryValidationException>()),
      );
    });

    test('accepts expense category with expenseClassification', () {
      final category = CategoryEntity(
        id: 'cat-3',
        name: 'Groceries',
        transactionType: 'expense',
        expenseClassification: 'needs',
      );

      expect(() => CategoryValidator.validate(category), returnsNormally);
    });

    test('accepts expense category without expenseClassification', () {
      final category = CategoryEntity(
        id: 'cat-4',
        name: 'Groceries',
        transactionType: 'expense',
      );

      expect(() => CategoryValidator.validate(category), returnsNormally);
    });
  });
}