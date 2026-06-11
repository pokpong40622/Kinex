import 'arm_curl_counter.dart';
import 'chair_stand_counter.dart';
import 'rep_counter.dart';
import 'step_counter.dart';

/// Creates the [RepCounter] for a given assessment test id.
RepCounter createRepCounter(String testId) => switch (testId) {
      'arm_curl' => ArmCurlCounter(),
      'chair_stand' => ChairStandCounter(),
      'step_test' => StepCounter(),
      _ => throw ArgumentError('Unknown testId: $testId'),
    };
