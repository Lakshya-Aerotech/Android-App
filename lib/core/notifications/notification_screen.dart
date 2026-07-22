import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'notification_viewmodel.dart';
import 'notification_model.dart';
import 'notification_service.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(notificationViewModelProvider.notifier).markAllAsRead(),
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.border),
                  SizedBox(height: 16),
                  Text('No notifications yet'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(notification: notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final role = user?.role.name;

    return InkWell(
      onTap: () {
        if (!notification.read) {
          ref.read(notificationViewModelProvider.notifier).markAsRead(notification.id!);
        }
        NotificationService.handleNotificationClick(notification, role);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.read
                ? AppColors.border.withValues(alpha: 0.5)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.read
                    ? AppColors.border.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.type),
                size: 20,
                color: notification.read ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: notification.read ? FontWeight.w600 : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(notification.createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'BOOKING_SUBMITTED':
      case 'BOOKING_CREATED':
        return Icons.add_task;
      case 'BOOKING_APPROVED':
        return Icons.fact_check_outlined;
      case 'BOOKING_REJECTED':
        return Icons.cancel_outlined;
      case 'PILOT_ASSIGNED':
        return Icons.person_add;
      case 'PILOT_EN_ROUTE':
        return Icons.directions_run;
      case 'PILOT_ARRIVED':
        return Icons.location_on;
      case 'MISSION_STARTED':
        return Icons.play_circle_outline;
      case 'MISSION_COMPLETED':
        return Icons.check_circle_outline;
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_RECORDED':
      case 'PAYMENT_CONFIRMED':
        return Icons.payments_outlined;
      case 'PAYMENT_REJECTED':
        return Icons.error_outline;
      case 'CASH_COLLECTION_REQUIRED':
      case 'CASH_DEPOSIT_REMINDER':
        return Icons.notification_important_outlined;
      case 'CASH_COLLECTED':
        return Icons.money;
      case 'CASH_DEPOSITED':
        return Icons.account_balance;
      case 'COUPON_VERIFIED':
        return Icons.local_offer_outlined;
      case 'COUPON_VERIFICATION_REQUIRED':
        return Icons.fact_check_outlined;
      case 'REGISTRATION_SUBMITTED':
      case 'NEW_FARMER_REGISTERED':
      case 'NEW_RETAILER_REGISTERED':
      case 'NEW_PILOT_REGISTERED':
      case 'NEW_EXTERNAL_PILOT_REGISTERED':
        return Icons.person_add_alt_1_outlined;
      case 'REGISTRATION_APPROVED':
      case 'RETAILER_APPROVED':
        return Icons.verified_user_outlined;
      case 'REGISTRATION_REJECTED':
      case 'RETAILER_REJECTED':
        return Icons.report_gmailerrorred_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
