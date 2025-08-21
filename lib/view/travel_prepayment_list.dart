import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yoen_front/data/dialog/confirm.dart';
import 'package:yoen_front/data/dialog/openers.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/prepayment_notifier.dart';
import 'package:yoen_front/data/widget/payment_tile.dart';
import 'package:yoen_front/view/travel_prepayment_create.dart';
import 'package:yoen_front/view/travel_prepayment_update.dart';

import '../data/enums/status.dart';

class TravelPrepaymentListScreen extends ConsumerStatefulWidget {
  final int travelId;
  const TravelPrepaymentListScreen({super.key, required this.travelId});

  @override
  ConsumerState<TravelPrepaymentListScreen> createState() =>
      _TravelPrepaymentListScreenState();
}

class _TravelPrepaymentListScreenState
    extends ConsumerState<TravelPrepaymentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchPrePayments);
  }

  Future<void> _fetchPrePayments() async {
    await ref
        .read(prepaymentNotifierProvider.notifier)
        .getPrepayments(widget.travelId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prepaymentNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('사전 사용금액 목록')),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final success = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  TravelPrepaymentCreateScreen(travelId: widget.travelId),
            ),
          );
          if (success == true) {
            _fetchPrePayments();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(PrepaymentState state) {
    switch (state.listStatus) {
      case Status.loading:
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (_, __) => const _PaymentCardSkeleton(),
        );

      case Status.error:
        return Center(child: Text('오류가 발생했습니다: ${state.errorMessage}'));

      case Status.success:
        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await _fetchPrePayments();
          },
          child: state.prepayments.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('등록된 사전 사용금액이 없습니다.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.prepayments.length,
                  itemBuilder: (context, index) {
                    final payment = state.prepayments[index];
                    return PaymentTile(
                      isTimeView: false,
                      payment: payment,
                      onTap: () async {
                        await openPaymentDetailDialog(context, payment);
                      },
                      onMenuAction: (action) async {
                        if (action == 'delete') {
                          final ok = await showConfirmDialog(
                            context,
                            title: '기록 삭제',
                            content: '\'${payment.paymentName}\'을(를) 삭제하시겠습니까?',
                          );
                          if (ok == true) {
                            await ref
                                .read(prepaymentNotifierProvider.notifier)
                                .deletePrepayment(payment.paymentId);
                          }
                        } else if (action == 'edit') {
                          await ref
                              .read(prepaymentNotifierProvider.notifier)
                              .deletePrepayment(payment.paymentId);

                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => TravelPrepaymentUpdateScreen(),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        );

      default:
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (_, __) => const _PaymentCardSkeleton(),
        );
    }
  }
}

class _PaymentCardSkeleton extends StatelessWidget {
  const _PaymentCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    final highlight = Theme.of(
      context,
    ).colorScheme.surfaceVariant.withOpacity(.85);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            double vw(double x) => x.clamp(0, w);

            final titleW = vw(w * 0.64);
            final catW = vw(w * 0.20);
            final labelW = vw(w * 0.16);
            final valueW = vw(w * 0.26);
            final timeW = vw(w * 0.18);

            Widget bar(double width, double height) => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            );

            return Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [bar(titleW, 18), const Spacer(), bar(catW, 14)],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          bar(labelW * .6, 10),
                          const SizedBox(width: 8),
                          bar(valueW, 16),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          bar(labelW * .6, 10),
                          const SizedBox(width: 8),
                          bar(valueW, 16),
                        ],
                      ),
                      bar(timeW, 12),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
