import 'package:di/static_injector.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

import 'injector_benchmark_common.dart' hide InjectorBenchmark;

/**
 * This benchmark creates the same objects as the StaticInjectorBenchmark
 * without using DI, to serve as a baseline for comparison.
 */
class StaticInjectorBaselineBenchmark extends BenchmarkBase{
  StaticInjectorBaselineBenchmark(name) : super(name);

  void run() {
    var b1 = new B(new D(), new E());
    var c1 = new C();
    var d1 = new D();
    var e1 = new E();

    var a = new A(b1, c1);
    var b = new B(d1, e1);

    var c = new A(b1, c1);
    var d = new B(d1, e1);
  }

  void teardown(){
    print(count);
  }
}

main() {
  new StaticInjectorBaselineBenchmark("StaticInjectorBaseline").report();
}
