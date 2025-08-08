import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:yoen_front/data/model/settlement_item.dart';

@immutable
class PaymentCreateState {
  final String? paymentName;
  final String? paymentMethod;
  final String? payerType;
  final int? categoryId;
  final String? categoryName;
  final int? payerTravelUserId;
  final String? payerName;
  final DateTime? payTime;
  final String? currency; // YEN | WON
  final List<SettlementItem> settlementItems;
  final List<XFile> images;

  const PaymentCreateState({
    this.paymentName,
    this.paymentMethod = 'CARD',
    this.payerType = 'INDIVIDUAL',
    this.categoryId,
    this.categoryName,
    this.payerTravelUserId,
    this.payerName,
    this.payTime,
    this.currency,
    this.settlementItems = const [],
    this.images = const [],
  });

  PaymentCreateState copyWith({
    String? paymentName,
    String? paymentMethod,
    String? payerType,
    int? categoryId,
    String? categoryName,
    int? payerTravelUserId,
    String? payerName,
    DateTime? payTime,
    String? currency,
    List<SettlementItem>? settlementItems,
    List<XFile>? images,
    bool clearPayer = false,
  }) {
    return PaymentCreateState(
      paymentName: paymentName ?? this.paymentName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payerType: payerType ?? this.payerType,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      payerTravelUserId: clearPayer
          ? null
          : (payerTravelUserId ?? this.payerTravelUserId),
      payerName: clearPayer ? null : (payerName ?? this.payerName),
      payTime: payTime ?? this.payTime,
      currency: currency ?? this.currency,
      settlementItems: settlementItems ?? this.settlementItems,
      images: images ?? this.images,
    );
  }
}

class PaymentCreateNotifier extends StateNotifier<PaymentCreateState> {
  PaymentCreateNotifier() : super(const PaymentCreateState());

  void initialize(DateTime initialDate) {
    final now = DateTime.now();
    state = PaymentCreateState(
      payTime: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
        now.hour,
        now.minute,
      ),
      currency: state.currency, // 화면에서 nation 기반으로 세팅해둔 값 유지
      settlementItems: [SettlementItem()],
    );
  }

  void updateField({
    String? paymentName,
    String? paymentMethod,
    String? payerType,
    int? categoryId,
    String? categoryName,
    int? payerTravelUserId,
    String? payerName,
    DateTime? payTime,
    String? currency,
    bool clearPayer = false,
  }) {
    state = state.copyWith(
      paymentName: paymentName,
      paymentMethod: paymentMethod,
      payerType: payerType,
      categoryId: categoryId,
      categoryName: categoryName,
      payerTravelUserId: payerTravelUserId,
      payerName: payerName,
      payTime: payTime,
      currency: currency,
      clearPayer: clearPayer,
    );
  }

  void addSettlementItem(GlobalKey<AnimatedListState> listKey) {
    final newIndex = state.settlementItems.length;
    final newItems = List<SettlementItem>.from(state.settlementItems)
      ..add(SettlementItem());
    state = state.copyWith(settlementItems: newItems);
    listKey.currentState?.insertItem(
      newIndex,
      duration: const Duration(milliseconds: 300),
    );
  }

  void removeSettlementItem(
    int index,
    GlobalKey<AnimatedListState> listKey,
    Widget Function(SettlementItem, Animation<double>, int) buildItem,
  ) {
    final removedItem = state.settlementItems[index];
    final newItems = List<SettlementItem>.from(state.settlementItems)
      ..removeAt(index);
    state = state.copyWith(settlementItems: newItems);
    listKey.currentState?.removeItem(
      index,
      (context, animation) => buildItem(removedItem, animation, index),
      duration: const Duration(milliseconds: 300),
    );
  }

  void addImages(List<XFile> newImages) {
    state = state.copyWith(images: [...state.images, ...newImages]);
  }

  void removeImage(int index) {
    final newImages = List<XFile>.from(state.images)..removeAt(index);
    state = state.copyWith(images: newImages);
  }
}

final paymentCreateNotifierProvider =
    StateNotifierProvider.autoDispose<
      PaymentCreateNotifier,
      PaymentCreateState
    >((ref) {
      return PaymentCreateNotifier();
    });
