import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { earning, salaryPayment }

extension TransactionTypeExtension on TransactionType {
  String get value => toString().split('.').last;
}

class WalletTransactionModel {
  final String? id;
  final String userId;
  final String? bookingId;
  final TransactionType type;
  final double amount;
  final double? acres;
  final double? ratePerAcre;
  final String description;
  final DateTime createdAt;

  WalletTransactionModel({
    this.id,
    required this.userId,
    this.bookingId,
    required this.type,
    required this.amount,
    this.acres,
    this.ratePerAcre,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookingId': bookingId,
      'type': type.value,
      'amount': amount,
      'acres': acres,
      'ratePerAcre': ratePerAcre,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      bookingId: map['bookingId'],
      type: TransactionType.values.firstWhere((t) => t.value == map['type'], orElse: () => TransactionType.earning),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      acres: (map['acres'] as num?)?.toDouble(),
      ratePerAcre: (map['ratePerAcre'] as num?)?.toDouble(),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
