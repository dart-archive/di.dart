import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';

import 'injector_benchmark_common.dart';

/**
 * tests the speed of looking up typeFactories and binding them to
 * a module. Mirroring time is not counted because DynamicTypeFactories
 * caches the results.
 */
class ModuleBenchmark extends BenchmarkBase {
  var injectorFactory;

  ModuleBenchmark() : super('ModuleBenchmark');

  void run() {
    var m = new Module()
      ..bind(A)
      ..bind(B)
      ..bind(C)
      ..bind(D)
      ..bind(E);
  }
}

main() {
  new ModuleBenchmark().report();
}
