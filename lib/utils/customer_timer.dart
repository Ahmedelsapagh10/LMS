import 'dart:async';

class CustomTimer {
  final Duration interval;
  final void Function() onTick;
  Timer? _timer;

  CustomTimer({required this.interval, required this.onTick});

  void start() {
    _timer = Timer.periodic(interval, (timer) {
      onTick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isRunning => _timer?.isActive ?? false;
}
