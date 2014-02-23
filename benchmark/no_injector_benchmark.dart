import 'package:benchmark_harness/benchmark_harness.dart';

import 'injector_benchmark_common.dart';
import 'emitter.dart';

main() {
  ScoreEmitter emitter = new StdoutScoreEmitter();
  new NoInjectorBenchmark('NoInjectorBenchmark', emitter).report();
}