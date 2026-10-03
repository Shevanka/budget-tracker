import 'package:drift/drift.dart';

/// Monthly budgets table schema.
/// Keyed by [yearMonth] ('YYYY-MM') with a UNIQUE index.
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get yearMonth => text().unique()();
  IntColumn get totalLimit => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (total_limit >= 0)'];
}
