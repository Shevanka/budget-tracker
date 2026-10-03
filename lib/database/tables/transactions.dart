import 'package:drift/drift.dart';
import '../converters/transaction_type.dart';
import '../converters/utc_date_time_converter.dart';
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
  DateTimeColumn get date => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get updatedAt =>
      dateTime().nullable().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (amount > 0)'];
}
