import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/dynamic_injector.dart';

import 'injector_benchmark_common.dart';
import 'score_emitter.dart';


main(List<String> args) {
  ScoreEmitter emitter = new HttpScoreEmitter(Uri.parse(args[0]));

  new InjectorBenchmark('DynamicInjectorBenchmark',
      (m) => new DynamicInjector(modules: m), emitter).report();
}