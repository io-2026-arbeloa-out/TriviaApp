import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/session_status.dart';

void main() {
  for (final status in SessionStatus.values) {
    test('session status round-trip: ${status.name}', () {
      expect(SessionStatus.fromJson(status.toJson()), status);
    });
  }
  for (final value in [
    null,
    '',
    'answering',
    'resolving',
    'lobby',
    'INPROGRESS',
    'unknown',
    0,
    false,
    [],
    {},
  ]) {
    test('unknown session status is rejected: $value', () {
      expect(() => SessionStatus.fromJson(value), throwsFormatException);
    });
  }
  for (final phase in RoundPhase.values) {
    test('round phase is separate: ${phase.name}', () {
      expect(RoundPhase.fromJson(phase.name), phase);
    });
  }
  for (final value in [null, 'inProgress', 'waiting', '', 1]) {
    test('unknown round phase is rejected: $value', () {
      expect(() => RoundPhase.fromJson(value), throwsFormatException);
    });
  }
}
