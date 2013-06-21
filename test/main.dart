import 'dart:collection';
import 'dart:mirrors';
import 'fixed-unittest.dart';
import 'package:di/di.dart';

// just some classes for testing
class Engine {
  String id = 'v8-id';
}

class MockEngine implements Engine {
  String id = 'mock-id';
}

class MockEngine2 implements Engine {
  String id = 'mock-id-2';
}

class Car {
  Engine engine;
  Injector injector;

  Car(Engine this.engine, Injector this.injector);
}

class NumDependency {
  NumDependency(num value) {}
}

class IntDependency {
  IntDependency(int value) {}
}

class DoubleDependency {
  DoubleDependency(double value) {}
}

class StringDependency {
  StringDependency(String value) {}
}

class BoolDependency {
  BoolDependency(bool value) {}
}


class CircularA {
  CircularA(CircularB b) {}
}

class CircularB {
  CircularB(CircularA a) {}
}

typedef int CompareInt(int a, int b);

int compareIntAsc(int a, int b) {
  if (a == b) {
    return 0;
  }
  if (a < b) {
    return 1;
  }
  return -1;
}

class WithTypeDefDependency {
  CompareInt compare;

  WithTypeDefDependency(CompareInt c) {
    compare = c;
  }
}

// pretend, you don't see this main method
void main() {

it('should instantiate a type', () {
  var injector = new Injector();
  var instance = injector.get(Engine);

  expect(instance, instanceOf(Engine));
  expect(instance.id, toEqual('v8-id'));
});

it('should fail if implicit injection is disabled', () {
  var injector = new Injector([], false);
  expect(() {
    injector.get(Engine);
  }, toThrow(NoProviderException, 'No provider found for Engine! '
                                  '(resolving Engine)'));
});


it('should resolve basic dependencies', () {
  var injector = new Injector();
  var instance = injector.get(Car);

  expect(instance, instanceOf(Car));
  expect(instance.engine.id, toEqual('v8-id'));
});


it('should allow modules and overriding providers', () {
  var module = new Module();
  module.type(Engine, MockEngine);

  // injector is immutable
  // you can't load more modules once it's instantiated
  // (you can create a child injector)
  var injector = new Injector([module]);
  var instance = injector.get(Engine);

  expect(instance.id, toEqual('mock-id'));
});


it('should only create a single instance', () {
  var injector = new Injector();
  var first = injector.get(Engine);
  var second = injector.get(Engine);

  expect(first, toBe(second));
});


it('should allow providing values', () {
  var module = new Module();
  module.value(Engine, 'str value');
  module.value(Car, 123);

  var injector = new Injector([module]);
  var abcInstance = injector.get(Engine);
  var complexInstance = injector.get(Car);

  expect(abcInstance, toEqual('str value'));
  expect(complexInstance, toEqual(123));
});


it('should allow providing factory functions', () {
  var module = new Module();
  module.factory(Engine, () {
    return 'factory-product';
  });

  var injector = new Injector([module]);
  var instance = injector.get(Engine);

  expect(instance, toEqual('factory-product'));
});


it('should inject factory function', () {
  var module = new Module();
  module.factory(Car, (Engine abc) {
    return abc;
  });

  var injector = new Injector([module]);
  var instance = injector.get(Car);

  expect(instance, instanceOf(Engine));
  expect(instance.id, toEqual('v8-id'));
});


it('should throw an exception when injecting a primitive type', () {
  var injector = new Injector();

  expect(() {
    injector.get(NumDependency);
  }, toThrow(NoProviderException, 'Cannot inject a primitive type of num! ' +
                                  '(resolving NumDependency -> num)'));

  expect(() {
    injector.get(IntDependency);
  }, toThrow(NoProviderException, 'Cannot inject a primitive type of int! ' +
                                  '(resolving IntDependency -> int)'));

  expect(() {
    injector.get(DoubleDependency);
  }, toThrow(NoProviderException, 'Cannot inject a primitive type of double! ' +
                                  '(resolving DoubleDependency -> double)'));

  expect(() {
    injector.get(BoolDependency);
  }, toThrow(NoProviderException, 'Cannot inject a primitive type of bool! ' +
                                  '(resolving BoolDependency -> bool)'));

  expect(() {
    injector.get(StringDependency);
  }, toThrow(NoProviderException, 'Cannot inject a primitive type of String! ' +
                                  '(resolving StringDependency -> String)'));
});


it('should throw an exception when circular dependency', () {
  var injector = new Injector();

  expect(() {
    injector.get(CircularA);
  }, toThrow(CircularDependencyException, 'Cannot resolve a circular dependency! ' +
                                          '(resolving CircularA -> CircularB -> CircularA)'));
});


it('should provide the injector as Injector', () {
  var injector = new Injector();

  expect(injector.get(Injector), toBe(injector));
});


it('should inject a typedef', () {
  var module = new Module();
  module.value(CompareInt, compareIntAsc);

  var injector = new Injector([module]);
  var compare = injector.get(CompareInt);

  expect(compare(1, 2), toBe(1));
  expect(compare(5, 2), toBe(-1));
});


it('should throw an exception when injecting typedef without providing it', () {
  var injector = new Injector();

  expect(() {
    injector.get(WithTypeDefDependency);
  }, toThrow(NoProviderException, 'No implementation provided for CompareInt typedef! ' +
                                  '(resolving WithTypeDefDependency -> CompareInt)'));
});


// CHILD INJECTORS
it('should inject from child', () {
  var module = new Module();
  module.type(Engine, MockEngine);

  var parent = new Injector();
  var child = parent.createChild([module]);

  var abcFromParent = parent.get(Engine);
  var abcFromChild = child.get(Engine);

  expect(abcFromParent.id, toEqual('v8-id'));
  expect(abcFromChild.id, toEqual('mock-id'));
});


it('should inject instance from parent if not provided in child', () {
  var module = new Module();
  module.type(Car, Car);

  var parent = new Injector();
  var child = parent.createChild([module]);

  var complexFromParent = parent.get(Car);
  var complexFromChild = child.get(Car);
  var abcFromParent = parent.get(Engine);
  var abcFromChild = child.get(Engine);

  expect(complexFromChild, not(toBe(complexFromParent)));
  expect(abcFromChild, toBe(abcFromParent));
});


it('should inject instance from parent but never use dependency from child', () {
  var module = new Module();
  module.type(Engine, MockEngine);

  var parent = new Injector();
  var child = parent.createChild([module]);

  var complexFromParent = parent.get(Car);
  var complexFromChild = child.get(Car);
  var abcFromParent = parent.get(Engine);
  var abcFromChild = child.get(Engine);

  expect(complexFromChild, toBe(complexFromParent));
  expect(complexFromChild.engine, toBe(abcFromParent));
  expect(complexFromChild.engine, not(toBe(abcFromChild)));
});


it('should force new instance in child even if already instantiated in parent', () {
  var parent = new Injector();
  var abcAlreadyInParent = parent.get(Engine);

  var child = parent.createChild([], [Engine]);
  var abcFromChild = child.get(Engine);

  expect(abcFromChild, not(toBe(abcAlreadyInParent)));
});


it('should force new instance in child using provider from grand parent', () {
  var module = new Module();
  module.type(Engine, MockEngine);

  var grandParent = new Injector([module]);
  var parent = grandParent.createChild([]);
  var child = parent.createChild([], [Engine]);

  var abcFromGrandParent = grandParent.get(Engine);
  var abcFromChild = child.get(Engine);

  expect(abcFromChild.id, toEqual(('mock-id')));
  expect(abcFromChild, not(toBe(abcFromGrandParent)));
});


it('should provide child injector as Injector', () {
  var injector = new Injector();
  var child = injector.createChild([]);

  expect(child.get(Injector), toBe(child));
});

describe('instantiate', () {

  it('should instantiate new instance and cache on in the requesting injector', () {
    var module = new Module();
    module.type(Engine, MockEngine);

    var injector = new Injector([module]);
    var child = injector.createChild([]);

    var engine1 = child.instantiate(Engine);
    var engine2 = child.instantiate(Engine);
    var engine3 = child.get(Engine);
    var engine4 = injector.get(Engine);
    var engine5 = injector.instantiate(Engine);

    expect(engine1, same(engine2));
    expect(engine2, same(engine3));
    expect(engine3, not(same(engine4)));
    expect(engine4, same(engine5));
  });


  it('should override dependencies with locals', () {
    var module = new Module();
    module.type(Engine, MockEngine);

    var injector = new Injector([module]);

    Map<Type, dynamic> locals = new HashMap<Type, dynamic>();
    var localEngine = new MockEngine2();
    locals[Engine] = localEngine;
    var car = injector.instantiate(Car, locals);
    expect(car.engine, same(localEngine));
  });


  it('should ignore locals if value is cached', () {
    var module = new Module();
    module.type(Engine, MockEngine);

    var injector = new Injector([module]);
    var car1 = injector.get(Car);

    Map<Type, dynamic> locals = new HashMap<Type, dynamic>();
    var localEngine = new MockEngine2();
    locals[Engine] = localEngine;
    var car2 = injector.instantiate(Car, locals);
    expect(car2, same(car1));
    expect(car2.engine, not(same(localEngine)));
  });


  it('should inject "locals injector" as a dependency', () {
    var module = new Module()
      ..type(Car, Car)
      ..type(Engine, MockEngine);

    var injector = new Injector([module]);

    Map<Type, dynamic> locals = new HashMap<Type, dynamic>();
    var localEngine = new MockEngine2();
    locals[Engine] = localEngine;
    var car = injector.instantiate(Car, locals);
    expect(car.injector.get(Engine), same(localEngine));
  });

});


describe('creation strategy', () {

  it('should get called for instance creation', () {

    List creationLog = [];
    dynamic creation(Symbol type, Injector requesting, Injector defining,
                     bool directInstantation, Factory factory) {
      creationLog.add([type, requesting, defining, directInstantation]);
      return factory();
    }

    var parentModule = new Module()
      ..type(Engine, MockEngine, creation: creation)
      ..type(Car, Car, creation: creation);

    var parentInjector = new Injector([parentModule]);
    var childInjector = parentInjector.createChild([]);
    childInjector.instantiate(Car);
    expect(creationLog, [
      [reflectClass(Car).simpleName, childInjector, parentInjector, true],
      [reflectClass(Engine).simpleName, childInjector, parentInjector, false]
    ]);
  });

  it('should be able to prevent instantiation in custom conditions', () {

    List creationLog = [];
    dynamic creation(Symbol type, Injector requesting, Injector defining,
                     bool directInstantation, Factory factory) {
      creationLog.add([type, requesting, defining, directInstantation]);
      if (!directInstantation) {
        throw 'not allowing $type unless called injector.intantiate on';
      }
      return factory();
    }

    var module = new Module()
      ..type(Engine, MockEngine, creation: creation);
    var injector = new Injector([module]);
    expect(() {
      injector.get(Engine);
    }, throwsA('not allowing Symbol("Engine") unless called injector.intantiate on'));
    expect(injector.instantiate(Engine), instanceOf(MockEngine));
  });

});

describe('visiblity', () {

  it('should hide instances', () {

    var rootMock = new MockEngine();
    var childMock = new MockEngine();

    var parentModule = new Module()
      ..value(Engine, rootMock);
    var childModule = new Module()
      ..value(Engine, childMock, visibility: (_, __) => false);

    var parentInjector = new Injector([parentModule]);
    var childInjector = parentInjector.createChild([childModule]);

    var val = childInjector.get(Engine);
    expect(val, same(rootMock));
  });

});

}
