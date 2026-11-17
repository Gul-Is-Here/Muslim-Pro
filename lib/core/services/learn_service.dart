import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quran_pro/core/errors/result.dart';
import 'package:quran_pro/data/models/learn.dart';
import 'package:quran_pro/data/models/learn_progress.dart';
import 'package:quran_pro/domain/repositories/learn_repository.dart';

/// Curriculum plus the learner's progress, shared by Home and the Learn tab.
final class LearnService extends GetxService {
  LearnService(this._repo, this._box);

  final LearnRepository _repo;
  final GetStorage _box;
  static const _k = 'learnProgress';

  final Rxn<Curriculum> _curriculum = Rxn<Curriculum>();
  late final Rx<LearnProgress> _progress = _load().obs;

  Curriculum? get curriculum => _curriculum.value;
  LearnProgress get progress => _progress.value;
  set progress(LearnProgress p) {
    _progress.value = p;
    unawaited(_box.write(_k, p.toJson()));
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    if (_curriculum.value != null) return;
    if (await _repo.curriculum() case Ok(:final value)) _curriculum.value = value;
  }

  /// First unfinished lesson of the first unfinished unit, or null when everything is done.
  ({LearnUnit unit, LearnLesson lesson, int index})? nextLesson({bool kidsOnly = false}) {
    final units = curriculum?.units.where((u) => !kidsOnly || u.kids).toList() ?? const [];
    final done = progress.completed;
    for (final u in units) {
      for (var i = 0; i < u.lessons.length; i++) {
        if (!done.contains(u.lessons[i].id)) return (unit: u, lesson: u.lessons[i], index: i);
      }
    }
    return null;
  }

  LearnProgress _load() {
    try {
      final json = _box.read<Map<String, dynamic>>(_k);
      return json == null ? const LearnProgress() : LearnProgress.fromJson(json);
    } on Object {
      return const LearnProgress(); // corrupt data: start fresh rather than crash
    }
  }
}
