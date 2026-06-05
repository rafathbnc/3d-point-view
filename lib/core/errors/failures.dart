abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class LiDARNotAvailableFailure extends Failure {
  const LiDARNotAvailableFailure()
      : super('3D Point Cloud requires a LiDAR-enabled device.');
}

class ARSessionFailure extends Failure {
  const ARSessionFailure(super.message);
}

class FileIOFailure extends Failure {
  const FileIOFailure(super.message);
}

class ChannelFailure extends Failure {
  const ChannelFailure(super.message);
}
