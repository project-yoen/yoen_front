import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/model/record_response.dart';

enum TimelineItemType { record, payment }

class TimelineItem {
  final TimelineItemType type;
  final DateTime timestamp;
  final dynamic data;

  TimelineItem({required this.type, required this.timestamp, required this.data});

  RecordResponse get record => data as RecordResponse;
  PaymentResponse get payment => data as PaymentResponse;
}
