import 'package:drift/drift.dart';
import '../converters/transaction_type.dart';
import 'categories.dart';

/// Transactions table schema.
/// Money is stored as an integer (whole IDR), dates are stored as UTC.
@TableIndex(name: 'idx_transactions_date_type', columns: {#date, #type})
@TableIndex(name: 'idx_transactions_category', columns: {#categoryId})
class Transactions extends Table {
  TextColumn get id => text()();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get source => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
