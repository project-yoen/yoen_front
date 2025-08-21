// lib/data/notifier/prepayment_notifier.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/enums/status.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import 'package:yoen_front/data/model/payment_update_request.dart';
import 'package:yoen_front/data/model/payment_detail_response.dart';
import 'package:yoen_front/data/model/payment_image_response.dart';
import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/model/settlement_item.dart';
import 'package:yoen_front/data/repository/payment_repository.dart';

/// Payment와 동일 구조를 재사용 (드래프트 구조는 동일)
class PrepaymentEditDraft {
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
  final List<PaymentImageResponse> images;
  final Set<int> removedImageIds;

  const PrepaymentEditDraft({
    required this.paymentId,
    this.paymentName,
    this.paymentMethod = 'CARD',
    this.payerType = 'INDIVIDUAL',
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

  PrepaymentEditDraft copyWith({
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
    return PrepaymentEditDraft(
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

class PrepaymentState {
  final Status listStatus;
  final Status createStatus;
  final Status deleteStatus;
  final Status detailsStatus;
  final Status updateStatus;

  final List<PaymentResponse> prepayments; // PREPAYMENT 전용 목록
  final PaymentDetailResponse? selected; // 상세
  final String? errorMessage;

  final PrepaymentEditDraft? editDraft;

  final int? lastTravelId; // 새로고침용
  const PrepaymentState({
    this.listStatus = Status.initial,
    this.createStatus = Status.initial,
    this.deleteStatus = Status.initial,
    this.detailsStatus = Status.initial,
    this.updateStatus = Status.initial,
    this.prepayments = const [],
    this.selected,
    this.errorMessage,
    this.editDraft,
    this.lastTravelId,
  });

  PrepaymentState copyWith({
    Status? listStatus,
    Status? createStatus,
    Status? deleteStatus,
    Status? detailsStatus,
    Status? updateStatus,
    List<PaymentResponse>? prepayments,
    PaymentDetailResponse? selected,
    String? errorMessage,
    PrepaymentEditDraft? editDraft,
    int? lastTravelId,
    bool resetCreateStatus = false,
    bool resetDeleteStatus = false,
    bool resetUpdateStatus = false,
  }) {
    return PrepaymentState(
      listStatus: listStatus ?? this.listStatus,
      createStatus: resetCreateStatus
          ? Status.initial
          : (createStatus ?? this.createStatus),
      deleteStatus: resetDeleteStatus
          ? Status.initial
          : (deleteStatus ?? this.deleteStatus),
      detailsStatus: detailsStatus ?? this.detailsStatus,
      updateStatus: resetUpdateStatus
          ? Status.initial
          : (updateStatus ?? this.updateStatus),
      prepayments: prepayments ?? this.prepayments,
      selected: selected ?? this.selected,
      errorMessage: errorMessage ?? this.errorMessage,
      editDraft: editDraft ?? this.editDraft,
      lastTravelId: lastTravelId ?? this.lastTravelId,
    );
  }
}

class PrepaymentNotifier extends StateNotifier<PrepaymentState> {
  final PaymentRepository _repo;
  PrepaymentNotifier(this._repo) : super(const PrepaymentState());

  // 목록
  Future<void> getPrepayments(int travelId) async {
    state = state.copyWith(
      listStatus: Status.loading,
      lastTravelId: travelId,
      resetCreateStatus: true,
      resetDeleteStatus: true,
      resetUpdateStatus: true,
    );
    try {
      final list = await _repo.getPayments(travelId, null, 'PREPAYMENT');
      list.sort((a, b) => a.payTime.compareTo(b.payTime));
      state = state.copyWith(listStatus: Status.success, prepayments: list);
    } catch (e) {
      state = state.copyWith(
        listStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 생성
  Future<void> createPrepayment(
    PaymentRequest request,
    List<File> images,
  ) async {
    state = state.copyWith(createStatus: Status.loading);
    try {
      await _repo.createPayment(
        request,
        images,
      ); // request.paymentType은 PREPAYMENT 여야 함
      state = state.copyWith(createStatus: Status.success);
      final tid = state.lastTravelId;
      if (tid != null) await getPrepayments(tid);
    } catch (e) {
      state = state.copyWith(
        createStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 상세
  Future<void> getPrepaymentDetails(int paymentId) async {
    state = state.copyWith(
      detailsStatus: Status.loading,
      resetCreateStatus: true,
      resetUpdateStatus: true,
    );
    try {
      final detail = await _repo.getPaymentDetails(paymentId);
      state = state.copyWith(detailsStatus: Status.success, selected: detail);
    } catch (e) {
      state = state.copyWith(
        detailsStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 삭제
  Future<void> deletePrepayment(int paymentId) async {
    state = state.copyWith(deleteStatus: Status.loading);
    try {
      await _repo.deletePayment(paymentId);
      state = state.copyWith(
        deleteStatus: Status.success,
        prepayments: state.prepayments
            .where((p) => p.paymentId != paymentId)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
        deleteStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 수정 (이미지 추가/삭제 포함)
  Future<void> updatePrepayment(
    PaymentUpdateRequest request,
    List<File> newImages, {
    bool refreshDetails = true,
  }) async {
    state = state.copyWith(updateStatus: Status.loading);
    try {
      await _repo.updatePayment(request, newImages);
      state = state.copyWith(updateStatus: Status.success);

      // 상세 다시 불러오기(옵션)
      if (refreshDetails) await getPrepaymentDetails(request.paymentId);

      // 목록 갱신
      final tid = state.lastTravelId;
      if (tid != null) await getPrepayments(tid);
    } catch (e) {
      state = state.copyWith(
        updateStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 편집 드래프트 구성 (상세 → 편집)
  void beginEditFromSelected() {
    final d = state.selected;
    if (d == null || d.paymentId == null) return;

    DateTime? pay;
    try {
      if ((d.payTime ?? '').isNotEmpty) pay = DateTime.parse(d.payTime!);
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

    final draft = PrepaymentEditDraft(
      paymentId: d.paymentId!,
      paymentName: d.paymentName,
      paymentMethod: d.paymentMethod,
      payerType: d.payerType ?? 'INDIVIDUAL',
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
      (ctx, anim) => buildItem(removedItem, anim, index),
      duration: const Duration(milliseconds: 300),
    );
  }

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

  void resetAll() => state = const PrepaymentState();
}

final _prepaymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentRepository(apiService);
});

final prepaymentNotifierProvider =
    StateNotifierProvider<PrepaymentNotifier, PrepaymentState>((ref) {
      final repo = ref.watch(_prepaymentRepositoryProvider);
      return PrepaymentNotifier(repo);
    });
