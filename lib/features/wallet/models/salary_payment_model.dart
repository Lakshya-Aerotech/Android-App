import 'package:cloud_firestore/cloud_firestore.dart';

class SalaryPaymentModel {
  final String? id;
  final String pilotId;
  final double amountPaid;
  final String salaryPeriod;
  final String paidBy;
  final DateTime paidAt;
  final String? remarks;

  SalaryPaymentModel({
    this.id,
    required this.pilotId,
    required this.amountPaid,
    required this.salaryPeriod,
    required this.paidBy,
    required this.paidAt,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'pilotId': pilotId,
      'amountPaid': amountPaid,
      'salaryPeriod': salaryPeriod,
      'paidBy': paidBy,
      'paidAt': Timestamp.fromDate(paidAt),
      'remarks': remarks,
    };
  }

  factory SalaryPaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return SalaryPaymentModel(
      id: id,
      pilotId: map['pilotId'] ?? '',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      salaryPeriod: map['salaryPeriod'] ?? '',
      paidBy: map['paidBy'] ?? '',
      paidAt: (map['paidAt'] as Timestamp).toDate(),
      remarks: map['remarks'],
    );
  }
}
