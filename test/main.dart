import 'fixed-unittest.dart';
import 'package:di/di.dart';

// just some classes for testing
class Engine {
  String id = 'v8-id';
}

class MockEngine implements Engine {
  String id = 'mock-id';
}

class Car {
  Engine engine;
  
  Car(Engine e) {
    engine = e;
  }
  
  Engine getValue() {
    return engine;
  }
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


it('should resolve basic dependencies', () {
  var injector = new Injector();
  var instance = injector.get(Car);

  expect(instance, instanceOf(Car));
  expect(instance.getValue().id, toEqual('v8-id'));
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
  expect(complexFromChild.getValue(), toBe(abcFromParent));
  expect(complexFromChild.getValue(), not(toBe(abcFromChild)));
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

}
