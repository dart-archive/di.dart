library di.injector_benchmark_common;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:di/di.dart';

int count = 0;

class InjectorBenchmark extends BenchmarkBase {
  var module;
  var typeReflector;
  Key KEY_A;
  Key KEY_B;
  Key KEY_C;
  Key KEY_D;
  Key KEY_E;

  InjectorBenchmark(name, this.typeReflector) : super(name);

  void run() {
    Injector injector = new ModuleInjector([module]);
    injector.getByKey(KEY_A);
    injector.getByKey(KEY_B);

    var childInjector = new ModuleInjector([module], injector);
    childInjector.getByKey(KEY_A);
    childInjector.getByKey(KEY_B);
  }

  setup() {
    module = new Module.withReflector(typeReflector)
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
    A: (a1, a2) => new A(a1, a2),
    B: (a1, a2) => new B(a1, a2),
    C: () => new C(),
    D: () => new D(),
    E: () => new E(),
    COne: () => new COne(),
    ETwo: () => new ETwo(),
    F: (a1, a2) => new F(a1, a2),
    G: (a1) => new G(a1),
};

var paramKeys = {
    A: [new Key(B), new Key(C)],
    B: [new Key(D), new Key(E)],
    C: const [],
    D: const [],
    E: const [],
    COne: const [],
    ETwo: const [],
    F: [new Key(C, AnnOne), new Key(D)],
    G: [new Key(G, AnnTwo)],
};
