import 'dart:async';

import 'package:async/async.dart';
import 'package:ficonsax/ficonsax.dart';
import 'package:fladder/providers/settings/photo_view_settings_provider.dart';
import 'package:fladder/util/simple_duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:square_progress_indicator/square_progress_indicator.dart';

class RestarableTimerController {
  late Duration _steps = const Duration(milliseconds: 32);
  RestartableTimer? _timer;
  late Duration _duration = const Duration(seconds: 1);
  late Function() _onTimeout;

  late Duration _timeLeft = _duration;
  set setTimeLeft(Duration value) {
    _timeLeftController.add(value);
    _timeLeft = value;
  }

  final StreamController<Duration> _timeLeftController = StreamController<Duration>.broadcast();
  final StreamController<bool> _isActiveController = StreamController<bool>.broadcast();

  RestarableTimerController(Duration duration, Duration steps, Function() onTimeout) {
    _steps = steps;
    _duration = duration;
    _onTimeout = onTimeout;
  }

  void playPause() {
    if (_timer?.isActive == true) {
      cancel();
    } else {
      play();
    }
  }

  void play() {
    _timer?.cancel();
    _timer = _startTimer();
    _isActiveController.add(_timer?.isActive ?? true);
  }

  RestartableTimer _startTimer() {
    return RestartableTimer(
      _steps,
      () {
        if (_timeLeft < _steps) {
          setTimeLeft = _duration;
          _onTimeout.call();
        } else {
          setTimeLeft = _timeLeft - _steps;
        }
        _timer?.reset();
      },
    );
  }

  bool get timerIsActive => _timer?.isActive ?? false;

  Stream<bool> get isActive => _isActiveController.stream;

  Stream<Duration> get timeLeft => _timeLeftController.stream;

  void setDuration(Duration value) => {
        _duration = value,
      };

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isActiveController.add(false);
  }

  void reset() {
    setTimeLeft = _duration;
    _timer?.reset();
  }

  void dispose() => _timer?.cancel();
}

class ProgressFloatingButton extends ConsumerStatefulWidget {
  final RestarableTimerController? controller;
  final Function()? onTimeOut;
  const ProgressFloatingButton({this.controller, this.onTimeOut, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProgressFloatingButtonState();
}

class _ProgressFloatingButtonState extends ConsumerState<ProgressFloatingButton> {
  late RestarableTimerController timer;
  late Duration timeLeft = timer._duration;
  late bool isActive = false;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    timer = widget.controller ??
        RestarableTimerController(
          const Duration(seconds: 1),
          const Duration(milliseconds: 32),
          widget.onTimeOut ?? () {},
        );
    subscriptions.addAll([
      timer.timeLeft.listen((event) => setState(() => timeLeft = event)),
      timer.isActive.listen((event) => setState(() => isActive = event))
    ]);
  }

  @override
  void dispose() {
    timer.cancel();
    for (var element in subscriptions) {
      element.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        HapticFeedback.vibrate();
        setState(() {
          timer.reset();
        });
      },
      onLongPress: () async {
        HapticFeedback.vibrate();
        final newTimer =
            await showSimpleDurationPicker(context: context, initialValue: timer._duration, showNever: false);
        if (newTimer != null) {
          setState(() {
            ref.read(photoViewSettingsProvider.notifier).update((state) => state.copyWith(timer: newTimer));
            timer.setDuration(newTimer);
          });
        }
      },
      child: FloatingActionButton(
        onPressed: isActive ? timer.cancel : timer.play,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            SquareProgressIndicator(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              borderRadius: 6,
              strokeWidth: 4,
              value: timeLeft.inMilliseconds / timer._duration.inMilliseconds,
            ),
            Icon(isActive ? IconsaxBold.pause : IconsaxBold.play)
          ],
        ),
      ),
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
