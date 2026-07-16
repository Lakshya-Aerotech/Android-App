import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import 'add_employee_screen.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
          IconButton(
            onPressed: () => context.push('/admin/add-employee'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 16),
                  const Text('No employees found'),
                  TextButton(
                    onPressed: () => context.push('/admin/add-employee'),
                    child: const Text('Add your first employee'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: employees.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final employee = employees[index];
              return _buildEmployeeCard(context, ref, employee);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    WidgetRef ref,
    UserModel employee,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            employee.name?[0].toUpperCase() ?? 'E',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          employee.name ?? 'No Name',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.email ?? '', style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(employee.role.name.toUpperCase(), Colors.blue),
                const SizedBox(width: 8),
                _buildBadge(
                  employee.isActive ? 'ACTIVE' : 'INACTIVE',
                  employee.isActive ? AppColors.success : Colors.red,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEmployeeScreen(employee: employee),
                ),
              );
            } else if (value == 'status') {
              if (employee.isActive) {
                _showDeactivateDialog(context, ref, employee);
              } else {
                _updateStatus(context, ref, employee, true);
              }
            } else if (value == 'delete') {
              _showDeleteDialog(context, ref, employee.docId ?? '');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'status',
              child: Row(
                children: [
                  Icon(
                    employee.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(employee.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: const Text(
          'Are you sure you want to remove this employee record? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminViewModelProvider.notifier).deleteEmployee(docId);
              context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel employee,
  ) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Deactivate Employee',
        content: 'Are you sure you want to deactivate this employee?',
        confirmLabel: 'Deactivate',
        cancelLabel: 'Cancel',
        onConfirm: () => _updateStatus(context, ref, employee, false),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    UserModel employee,
    bool isActive,
  ) async {
    final docId = employee.docId;
    if (docId == null || docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Employee record was not found. It may have been deleted.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final error = await ref
        .read(adminViewModelProvider.notifier)
        .updateStatus(docId, isActive);

    if (!context.mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Employee activated successfully'
                : 'Employee deactivated successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }
}
