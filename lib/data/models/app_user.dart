import 'package:equatable/equatable.dart';

final class AppUser extends Equatable {
  const AppUser({required this.uid, required this.isGuest, this.email, this.displayName});

  final String uid;
  final bool isGuest;
  final String? email;
  final String? displayName;

  @override
  List<Object?> get props => [uid, isGuest, email, displayName];
}
