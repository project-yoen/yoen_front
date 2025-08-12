// lib/data/notifier/payment_notifier.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/model/payment_create_request.dart'; // PaymentRequest/Settlement/SettlementParticipant
import 'package:yoen_front/data/model/payment_update_request.dart'; // DTO
import 'package:yoen_front/data/model/payment_detail_response.dart';
import 'package:yoen_front/data/model/payment_image_response.dart';
import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/model/settlement_item.dart';
import 'package:yoen_front/data/repository/payment_repository.dart';

enum Status { initial, loading, success, error }

/// 화면 편집용 드래프트 (UI는 SettlementItem 사용)
class PaymentEditDraft {
  final int paymentId;

  final String? paymentName;
  final String? paymentMethod; // CARD/CASH/TRAVELCARD
  final String? payerType; // INDIVIDUAL/SHAREDFUND
  final int? categoryId;
  final String? categoryName;
  final int? travelUserId;
  final String? payerName;
  final DateTime? payTime;
  final String? currency; // YEN/WON

  final List<SettlementItem> settlementItems;

  /// 서버 저장 이미지와 삭제 표시 id
  final List<PaymentImageResponse> images;
  final Set<int> removedImageIds;

  const PaymentEditDraft({
    required this.paymentId,
    this.paymentName,
    this.paymentMethod = 'CARD',
    this.payerType = 'SHAREDFUND', // ✅ 기본값을 공금으로 변경
    this.categoryId,
    this.categoryName,
    this.travelUserId,
    this.payerName,
    this.payTime,
    this.currency,
    this.settlementItems = const [],
    this.images = const [],
    this.removedImageIds = const {},
  });

  PaymentEditDraft copyWith({
    String? paymentName,
    String? paymentMethod,
    String? payerType,
    int? categoryId,
    String? categoryName,
    int? travelUserId,
    String? payerName,
    DateTime? payTime,
    String? currency,
    List<SettlementItem>? settlementItems,
    List<PaymentImageResponse>? images,
    Set<int>? removedImageIds,
    bool clearPayer = false,
  }) {
    return PaymentEditDraft(
      paymentId: paymentId,
      paymentName: paymentName ?? this.paymentName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payerType: payerType ?? this.payerType,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      travelUserId: clearPayer ? null : (travelUserId ?? this.travelUserId),
      payerName: clearPayer ? null : (payerName ?? this.payerName),
      payTime: payTime ?? this.payTime,
      currency: currency ?? this.currency,
      settlementItems: settlementItems ?? this.settlementItems,
      images: images ?? this.images,
      removedImageIds: removedImageIds ?? this.removedImageIds,
    );
  }

  List<PaymentImageResponse> get visibleImages => images
      .where((e) => !removedImageIds.contains(e.paymentImageId!))
      .toList();
}

class PaymentState {
  final Status getStatus;
  final Status createStatus;
  final Status deleteStatus;
  final Status getDetailsStatus;

  /// 업데이트 상태
  final Status updateStatus;

  final List<PaymentResponse> payments;
  final PaymentDetailResponse? selectedPayment;
  final String? errorMessage;

  /// 편집 드래프트
  final PaymentEditDraft? editDraft;
  final int? lastTravelId;
  final DateTime? lastListDate;
  final String? lastListType;

  PaymentState({
    this.getStatus = Status.initial,
    this.createStatus = Status.initial,
    this.deleteStatus = Status.initial,
    this.getDetailsStatus = Status.initial,
    this.updateStatus = Status.initial,
    this.payments = const [],
    this.selectedPayment,
    this.errorMessage,
    this.editDraft,
    this.lastTravelId,
    this.lastListDate,
    this.lastListType,
  });

  PaymentState copyWith({
    int? lastTravelId,
    DateTime? lastListDate,
    String? lastListType,
    Status? getStatus,
    Status? createStatus,
    Status? getDetailsStatus,
    Status? deleteStatus,
    Status? updateStatus,
    List<PaymentResponse>? payments,
    PaymentDetailResponse? selectedPayment,
    String? errorMessage,
    bool? resetCreateStatus,
    bool? resetDeleteStatus,
    bool? resetUpdateStatus,
    PaymentEditDraft? editDraft,
  }) {
    return PaymentState(
      lastTravelId: lastTravelId ?? this.lastTravelId,
      lastListDate: lastListDate ?? this.lastListDate,
      lastListType: lastListType ?? this.lastListType,
      getStatus: getStatus ?? this.getStatus,
      createStatus: resetCreateStatus == true
          ? Status.initial
          : (createStatus ?? this.createStatus),
      deleteStatus: resetDeleteStatus == true
          ? Status.initial
          : (deleteStatus ?? this.deleteStatus),
      getDetailsStatus: getDetailsStatus ?? this.getDetailsStatus,
      updateStatus: resetUpdateStatus == true
          ? Status.initial
          : (updateStatus ?? this.updateStatus),
      payments: payments ?? this.payments,
      selectedPayment: selectedPayment ?? this.selectedPayment,
      errorMessage: errorMessage ?? this.errorMessage,
      editDraft: editDraft ?? this.editDraft,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(PaymentState());

  // 생성
  Future<void> createPayment(PaymentRequest request, List<File> images) async {
    state = state.copyWith(createStatus: Status.loading);
    try {
      await _repository.createPayment(request, images);
      state = state.copyWith(createStatus: Status.success);
    } catch (e) {
      state = state.copyWith(
        createStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 상세
  Future<void> getPaymentDetails(int paymentId) async {
    state = state.copyWith(
      getDetailsStatus: Status.loading,
      resetCreateStatus: true,
      resetUpdateStatus: true,
    );
    try {
      final paymentDetails = await _repository.getPaymentDetails(paymentId);
      state = state.copyWith(
        getDetailsStatus: Status.success,
        selectedPayment: paymentDetails,
      );
    } catch (e) {
      state = state.copyWith(
        getDetailsStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 삭제
  Future<void> deletePayment(int paymentId) async {
    state = state.copyWith(deleteStatus: Status.loading);
    try {
      await _repository.deletePayment(paymentId);
      final updated = state.payments
          .where((p) => p.paymentId != paymentId)
          .toList();
      state = state.copyWith(deleteStatus: Status.success, payments: updated);
    } catch (e) {
      state = state.copyWith(
        deleteStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // =======================
  // 편집 (Edit) 지원
  // =======================

  /// 상세 → 드래프트 변환
  void beginEditFromSelected() {
    final d = state.selectedPayment;
    if (d == null || d.paymentId == null) return;

    DateTime? pay;
    try {
      if (d.payTime != null && d.payTime!.isNotEmpty) {
        pay = DateTime.parse(d.payTime!);
      }
    } catch (_) {}

    final items = <SettlementItem>[];
    for (final s in (d.settlements ?? const [])) {
      final ids = <int>[];
      final names = <String>[];
      final settled = <int>{};
      for (final u in s.travelUsers) {
        ids.add(u.travelUserId);
        names.add(u.travelNickname ?? '-');
        if (u.isPaid == true) settled.add(u.travelUserId);
      }
      items.add(
        SettlementItem(
          nameController: TextEditingController(text: s.settlementName),
          amountController: TextEditingController(
            text: (s.amount ?? 0).toString(),
          ),
          travelUserIds: ids,
          travelUserNames: names,
          settledUserIds: settled,
        ),
      );
    }

    final draft = PaymentEditDraft(
      paymentId: d.paymentId!,
      paymentName: d.paymentName,
      paymentMethod: d.paymentMethod,
      payerType: d.payerType ?? 'SHAREDFUND', // ✅ 상세에 값이 없으면 공금으로
      categoryId: d.categoryId,
      categoryName: d.categoryName,
      travelUserId: d.payerName?.travelUserId,
      payerName: d.payerName?.travelNickname,
      payTime: pay,
      currency: d.currency,
      settlementItems: items.isEmpty
          ? [
              SettlementItem(
                nameController: TextEditingController(),
                amountController: TextEditingController(),
                travelUserIds: const [],
                travelUserNames: const [],
                settledUserIds: <int>{},
              ),
            ]
          : items,
      images: d.images ?? const [],
      removedImageIds: <int>{},
    );

    state = state.copyWith(editDraft: draft);
  }

  // 상단 필드 업데이트
  void updateEditField({
    String? paymentName,
    String? paymentMethod,
    String? payerType,
    int? categoryId,
    String? categoryName,
    int? travelUserId,
    String? payerName,
    DateTime? payTime,
    String? currency,
    bool clearPayer = false,
  }) {
    final draft = state.editDraft;
    if (draft == null) return;
    state = state.copyWith(
      editDraft: draft.copyWith(
        paymentName: paymentName,
        paymentMethod: paymentMethod,
        payerType: payerType,
        categoryId: categoryId,
        categoryName: categoryName,
        travelUserId: travelUserId,
        payerName: payerName,
        payTime: payTime,
        currency: currency,
        clearPayer: clearPayer,
      ),
    );
  }

  // 항목 추가/제거
  void addEditSettlementItem(GlobalKey<AnimatedListState> listKey) {
    final draft = state.editDraft;
    if (draft == null) return;

    final newIndex = draft.settlementItems.length;
    final newItems = List<SettlementItem>.from(draft.settlementItems)
      ..add(
        SettlementItem(
          nameController: TextEditingController(),
          amountController: TextEditingController(),
          travelUserIds: const [],
          travelUserNames: const [],
          settledUserIds: <int>{},
        ),
      );

    state = state.copyWith(
      editDraft: draft.copyWith(settlementItems: newItems),
    );
    listKey.currentState?.insertItem(
      newIndex,
      duration: const Duration(milliseconds: 300),
    );
  }

  void removeEditSettlementItem(
    int index,
    GlobalKey<AnimatedListState> listKey,
    Widget Function(SettlementItem, Animation<double>, int) buildItem,
  ) {
    final draft = state.editDraft;
    if (draft == null) return;
    final removedItem = draft.settlementItems[index];
    final newItems = List<SettlementItem>.from(draft.settlementItems)
      ..removeAt(index);
    state = state.copyWith(
      editDraft: draft.copyWith(settlementItems: newItems),
    );
    listKey.currentState?.removeItem(
      index,
      (context, animation) => buildItem(removedItem, animation, index),
      duration: const Duration(milliseconds: 300),
    );
  }

  // 참여자/완료
  void setEditParticipants({
    required int index,
    required List<int> userIds,
    required List<String> userNames,
  }) {
    final draft = state.editDraft;
    if (draft == null) return;

    final items = List<SettlementItem>.from(draft.settlementItems);
    final item = items[index];

    final newIds = List<int>.from(userIds);
    final newNames = List<String>.from(userNames);
    final newSettled = item.settledUserIds.intersection(newIds.toSet());

    items[index] = SettlementItem(
      nameController: item.nameController,
      amountController: item.amountController,
      travelUserIds: newIds,
      travelUserNames: newNames,
      settledUserIds: newSettled,
      isPaid: item.isPaid,
    );

    state = state.copyWith(editDraft: draft.copyWith(settlementItems: items));
  }

  void toggleEditUserSettled({
    required int index,
    required int userId,
    bool? value,
  }) {
    final draft = state.editDraft;
    if (draft == null) return;

    final items = List<SettlementItem>.from(draft.settlementItems);
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

    state = state.copyWith(editDraft: draft.copyWith(settlementItems: items));
  }

  void setAllSettledForEditItem({required int index, required bool settled}) {
    final draft = state.editDraft;
    if (draft == null) return;

    final items = List<SettlementItem>.from(draft.settlementItems);
    final item = items[index];

    items[index] = SettlementItem(
      nameController: item.nameController,
      amountController: item.amountController,
      travelUserIds: item.travelUserIds,
      travelUserNames: item.travelUserNames,
      settledUserIds: settled ? item.travelUserIds.toSet() : <int>{},
      isPaid: item.isPaid,
    );

    state = state.copyWith(editDraft: draft.copyWith(settlementItems: items));
  }

  // 서버 이미지 삭제표시/복구
  void markEditImageRemoved(int paymentImageId) {
    final draft = state.editDraft;
    if (draft == null) return;
    final next = Set<int>.from(draft.removedImageIds)..add(paymentImageId);
    state = state.copyWith(editDraft: draft.copyWith(removedImageIds: next));
  }

  void undoEditImageRemoved(int paymentImageId) {
    final draft = state.editDraft;
    if (draft == null) return;
    final next = Set<int>.from(draft.removedImageIds)..remove(paymentImageId);
    state = state.copyWith(editDraft: draft.copyWith(removedImageIds: next));
  }

  Future<void> getPayments(int travelId, DateTime? date, String type) async {
    state = state.copyWith(
      getStatus: Status.loading,
      resetCreateStatus: true,
      resetDeleteStatus: true,
      resetUpdateStatus: true,
      lastTravelId: travelId,
      lastListDate: date,
      lastListType: type,
    );
    try {
      String? dateString;

      dateString = date?.toIso8601String();

      final payments = await _repository.getPayments(
        travelId,
        dateString,
        type,
      );
      payments.sort((a, b) => a.payTime.compareTo(b.payTime));
      state = state.copyWith(getStatus: Status.success, payments: payments);
    } catch (e) {
      state = state.copyWith(
        getStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  void resetAll() => state = PaymentState();

  // 생략 ...

  // 업데이트 제출 (Settlement로 전송)
  Future<void> updatePayment(
    PaymentUpdateRequest request,
    List<File> newImages,
  ) async {
    state = state.copyWith(updateStatus: Status.loading);
    try {
      await _repository.updatePayment(request, newImages);
      state = state.copyWith(updateStatus: Status.success);

      // 업데이트 후 상세 재조회
      await getPaymentDetails(request.paymentId);

      // 목록도 재조회 (마지막 조회 조건이 있을 때만)
      final lt = state.lastTravelId;
      final ld = state.lastListDate;
      final lty = state.lastListType;
      if (lt != null && ld != null && lty != null) {
        await getPayments(lt, ld, lty);
      }
    } catch (e) {
      state = state.copyWith(
        updateStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// providers
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentRepository(apiService);
});

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
      final repository = ref.watch(paymentRepositoryProvider);
      return PaymentNotifier(repository);
    });
