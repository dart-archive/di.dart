library di.tests;

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

class MultipleConstructors {
  String instantiatedVia;
  MultipleConstructors() : instantiatedVia = 'default';
  MultipleConstructors.named() : instantiatedVia = 'named';
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
  }, toThrow(NoProviderError, 'No provider found for di.tests.Engine! '
                                  '(resolving di.tests.Engine)'));
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
  }, toThrow(NoProviderError, 'Cannot inject a primitive type of dart.core.num! '
                              '(resolving di.tests.NumDependency -> dart.core.num)'));

  expect(() {
    injector.get(IntDependency);
  }, toThrow(NoProviderError, 'Cannot inject a primitive type of dart.core.int! '
                              '(resolving di.tests.IntDependency -> dart.core.int)'));

  expect(() {
    injector.get(DoubleDependency);
  }, toThrow(NoProviderError, 'Cannot inject a primitive type of dart.core.double! '
                              '(resolving di.tests.DoubleDependency -> dart.core.double)'));

  expect(() {
    injector.get(BoolDependency);
  }, toThrow(NoProviderError, 'Cannot inject a primitive type of dart.core.bool! '
                              '(resolving di.tests.BoolDependency -> dart.core.bool)'));

  expect(() {
    injector.get(StringDependency);
  }, toThrow(NoProviderError, 'Cannot inject a primitive type of dart.core.String! '
                              '(resolving di.tests.StringDependency -> dart.core.String)'));
});


it('should throw an exception when circular dependency', () {
  var injector = new Injector();

  expect(() {
    injector.get(CircularA);
  }, toThrow(CircularDependencyError, 'Cannot resolve a circular dependency! '
                                      '(resolving di.tests.CircularA -> '
                                      'di.tests.CircularB -> di.tests.CircularA)'));
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
  }, toThrow(NoProviderError, 'No implementation provided for di.tests.CompareInt typedef! '
                              '(resolving di.tests.WithTypeDefDependency -> di.tests.CompareInt)'));
});


it('should instantiate via the default/unnamed constructor', () {
  var injector = new Injector();
  MultipleConstructors instance = injector.get(MultipleConstructors);
  expect(instance.instantiatedVia, 'default');
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


describe('creation strategy', () {

  it('should get called for instance creation', () {

    List creationLog = [];
    dynamic creation(Symbol type, Injector requesting, Injector defining,
                     Factory factory) {
      creationLog.add([type, requesting, defining]);
      return factory();
    }

    var parentModule = new Module()
      ..type(Engine, MockEngine, creation: creation)
      ..type(Car, Car, creation: creation);

    var parentInjector = new Injector([parentModule]);
    var childInjector = parentInjector.createChild([]);
    childInjector.get(Car);
    expect(creationLog, [
      [reflectClass(Car).qualifiedName, childInjector, parentInjector],
      [reflectClass(Engine).qualifiedName, childInjector, parentInjector]
    ]);
  });

  it('should be able to prevent instantiation', () {

    List creationLog = [];
    dynamic creation(Symbol type, Injector requesting, Injector defining,
                     Factory factory) {
      creationLog.add([type, requesting, defining]);
      throw 'not allowing $type';
    }

    var module = new Module()
      ..type(Engine, MockEngine, creation: creation);
    var injector = new Injector([module]);
    expect(() {
      injector.get(Engine);
    }, throwsA('not allowing Symbol("di.tests.Engine")'));
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
