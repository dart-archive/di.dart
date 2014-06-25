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
      ..type(A)
      ..type(B)
      ..type(C)
      ..type(C, withAnnotation: AnnOne, implementedBy: COne )
      ..type(D)
      ..type(E)
      ..type(E, withAnnotation: AnnTwo, implementedBy: ETwo )
      ..type(F)
      ..type(G);
  
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
    A: (p) => new A(p[0], p[1]),
    B: (p) => new B(p[0], p[1]),
    C: (p) => new C(),
    D: (p) => new D(),
    E: (p) => new E(),
    COne: (p) => new COne(),
    ETwo: (p) => new ETwo(),
    F: (p) => new F(p[0], p[1]),
    G: (p) => new G(p[0]),
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
