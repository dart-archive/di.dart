import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';
import 'package:di/dynamic_injector.dart';
import 'package:di/static_injector.dart';

class InjectorBenchmark extends BenchmarkBase {
  var injectorFactory;
  var module;

  InjectorBenchmark(name, this.injectorFactory) : super(name);

  void run() {
    Injector injector = injectorFactory([module]);
    injector.get(A);
  }

  setup() {
    module = new Module()
      ..type(A)
      ..type(B)
      ..type(C)
      ..type(D)
      ..type(E);
  }
}

class ModuleBenchmark extends BenchmarkBase {
  var injectorFactory;

  ModuleBenchmark() : super('ModuleBenchmark');

  void run() {
    var m = new Module()
      ..type(A)
      ..type(B)
      ..type(C)
      ..type(D)
      ..type(E);
  }
}

class A {
  A(B b, C c);
}

class B {
  B(D b, E c);
}

class C {
}

class D {
}

class E {
}

main() {
  new ModuleBenchmark().report();


  new InjectorBenchmark('DynamicInjectorBenchmark',
      (m) => new DynamicInjector(modules: m)).report();

  var typeFactories = new Map();
  typeFactories[A] = (f) => new A(f(B), f(C));
  typeFactories[B] = (f) => new B(f(D), f(E));
  typeFactories[C] = (f) => new C();
  typeFactories[D] = (f) => new D();
  typeFactories[E] = (f) => new E();

  new InjectorBenchmark('StaticInjectorBenchmark',
      (m) => new StaticInjector(modules: m, typeFactories: typeFactories)
  ).report();
}