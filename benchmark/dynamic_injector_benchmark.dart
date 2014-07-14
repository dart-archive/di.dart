import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/src/reflector_dynamic.dart';

import 'injector_benchmark_common.dart';

main() {
  new InjectorBenchmark('DynamicInjectorBenchmark',
      new DynamicTypeFactories()).report();
}
