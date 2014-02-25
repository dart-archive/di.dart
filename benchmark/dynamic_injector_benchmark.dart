import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/dynamic_injector.dart';

import 'injector_benchmark_common.dart';
import 'emitter.dart';


main(List<String> args) {
  ScoreEmitter emitter = new StdoutScoreEmitter();

  new InjectorBenchmark('DynamicInjectorBenchmark',
      (m) => new DynamicInjector(modules: m), emitter).report();
}