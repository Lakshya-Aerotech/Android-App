import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import 'notification_model.dart';
import 'notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).getNotificationsStream(user.uid!, user.role);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.read).length,
    orElse: () => 0,
  );
});

class NotificationViewModel extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationViewModel(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(userModelProvider);
    if (user == null || user.uid == null) return;
    try {
      await _repository.markAllAsRead(user.uid!, user.role);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final notificationViewModelProvider =
    StateNotifierProvider<NotificationViewModel, AsyncValue<void>>((ref) {
      return NotificationViewModel(ref.watch(notificationRepositoryProvider), ref);
    });
