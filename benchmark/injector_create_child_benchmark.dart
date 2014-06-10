import 'package:di/static_injector.dart';

import 'injector_benchmark_common.dart';

class CreateChildBenchmark extends InjectorBenchmark{
  CreateChildBenchmark(name, injectorFactory) : super(name, injectorFactory);

  StaticInjector injector;
  List moreModules;

  void setup() {
    getModule([_]) {
      var m = new Module()
        ..bind(A)
        ..bind(B)
        ..bind(C)
        ..bind(D)
        ..bind(E)
        ..bind(F)
        ..bind(G);
      return m;
    }
    module = getModule();
    moreModules = new List.generate(30, getModule, growable:true);
  }

  void run(){
    injector = injectorFactory([module]);
    for (var i = 0; i < 30; i++) {
      injector = injector.createChild(moreModules);
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

  new CreateChildBenchmark('CreateChildBenchmark',
      (m) => new StaticInjector(modules: m, typeFactories: typeFactories)
  ).report();
}
