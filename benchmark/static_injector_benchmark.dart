import 'package:di/di.dart';
import 'package:di/di_static.dart';
import 'injector_benchmark_common.dart';

main() {
  new InjectorBenchmark('StaticInjectorBenchmark',
      new GeneratedTypeFactories(typeFactories, paramKeys)
  ).report();
}
