import 'package:di/static_injector.dart';
import 'package:di/src/base_injector.dart';
import 'package:di/src/provider.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

import 'injector_benchmark_common.dart';
import 'static_injector_benchmark.dart';

class TestInjector {
  const TestInjector();
}

/**
 * This benchmark creates the same objects as the StaticInjectorBenchmark
 * without using DI, to serve as a baseline for comparison.
 */
class CreateObjectsOnly extends BenchmarkBase{
  CreateObjectsOnly(name) : super(name);

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

  void teardown() {
    print(count);
  }
}

class CreateSingleInjector extends InjectorBenchmark {

  CreateSingleInjector(name, injectorFactory) : super(name, injectorFactory);

  void run() {
    Injector injector = injectorFactory([module]);

    var b1 = new B(new D(), new E());
    var c1 = new C();
    var d1 = new D();
    var e1 = new E();

    var a = new A(b1, c1);
    var b = new B(d1, e1);

    var c = new A(b1, c1);
    var d = new B(d1, e1);
  }
}

class CreateInjectorAndChild extends InjectorBenchmark {

  CreateInjectorAndChild(name, injectorFactory) : super(name, injectorFactory);

  void run() {
    Injector injector = injectorFactory([module]);
    var childInjector = injector.createChild([module]);

    var b1 = new B(new D(), new E());
    var c1 = new C();
    var d1 = new D();
    var e1 = new E();

    var a = new A(b1, c1);
    var b = new B(d1, e1);

    var c = new A(b1, c1);
    var d = new B(d1, e1);
  }
}

@TestInjector()
class BasicInjector {
  Map<Type, TypeFactory> typeFactories;
  BasicInjector parent;

  Map<Type, Object> instances = new Map();

  BasicInjector(modules, this.typeFactories, [this.parent]);

  Object getFromParent(Type type) {
    var injector = this;
    var instance;
    do {
      if (injector.parent == null) {
        return newInstanceOf(type);
      }
      injector = injector.parent;
      instance = injector.instances[type];
    } while (instance == null);
    return instance;
  }

  Object newInstanceOf(type) {
    var instance = typeFactories[type]((t){
      var inst = instances[type];
      if (inst == null){
        inst = getFromParent(t);
      }
      return inst;
    });
    instances[type] = instance;
    return instance;
  }

  Object getByKey(Key key) {
    Type type = key.type;
    var instance = instances[type];
    if (instance == null){
      instance = newInstanceOf(type);
    }
    return instance;
  }

  BasicInjector createChild(modules) => new BasicInjector(modules, typeFactories, this);
}

@TestInjector()
class ModifiedStaticInjector extends StaticInjector {

  ModifiedStaticInjector(m, typeFactories)
    : super(modules: m, typeFactories: typeFactories);

  @override
  Object getInstanceByKey(key, requester, resolving) {
    get(type) => typeFactories[type](get);
    return get(key.type);
  }
}
/**
 * creates a new instance every time
 */
class GetInstanceFromProvider extends InjectByKey {

  GetInstanceFromProvider(name, injectorFactory) : super(name, injectorFactory);

  void run() {
    ModifiedStaticInjector injector = injectorFactory([module]);
    injector.getByKey(KEY_A);
    injector.getByKey(KEY_B);

    ModifiedStaticInjector childInjector = injector.createChild([module]);
    childInjector.getByKey(KEY_A);
    childInjector.getByKey(KEY_B);
  }
}

class InjectByKey extends InjectorBenchmark {
  final Key KEY_A;
  final Key KEY_B;

  InjectByKey(name, injectorFactory)
    : super(name, injectorFactory),
      KEY_A = new Key(A),
      KEY_B = new Key(B);

  void run() {
    var injector = injectorFactory([module]);
    injector.getByKey(KEY_A);
    injector.getByKey(KEY_B);

    var childInjector = injector.createChild([module]);
    childInjector.getByKey(KEY_A);
    childInjector.getByKey(KEY_B);
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

  const PAD_LENGTH = 35;
  Function injectorFactory = (m) => new StaticInjector(modules: m, typeFactories: typeFactories);

  new CreateObjectsOnly("Create objects manually without DI".padRight(PAD_LENGTH)).report();
  new CreateSingleInjector('.. and create an injector'.padRight(PAD_LENGTH),
      injectorFactory
  ).report();
  new CreateInjectorAndChild('.. and a child injector'.padRight(PAD_LENGTH),
      (m) => new StaticInjector(modules: m, typeFactories: typeFactories)
  ).report();
  new InjectorBenchmark('DI using StaticInjector'.padRight(PAD_LENGTH),
  injectorFactory
  ).report();
  new InjectByKey('.. and precompute keys'.padRight(PAD_LENGTH),
      injectorFactory
  ).report();
  new GetInstanceFromProvider('.. and always create a new instance'.padRight(PAD_LENGTH),
      (m) => new ModifiedStaticInjector(m, typeFactories)
  ).report();
  new InjectByKey('DI using BasicInjector'.padRight(PAD_LENGTH),
      (m) => new BasicInjector(m, typeFactories)
  ).report();
}
