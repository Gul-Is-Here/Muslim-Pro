import 'package:equatable/equatable.dart';
import 'package:quran_pro/core/errors/error_mapper.dart';

final class Failure extends Equatable {
  const Failure(this.code);

  final String code;

  String get messageKey => ErrorMapper.keyFor(code);
  bool get isCancelled => ErrorMapper.isCancellation(code);

  @override
  List<Object> get props => [code];
}
