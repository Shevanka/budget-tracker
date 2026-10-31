import '../../../database/app_database.dart';
import '../../../database/converters/transaction_type.dart';
import '../constants/watched_apps.dart';
import 'parsed_notification.dart';

/// Represents an unconfirmed draft transaction created from an intercepted system notification.
class DraftTransaction {
  /// The persisted database record representing the raw notification.
  final NotificationLog log;

  /// The parsed transaction extracted by [NotificationParser], or `null` if unparsed.
  final ParsedNotification? parsed;

  const DraftTransaction({
    required this.log,
    this.parsed,
  });

  /// Unique identifier of the underlying notification log.
  String get id => log.id;

  /// The source Android package name.
  String get appPackage => log.appPackage;

  /// The raw notification title.
  String? get rawTitle => log.title;

  /// The raw notification body text.
  String? get rawBody => log.body;

  /// UTC receipt timestamp.
  DateTime get receivedAt => log.receivedAt;

  /// Whether this draft was successfully recognized as a financial transaction.
  bool get isRecognized => parsed != null;

  /// Detected amount in IDR (or 0 if unrecognized).
  int get amount => parsed?.amount ?? 0;

  /// Formatted IDR string of the detected amount.
  String get formattedAmount => parsed != null ? parsed!.formattedAmount : 'Rp 0';

  /// Detected merchant or note.
  String get merchant =>
      parsed?.merchant ?? (log.title?.isNotEmpty == true ? log.title! : 'Unknown');

  /// Name of the financial institution.
  String get source =>
      parsed?.source ?? WatchedApps.findByPackage(log.appPackage)?.name ?? log.appPackage;

  /// Suggested category identifier from keyword matching.
  String? get suggestedCategoryId => parsed?.suggestedCategoryId;

  /// Suggested category name from keyword matching.
  String? get suggestedCategoryName => parsed?.suggestedCategoryName;

  /// Transaction type (defaults to expense).
  TransactionType get type => parsed?.type ?? TransactionType.expense;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftTransaction &&
          runtimeType == other.runtimeType &&
          log.id == other.log.id &&
          parsed == other.parsed;

  @override
  int get hashCode => Object.hash(log.id, parsed);

  @override
  String toString() =>
      'DraftTransaction(id: $id, source: $source, amount: $formattedAmount, merchant: "$merchant")';
}
