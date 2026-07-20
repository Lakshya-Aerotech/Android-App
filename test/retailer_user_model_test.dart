import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_aerotech/features/auth/models/user_model.dart';

void main() {
  group('Retailer user model', () {
    test('preserves retailer-specific metadata when copied', () {
      final retailer = UserModel(
        role: UserRole.retailer,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdByRetailerId: 'ret-123',
        createdByRole: 'retailer',
        approvalStatus: ApprovalStatus.pending,
        shopName: 'Green Shop',
        ownerName: 'Ravi',
      );

      final copied = retailer.copyWith(shopName: 'Green Shop Updated');

      expect(copied.createdByRetailerId, 'ret-123');
      expect(copied.createdByRole, 'retailer');
      expect(copied.approvalStatus, ApprovalStatus.pending);
      expect(copied.shopName, 'Green Shop Updated');
    });
  });
}
