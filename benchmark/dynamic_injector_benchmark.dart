import 'package:benchmark_harness/benchmark_harness.dart';

import 'injector_benchmark_common.dart';

main() {
  new InjectorBenchmark('DynamicInjectorBenchmark',
      new DynamicTypeFactories()).report();
}
