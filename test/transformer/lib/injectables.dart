library di_test.injectables;

import 'package:di/di.dart';

/**
 * Annotation used to mark classes for which static type factory must be
 * generated. For testing purposes not all classes are marked with this
 * annotation, some classes are included in @Injectables at the top.
 */
class Injectable {
  const Injectable();
}

// just some classes for testing
@Injectable()
class Engine {
  final String id = 'v8-id';
}

@Injectable()
class MockEngine implements Engine {
  final String id = 'mock-id';
}

@Injectable()
class MockEngine2 implements Engine {
  String id = 'mock-id-2';
}

class HiddenConstructor {
  HiddenConstructor._();
}

@Injectable()
class Car {
  Engine engine;
  Injector injector;

  Car(this.engine, this.injector);
}

class Lemon {
  final engine;
  final Injector injector;

  Lemon(this.engine, this.injector);
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

int compareIntAsc(int a, int b) => b.compareTo(a);

class WithTypeDefDependency {
  CompareInt compare;

  WithTypeDefDependency(this.compare);
}

class MultipleConstructors {
  String instantiatedVia;
  MultipleConstructors() : instantiatedVia = 'default';
  MultipleConstructors.named() : instantiatedVia = 'named';
}

class InterfaceOne {
}

class ClassOne implements InterfaceOne {
  ClassOne(Log log) {
    log.add('ClassOne');
  }
}

@Injectable()
class ParameterizedType<T1, T2> {
  ParameterizedType();
}

@Injectable()
class ParameterizedDependency {
  final ParameterizedType<bool, int> _p;
  ParameterizedDependency(this._p);
}

@Injectable()
class GenericParameterizedDependency {
  final ParameterizedType _p;
  GenericParameterizedDependency(this._p);
}

@Injectable()
class Log {
  var log = [];

  add(String message) => log.add(message);
}

class EmulatedMockEngineFactory {
  call(Injector i) => new MockEngine();
}
