import 'fixed-unittest.dart';
import '../lib/di.dart';

// just some classes for testing
class Abc {
  String id = 'abc-id';
  
  void greet() {
    print('HELLO');
  }
}

class MockAbc implements Abc {
  String id = 'mock-id';
  
  void greet() {
    print('MOCK HELLO');
  }
}

class Complex {
  Abc value;
  
  Complex(Abc val) {
    value = val;
  }
  
  dynamic getValue() {
    return value;
  }
}

class NumDependency {
  NumDependency(num value) {}
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

// pretend, you don't see this main method
void main() {
  
it('should instantiate a type', () {
  var injector = new Injector();
  var instance = injector.get(Abc);
  
  expect(instance, instanceOf(Abc));
  expect(instance.id, toEqual('abc-id'));
});


it('should resolve basic dependencies', () {
  var injector = new Injector();
  var instance = injector.get(Complex);

  expect(instance, instanceOf(Complex));
  expect(instance.getValue().id, toEqual('abc-id'));
});


it('should allow modules and overriding providers', () {
  var module = new Module();
  module.type(Abc, MockAbc);
  
  // injector is immutable
  // you can't load more modules once it's instantiated
  // (you can create a child injector)
  var injector = new Injector([module]);
  var instance = injector.get(Abc);
  
  expect(instance.id, toEqual('mock-id'));
});


it('should only create a single instance', () {
  var injector = new Injector();
  var first = injector.get(Abc);
  var second = injector.get(Abc);
  
  expect(first, toBe(second));
});


it('should allow providing values', () {
  var module = new Module();
  module.value(Abc, 'str value');
  module.value(Complex, 123);

  var injector = new Injector([module]);
  var abcInstance = injector.get(Abc);
  var complexInstance = injector.get(Complex);

  expect(abcInstance, toEqual('str value'));
  expect(complexInstance, toEqual(123));
});


it('should allow providing factory functions', () {
  var module = new Module();
  module.factory(Abc, () {
    return 'factory-product';
  });

  var injector = new Injector([module]);
  var instance = injector.get(Abc);

  expect(instance, toEqual('factory-product'));
});


it('should inject factory function', () {
  var module = new Module();
  module.factory(Complex, (Abc abc) {
    return abc;
  });

  var injector = new Injector([module]);
  var instance = injector.get(Complex);

  expect(instance, instanceOf(Abc));
  expect(instance.id, toEqual('abc-id'));
});


it('should throw an exception when injecting a primitive type', () {
  var injector = new Injector();

  expect(() {
    injector.get(NumDependency);
  }, toThrow(NoProviderException, 'Cannot inject a primitive type of num! ' +
                                  '(resolving NumDependency -> num)'));

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


// CHILD INJECTORS
it('should inject from child', () {
  var module = new Module();
  module.type(Abc, MockAbc);

  var parent = new Injector();
  var child = parent.createChild([module]);

  var abcFromParent = parent.get(Abc);
  var abcFromChild = child.get(Abc);

  expect(abcFromParent.id, toEqual('abc-id'));
  expect(abcFromChild.id, toEqual('mock-id'));
});


it('should inject instance from parent if not provided in child', () {
  var module = new Module();
  module.type(Complex, Complex);

  var parent = new Injector();
  var child = parent.createChild([module]);

  var complexFromParent = parent.get(Complex);
  var complexFromChild = child.get(Complex);
  var abcFromParent = parent.get(Abc);
  var abcFromChild = child.get(Abc);

  expect(complexFromChild, not(toBe(complexFromParent)));
  expect(abcFromChild, toBe(abcFromParent));
});


it('should inject instance from parent but never use dependency from child', () {
  var module = new Module();
  module.type(Abc, MockAbc);

  var parent = new Injector();
  var child = parent.createChild([module]);

  var complexFromParent = parent.get(Complex);
  var complexFromChild = child.get(Complex);
  var abcFromParent = parent.get(Abc);
  var abcFromChild = child.get(Abc);

  expect(complexFromChild, toBe(complexFromParent));
  expect(complexFromChild.getValue(), toBe(abcFromParent));
  expect(complexFromChild.getValue(), not(toBe(abcFromChild)));
});


it('should force new instance in child even if already instantiated in parent', () {
  var parent = new Injector();
  var abcAlreadyInParent = parent.get(Abc);

  var child = parent.createChild([], [Abc]);
  var abcFromChild = child.get(Abc);

  expect(abcFromChild, not(toBe(abcAlreadyInParent)));
});


it('should force new instance in child using provider from grand parent', () {
  var module = new Module();
  module.type(Abc, MockAbc);

  var grandParent = new Injector([module]);
  var parent = grandParent.createChild([]);
  var child = parent.createChild([], [Abc]);

  var abcFromGrandParent = grandParent.get(Abc);
  var abcFromChild = child.get(Abc);

  expect(abcFromChild.id, toEqual(('mock-id')));
  expect(abcFromChild, not(toBe(abcFromGrandParent)));
});

}
