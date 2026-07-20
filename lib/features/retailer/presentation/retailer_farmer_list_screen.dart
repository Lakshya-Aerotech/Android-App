import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/models/user_model.dart';
import '../viewmodels/retailer_viewmodel.dart';

class RetailerFarmerListScreen extends ConsumerStatefulWidget {
  final bool selectionMode;

  const RetailerFarmerListScreen({super.key, this.selectionMode = false});

  @override
  ConsumerState<RetailerFarmerListScreen> createState() =>
      _RetailerFarmerListScreenState();
}

class _RetailerFarmerListScreenState
    extends ConsumerState<RetailerFarmerListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmersAsync = ref.watch(retailerFarmersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Select Farmer' : 'My Farmers'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/retailer/register-farmer'),
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search farmer, mobile, village...',
                prefixIcon: Icon(Icons.search),
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: farmersAsync.when(
              data: (farmers) {
                final filtered = farmers.where((farmer) {
                  return (farmer.name ?? '').toLowerCase().contains(_query) ||
                      (farmer.phoneNumber ?? '').toLowerCase().contains(
                        _query,
                      ) ||
                      (farmer.village ?? '').toLowerCase().contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'No farmers found.',
                    message: 'Register a farmer to start booking services.',
                    icon: Icons.people_outline,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _FarmerCard(
                    farmer: filtered[index],
                    select: widget.selectionMode,
                  ),
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

class _FarmerCard extends StatelessWidget {
  final UserModel farmer;
  final bool select;

  const _FarmerCard({required this.farmer, required this.select});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (select) {
          context.push('/retailer/book-service', extra: farmer);
        } else {
          context.push('/retailer/farmer-details', extra: farmer);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (farmer.name?.isNotEmpty ?? false)
                    ? farmer.name![0].toUpperCase()
                    : 'F',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmer.name ?? 'Farmer',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${farmer.phoneNumber ?? ''}  ${farmer.village ?? ''}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(select ? Icons.arrow_forward : Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
