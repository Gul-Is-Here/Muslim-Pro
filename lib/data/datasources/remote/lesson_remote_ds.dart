import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_pro/data/datasources/remote/firebase_guard.dart';
import 'package:quran_pro/data/models/lesson_model.dart';

final class LessonRemoteDataSource {
  LessonRemoteDataSource([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  late final CollectionReference<LessonModel> _lessons = _db
      .collection('lessons')
      .withConverter<LessonModel>(
        fromFirestore: (snap, _) => LessonModel.fromJson(snap.id, snap.data()!),
        toFirestore: (lesson, _) => lesson.toJson(),
      );

  /// [afterOrder] is the `order` of the last lesson already shown (null for the first page).
  Future<List<LessonModel>> page({required int unit, int? afterOrder, int limit = 20}) =>
      guard(() async {
        var q = _lessons.where('unit', isEqualTo: unit).orderBy('order').limit(limit);
        if (afterOrder != null) q = q.startAfter([afterOrder]);
        return (await q.get()).docs.map((d) => d.data()).toList();
      });
}
