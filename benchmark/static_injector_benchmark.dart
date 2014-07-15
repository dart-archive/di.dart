import 'package:di/static_injector.dart';

import 'injector_benchmark_common.dart';

main() {
  new InjectorBenchmark('StaticInjectorBenchmark',
      (m) => new StaticInjector(modules: m, typeFactories: typeFactories)
  ).report();
}
