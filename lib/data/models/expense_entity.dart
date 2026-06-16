import 'package:isar/isar.dart';

part 'expense_entity.g.dart';

@Collection()
class ExpenseEntity {
  ExpenseEntity();

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  late String title;
  late String category;
  late double amount;
  late DateTime date;
  String? notes;
  String? receiptPath;
}
