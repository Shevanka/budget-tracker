import 'package:budget_tracker/features/alerts/constants/notification_channels.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationChannels Tests', () {
    test('budgetWarning channel is configured for 80% warnings with high importance', () {
      expect(NotificationChannels.budgetWarning.id, 'budget_warnings');
      expect(NotificationChannels.budgetWarning.name, 'Budget Warnings (80%)');
      expect(NotificationChannels.budgetWarning.importance, Importance.high);
      expect(
        NotificationChannels.budgetWarning.description,
        contains('80% of budget limits'),
      );
    });

    test('budgetExceeded channel is configured for 100% exceeded with max importance', () {
      expect(NotificationChannels.budgetExceeded.id, 'budget_exceeded');
      expect(NotificationChannels.budgetExceeded.name, 'Budget Exceeded (100%)');
      expect(NotificationChannels.budgetExceeded.importance, Importance.max);
      expect(
        NotificationChannels.budgetExceeded.description,
        contains('100% of budget limits'),
      );
    });

    test('budgetReminder channel is configured for reminders with default importance', () {
      expect(NotificationChannels.budgetReminder.id, 'budget_reminders');
      expect(NotificationChannels.budgetReminder.name, 'Budget Reminders');
      expect(NotificationChannels.budgetReminder.importance, Importance.defaultImportance);
    });

    test('allChannels contains all registered channels', () {
      expect(NotificationChannels.allChannels, [
        NotificationChannels.budgetWarning,
        NotificationChannels.budgetExceeded,
        NotificationChannels.budgetReminder,
      ]);
    });

    test('notification details use proper channels and app launcher icon', () {
      expect(
        NotificationChannels.warningDetails.channelId,
        NotificationChannels.budgetWarning.id,
      );
      expect(NotificationChannels.warningDetails.importance, Importance.high);
      expect(NotificationChannels.warningDetails.priority, Priority.high);
      expect(NotificationChannels.warningDetails.icon, '@mipmap/ic_launcher');

      expect(
        NotificationChannels.exceededDetails.channelId,
        NotificationChannels.budgetExceeded.id,
      );
      expect(NotificationChannels.exceededDetails.importance, Importance.max);
      expect(NotificationChannels.exceededDetails.priority, Priority.max);
      expect(NotificationChannels.exceededDetails.icon, '@mipmap/ic_launcher');

      expect(
        NotificationChannels.reminderDetails.channelId,
        NotificationChannels.budgetReminder.id,
      );
      expect(NotificationChannels.reminderDetails.importance, Importance.defaultImportance);
      expect(NotificationChannels.reminderDetails.priority, Priority.defaultPriority);
      expect(NotificationChannels.reminderDetails.icon, '@mipmap/ic_launcher');
    });
  });
}
