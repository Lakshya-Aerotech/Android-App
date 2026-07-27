import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../../core/notifications/notification_api_service.dart';

class OpsNotificationState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  OpsNotificationState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  OpsNotificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return OpsNotificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class OpsNotificationViewModel extends StateNotifier<OpsNotificationState> {
  final NotificationApiService _apiService;

  OpsNotificationViewModel(this._apiService) : super(OpsNotificationState());

  Future<void> sendNotification({
    required String title,
    required String message,
    required List<String> recipientRoles,
    required List<String> recipientUserIds,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.sendCustomNotification(
        title: title,
        message: message,
        recipientRoles: recipientRoles,
        recipientUserIds: recipientUserIds,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = OpsNotificationState();
  }
}

final opsNotificationViewModelProvider =
    StateNotifierProvider<OpsNotificationViewModel, OpsNotificationState>((ref) {
  final apiService = ref.watch(notificationApiServiceProvider);
  return OpsNotificationViewModel(apiService);
});

final opsNotificationHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(notificationApiServiceProvider);
  return apiService.getNotificationHistory();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), docId: doc.id))
        .toList()
      ..sort((a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
  });
});
