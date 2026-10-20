import 'dart:async';

typedef CancelTimer = void Function();
typedef ScheduleTimer =
    CancelTimer Function(Duration delay, void Function() callback);

CancelTimer scheduleControllerTimer(Duration delay, void Function() callback) {
  final timer = Timer(delay, callback);
  return timer.cancel;
}
