import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/datasources/local/quran_local_ds.dart';
import 'package:quran_pro/data/models/quran_index.dart';
import 'package:quran_pro/data/repositories/run_catching.dart';
import 'package:quran_pro/domain/repositories/quran_repository.dart';

final class QuranRepositoryImpl implements QuranRepository {
  const QuranRepositoryImpl(this._local);

  final QuranLocalDataSource _local;

  @override
  Future<Result<QuranIndex>> index() => runCatching(_local.index);

  @override
  Future<Result<SurahText>> surah(int number) => runCatching(() => _local.surah(number));
}
