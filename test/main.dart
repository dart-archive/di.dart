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

}
