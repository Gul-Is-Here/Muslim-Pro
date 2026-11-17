import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/learn.dart';

abstract interface class LearnRepository {
  Future<Result<Curriculum>> curriculum();
}
