import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/destination_response.dart';

enum DestinationStatus { idle, loading, success, error }

class DestinationState {
  final DestinationStatus status;
  final List<DestinationResponse> destinations;
  final String? errorMessage;

  DestinationState({
    this.status = DestinationStatus.idle,
    this.destinations = const [],
    this.errorMessage,
  });

  DestinationState copyWith({
    DestinationStatus? status,
    List<DestinationResponse>? destinations,
    String? errorMessage,
  }) {
    return DestinationState(
      status: status ?? this.status,
      destinations: destinations ?? this.destinations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final destinationNotifierProvider =
    NotifierProvider<DestinationNotifier, DestinationState>(
      () => DestinationNotifier(),
    );

class DestinationNotifier extends Notifier<DestinationState> {
  late final ApiService _api;

  @override
  DestinationState build() {
    _api = ref.read(apiServiceProvider);
    return DestinationState();
  }

  Future<void> fetchDestinations() async {
    state = state.copyWith(status: DestinationStatus.loading);
    try {
      final response = await _api.getDestinations();
      if (response.data != null) {
        state = state.copyWith(
          status: DestinationStatus.success,
          destinations: response.data,
        );
      } else {
        state = state.copyWith(
          status: DestinationStatus.error,
          errorMessage: response.error ?? '알 수 없는 오류가 발생했습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: DestinationStatus.error,
        errorMessage: '서버와 통신 중 오류가 발생했습니다.',
      );
    }
  }
}
