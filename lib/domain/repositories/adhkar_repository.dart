import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/adhkar.dart';

abstract interface class AdhkarRepository {
  Future<Result<AdhkarBook>> book();
}
