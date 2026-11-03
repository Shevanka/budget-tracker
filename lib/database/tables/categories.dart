import 'package:drift/drift.dart';
import '../converters/transaction_type.dart';
import '../converters/utc_date_time_converter.dart';

/// Categories table schema.
/// Category deletion is soft delete (`isActive = false`) to preserve historical FKs.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  TextColumn get type =>
      textEnum<TransactionType>().withDefault(const Constant('expense'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
