import 'package:flutter/services.dart';
import '../../core/constants/channel_constants.dart';
import '../../core/errors/failures.dart';
import 'package:fpdart/fpdart.dart';

class ARSessionDataSource {
  static const _channel =
      MethodChannel(ChannelConstants.arSessionChannel);

  Future<Either<Failure, bool>> checkLiDARAvailability() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkLiDARAvailability');
      return Right(result ?? false);
    } on PlatformException catch (e) {
      return Left(ChannelFailure(e.message ?? 'LiDAR check failed'));
    }
  }

  Future<Either<Failure, void>> startSession() async {
    try {
      await _channel.invokeMethod<void>('startARSession');
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(ARSessionFailure(e.message ?? 'Failed to start AR session'));
    }
  }

  Future<Either<Failure, void>> stopSession() async {
    try {
      await _channel.invokeMethod<void>('stopARSession');
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(ARSessionFailure(e.message ?? 'Failed to stop AR session'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> captureFrame() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('captureFrame');
      if (result == null) return Left(const ChannelFailure('Null frame result'));
      return Right(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      return Left(ChannelFailure(e.message ?? 'Capture failed'));
    }
  }

  Future<Either<Failure, void>> setFlash({required bool on}) async {
    try {
      await _channel.invokeMethod<void>('setFlash', {'on': on});
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(ChannelFailure(e.message ?? 'Flash toggle failed'));
    }
  }
}
