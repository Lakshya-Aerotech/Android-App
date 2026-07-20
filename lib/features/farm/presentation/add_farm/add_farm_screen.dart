import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/models/user_model.dart';
import '../../viewmodels/farm_viewmodel.dart';
import '../../models/farm_model.dart';
import '../map_picker/map_picker_screen.dart';

class AddFarmScreen extends ConsumerStatefulWidget {
  final FarmModel? existingFarm;
  final UserModel? farmerOverride;
  const AddFarmScreen({super.key, this.existingFarm, this.farmerOverride});

  @override
  ConsumerState<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends ConsumerState<AddFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _villageController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _areaController;
  late TextEditingController _otherCropController;

  String _selectedCrop = 'Cotton';
  String _selectedUnit = 'Acres';
  LatLng? _selectedLocation;

  static const List<String> _cropTypes = [
    'Cotton',
    'Paddy',
    'Chilli',
    'Maize',
    'Soya',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final farm = widget.existingFarm;
    _nameController = TextEditingController(text: farm?.farmName);
    _villageController = TextEditingController(text: farm?.village);
    _districtController = TextEditingController(text: farm?.district);
    _stateController = TextEditingController(text: farm?.state ?? 'Telangana');
    _areaController = TextEditingController(text: farm?.area.toString());
    _otherCropController = TextEditingController();

    if (farm != null) {
      if (_cropTypes.contains(farm.cropType)) {
        _selectedCrop = farm.cropType;
      } else if (farm.cropType == 'Others') {
        _selectedCrop = 'Other';
      } else {
        _selectedCrop = 'Other';
        _otherCropController.text = farm.cropType;
      }
      _selectedUnit = farm.unit;
      _selectedLocation = LatLng(farm.latitude, farm.longitude);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _areaController.dispose();
    _otherCropController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Please select farm location on map')),
        ),
      );
      return;
    }

    final notifier = ref.read(farmViewModelProvider.notifier);
    final cropType = _selectedCrop == 'Other'
        ? _otherCropController.text.trim()
        : _selectedCrop;

    if (widget.existingFarm != null) {
      final updatedFarm = widget.existingFarm!.copyWith(
        farmName: _nameController.text.trim(),
        cropType: cropType,
        area: double.parse(_areaController.text),
        unit: _selectedUnit,
        village: _villageController.text.trim(),
        district: _districtController.text.trim(),
        state: _stateController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );
      await notifier.updateFarm(updatedFarm);
    } else {
      await notifier.addFarm(
        farmName: _nameController.text.trim(),
        cropType: cropType,
        area: double.parse(_areaController.text),
        unit: _selectedUnit,
        village: _villageController.text.trim(),
        district: _districtController.text.trim(),
        stateName: _stateController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        farmerUidOverride: widget.farmerOverride?.uid,
      );
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(farmViewModelProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.tr(
            widget.existingFarm != null ? 'Edit Farm' : 'Add New Farm',
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Farm Name *',
                hintText: 'e.g. Green Valley Farm',
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Farm name is required' : null,
              ),
              AppSpacing.verticalMd,

              Text(context.tr('Crop Type *'), style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _selectedCrop,
                items: _cropTypes,
                onChanged: (v) => setState(() => _selectedCrop = v!),
                labelBuilder: (v) => v,
              ),
              if (_selectedCrop == 'Other') ...[
                AppSpacing.verticalMd,
                CustomTextField(
                  label: 'Other Crop Type *',
                  hintText: 'Enter crop name',
                  controller: _otherCropController,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Crop name is required'
                      : null,
                ),
              ],
              AppSpacing.verticalMd,

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Area *',
                      hintText: '0.0',
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Unit'),
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        _buildDropdown<String>(
                          value: _selectedUnit,
                          items: ['Acres', 'Hectares'],
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                          labelBuilder: (v) => v,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalMd,

              CustomTextField(
                label: 'Village *',
                hintText: 'Enter village',
                controller: _villageController,
                validator: (v) => v!.isEmpty ? 'Village is required' : null,
              ),
              AppSpacing.verticalMd,

              CustomTextField(
                label: 'District *',
                hintText: 'Enter district',
                controller: _districtController,
                validator: (v) => v!.isEmpty ? 'District is required' : null,
              ),
              AppSpacing.verticalMd,

              CustomTextField(
                label: 'State *',
                hintText: 'Enter state',
                controller: _stateController,
                validator: (v) => v!.isEmpty ? 'State is required' : null,
              ),
              AppSpacing.verticalLg,

              Text(
                context.tr('Farm Location *'),
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickLocation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedLocation != null
                          ? AppColors.success
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: _selectedLocation != null
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedLocation != null
                              ? '${context.tr('Location Selected')} (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})'
                              : context.tr('Select Location on Map'),
                          style: TextStyle(
                            color: _selectedLocation != null
                                ? AppColors.success
                                : AppColors.textPrimary,
                            fontWeight: _selectedLocation != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_selectedLocation != null)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),
              PrimaryButton(
                text: widget.existingFarm != null ? 'Update Farm' : 'Save Farm',
                onPressed: _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                context.tr(labelBuilder(item)),
                style: AppTextStyles.bodyLarge,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
