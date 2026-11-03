import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_categories.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../models/draft_transaction.dart';
import 'notification_watcher_provider.dart';

/// Streams unconfirmed draft transactions derived from unparsed notification logs.
final pendingDraftTransactionsProvider =
    StreamProvider.autoDispose<List<DraftTransaction>>((ref) {
  final parser = ref.watch(notificationParserProvider);
  final logService = ref.watch(notificationLogServiceProvider);

  return logService.watchUnparsedLogs().map((logs) {
    return logs.map((log) {
      final parsed = parser.parse(
        body: log.body ?? '',
        title: log.title,
        appPackage: log.appPackage,
        timestamp: log.receivedAt,
      );
      return DraftTransaction(
        log: log,
        parsed: parsed,
      );
    }).toList();
  });
});

/// Controller for confirming, editing, or dismissing pending draft transactions.
class DraftTransactionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Confirms a [draft] transaction, saves it into SQLite via [TransactionController],
  /// and marks the corresponding notification log as parsed.
  Future<bool> confirmDraft({
    required DraftTransaction draft,
    required String categoryId,
    String? note,
    int? amount,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      final txAmount = amount ?? draft.amount;
      if (txAmount <= 0) {
        state = AsyncValue.error(
          Exception('Transaction amount must be greater than zero'),
          StackTrace.current,
        );
        return false;
      }

      final txDate = date ?? draft.receivedAt;
      final txNote = note ?? draft.merchant;

      final controller = ref.read(transactionControllerProvider.notifier);
      final created = await controller.createTransaction(
        amount: txAmount,
        type: draft.type,
        categoryId: categoryId,
        source: draft.source,
        date: txDate,
        note: txNote.isNotEmpty ? txNote : null,
      );

      if (created != null) {
        final logService = ref.read(notificationLogServiceProvider);
        await logService.markAsParsed(
          logId: draft.id,
          transactionId: created.id,
        );
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error(
          Exception('Failed to create transaction record'),
          StackTrace.current,
        );
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Dismisses / deletes an unconfirmed notification log so it no longer appears in review.
  Future<bool> dismissDraft(String logId) async {
    try {
      final logService = ref.read(notificationLogServiceProvider);
      await logService.deleteLog(logId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Automatically confirms all recognized draft transactions with their suggested category.
  Future<int> confirmAll(List<DraftTransaction> drafts) async {
    var confirmedCount = 0;
    for (final draft in drafts) {
      if (draft.isRecognized && draft.amount > 0) {
        final categoryId =
            draft.suggestedCategoryId ?? DefaultCategories.otherId;
        final success = await confirmDraft(
          draft: draft,
          categoryId: categoryId,
        );
        if (success) confirmedCount++;
      }
    }
    return confirmedCount;
  }
}

/// Provider for [DraftTransactionController].
final draftTransactionControllerProvider =
    AutoDisposeAsyncNotifierProvider<DraftTransactionController, void>(
  DraftTransactionController.new,
);
