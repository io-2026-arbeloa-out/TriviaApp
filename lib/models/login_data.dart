import 'package:flutter/foundation.dart';

@immutable
class LoginData {
  final String _uid;
  final String _email;
  final String _password;

  const LoginData({
    required String uid,
    required String email,
    required String password,
  })  : _uid = uid,
        _email = email,
        _password = password;

  LoginData copyWith({
    required String uid,
    required String email,
    String? password,
  }) {
    return LoginData(
      uid: this.uid,
      email: this.email,
      password: password ?? _password,
    );
  }

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      uid: json['uid'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': _uid,
      'email': _email,
      'password': _password,
    };
  }

  String get uid => _uid;
  String get email => _email;
  String get password => _password;
}