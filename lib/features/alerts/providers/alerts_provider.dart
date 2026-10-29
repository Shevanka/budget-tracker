import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';

/// Provides the active [NotificationService] instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});
