import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/quran_index.dart';

abstract interface class QuranRepository {
  Future<Result<QuranIndex>> index();
  Future<Result<SurahText>> surah(int number);
}
