import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

enum ARSessionStatus { idle, starting, running, error }

class ARSessionState {
  final ARSessionStatus status;
  final String? errorMessage;

  const ARSessionState({required this.status, this.errorMessage});

  static const idle = ARSessionState(status: ARSessionStatus.idle);
  static const starting = ARSessionState(status: ARSessionStatus.starting);
  static const running = ARSessionState(status: ARSessionStatus.running);

  ARSessionState copyWith({ARSessionStatus? status, String? errorMessage}) =>
      ARSessionState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class ARSessionNotifier extends Notifier<ARSessionState> {
  @override
  ARSessionState build() => ARSessionState.idle;

  Future<void> start() async {
    state = ARSessionState.starting;
    final useCase = ref.read(startARSessionUseCaseProvider);
    final result = await useCase();
    result.fold(
      (failure) => state = ARSessionState(
        status: ARSessionStatus.error,
        errorMessage: failure.message,
      ),
      (_) => state = ARSessionState.running,
    );
  }

  Future<void> stop() async {
    final useCase = ref.read(stopARSessionUseCaseProvider);
    await useCase();
    state = ARSessionState.idle;
  }
}

final arSessionProvider =
    NotifierProvider<ARSessionNotifier, ARSessionState>(
  ARSessionNotifier.new,
);
