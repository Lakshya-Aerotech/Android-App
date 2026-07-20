import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/auth/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class ExternalPilotDetailsScreen extends ConsumerStatefulWidget {
  final UserModel pilot;
  const ExternalPilotDetailsScreen({super.key, required this.pilot});

  @override
  ConsumerState<ExternalPilotDetailsScreen> createState() => _ExternalPilotDetailsScreenState();
}

class _ExternalPilotDetailsScreenState extends ConsumerState<ExternalPilotDetailsScreen> {
  final _reasonController = TextEditingController();
  bool _isActionLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleApproval(bool approved) async {
    if (!approved && _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for rejection')),
      );
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      final notifier = ref.read(adminViewModelProvider.notifier);
      if (approved) {
        await notifier.approveExternalPilot(widget.pilot.docId!);
      } else {
        await notifier.rejectExternalPilot(widget.pilot.docId!, _reasonController.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pilot ${approved ? 'approved' : 'rejected'} successfully'),
            backgroundColor: approved ? AppColors.success : Colors.red,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleAccountStatus(AccountStatus status) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(adminViewModelProvider.notifier).updateExternalPilotAccountStatus(
        widget.pilot.docId!,
        status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account ${status.name} successfully'),
            backgroundColor: status == AccountStatus.active ? AppColors.success : Colors.red,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pilot;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pilot Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: p.profilePhotographUrl != null 
                      ? NetworkImage(p.profilePhotographUrl!) 
                      : null,
                    child: p.profilePhotographUrl == null 
                      ? const Icon(Icons.person, size: 50) 
                      : null,
                  ),
                  const SizedBox(height: 16),
                  Text(p.name ?? 'N/A', style: AppTextStyles.headlineSmall),
                  Text(p.email ?? 'N/A', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 8),
                  _buildStatusChip(p),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Personal Information'),
            _buildDetailRow('Mobile', p.phoneNumber ?? 'N/A'),
            _buildDetailRow('Address', p.address ?? 'N/A'),
            _buildDetailRow('Aadhaar', p.aadhaarNumber ?? 'N/A'),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Drone & Operations'),
            _buildDetailRow('Drone Details', p.droneDetails ?? 'N/A'),
            _buildDetailRow('Districts', p.operatingDistricts.join(', ')),
            _buildDetailRow('Radius', '${p.operatingRadius ?? 0} km'),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Documents'),
            _buildDocumentTile('Drone Pilot Certificate', p.dronePilotCertificateUrl),
            _buildDocumentTile('DGCA Certificate', p.dgcaCertificateUrl),
            
            const SizedBox(height: 40),
            
            if (p.approvalStatus == ApprovalStatus.pending) ...[
              const Divider(),
              const SizedBox(height: 24),
              Text('Action Required', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason (if rejecting)',
                  hintText: 'e.g. Invalid documents',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isActionLoading ? null : () => _handleApproval(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Approve',
                      isLoading: _isActionLoading,
                      onPressed: () => _handleApproval(true),
                    ),
                  ),
                ],
              ),
            ] else if (p.approvalStatus == ApprovalStatus.approved) ...[
              const Divider(),
              const SizedBox(height: 24),
              if (p.accountStatus == AccountStatus.active)
                PrimaryButton(
                  text: 'Suspend Account',
                  backgroundColor: Colors.red,
                  isLoading: _isActionLoading,
                  onPressed: () => _handleAccountStatus(AccountStatus.suspended),
                )
              else if (p.accountStatus == AccountStatus.suspended)
                PrimaryButton(
                  text: 'Reactivate Account',
                  isLoading: _isActionLoading,
                  onPressed: () => _handleAccountStatus(AccountStatus.active),
                ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String label, String? url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.bodyMedium),
      subtitle: Text(url != null ? 'Click to view' : 'Not uploaded', style: AppTextStyles.bodySmall),
      trailing: url != null ? const Icon(Icons.open_in_new, size: 20) : null,
      onTap: url != null ? () => launchUrl(Uri.parse(url)) : null,
    );
  }

  Widget _buildStatusChip(UserModel p) {
    Color color = Colors.orange;
    String label = 'PENDING';
    
    if (p.approvalStatus == ApprovalStatus.approved) {
      if (p.accountStatus == AccountStatus.suspended) {
        color = Colors.red;
        label = 'SUSPENDED';
      } else {
        color = AppColors.success;
        label = 'APPROVED';
      }
    } else if (p.approvalStatus == ApprovalStatus.rejected) {
      color = Colors.red;
      label = 'REJECTED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
