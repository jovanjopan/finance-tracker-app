class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.isActive,
  });

  final String id;
  final String name;
  final String type;
  final double initialBalance;
  final bool isActive;
}