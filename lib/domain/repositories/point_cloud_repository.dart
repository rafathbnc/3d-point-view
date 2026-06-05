import 'package:fpdart/fpdart.dart';
import '../entities/point_cloud.dart';
import '../../core/errors/failures.dart';

abstract class PointCloudRepository {
  Stream<Either<Failure, PointCloud>> get pointCloudStream;
}
