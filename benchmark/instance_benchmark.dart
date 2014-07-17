import 'package:di/static_injector.dart';

import 'injector_benchmark_common.dart';

// tests the speed of cached getInstanceByKey requests
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
  new InstanceBenchmark('InstanceBenchmark',
      (m) => new StaticInjector(modules: m, typeFactories: typeFactories)
  ).report();
}
