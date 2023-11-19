import 'dart:developer' as developer;

T estimateCallTime<T>(T Function() action) {
  final stopwatch = Stopwatch()..start();
  final result = action();
  developer.log('_getTappedCell() executed in ${stopwatch.elapsed}');

  return result;
}
