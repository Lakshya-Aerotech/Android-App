import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../shared/components/dashboard_header.dart';
import '../../../farm/models/farm_model.dart';
import '../../../farm/viewmodels/farm_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';

class BookServiceScreen extends ConsumerStatefulWidget {
  const BookServiceScreen({super.key});

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  FarmModel? _selectedFarm;
  String _selectedService = 'Pesticide Spraying';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final List<String> _services = [
    'Pesticide Spraying',
    'Fertilizer Spraying',
    'Micronutrient Spraying',
    'Survey Mapping',
    'Seed Broadcasting',
  ];

  @override
  void dispose() {
    _areaController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _onFarmSelected(FarmModel? farm) {
    setState(() {
      _selectedFarm = farm;
      if (farm != null) {
        _areaController.text = farm.area.toString();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFarm == null) {
      if (_selectedFarm == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a farm')),
        );
      }
      return;
    }

    final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    await ref.read(bookingViewModelProvider.notifier).createBooking(
      farmId: _selectedFarm!.docId!,
      farmName: _selectedFarm!.farmName,
      cropType: _selectedFarm!.cropType,
      serviceType: _selectedService,
      bookingDate: _selectedDate,
      preferredTime: formattedTime,
      estimatedArea: double.parse(_areaController.text),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(farmsStreamProvider);
    final bookingState = ref.watch(bookingViewModelProvider);

    ref.listen(bookingViewModelProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        context.go('/booking-success', extra: next.value);
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}'), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            DashboardHeader(userName: 'Farmer', subtitle: 'Book a new drone service.'),
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Details',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalLg,

                    // Farm Selection
                    Text('Select Farm *', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    farmsAsync.when(
                      data: (farms) => _buildDropdown<FarmModel>(
                        value: _selectedFarm,
                        items: farms,
                        hint: 'Choose a farm',
                        onChanged: _onFarmSelected,
                        labelBuilder: (farm) => '${farm.farmName} (${farm.village})',
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading farms: $e'),
                    ),
                    if (_selectedFarm != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Crop: ${_selectedFarm!.cropType} | Area: ${_selectedFarm!.area} ${_selectedFarm!.unit}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                    ],
                    AppSpacing.verticalMd,

                    // Service Type
                    Text('Service Type *', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: _selectedService,
                      items: _services,
                      onChanged: (v) => setState(() => _selectedService = v!),
                      labelBuilder: (v) => v,
                    ),
                    AppSpacing.verticalMd,

                    // Date and Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Preferred Date *', style: AppTextStyles.labelLarge),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                                      const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Preferred Time *', style: AppTextStyles.labelLarge),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectTime,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_selectedTime.format(context)),
                                      const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalMd,

                    // Estimated Area
                    CustomTextField(
                      label: 'Estimated Area (to be sprayed) *',
                      hintText: '0.0',
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Area is required' : null,
                    ),
                    AppSpacing.verticalMd,

                    // Additional Notes
                    CustomTextField(
                      label: 'Additional Notes (Optional)',
                      hintText: 'Any special instructions...',
                      controller: _remarksController,
                    ),
                    
                    const SizedBox(height: 48),
                    PrimaryButton(
                      text: 'Submit Booking',
                      onPressed: _submit,
                      isLoading: bookingState is AsyncLoading,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    String? hint,
    required void Function(T?) onChanged,
    required String Function(T) labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null ? Text(hint) : null,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item), style: AppTextStyles.bodyLarge),
            );
          }).toList(),
        ),
      ),
    );
  }
}
