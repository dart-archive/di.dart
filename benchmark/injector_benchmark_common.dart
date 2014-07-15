library di.injector_benchmark_common;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';

int count = 0;

class InjectorBenchmark extends BenchmarkBase {
  var module;
  var injectorFactory;
  Key KEY_A;
  Key KEY_B;
  Key KEY_C;
  Key KEY_D;
  Key KEY_E;

  InjectorBenchmark(name, this.injectorFactory) : super(name);

  void run() {
    Injector injector = injectorFactory([module]);
    injector.getByKey(KEY_A);
    injector.getByKey(KEY_B);

    var childInjector = injector.createChild([module]);
    childInjector.getByKey(KEY_A);
    childInjector.getByKey(KEY_B);
  }

  setup() {
    module = new Module()
      ..bind(A)
      ..bind(B)
      ..bind(C)
      ..bind(C, withAnnotation: AnnOne, toImplementation: COne )
      ..bind(D)
      ..bind(E)
      ..bind(E, withAnnotation: AnnTwo, toImplementation: ETwo )
      ..bind(F)
      ..bind(G);

    KEY_A = new Key(A);
    KEY_B = new Key(B);
    KEY_C = new Key(C);
    KEY_D = new Key(D);
    KEY_E = new Key(E);
  }

  teardown() {
    print(count);
  }
}

class AnnOne {
  const AnnOne();
}

class AnnTwo {
  const AnnTwo();
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

class COne {
  COne() {
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

class ETwo {
  ETwo() {
    count++;
  }
}

class F {
  F(@AnnOne() C c, D d) {
    count++;
  }
}

class G {
  G(@AnnTwo() E e) {
    count++;
  }
}

var typeFactories = {
    A: (f) => new A(f(B), f(C)),
    B: (f) => new B(f(D), f(E)),
    C: (f) => new C(),
    D: (f) => new D(),
    E: (f) => new E(),
    COne: (f) => new COne(),
    ETwo: (f) => new ETwo(),
    F: (f) => new F(f(C), f(D)),
    G: (f) => new G(f(E)),
};
