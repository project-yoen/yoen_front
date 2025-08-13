// lib/ui/dialogs/openers.dart
import 'package:flutter/material.dart';
import 'package:yoen_front/data/dialog/record_detail_dialog.dart';
import 'package:yoen_front/data/dialog/payment_detail_dialog.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/model/payment_response.dart';

Future<void> openRecordDetailDialog(BuildContext context) {
  return showDialog(context: context, builder: (_) => RecordDetailDialog());
}

Future<void> openPaymentDetailDialog(
  BuildContext context,
  PaymentResponse payment,
) {
  return showDialog(
    context: context,
    builder: (_) => PaymentDetailDialog(paymentId: payment.paymentId),
  );
}
