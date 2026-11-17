import 'package:equatable/equatable.dart';

final class LessonModel extends Equatable {
  const LessonModel({
    required this.id,
    required this.unit,
    required this.order,
    required this.title,
    required this.content,
    this.audioUrl,
  });

  factory LessonModel.fromJson(String id, Map<String, dynamic> json) => LessonModel(
    id: id,
    unit: json['unit'] as int,
    order: json['order'] as int,
    title: Map<String, String>.from(json['title'] as Map),
    content: Map<String, String>.from(json['content'] as Map),
    audioUrl: json['audioUrl'] as String?,
  );

  final String id;
  final int unit;
  final int order;
  final Map<String, String> title;
  final Map<String, String> content;
  final String? audioUrl;

  String titleFor(String lang) => title[lang] ?? title['en'] ?? '';

  Map<String, dynamic> toJson() => {
    'unit': unit,
    'order': order,
    'title': title,
    'content': content,
    'audioUrl': audioUrl,
  };

  LessonModel copyWith({String? audioUrl}) => LessonModel(
    id: id,
    unit: unit,
    order: order,
    title: title,
    content: content,
    audioUrl: audioUrl ?? this.audioUrl,
  );

  @override
  List<Object?> get props => [id, unit, order, title, content, audioUrl];
}
