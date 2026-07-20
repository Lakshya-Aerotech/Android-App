import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';

class RetailerManagementScreen extends ConsumerStatefulWidget {
  const RetailerManagementScreen({super.key});

  @override
  ConsumerState<RetailerManagementScreen> createState() =>
      _RetailerManagementScreenState();
}

class _RetailerManagementScreenState
    extends ConsumerState<RetailerManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final retailersAsync = ref.watch(retailersStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Retailer Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search retailers...',
                prefixIcon: Icon(Icons.search),
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: retailersAsync.when(
              data: (retailers) {
                final filtered = retailers.where((retailer) {
                  return (retailer.shopName ?? '').toLowerCase().contains(
                        _query,
                      ) ||
                      (retailer.ownerName ?? '').toLowerCase().contains(
                        _query,
                      ) ||
                      (retailer.phoneNumber ?? '').contains(_query) ||
                      (retailer.village ?? '').toLowerCase().contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No retailers found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _RetailerCard(retailer: filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetailerCard extends ConsumerWidget {
  final UserModel retailer;

  const _RetailerCard({required this.retailer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = retailer.approvalStatus ?? ApprovalStatus.pending;
    final statusColor = switch (status) {
      ApprovalStatus.approved => AppColors.success,
      ApprovalStatus.pending => Colors.orange,
      ApprovalStatus.rejected => AppColors.error,
      ApprovalStatus.suspended => Colors.red,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        title: Text(
          retailer.shopName ?? 'Retailer',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(retailer.ownerName ?? retailer.name ?? ''),
            Text('${retailer.phoneNumber ?? ''}  ${retailer.village ?? ''}'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                _Badge(status.name.toUpperCase(), statusColor),
                _Badge(
                  retailer.isActive ? 'ACTIVE' : 'INACTIVE',
                  retailer.isActive ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'details') {
              _showDetails(context, retailer);
            } else if (value == 'approve') {
              _update(ref, ApprovalStatus.approved, true);
            } else if (value == 'reject') {
              _update(ref, ApprovalStatus.rejected, false);
            } else if (value == 'suspend') {
              _update(ref, ApprovalStatus.suspended, false);
            } else if (value == 'reactivate') {
              _update(ref, ApprovalStatus.approved, true);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'details', child: Text('View Details')),
            PopupMenuItem(value: 'approve', child: Text('Approve')),
            PopupMenuItem(value: 'reject', child: Text('Reject')),
            PopupMenuItem(value: 'suspend', child: Text('Suspend')),
            PopupMenuItem(value: 'reactivate', child: Text('Reactivate')),
          ],
        ),
      ),
    );
  }

  Future<void> _update(
    WidgetRef ref,
    ApprovalStatus approvalStatus,
    bool isActive,
  ) async {
    final docId = retailer.docId;
    if (docId == null) return;
    await ref
        .read(adminViewModelProvider.notifier)
        .updateRetailerStatus(
          docId: docId,
          approvalStatus: approvalStatus,
          isActive: isActive,
        );
  }

  void _showDetails(BuildContext context, UserModel retailer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              retailer.shopName ?? 'Retailer',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _detail('Owner', retailer.ownerName ?? retailer.name ?? '-'),
            _detail('Mobile', retailer.phoneNumber ?? '-'),
            _detail('Email', retailer.email ?? '-'),
            _detail('GST', retailer.gstNumber ?? '-'),
            _detail('Aadhaar/PAN', retailer.aadhaarPan ?? '-'),
            _detail('Address', retailer.shopAddress ?? '-'),
            _detail(
              'Location',
              '${retailer.village ?? '-'}, ${retailer.mandal ?? '-'}, ${retailer.district ?? '-'}, ${retailer.state ?? '-'}',
            ),
            _detail(
              'GPS',
              retailer.latitude == null || retailer.longitude == null
                  ? '-'
                  : '${retailer.latitude}, ${retailer.longitude}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text('$label: $value'),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
