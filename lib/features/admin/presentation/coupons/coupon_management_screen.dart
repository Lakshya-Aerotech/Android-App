import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/models/user_model.dart';
import '../../models/coupon_model.dart';
import '../../viewmodels/admin_viewmodel.dart';

class CouponManagementScreen extends ConsumerWidget {
  const CouponManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(context.tr('Coupon Management')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: context.tr('Usage History'),
            onPressed: () => context.push('/admin/coupons/history'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('Create Coupon')),
      ),
      body: couponsAsync.when(
        data: (coupons) {
          if (coupons.isEmpty) {
            return Center(child: Text(context.tr('No coupons found')));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _CouponCard(
              coupon: coupons[index],
              onEdit: () => _openForm(context, coupon: coupons[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _openForm(BuildContext context, {CouponModel? coupon}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CouponFormScreen(existingCoupon: coupon),
      ),
    );
  }
}

class _CouponCard extends ConsumerWidget {
  final CouponModel coupon;
  final VoidCallback onEdit;

  const _CouponCard({required this.coupon, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final discount = coupon.discountType == CouponDiscountType.percentage
        ? '${coupon.discountValue.toStringAsFixed(0)}%'
        : 'Rs. ${coupon.discountValue.toStringAsFixed(0)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.couponCode,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusBadge(isActive: coupon.isActive),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'toggle') {
                      await _toggleStatus(ref, context);
                    } else if (value == 'delete') {
                      await _confirmDelete(ref, context);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(context.tr('Edit')),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        context.tr(coupon.isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        context.tr('Delete'),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip('${context.tr('Discount')}: $discount'),
                _InfoChip(
                  '${context.tr('Usage')}: ${coupon.remainingUsage}/${coupon.maximumUsage}',
                ),
                _InfoChip(
                  '${dateFormat.format(coupon.validFrom)} - ${dateFormat.format(coupon.validUntil)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailLine(
              label: context.tr('Eligible Service'),
              value: coupon.eligibleService,
            ),
            _DetailLine(
              label: context.tr('Applicable Region'),
              value: coupon.applicableRegion,
            ),
            _DetailLine(
              label: context.tr('Assigned Retailers'),
              value: coupon.assignedRetailerNames.isEmpty
                  ? '-'
                  : coupon.assignedRetailerNames.join(', '),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(WidgetRef ref, BuildContext context) async {
    final docId = coupon.docId;
    if (docId == null) return;

    final error = await ref
        .read(adminViewModelProvider.notifier)
        .updateCouponStatus(docId, !coupon.isActive);
    if (context.mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _confirmDelete(WidgetRef ref, BuildContext context) async {
    final docId = coupon.docId;
    if (docId == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Delete Coupon')),
        content: Text(
          context.tr('Are you sure you want to delete this coupon?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr('Delete'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    final error = await ref
        .read(adminViewModelProvider.notifier)
        .deleteCoupon(docId);
    if (context.mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }
}

class _CouponFormScreen extends ConsumerStatefulWidget {
  final CouponModel? existingCoupon;

  const _CouponFormScreen({this.existingCoupon});

  @override
  ConsumerState<_CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends ConsumerState<_CouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maximumUsageController = TextEditingController();
  final _remainingUsageController = TextEditingController();
  final _eligibleServiceController = TextEditingController();
  final _applicableRegionController = TextEditingController();
  final Set<String> _selectedRetailerIds = {};
  final Map<String, String> _selectedRetailerNames = {};

  String _selectedService = 'Pesticide Spraying';
  static const List<String> _serviceTypes = [
    'Pesticide Spraying',
    'Crop Monitoring',
    'Seed Sowing',
    'Other',
  ];

  CouponDiscountType _discountType = CouponDiscountType.percentage;
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _isActive = true;

  bool get _isEditMode => widget.existingCoupon != null;

  @override
  void initState() {
    super.initState();
    final coupon = widget.existingCoupon;
    if (coupon == null) {
      _eligibleServiceController.text = _selectedService;
      return;
    }

    _codeController.text = coupon.couponCode;
    _discountType = coupon.discountType;
    _discountValueController.text = _formatNumber(coupon.discountValue);
    _maximumUsageController.text = coupon.maximumUsage.toString();
    _remainingUsageController.text = coupon.remainingUsage.toString();
    
    if (_serviceTypes.contains(coupon.eligibleService)) {
      _selectedService = coupon.eligibleService;
    } else {
      _selectedService = 'Other';
    }
    _eligibleServiceController.text = coupon.eligibleService;
    
    _applicableRegionController.text = coupon.applicableRegion;
    _selectedRetailerIds.addAll(coupon.assignedRetailerIds);
    for (var i = 0; i < coupon.assignedRetailerIds.length; i++) {
      final id = coupon.assignedRetailerIds[i];
      final name = i < coupon.assignedRetailerNames.length
          ? coupon.assignedRetailerNames[i]
          : id;
      _selectedRetailerNames[id] = name;
    }
    _validFrom = coupon.validFrom;
    _validUntil = coupon.validUntil;
    _isActive = coupon.isActive;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _maximumUsageController.dispose();
    _remainingUsageController.dispose();
    _eligibleServiceController.dispose();
    _applicableRegionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_validFrom == null || _validUntil == null) {
      _showError('Please select valid dates.');
      return;
    }
    if (_validUntil!.isBefore(_validFrom!)) {
      _showError('Valid until must be after valid from.');
      return;
    }

    final service = _selectedService == 'Other' 
        ? _eligibleServiceController.text.trim() 
        : _selectedService;

    final coupon = CouponModel(
      docId: widget.existingCoupon?.docId,
      couponCode: _codeController.text.trim().toUpperCase(),
      discountType: _discountType,
      discountValue: double.parse(_discountValueController.text.trim()),
      validFrom: _validFrom!,
      validUntil: _validUntil!,
      maximumUsage: int.parse(_maximumUsageController.text.trim()),
      remainingUsage: int.parse(_remainingUsageController.text.trim()),
      eligibleService: service,
      applicableRegion: _applicableRegionController.text.trim(),
      assignedRetailerIds: _selectedRetailerIds.toList(),
      assignedRetailerNames: _selectedRetailerIds
          .map((id) => _selectedRetailerNames[id] ?? id)
          .toList(),
      isActive: _isActive,
    );

    final error = _isEditMode
        ? await ref.read(adminViewModelProvider.notifier).updateCoupon(coupon)
        : await ref.read(adminViewModelProvider.notifier).createCoupon(coupon);

    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              _isEditMode
                  ? 'Coupon updated successfully'
                  : 'Coupon created successfully',
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final retailersAsync = ref.watch(retailersStreamProvider);
    final isLoading = ref.watch(adminViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_isEditMode ? 'Edit Coupon' : 'Create Coupon')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Coupon Code',
                hintText: 'e.g. SPRAY10',
                controller: _codeController,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Discount Type'),
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              _buildDropdown<CouponDiscountType>(
                value: _discountType,
                items: CouponDiscountType.values,
                onChanged: (value) => setState(() => _discountType = value!),
                labelBuilder: (value) => value == CouponDiscountType.percentage
                    ? 'Percentage'
                    : 'Fixed',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Discount Value',
                hintText: '0',
                controller: _discountValueController,
                keyboardType: TextInputType.number,
                validator: _discountValueValidator,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'Valid From',
                      value: _validFrom,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTile(
                      label: 'Valid Until',
                      value: _validUntil,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Maximum Usage',
                      hintText: '0',
                      controller: _maximumUsageController,
                      keyboardType: TextInputType.number,
                      validator: _positiveIntValidator,
                      onChanged: (val) {
                        if (!_isEditMode) {
                          _remainingUsageController.text = val;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Remaining Usage',
                      hintText: '0',
                      controller: _remainingUsageController,
                      keyboardType: TextInputType.number,
                      validator: _remainingUsageValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Eligible Service'),
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _selectedService,
                items: _serviceTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedService = value!;
                    if (value != 'Other') {
                      _eligibleServiceController.text = value;
                    }
                  });
                },
                labelBuilder: (value) => value,
              ),
              if (_selectedService == 'Other') ...[
                const SizedBox(height: 8),
                CustomTextField(
                  label: 'Custom Service Name',
                  hintText: 'Enter service name',
                  controller: _eligibleServiceController,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Applicable Region',
                hintText: 'e.g. Telangana (leave empty for All)',
                controller: _applicableRegionController,
                // Removed validator to allow empty for global
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Assigned Retailers'),
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              retailersAsync.when(
                data: _buildRetailerSelector,
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('Active Status')),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.success,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: _isEditMode ? 'Update Coupon' : 'Create Coupon',
                onPressed: _submit,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetailerSelector(List<UserModel> retailers) {
    if (retailers.isEmpty) {
      return Text(context.tr('No retailers found'));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: retailers.map((retailer) {
          final id = retailer.uid ?? retailer.docId;
          if (id == null) return const SizedBox.shrink();
          final name =
              retailer.shopName ?? retailer.ownerName ?? retailer.name ?? id;

          return CheckboxListTile(
            value: _selectedRetailerIds.contains(id),
            title: Text(name),
            subtitle: Text(retailer.phoneNumber ?? ''),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedRetailerIds.add(id);
                  _selectedRetailerNames[id] = name;
                } else {
                  _selectedRetailerIds.remove(id);
                  _selectedRetailerNames.remove(id);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(context.tr(labelBuilder(item))),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_validFrom ?? now)
        : (_validUntil ?? _validFrom ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _validFrom = picked;
          if (_validUntil != null && _validUntil!.isBefore(picked)) {
            _validUntil = picked;
          }
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  String? _discountValueValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Must be greater than 0';
    }
    if (_discountType == CouponDiscountType.percentage && parsed > 100) {
      return 'Percentage discount cannot exceed 100%';
    }
    return null;
  }

  String? _positiveIntValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0 ? 'Must be greater than 0' : null;
  }

  String? _remainingUsageValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Required';
    final maximum = int.tryParse(_maximumUsageController.text.trim());
    if (maximum != null && parsed > maximum) {
      return 'Remaining usage cannot exceed maximum usage';
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(message)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _formatNumber(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: context.tr(label)),
        child: Text(
          value == null ? context.tr('Select Date') : dateFormat.format(value!),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        context.tr(isActive ? 'Active' : 'Inactive'),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTextStyles.bodySmall),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('$label: $value', style: AppTextStyles.bodySmall),
    );
  }
}
