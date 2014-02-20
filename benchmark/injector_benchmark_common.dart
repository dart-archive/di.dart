library di.injector_benchmark_common;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';

int count = 0;

class IdealizedInjectorBenchmark extends BenchmarkBase {
  IdealizedInjectorBenchmark(name, emitter) : super(name, emitter: emitter);

  void run() {
    new A(new B(new D(), new E()), new C());
    new B(new D(), new E());
  }
}

class InjectorBenchmark extends BenchmarkBase {
  var injectorFactory;
  var module;

  InjectorBenchmark(name, this.injectorFactory, ScoreEmitter emitter) : super(name, emitter: emitter);

  void run() {
    Injector injector = injectorFactory([module]);
    injector.get(A);
    injector.get(B);

    var childInjector = injector.createChild([module]);
    childInjector.get(A);
    childInjector.get(B);
  }

  setup() {
    module = new Module()
      ..type(A)
      ..type(B)
      ..type(C)
      ..type(D)
      ..type(E);
  }

  teardown() { }
}

class A {
  A(B b, C c) {
    count++;
  }
}

class B {
  B(D b, E c) {
    count++;
  }
}

class C {
  C() {
    count++;
  }
}

class D {
  D() {
    count++;
  }
}

class E {
  E() {
    count++;
  }
}
