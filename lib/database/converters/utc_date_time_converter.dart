import 'package:drift/drift.dart';

/// A Drift [TypeConverter] that guarantees [DateTime] values are stored and retrieved as UTC.
class UtcDateTimeConverter extends TypeConverter<DateTime, DateTime> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(DateTime fromSql) => fromSql.toUtc();

  @override
  DateTime toSql(DateTime value) => value.toUtc();
}
