import 'package:di/static_injector.dart';

import 'injector_benchmark_common.dart';

// tests the speed of creating lots of instances
class InstanceBenchmark extends InjectorBenchmark{
  InstanceBenchmark(name, injectorFactory) : super(name, injectorFactory);

  void run(){
    Injector injector = injectorFactory([module]);
    for (var i = 0; i < 30; i++) {
      injector.get(A);
    }
  }
}

main() {
  var typeFactories = {
      A: (f) => new A(f(B), f(C)),
      B: (f) => new B(f(D), f(E)),
      C: (f) => new C(),
      D: (f) => new D(),
      E: (f) => new E(),
  };

  new InstanceBenchmark('InstanceBenchmark',
      (m) => new StaticInjector(modules: m, typeFactories: typeFactories)
  ).report();
}
