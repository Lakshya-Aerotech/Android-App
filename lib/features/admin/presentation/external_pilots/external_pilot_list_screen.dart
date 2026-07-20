import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ExternalPilotListScreen extends ConsumerStatefulWidget {
  const ExternalPilotListScreen({super.key});

  @override
  ConsumerState<ExternalPilotListScreen> createState() => _ExternalPilotListScreenState();
}

class _ExternalPilotListScreenState extends ConsumerState<ExternalPilotListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pilotsAsync = ref.watch(externalPilotsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('External Pilot Approvals'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Other'),
          ],
        ),
      ),
      body: pilotsAsync.when(
        data: (pilots) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildPilotList(pilots.where((p) => p.approvalStatus == ApprovalStatus.pending).toList()),
              _buildPilotList(pilots.where((p) => p.approvalStatus == ApprovalStatus.approved && p.accountStatus == AccountStatus.active).toList()),
              _buildPilotList(pilots.where((p) => p.approvalStatus == ApprovalStatus.rejected || p.accountStatus == AccountStatus.suspended).toList()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPilotList(List<UserModel> pilots) {
    if (pilots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text('No pilots found', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: pilots.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pilot = pilots[index];
        return _buildPilotCard(context, pilot);
      },
    );
  }

  Widget _buildPilotCard(BuildContext context, UserModel pilot) {
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
          backgroundImage: pilot.profilePhotographUrl != null 
            ? NetworkImage(pilot.profilePhotographUrl!) 
            : null,
          child: pilot.profilePhotographUrl == null 
            ? Text(pilot.name?[0].toUpperCase() ?? 'P', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
            : null,
        ),
        title: Text(
          pilot.name ?? 'No Name',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pilot.email ?? '', style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(pilot.approvalStatus?.name.toUpperCase() ?? 'PENDING', 
                  pilot.approvalStatus == ApprovalStatus.approved ? AppColors.success : 
                  pilot.approvalStatus == ApprovalStatus.rejected ? Colors.red : Colors.orange),
                const SizedBox(width: 8),
                if (pilot.accountStatus == AccountStatus.suspended)
                  _buildBadge('SUSPENDED', Colors.red),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/admin/external-pilot-details', extra: pilot);
        },
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
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
