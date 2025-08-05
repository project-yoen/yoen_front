import 'package:flutter/material.dart';

class SettlementItem {
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool isPaid = false;
  List<int> travelUserIds = [];
  List<String> travelUserNames = [];
}
