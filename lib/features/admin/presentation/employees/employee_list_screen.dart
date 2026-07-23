import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import 'add_employee_screen.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  UserRole? _filterRole;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(),
            icon: Icon(
              Icons.filter_list,
              color: _filterRole != null ? AppColors.primary : null,
            ),
          ),
          IconButton(
            onPressed: () => context.push('/admin/add-employee'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          final filteredEmployees = _filterRole == null
              ? employees
              : employees.where((e) => e.role == _filterRole).toList();

          if (filteredEmployees.isEmpty) {
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
                  Text(_filterRole == null
                      ? 'No employees found'
                      : 'No ${ _filterRole!.value}s found'),
                  if (_filterRole == null)
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
            itemCount: filteredEmployees.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final employee = filteredEmployees[index];
              return _buildEmployeeCard(context, ref, employee);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Role',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All Employees',
                    selected: _filterRole == null,
                    onSelected: (selected) {
                      setState(() => _filterRole = null);
                      Navigator.pop(context);
                    },
                  ),
                  _FilterChip(
                    label: 'Operations',
                    selected: _filterRole == UserRole.operations,
                    onSelected: (selected) {
                      setState(() => _filterRole = UserRole.operations);
                      Navigator.pop(context);
                    },
                  ),
                  _FilterChip(
                    label: 'Pilots',
                    selected: _filterRole == UserRole.pilot,
                    onSelected: (selected) {
                      setState(() => _filterRole = UserRole.pilot);
                      Navigator.pop(context);
                    },
                  ),
                  _FilterChip(
                    label: 'External Pilots',
                    selected: _filterRole == UserRole.externalPilot,
                    onSelected: (selected) {
                      setState(() => _filterRole = UserRole.externalPilot);
                      Navigator.pop(context);
                    },
                  ),
                  _FilterChip(
                    label: 'Retailers',
                    selected: _filterRole == UserRole.retailer,
                    onSelected: (selected) {
                      setState(() => _filterRole = UserRole.retailer);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
                _buildBadge(employee.role.value.toUpperCase(), Colors.blue),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
