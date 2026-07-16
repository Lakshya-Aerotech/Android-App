import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_indicator.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../farm/models/farm_model.dart';
import '../../../farm/viewmodels/farm_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../widgets/farm_selection_card.dart';
import '../../widgets/booking_summary_card.dart';

class BookServiceScreen extends ConsumerStatefulWidget {
  const BookServiceScreen({super.key});

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  FarmModel? _selectedFarm;
  final String _selectedService = "Pesticide Spraying";
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final List<String> _stepTitles = ['Farm', 'Service', 'Schedule', 'Review'];

  @override
  void dispose() {
    _pageController.dispose();
    _areaController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 3) {
      if (_currentStep == 0 && _selectedFarm == null) {
        _showError('Please select a farm');
        return;
      }
      if (_currentStep == 2 && _areaController.text.isEmpty) {
        _showError('Please enter the area');
        return;
      }

      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submit() async {
    final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    await ref.read(bookingViewModelProvider.notifier).createBooking(
      farmId: _selectedFarm!.docId!,
      farmName: _selectedFarm!.farmName,
      cropType: _selectedFarm!.cropType,
      serviceType: _selectedService,
      bookingDate: _selectedDate,
      preferredTime: formattedTime,
      estimatedArea: double.parse(_areaController.text),
      village: _selectedFarm!.village,
      district: _selectedFarm!.district,
      stateName: _selectedFarm!.state,
      farmArea: _selectedFarm!.area,
      latitude: _selectedFarm!.latitude,
      longitude: _selectedFarm!.longitude,
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
        _showError('Error: ${next.error}');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => _currentStep == 0 ? context.pop() : _previousPage(),
        ),
        title: Text(
          'Book New Service',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StepIndicator(currentStep: _currentStep, steps: _stepTitles),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFarmStep(farmsAsync),
                _buildServiceStep(),
                _buildScheduleStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomActionBar(bookingState is AsyncLoading),
        ],
      ),
    );
  }

  Widget _buildFarmStep(AsyncValue<List<FarmModel>> farmsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Select Farm'),
          const SizedBox(height: 16),
          farmsAsync.when(
            data: (farms) {
              if (farms.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.landscape_outlined, size: 64, color: AppColors.border),
                      const SizedBox(height: 16),
                      const Text('No farms registered yet.'),
                      TextButton(
                        onPressed: () => context.push('/add-farm'),
                        child: const Text('Add a Farm First'),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: farms.map((farm) => FarmSelectionCard(
                  farm: farm,
                  isSelected: _selectedFarm?.docId == farm.docId,
                  onTap: () {
                    setState(() {
                      _selectedFarm = farm;
                      _areaController.text = farm.area.toString();
                    });
                  },
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Service Information'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  _selectedService,
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Precision agricultural drone spraying for pesticides. Ensuring uniform coverage and efficient pest control for your crops.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const Divider(height: 40),
                _buildInfoRow(Icons.timer_outlined, 'Estimated Duration', '15-20 min / acre'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.check_circle_outline, 'Benefit', 'Saves water and chemical usage'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label, 
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value, 
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Schedule Service'),
          const SizedBox(height: 16),
          
          _buildClickableCard(
            label: 'Preferred Date',
            value: DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
            icon: Icons.calendar_today_outlined,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          
          _buildClickableCard(
            label: 'Preferred Time',
            value: _selectedTime.format(context),
            icon: Icons.access_time_outlined,
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _selectedTime);
              if (picked != null) setState(() => _selectedTime = picked);
            },
          ),

          const SizedBox(height: 24),
          const Text('Estimated Area', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.0',
                    ),
                  ),
                ),
                Text('Acres', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Additional Notes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Any special instructions...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final user = ref.watch(userModelProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Review Booking'),
          const SizedBox(height: 16),
          BookingSummaryCard(
            label: 'Farmer',
            value: user?.name ?? 'Not Set',
            icon: Icons.person_outline,
          ),
          BookingSummaryCard(
            label: 'Farm',
            value: _selectedFarm?.farmName ?? '',
            icon: Icons.landscape_outlined,
          ),
          BookingSummaryCard(
            label: 'Service',
            value: _selectedService,
            icon: Icons.water_drop_outlined,
          ),
          BookingSummaryCard(
            label: 'Date',
            value: DateFormat('dd MMM yyyy').format(_selectedDate),
            icon: Icons.calendar_today_outlined,
          ),
          BookingSummaryCard(
            label: 'Time',
            value: _selectedTime.format(context),
            icon: Icons.access_time_outlined,
          ),
          BookingSummaryCard(
            label: 'Estimated Area',
            value: '${_areaController.text} Acres',
            icon: Icons.crop_free,
          ),
          if (_remarksController.text.isNotEmpty)
            BookingSummaryCard(
              label: 'Notes',
              value: _remarksController.text,
              icon: Icons.notes,
            ),
        ],
      ),
    );
  }

  Widget _buildClickableCard({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                  Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _previousPage,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: PrimaryButton(
              text: _currentStep == 3 ? 'Confirm & Book' : 'Next →',
              onPressed: isLoading ? null : (_currentStep == 3 ? _submit : _nextPage),
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
