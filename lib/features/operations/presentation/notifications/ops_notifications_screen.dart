import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/models/user_model.dart';
import '../../viewmodels/ops_notifications_viewmodel.dart';

class OpsNotificationsScreen extends ConsumerStatefulWidget {
  const OpsNotificationsScreen({super.key});

  @override
  ConsumerState<OpsNotificationsScreen> createState() => _OpsNotificationsScreenState();
}

class _OpsNotificationsScreenState extends ConsumerState<OpsNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Composer fields
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedRecipientType = 'farmer'; // 'farmer', 'pilot', 'external_pilot', 'retailer', 'everyone', 'specific'
  final Set<String> _selectedUserIds = {};
  String _userSearchQuery = '';
  String? _selectedRoleFilter;

  // History filters
  String _historySearchQuery = '';
  String _historyDateFilter = 'all'; // 'today', 'week', 'month', 'all'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _resetComposer() {
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _selectedRecipientType = 'farmer';
      _selectedUserIds.clear();
      _userSearchQuery = '';
      _selectedRoleFilter = null;
    });
    ref.read(opsNotificationViewModelProvider.notifier).reset();
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required List<String> recipientRoles,
    required List<String> recipientUserIds,
    required int recipientCount,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Confirm Broadcast')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${context.tr("You are about to send this notification to")} $recipientCount ${context.tr("recipient(s)")}.',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('${context.tr("Title")}:', style: AppTextStyles.labelLarge),
              Text(title, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              Text('${context.tr("Message")}:', style: AppTextStyles.labelLarge),
              Text(message, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              Text('${context.tr("Recipient Group(s)")}:', style: AppTextStyles.labelLarge),
              Text(
                recipientRoles.isNotEmpty
                    ? recipientRoles.map((r) => r.toUpperCase()).join(', ')
                    : '${context.tr("Specific Users")} ($recipientCount)',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(context.tr('Send'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(opsNotificationViewModelProvider.notifier).sendNotification(
            title: title,
            message: message,
            recipientRoles: recipientRoles,
            recipientUserIds: recipientUserIds,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final composerState = ref.watch(opsNotificationViewModelProvider);

    ref.listen(opsNotificationViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Notification broadcasted successfully!')),
            backgroundColor: AppColors.success,
          ),
        );
        _resetComposer();
        ref.invalidate(opsNotificationHistoryProvider);
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Notification Center')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(icon: const Icon(Icons.send_rounded), text: context.tr('Compose')),
            Tab(icon: const Icon(Icons.history_rounded), text: context.tr('Sent History')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComposeTab(composerState),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildComposeTab(OpsNotificationState state) {
    final usersAsync = ref.watch(allUsersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('1. Target Audience'), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRecipientType,
                isExpanded: true,
                dropdownColor: Colors.white,
                items: [
                  DropdownMenuItem(value: 'farmer', child: Text(context.tr('All Farmers'))),
                  DropdownMenuItem(value: 'pilot', child: Text(context.tr('All Internal Pilots'))),
                  DropdownMenuItem(value: 'external_pilot', child: Text(context.tr('All External Pilots'))),
                  DropdownMenuItem(value: 'retailer', child: Text(context.tr('All Retailers'))),
                  DropdownMenuItem(value: 'operations', child: Text(context.tr('All Operations Staff'))),
                  DropdownMenuItem(value: 'everyone', child: Text(context.tr('Everyone'))),
                  DropdownMenuItem(value: 'specific', child: Text(context.tr('Specific Users...'))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRecipientType = val);
                  }
                },
              ),
            ),
          ),
          if (_selectedRecipientType == 'specific') ...[
            const SizedBox(height: 16),
            _buildSpecificUsersSelection(usersAsync),
          ],
          const SizedBox(height: 28),
          Text(context.tr('2. Notification Content'), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          CustomTextField(
            label: '${context.tr("Title")} *',
            hintText: context.tr('Enter notification title'),
            controller: _titleController,
            maxLength: 100,
            onChanged: (text) => setState(() {}),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: '${context.tr("Message")} *',
            hintText: context.tr('Enter notification description'),
            controller: _messageController,
            maxLines: 4,
            maxLength: 500,
            onChanged: (text) => setState(() {}),
          ),
          const SizedBox(height: 28),
          Text(context.tr('3. Notification Preview'), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildNotificationPreviewCard(),
          const SizedBox(height: 40),
          PrimaryButton(
            text: context.tr('Send Notification'),
            isLoading: state.isLoading,
            onPressed: state.isLoading ? null : () => _onValidateAndConfirm(usersAsync),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSpecificUsersSelection(AsyncValue<List<UserModel>> usersAsync) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: '',
                  hintText: context.tr('Search users by name/phone'),
                  onChanged: (val) => setState(() => _userSearchQuery = val.trim()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(context.tr('All')),
                  selected: _selectedRoleFilter == null,
                  onSelected: (sel) => setState(() => _selectedRoleFilter = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(context.tr('Farmers')),
                  selected: _selectedRoleFilter == 'farmer',
                  onSelected: (sel) => setState(() => _selectedRoleFilter = sel ? 'farmer' : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(context.tr('Pilots')),
                  selected: _selectedRoleFilter == 'pilot',
                  onSelected: (sel) => setState(() => _selectedRoleFilter = sel ? 'pilot' : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(context.tr('Retailers')),
                  selected: _selectedRoleFilter == 'retailer',
                  onSelected: (sel) => setState(() => _selectedRoleFilter = sel ? 'retailer' : null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_selectedUserIds.length} ${context.tr("users selected")}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          usersAsync.when(
            data: (users) {
              final filtered = users.where((u) {
                // Apply role filter
                if (_selectedRoleFilter != null && u.role.name != _selectedRoleFilter) {
                  return false;
                }
                // Apply search query
                if (_userSearchQuery.isNotEmpty) {
                  final query = _userSearchQuery.toLowerCase();
                  final nameMatches = (u.name ?? '').toLowerCase().contains(query);
                  final phoneMatches = (u.phoneNumber ?? '').contains(query);
                  if (!nameMatches && !phoneMatches) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(context.tr('No matching users found')),
                ));
              }

              return Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    final isChecked = _selectedUserIds.contains(u.uid);
                    return CheckboxListTile(
                      title: Text(u.name ?? context.tr('Unknown User')),
                      subtitle: Text('${u.role.name.toUpperCase()} | ${u.phoneNumber ?? ""}'),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            if (u.uid != null) _selectedUserIds.add(u.uid!);
                          } else {
                            if (u.uid != null) _selectedUserIds.remove(u.uid!);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
            error: (e, st) => Text('${context.tr("Error loading users")}: $e'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreviewCard() {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50.withOpacity(0.4), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_outlined, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? context.tr('Preview Title') : title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: title.isEmpty ? Colors.grey : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.isEmpty ? context.tr('Preview Message details will go here...') : message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: message.isEmpty ? Colors.grey : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onValidateAndConfirm(AsyncValue<List<UserModel>> usersAsync) {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter a notification title')), backgroundColor: AppColors.error),
      );
      return;
    }
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter a notification message')), backgroundColor: AppColors.error),
      );
      return;
    }

    List<String> recipientRoles = [];
    List<String> recipientUserIds = [];
    int recipientCount = 0;

    if (_selectedRecipientType == 'specific') {
      if (_selectedUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Please select at least one recipient user')), backgroundColor: AppColors.error),
        );
        return;
      }
      recipientUserIds = _selectedUserIds.toList();
      recipientCount = _selectedUserIds.length;
    } else {
      recipientRoles = [_selectedRecipientType];
      
      // Resolve recipient count
      usersAsync.whenData((users) {
        if (_selectedRecipientType == 'everyone') {
          recipientCount = users.length;
        } else {
          recipientCount = users.where((u) => u.role.name == _selectedRecipientType).length;
        }
      });
    }

    _showConfirmationDialog(
      title: title,
      message: message,
      recipientRoles: recipientRoles,
      recipientUserIds: recipientUserIds,
      recipientCount: recipientCount,
    );
  }

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(opsNotificationHistoryProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(opsNotificationHistoryProvider),
      child: Column(
        children: [
          // Filter Panel
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                CustomTextField(
                  label: '',
                  hintText: context.tr('Filter history by title/message...'),
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (val) => setState(() => _historySearchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', context.tr('All Dates')),
                      const SizedBox(width: 8),
                      _buildFilterChip('today', context.tr('Today')),
                      const SizedBox(width: 8),
                      _buildFilterChip('week', context.tr('This Week')),
                      const SizedBox(width: 8),
                      _buildFilterChip('month', context.tr('This Month')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              data: (history) {
                final filtered = history.where((item) {
                  // 1. Text filter
                  if (_historySearchQuery.isNotEmpty) {
                    final title = (item['title'] ?? '').toString().toLowerCase();
                    final msg = (item['message'] ?? '').toString().toLowerCase();
                    if (!title.contains(_historySearchQuery) && !msg.contains(_historySearchQuery)) {
                      return false;
                    }
                  }

                  // 2. Date filter
                  if (_historyDateFilter != 'all' && item['createdAt'] != null) {
                    final DateTime created = DateTime.parse(item['createdAt'].toString());
                    final now = DateTime.now();
                    if (_historyDateFilter == 'today') {
                      if (created.day != now.day || created.month != now.month || created.year != now.year) {
                        return false;
                      }
                    } else if (_historyDateFilter == 'week') {
                      final difference = now.difference(created).inDays;
                      if (difference > 7) return false;
                    } else if (_historyDateFilter == 'month') {
                      if (created.month != now.month || created.year != now.year) {
                        return false;
                      }
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(child: Text(context.tr('No notifications sent matching these filters.'))),
                    ],
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildHistoryCard(item);
                  },
                );
              },
              error: (e, st) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(child: Text('${context.tr("Error loading history")}: $e')),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterVal, String label) {
    final isSelected = _historyDateFilter == filterVal;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (sel) {
        if (sel) {
          setState(() => _historyDateFilter = filterVal);
        }
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final message = item['message'] ?? '';
    final senderName = item['senderName'] ?? 'Unknown Sender';
    final senderRole = (item['senderRole'] ?? '').toString().toUpperCase();
    final status = (item['status'] ?? 'sent').toString().toLowerCase();
    
    // Recipient translation description
    final List recipientRoles = item['recipientRoles'] ?? [];
    final List recipientUserIds = item['recipientUserIds'] ?? [];
    String toLabel = '';
    if (recipientRoles.isNotEmpty) {
      toLabel = recipientRoles.map((r) => r.toUpperCase()).join(', ');
    } else {
      toLabel = '${recipientUserIds.length} ${context.tr("specific users")}';
    }

    String formattedDate = '';
    if (item['createdAt'] != null) {
      try {
        final parsedDate = DateTime.parse(item['createdAt'].toString());
        formattedDate = DateFormat('d MMM yyyy, h:mm a').format(parsedDate);
      } catch (_) {
        formattedDate = item['createdAt'].toString();
      }
    }

    final isFailed = status == 'failed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFailed ? AppColors.error.withOpacity(0.12) : AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    isFailed ? context.tr('Failed') : context.tr('Sent'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isFailed ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${context.tr("To")}: $toLabel',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedDate,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${context.tr("By")}: $senderName ($senderRole)',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (item.containsKey('sentCount') && item.containsKey('failedCount')) ...[
                  const Spacer(),
                  Text(
                    'Success: ${item["sentCount"]} | Fail: ${item["failedCount"]}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
