import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/datasources/local/adhkar_local_ds.dart';
import 'package:quran_pro/data/models/adhkar.dart';
import 'package:quran_pro/data/repositories/run_catching.dart';
import 'package:quran_pro/domain/repositories/adhkar_repository.dart';

final class AdhkarRepositoryImpl implements AdhkarRepository {
  const AdhkarRepositoryImpl(this._local);

  final AdhkarLocalDataSource _local;

  @override
  Future<Result<AdhkarBook>> book() => runCatching(_local.book);
}
