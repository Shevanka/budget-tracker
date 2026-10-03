import 'package:drift/drift.dart';
import '../converters/utc_date_time_converter.dart';

/// Monthly budgets table schema.
/// Keyed by [yearMonth] ('YYYY-MM') with a UNIQUE index.
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get yearMonth => text().unique()();
  IntColumn get totalLimit => integer()();
  DateTimeColumn get createdAt =>
      dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (total_limit >= 0)'];
}
