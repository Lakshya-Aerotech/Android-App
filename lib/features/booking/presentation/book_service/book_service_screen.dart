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
import '../../../auth/models/user_model.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../widgets/farm_selection_card.dart';
import '../../widgets/booking_summary_card.dart';
import '../../../admin/models/coupon_model.dart';
import '../../../admin/viewmodels/admin_viewmodel.dart';
import '../../../payment/data/services/payment_api.dart';
import '../../../payment/presentation/screens/payment_webview_screen.dart';

class BookServiceScreen extends ConsumerStatefulWidget {
  final UserModel? farmerOverride;
  final FarmModel? initialFarm;
  const BookServiceScreen({super.key, this.farmerOverride, this.initialFarm});

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

  CouponModel? _appliedCoupon;
  String? _couponError;
  final TextEditingController _couponController = TextEditingController();

  String _paymentTiming = 'PAY_NOW'; // 'PAY_NOW' | 'PAY_AFTER_SERVICE'
  String _paymentMethod = 'UPI'; // 'UPI' | 'CASH'

  final List<String> _stepTitles = ['Farm', 'Service', 'Schedule', 'Review'];

  @override
  void initState() {
    super.initState();
    if (widget.initialFarm != null) {
      _selectedFarm = widget.initialFarm;
      _areaController.text = _selectedFarm!.area.toString();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _areaController.dispose();
    _remarksController.dispose();
    _couponController.dispose();
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
    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final double area = double.tryParse(_areaController.text) ?? 0.0;
    final double ratePerAcre = 800.0;
    final double originalAmount = area * ratePerAcre;

    double discountAmount = 0.0;
    if (_appliedCoupon != null) {
      if (_appliedCoupon!.discountType == CouponDiscountType.percentage) {
        discountAmount = originalAmount * (_appliedCoupon!.discountValue / 100.0);
      } else {
        discountAmount = _appliedCoupon!.discountValue;
      }
    }

    if (discountAmount > originalAmount) {
      discountAmount = originalAmount;
    }

    final double finalAmount = originalAmount - discountAmount;
    final chosenMethod = _paymentTiming == 'PAY_NOW' ? 'UPI' : _paymentMethod;
    final initialStatus = _paymentTiming == 'PAY_NOW' ? 'PENDING' : 'PAYMENT_PENDING';

    final createdBooking = await ref
        .read(bookingViewModelProvider.notifier)
        .createBooking(
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
          remarks: _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
          farmerOverride: widget.farmerOverride,
          couponId: _appliedCoupon?.docId,
          couponCode: _appliedCoupon?.couponCode,
          couponDiscountType: _appliedCoupon?.discountType.value,
          couponDiscountValue: _appliedCoupon?.discountValue,
          originalAmount: originalAmount,
          discountAmount: discountAmount,
          payableAmount: finalAmount,
          paymentTiming: _paymentTiming,
          paymentMethod: chosenMethod,
          paymentStatus: initialStatus,
        );

    if (createdBooking != null) {
      if (_paymentTiming == 'PAY_NOW') {
        try {
          final paymentApi = ref.read(paymentApiServiceProvider);
          final paymentResponse = await paymentApi.createPayment(
            bookingId: createdBooking.docId ?? createdBooking.bookingId,
            userId: createdBooking.farmerUid,
            amount: finalAmount,
            mobileNumber: createdBooking.farmerPhone ?? '9999999999',
          );

          if (mounted && paymentResponse.paymentUrl.isNotEmpty) {
            final isPaid = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebViewScreen(
                  booking: createdBooking,
                  paymentUrl: paymentResponse.paymentUrl,
                ),
              ),
            );

            if (isPaid == true) {
              if (mounted) {
                context.go('/booking-success', extra: createdBooking.bookingId);
              }
            } else {
              if (createdBooking.docId != null) {
                await ref.read(bookingViewModelProvider.notifier).cancelBooking(
                  createdBooking.docId!,
                  remarks: 'Payment cancelled by user before completion.',
                );
              }
              if (mounted) {
                _showError("Payment was not completed. You can try paying again or switch to 'Pay After Service'.");
              }
            }
            return;
          }
        } catch (e) {
          debugPrint('Error initiating Cashfree checkout for Pay Now: $e');
          if (createdBooking.docId != null) {
            await ref.read(bookingViewModelProvider.notifier).cancelBooking(
              createdBooking.docId!,
              remarks: 'Payment failed during checkout initiation.',
            );
          }
          if (mounted) {
            _showError('Failed to launch Cashfree Gateway: ${e.toString().replaceAll('Exception: ', '')}');
          }
          return;
        }
      }

      if (mounted) {
        context.go('/booking-success', extra: createdBooking.bookingId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmerOverride = widget.farmerOverride;
    final farmsAsync = farmerOverride?.uid != null
        ? ref.watch(farmsStreamByFarmerUidProvider(farmerOverride!.uid!))
        : ref.watch(farmsStreamProvider);
    final bookingState = ref.watch(bookingViewModelProvider);

    ref.listen(bookingViewModelProvider, (previous, next) {
      if (next is AsyncError) {
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
                      const Icon(
                        Icons.landscape_outlined,
                        size: 64,
                        color: AppColors.border,
                      ),
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
                children: farms
                    .map(
                      (farm) => FarmSelectionCard(
                        farm: farm,
                        isSelected: _selectedFarm?.docId == farm.docId,
                        onTap: () {
                          setState(() {
                            _selectedFarm = farm;
                            _areaController.text = farm.area.toString();
                          });
                        },
                      ),
                    )
                    .toList(),
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
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
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
                  child: const Icon(
                    Icons.water_drop,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _selectedService,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Precision agricultural drone spraying for pesticides. Ensuring uniform coverage and efficient pest control for your crops.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const Divider(height: 40),
                _buildInfoRow(
                  Icons.timer_outlined,
                  'Estimated Duration',
                  '15-20 min / acre',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.check_circle_outline,
                  'Benefit',
                  'Saves water and chemical usage',
                ),
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
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Estimated Area',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.0',
                    ),
                  ),
                ),
                Text(
                  'Acres',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Additional Notes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
    final couponsAsync = ref.watch(couponsStreamProvider);

    final double area = double.tryParse(_areaController.text) ?? 0.0;
    final double ratePerAcre = 800.0;
    final double originalAmount = area * ratePerAcre;

    double discountAmount = 0.0;
    if (_appliedCoupon != null) {
      if (_appliedCoupon!.discountType == CouponDiscountType.percentage) {
        discountAmount = originalAmount * (_appliedCoupon!.discountValue / 100.0);
      } else {
        discountAmount = _appliedCoupon!.discountValue;
      }
    }

    if (discountAmount > originalAmount) {
      discountAmount = originalAmount;
    }

    final double finalAmount = originalAmount - discountAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Review Booking'),
          const SizedBox(height: 16),
          BookingSummaryCard(
            label: 'Farmer',
            value: widget.farmerOverride?.name ?? user?.name ?? 'Not Set',
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
          const SizedBox(height: 24),
          const SectionHeader(title: 'Payment Details'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildPriceRow(
                  'Original Amount',
                  'Rs. ${originalAmount.toStringAsFixed(2)}',
                  isBold: false,
                ),
                if (_appliedCoupon != null) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Discount Amount',
                    '- Rs. ${discountAmount.toStringAsFixed(2)}',
                    isBold: false,
                    color: AppColors.success,
                  ),
                ],
                const Divider(height: 24),
                _buildPriceRow(
                  'Final Payable Amount',
                  'Rs. ${finalAmount.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Payment Timing'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  activeColor: AppColors.primary,
                  title: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('Pay immediately via Cashfree UPI online', style: TextStyle(fontSize: 12)),
                  value: 'PAY_NOW',
                  groupValue: _paymentTiming,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentTiming = val;
                        _paymentMethod = 'UPI';
                      });
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  activeColor: AppColors.primary,
                  title: const Text('Pay After Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('Pay after pilot completes drone spraying service', style: TextStyle(fontSize: 12)),
                  value: 'PAY_AFTER_SERVICE',
                  groupValue: _paymentTiming,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentTiming = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_paymentTiming == 'PAY_NOW') ...[
            const SectionHeader(title: 'Payment Method'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text('UPI (Cashfree Online)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Spacer(),
                  Chip(
                    label: Text('Instant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    backgroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No payment is required right now. You will choose your preferred payment method (UPI or Cash) after the pilot completes the drone spraying service.',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (user?.role != UserRole.farmer) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: 'Apply Coupon'),
            const SizedBox(height: 12),
            if (_appliedCoupon == null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'Enter Coupon Code',
                        errorText: _couponError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final coupons = couponsAsync.maybeWhen(
                        data: (list) => list,
                        orElse: () => <CouponModel>[],
                      );
                      _applyCoupon(coupons, user);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(80, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Select from Available Coupons'),
                  onPressed: () {
                    final coupons = couponsAsync.maybeWhen(
                      data: (list) => list,
                      orElse: () => <CouponModel>[],
                    );
                    final eligibleCoupons = coupons.where((c) {
                      final isExpired = DateTime.now().isAfter(c.validUntil);
                      final isNotYetValid = DateTime.now().isBefore(c.validFrom);
                      final hasUsageLeft = c.remainingUsage > 0;
                      final couponRegion = c.applicableRegion.trim().toLowerCase();
                      final farmState = (_selectedFarm?.state ?? '').trim().toLowerCase();
                      final regionMatch = couponRegion.isEmpty ||
                          couponRegion == 'all' ||
                          couponRegion == 'global' ||
                          couponRegion == 'any' ||
                          couponRegion == farmState;
                      final serviceMatch =
                          c.eligibleService.trim().toLowerCase() ==
                              _selectedService.trim().toLowerCase();
                      
                      final retailerMatch = c.assignedRetailerIds.isEmpty ||
                          (user != null &&
                              (c.assignedRetailerIds.any((id) => id.trim() == user.uid?.trim()) ||
                               c.assignedRetailerIds.any((id) => id.trim() == user.docId?.trim())));

                      return c.isActive &&
                          !isExpired &&
                          !isNotYetValid &&
                          hasUsageLeft &&
                          regionMatch &&
                          serviceMatch &&
                          retailerMatch;
                    }).toList();

                    _showCouponsBottomSheet(context, eligibleCoupons, user);
                  },
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appliedCoupon!.couponCode,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _appliedCoupon!.discountType ==
                                    CouponDiscountType.percentage
                                ? 'Saved ${_appliedCoupon!.discountValue.toStringAsFixed(0)}%'
                                : 'Saved Rs. ${_appliedCoupon!.discountValue.toStringAsFixed(0)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.error,
                      ),
                      onPressed: () {
                        setState(() {
                          _appliedCoupon = null;
                          _couponController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildClickableCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: PrimaryButton(
              text: _currentStep == 3
                  ? (_paymentTiming == 'PAY_NOW' ? 'Pay Now (Cashfree UPI) →' : 'Confirm & Book')
                  : 'Next →',
              onPressed: isLoading
                  ? null
                  : (_currentStep == 3 ? _submit : _nextPage),
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }

  void _applyCoupon(List<CouponModel> coupons, UserModel? user) {
    setState(() {
      _couponError = null;
    });

    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponError = 'Please enter a coupon code';
      });
      return;
    }

    CouponModel? foundCoupon;
    for (final c in coupons) {
      if (c.couponCode.trim().toUpperCase() == code) {
        foundCoupon = c;
        break;
      }
    }

    if (foundCoupon == null) {
      setState(() {
        _couponError = 'Invalid coupon code';
      });
      return;
    }

    if (!foundCoupon.isActive) {
      setState(() {
        _couponError = 'This coupon is inactive';
      });
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      foundCoupon.validFrom.year,
      foundCoupon.validFrom.month,
      foundCoupon.validFrom.day,
    );
    final end = DateTime(
      foundCoupon.validUntil.year,
      foundCoupon.validUntil.month,
      foundCoupon.validUntil.day,
    );

    if (today.isBefore(start)) {
      setState(() {
        _couponError = 'This coupon is not active yet';
      });
      return;
    }
    if (today.isAfter(end)) {
      setState(() {
        _couponError = 'This coupon has expired';
      });
      return;
    }

    if (foundCoupon.remainingUsage <= 0) {
      setState(() {
        _couponError = 'This coupon has reached its maximum usage limit';
      });
      return;
    }

    if (foundCoupon.eligibleService.trim().toLowerCase() !=
        _selectedService.trim().toLowerCase()) {
      setState(() {
        _couponError = 'Not applicable to the selected service';
      });
      return;
    }

    final couponRegion = foundCoupon.applicableRegion.trim().toLowerCase();
    final farmState = (_selectedFarm?.state ?? '').trim().toLowerCase();
    final regionMatch = couponRegion.isEmpty ||
        couponRegion == 'all' ||
        couponRegion == 'global' ||
        couponRegion == 'any' ||
        couponRegion == farmState;

    if (_selectedFarm == null || !regionMatch) {
      setState(() {
        _couponError = 'Not applicable to this region';
      });
      return;
    }

    if (user != null && user.role == UserRole.retailer) {
      final isAssigned = foundCoupon.assignedRetailerIds.isEmpty ||
          foundCoupon.assignedRetailerIds.any((id) => id.trim() == user.uid?.trim()) ||
          foundCoupon.assignedRetailerIds.any((id) => id.trim() == user.docId?.trim());
      
      if (!isAssigned) {
        setState(() {
          _couponError = 'Not assigned to this retailer';
        });
        return;
      }
    } else {
      if (foundCoupon.assignedRetailerIds.isNotEmpty) {
        setState(() {
          _couponError = 'This coupon is restricted to specific retailers';
        });
        return;
      }
    }

    setState(() {
      _appliedCoupon = foundCoupon;
      _couponError = null;
    });
  }

  void _showCouponsBottomSheet(
    BuildContext context,
    List<CouponModel> eligibleCoupons,
    UserModel? user,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available Coupons',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (eligibleCoupons.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No eligible coupons found for this booking.'),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: eligibleCoupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final coupon = eligibleCoupons[index];
                      final discountDesc =
                          coupon.discountType == CouponDiscountType.percentage
                              ? '${coupon.discountValue.toStringAsFixed(0)}% Off'
                              : 'Rs. ${coupon.discountValue.toStringAsFixed(0)} Off';
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _appliedCoupon = coupon;
                            _couponController.text = coupon.couponCode;
                            _couponError = null;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coupon.couponCode,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Service: ${coupon.eligibleService}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                              Text(
                                discountDesc,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    required bool isBold,
    Color? color,
  }) {
    final style = isBold
        ? AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          )
        : AppTextStyles.bodyMedium.copyWith(
            color: color ?? AppColors.textSecondary,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 8),
        Text(value, style: style.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
