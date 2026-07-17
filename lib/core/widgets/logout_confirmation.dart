import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../localization/app_localizations.dart';
import 'confirmation_dialog.dart';

Future<void> showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return ConfirmationDialog(
        title: dialogContext.tr('Logout'),
        content: dialogContext.tr('Are you sure you want to log out?'),
        cancelLabel: dialogContext.tr('Cancel'),
        confirmLabel: dialogContext.tr('Logout'),
        onConfirm: () => ref.read(authViewModelProvider.notifier).logout(),
      );
    },
  );
}
