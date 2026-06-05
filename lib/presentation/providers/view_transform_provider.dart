import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

class ViewTransform {
  final double rotationX;
  final double rotationY;
  final double zoom;
  final double panX;
  final double panY;

  const ViewTransform({
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.panX,
    required this.panY,
  });

  static const identity = ViewTransform(
    rotationX: 0,
    rotationY: 0,
    zoom: 1.0,
    panX: 0,
    panY: 0,
  );

  ViewTransform copyWith({
    double? rotationX,
    double? rotationY,
    double? zoom,
    double? panX,
    double? panY,
  }) =>
      ViewTransform(
        rotationX: rotationX ?? this.rotationX,
        rotationY: rotationY ?? this.rotationY,
        zoom: zoom ?? this.zoom,
        panX: panX ?? this.panX,
        panY: panY ?? this.panY,
      );

  Map<String, double> toMap() => {
        'rotX': rotationX,
        'rotY': rotationY,
        'zoom': zoom,
        'panX': panX,
        'panY': panY,
      };
}

class ViewTransformNotifier extends Notifier<ViewTransform> {
  @override
  ViewTransform build() => ViewTransform.identity;

  void applyRotation(Offset delta) {
    final newRotX = (state.rotationX +
            delta.dy * AppConstants.gestureRotationSensitivity)
        .clamp(-math.pi / 2, math.pi / 2);
    final newRotY =
        state.rotationY + delta.dx * AppConstants.gestureRotationSensitivity;
    state = state.copyWith(rotationX: newRotX, rotationY: newRotY);
  }

  void applyZoom(double scaleFactor) {
    final newZoom = (state.zoom * scaleFactor)
        .clamp(AppConstants.gestureZoomMin, AppConstants.gestureZoomMax);
    state = state.copyWith(zoom: newZoom);
  }

  void applyPan(Offset delta) {
    state = state.copyWith(
      panX: state.panX + delta.dx * AppConstants.gesturePanSensitivity,
      panY: state.panY - delta.dy * AppConstants.gesturePanSensitivity,
    );
  }

  void setRotation(double rotX, double rotY) {
    state = state.copyWith(rotationX: rotX, rotationY: rotY);
  }

  // Must not run synchronously during widget tree finalization (dispose() → finalizeTree).
  void reset() => Future<void>(() => state = ViewTransform.identity);
}

final viewTransformProvider =
    NotifierProvider<ViewTransformNotifier, ViewTransform>(
  ViewTransformNotifier.new,
);
