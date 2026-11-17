import 'package:equatable/equatable.dart';

final class PushMessage extends Equatable {
  const PushMessage({this.title, this.body, this.route});

  final String? title;
  final String? body;

  /// Untrusted: navigate only if it is on an allowlist of AppRoutes.
  final String? route;

  @override
  List<Object?> get props => [title, body, route];
}
