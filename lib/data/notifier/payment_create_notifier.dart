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

  /// 초기화: 당일 시각 보존 + 기본 정산 항목 1개 생성
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
      currency: state.currency, // 화면에서 세팅된 통화 유지
      settlementItems: [
        SettlementItem(
          nameController: TextEditingController(),
          amountController: TextEditingController(),
          travelUserIds: const [],
          travelUserNames: const [],
          settledUserIds: <int>{},
        ),
      ],
    );
  }

  /// 상단 필드 업데이트(기존 시그니처 유지)
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

  /// 정산 항목 추가(애니메이션 포함)
  void addSettlementItem(GlobalKey<AnimatedListState> listKey) {
    final newIndex = state.settlementItems.length;
    final newItems = List<SettlementItem>.from(state.settlementItems)
      ..add(
        SettlementItem(
          nameController: TextEditingController(),
          amountController: TextEditingController(),
          travelUserIds: const [],
          travelUserNames: const [],
          settledUserIds: <int>{},
        ),
      );
    state = state.copyWith(settlementItems: newItems);
    listKey.currentState?.insertItem(
      newIndex,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// 정산 항목 제거(애니메이션 포함)
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

  /// 이미지 추가/제거
  void addImages(List<XFile> newImages) {
    state = state.copyWith(images: [...state.images, ...newImages]);
  }

  void removeImage(int index) {
    final newImages = List<XFile>.from(state.images)..removeAt(index);
    state = state.copyWith(images: newImages);
  }

  // ---------------------------------------------------------------------------
  // ✅ 사람 기준 정산 상태/참여자 관리 유틸
  // ---------------------------------------------------------------------------

  /// [index] 항목의 참여자 목록을 갱신한다.
  /// - travelUserIds / travelUserNames 교체
  /// - 기존 settledUserIds는 새 목록과 교집합 처리로 정리
  void setParticipants({
    required int index,
    required List<int> userIds,
    required List<String> userNames,
  }) {
    final items = List<SettlementItem>.from(state.settlementItems);
    final item = items[index];

    final newIds = List<int>.from(userIds);
    final newNames = List<String>.from(userNames);

    // 교집합으로 정리
    final newSettled = item.settledUserIds.intersection(newIds.toSet());

    items[index] = SettlementItem(
      nameController: item.nameController,
      amountController: item.amountController,
      travelUserIds: newIds,
      travelUserNames: newNames,
      settledUserIds: newSettled,
      // (구) isPaid는 직접 쓰지 않음. 필요 시衍生 사용.
      isPaid: item.isPaid,
    );

    state = state.copyWith(settlementItems: items);
  }

  /// [index] 항목에서 특정 사용자 정산 완료 여부 토글/설정
  void toggleUserSettled({
    required int index,
    required int userId,
    bool? value, // null이면 토글, true/false면 강제 설정
  }) {
    final items = List<SettlementItem>.from(state.settlementItems);
    final item = items[index];

    final next = Set<int>.from(item.settledUserIds);
    final currently = next.contains(userId);
    final willSet = value ?? !currently;

    if (willSet) {
      next.add(userId);
    } else {
      next.remove(userId);
    }

    items[index] = SettlementItem(
      nameController: item.nameController,
      amountController: item.amountController,
      travelUserIds: item.travelUserIds,
      travelUserNames: item.travelUserNames,
      settledUserIds: next,
      isPaid: item.isPaid,
    );

    state = state.copyWith(settlementItems: items);
  }

  /// (옵션) 항목 전체를 완료/해제
  void setAllSettledForItem({required int index, required bool settled}) {
    final items = List<SettlementItem>.from(state.settlementItems);
    final item = items[index];

    items[index] = SettlementItem(
      nameController: item.nameController,
      amountController: item.amountController,
      travelUserIds: item.travelUserIds,
      travelUserNames: item.travelUserNames,
      settledUserIds: settled ? item.travelUserIds.toSet() : <int>{},
      isPaid: item.isPaid,
    );

    state = state.copyWith(settlementItems: items);
  }
}

final paymentCreateNotifierProvider =
    StateNotifierProvider.autoDispose<
      PaymentCreateNotifier,
      PaymentCreateState
    >((ref) => PaymentCreateNotifier());
