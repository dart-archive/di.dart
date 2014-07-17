import 'package:di/di.dart';
import 'package:di/src/reflector_static.dart';

import 'injector_benchmark_common.dart';

// tests the speed of cached getInstanceByKey requests
class InstanceBenchmark extends InjectorBenchmark{
  InstanceBenchmark(name, typeReflector) : super(name, typeReflector);

  void run(){
    Injector injector = new ModuleInjector([module]);
    for (var i = 0; i < 30; i++) {
      injector.get(A);
    }
  }
}

main() {
  new InstanceBenchmark('InstanceBenchmark',
      new GeneratedTypeFactories(typeFactories, paramKeys)
  ).report();
}
