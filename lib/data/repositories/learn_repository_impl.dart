import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/datasources/local/learn_local_ds.dart';
import 'package:quran_pro/data/models/learn.dart';
import 'package:quran_pro/data/repositories/run_catching.dart';
import 'package:quran_pro/domain/repositories/learn_repository.dart';

final class LearnRepositoryImpl implements LearnRepository {
  const LearnRepositoryImpl(this._local);

  final LearnLocalDataSource _local;

  @override
  Future<Result<Curriculum>> curriculum() => runCatching(_local.curriculum);
}
