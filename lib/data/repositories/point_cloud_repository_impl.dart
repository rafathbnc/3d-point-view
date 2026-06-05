import 'package:fpdart/fpdart.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/point_cloud.dart';
import '../../domain/repositories/point_cloud_repository.dart';
import '../datasources/point_cloud_event_datasource.dart';
import '../models/point_cloud_model.dart';

class PointCloudRepositoryImpl implements PointCloudRepository {
  final PointCloudEventDataSource _dataSource;
  PointCloudRepositoryImpl(this._dataSource);

  @override
  Stream<Either<Failure, PointCloud>> get pointCloudStream {
    return _dataSource.rawStream.map((bytes) {
      try {
        final model = PointCloudModel.fromBytes(bytes);
        return Right<Failure, PointCloud>(model);
      } catch (e) {
        return Left<Failure, PointCloud>(
          ChannelFailure('Failed to parse point cloud: $e'),
        );
      }
    });
  }
}
