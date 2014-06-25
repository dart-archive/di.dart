@Injectables(const [
  ClassOne,
  CircularA,
  CircularB,
  MultipleConstructors,
  NumDependency,
  IntDependency,
  DoubleDependency,
  BoolDependency,
  StringDependency
])
library di.tests;

import 'package:guinness/guinness.dart';
import 'package:matcher/matcher.dart' as matcher;
import 'package:di/di.dart';
import 'package:di/annotations.dart';
import 'package:di/di_static.dart';
import 'package:di/di_dynamic.dart';

import 'test_annotations.dart';
// Generated file. Run ../test_tf_gen.sh.
import 'type_factories_gen.dart' as type_factories_gen;

import 'dart:mirrors';

/**
 * Annotation used to mark classes for which static type factory must be
 * generated. For testing purposes not all classes are marked with this
 * annotation, some classes are included in @Injectables at the top.
 */
class InjectableTest {
  const InjectableTest();
}

// just some classes for testing
@InjectableTest()
class Engine {
  final String id = 'v8-id';
}

@Injectable()
class MockEngine implements Engine {
  final String id = 'mock-id';
}

@InjectableTest()
class MockEngine2 implements Engine {
  String id = 'mock-id-2';
}

// this class should only be used in a single test (dynamic implicit injection)
@InjectableTest()
class SpecialEngine implements Engine {
  String id = 'special-id';
}

class HiddenConstructor {
  HiddenConstructor._();
}

@InjectableTest()
class TurboEngine implements Engine {
  String id = 'turbo-engine-id';
}

@InjectableTest()
class BrokenOldEngine implements Engine {
  String id = 'broken-old-engine-id';
}

@InjectableTest()
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

@InjectableTest()
class Porsche {
  Engine engine;
  Injector injector;

  Porsche(@Turbo() this.engine, this.injector);
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

@InjectableTest()
class ParameterizedType<T1, T2> {
  ParameterizedType();
}

@InjectableTest()
class ParameterizedDependency {
  final ParameterizedType<bool, int> _p;
  ParameterizedDependency(this._p);
}

@InjectableTest()
class GenericParameterizedDependency {
  final ParameterizedType _p;
  GenericParameterizedDependency(this._p);
}

@InjectableTest()
class Log {
  var log = [];

  add(String message) => log.add(message);
}

@InjectableTest()
class AnnotatedPrimitiveDependency {
  String strValue;
  AnnotatedPrimitiveDependency(@Turbo() this.strValue);
}

class EmulatedMockEngineFactory {
  call() => new MockEngine();
}

bool throwOnceShouldThrow = true;
@InjectableTest()
class ThrowOnce {
  ThrowOnce() {
    if (throwOnceShouldThrow) {
      throwOnceShouldThrow = false;
      throw ["ThrowOnce"];
    }
  }
}

void main() {
  moduleTest();

  new GeneratedTypeFactories(
      type_factories_gen.typeFactories, type_factories_gen.parameterKeys);
  createInjectorSpec('Static ModuleInjector ',
      (modules, [name]) => new ModuleInjector(modules),
      () => new Module.withReflector(new GeneratedTypeFactories()));

  TypeReflector reflector = new DynamicTypeFactories();
  createInjectorSpec('Dynamic ModuleInjector ',
      (modules, [name]) => new ModuleInjector(modules),
      () => new Module.withReflector(reflector));

  createKeySpec();
}

moduleTest() {

  describe('Module', () {

    const BIND_ERROR = 'Only one of following parameters can be specified: '
                       'toValue, toFactory, toFactoryPos, toImplementation';

    describe('bind', () {

      it('should throw if incorrect combination of parameters passed (1)', () {
        expect(() {
          new Module().bind(Engine, toValue: new Engine(), toImplementation: MockEngine);
        }).toThrowWith(message: BIND_ERROR);
      });

      it('should throw if incorrect combination of parameters passed (2)', () {
        expect(() {
          new Module().bind(Engine, toValue: new Engine(), toFactory: () => null);
        }).toThrowWith(message: BIND_ERROR);
      });

      it('should throw if incorrect combination of parameters passed (3)', () {
        expect(() {
          new Module().bind(Engine, toValue: new Engine(), toImplementation: MockEngine, toFactory: () => null);
        }).toThrowWith(message: BIND_ERROR);
      });

      it('should throw if incorrect combination of parameters passed (4)', () {
        expect(() {
          new Module().bind(Engine, toImplementation: MockEngine, toFactory: () => null);
        }).toThrowWith(message: BIND_ERROR);
      });

    });

  });
}

typedef Injector InjectorFactory(List<Module> modules, [String name]);
typedef Module ModuleFactory();

createInjectorSpec(String injectorName, InjectorFactory injectorFactory, 
                   ModuleFactory moduleFactory) {

  describe(injectorName, () {

    it('should instantiate a type', () {
      var injector = injectorFactory([moduleFactory()..bind(Engine)]);
      var instance = injector.get(Engine);

      expect(instance).toBeAnInstanceOf(Engine);
      expect(instance.id).toEqual('v8-id');
    });

    it('should instantiate an annotated type', () {
      var injector = injectorFactory([moduleFactory()
          ..bind(Engine, withAnnotation: Turbo, toImplementation: TurboEngine)
          ..bind(Car, toValue: new Engine())
      ]);
      var instance = injector.getByKey(new Key(Engine, Turbo));

      expect(instance).toBeAnInstanceOf(TurboEngine);
      expect(instance.id).toEqual('turbo-engine-id');
    });

    it('should fail if no binding is found', () {
      var injector = injectorFactory([moduleFactory()..bind(Car)]);
      expect(() {
        injector.get(Car);
      }).toThrowWith(message: 'No provider found for Engine! '
                              '(resolving Car -> Engine)');
    });


    it('should resolve basic dependencies', () {
      var injector = injectorFactory([
          moduleFactory()
              ..bind(Car)
              ..bind(Engine)
      ]);
      var instance = injector.get(Car);

      expect(instance).toBeAnInstanceOf(Car);
      expect(instance.engine.id).toEqual('v8-id');
    });

    it('should resolve complex dependencies', () {
      var injector = injectorFactory([moduleFactory()
            ..bind(Porsche)
            ..bind(TurboEngine)
            ..bind(Engine, withAnnotation: Turbo, toImplementation: TurboEngine)
      ]);
      var instance = injector.get(Porsche);

      expect(instance).toBeAnInstanceOf(Porsche);
      expect(instance.engine.id).toEqual('turbo-engine-id');
    });

    it('should resolve annotated primitive type', () {
      var injector = injectorFactory([moduleFactory()
            ..bind(AnnotatedPrimitiveDependency)
            ..bind(String, toValue: 'Worked!', withAnnotation: Turbo)
      ]);
      var instance = injector.get(AnnotatedPrimitiveDependency);

      expect(instance).toBeAnInstanceOf(AnnotatedPrimitiveDependency);
      expect(instance.strValue).toEqual('Worked!');
    });

    it('should inject generic parameterized types', () {
      var injector = injectorFactory([moduleFactory()
            ..bind(ParameterizedType)
            ..bind(GenericParameterizedDependency)
      ]);
      expect(injector.get(GenericParameterizedDependency))
          .toBeAnInstanceOf(GenericParameterizedDependency);
    });


    it('should error while resolving parameterized types', () {
      expect((){
        var injector = injectorFactory([moduleFactory()
          ..bind(ParameterizedType)
          ..bind(ParameterizedDependency)
        ]);
        injector.get(ParameterizedDependency);
      }).toThrowWith();
    });


    it('should allow modules and overriding providers', () {
      var module = moduleFactory()..bind(Engine, toImplementation: MockEngine);

      // injector is immutable
      // you can't load more modules once it's instantiated
      // (you can create a child injector)
      var injector = injectorFactory([module]);
      var instance = injector.get(Engine);

      expect(instance.id).toEqual('mock-id');
    });


    it('should only create a single instance', () {
      var injector = injectorFactory([moduleFactory()..bind(Engine)]);
      var first = injector.get(Engine);
      var second = injector.get(Engine);

      expect(first).toBe(second);
    });


    it('should allow providing values', () {
      var module = moduleFactory()
        ..bind(Engine, toValue: 'str value')
        ..bind(Car, toValue: 123);

      var injector = injectorFactory([module]);
      var abcInstance = injector.get(Engine);
      var complexInstance = injector.get(Car);

      expect(abcInstance).toEqual('str value');
      expect(complexInstance).toEqual(123);
    });


    it('should allow providing null values', () {
      var module = moduleFactory()
        ..bind(Engine, toValue: null);

      var injector = injectorFactory([module]);
      var engineInstance = injector.get(Engine);

      expect(engineInstance).toBeNull();
    });


    it('should allow providing factory functions', () {
      var module = moduleFactory()..bind(Engine, toFactory: () {
        return 'factory-product';
      });

      var injector = injectorFactory([module]);
      var instance = injector.get(Engine);

      expect(instance).toEqual('factory-product');
    });


    it('should allow providing with emulated factory functions', () {
      var module = moduleFactory();
      module.bind(Engine, toFactory: new EmulatedMockEngineFactory());

      var injector = injectorFactory([module]);
      var instance = injector.get(Engine);

      expect(instance).toBeAnInstanceOf(MockEngine);
    });


    it('should inject injector into factory function', () {
      var module = moduleFactory()
        ..bind(Engine)
        ..bind(Car, toFactory: (Engine engine, Injector injector) {
          return new Car(engine, injector);
        }, inject: [Engine, Injector]);

      var injector = injectorFactory([module]);
      var instance = injector.get(Car);

      expect(instance).toBeAnInstanceOf(Car);
      expect(instance.engine.id).toEqual('v8-id');
    });


    it('should throw an exception when injecting a primitive type', () {
      var injector = injectorFactory([
        moduleFactory()
          ..bind(NumDependency)
          ..bind(IntDependency)
          ..bind(DoubleDependency)
          ..bind(BoolDependency)
          ..bind(StringDependency)
      ]);

      expect(() {
        injector.get(NumDependency);
      }).toThrowWith(
          anInstanceOf: NoProviderError,
          message: 'Cannot inject a primitive type of num! '
                   '(resolving NumDependency -> num)');

      expect(() {
        injector.get(IntDependency);
      }).toThrowWith(
          anInstanceOf: NoProviderError,
          message: 'Cannot inject a primitive type of int! '
                   '(resolving IntDependency -> int)');

      expect(() {
        injector.get(DoubleDependency);
      }).toThrowWith(
          anInstanceOf: NoProviderError,
          message: 'Cannot inject a primitive type of double! '
                   '(resolving DoubleDependency -> double)');

      expect(() {
        injector.get(BoolDependency);
      }).toThrowWith(
          anInstanceOf: NoProviderError,
          message: 'Cannot inject a primitive type of bool! '
                   '(resolving BoolDependency -> bool)');

      expect(() {
        injector.get(StringDependency);
      }).toThrowWith(
          anInstanceOf: NoProviderError,
          message: 'Cannot inject a primitive type of String! '
                   '(resolving StringDependency -> String)');
    });


    it('should throw an exception when circular dependency', () {
      var injector = injectorFactory([moduleFactory()..bind(CircularA)
                                        ..bind(CircularB)]);

      expect(() {
        injector.get(CircularA);
      }).toThrowWith(
          anInstanceOf: CircularDependencyError,
          message: 'Cannot resolve a circular dependency! '
                   '(resolving CircularA -> CircularB -> CircularA)');
    });

    it('should throw an exception when circular dependency in factory', () {
      var injector = injectorFactory([moduleFactory()
          ..bind(CircularA, inject: [CircularA])
      ]);

      expect(() {
        injector.get(CircularA);
      }).toThrowWith(
          anInstanceOf: CircularDependencyError,
          message: 'Cannot resolve a circular dependency! '
                   '(resolving CircularA -> CircularA)');
    });


    it('should recover from errors', () {
      var injector = injectorFactory([moduleFactory()..bind(ThrowOnce)]);
      throwOnceShouldThrow = true;

      var caught = false;
      try {
        injector.get(ThrowOnce);
      } catch (e, s) {
        caught = true;
        expect(injector.get(ThrowOnce)).toBeDefined();
      }
      expect(caught).toEqual(true);
    });


    it('should provide the injector as Injector', () {
      var injector = injectorFactory([]);

      expect(injector.get(Injector)).toBe(injector);
    });


    it('should inject a typedef', () {
      var module = moduleFactory()..bind(CompareInt, toValue: compareIntAsc);

      var injector = injectorFactory([module]);
      var compare = injector.get(CompareInt);

      expect(compare(1, 2)).toEqual(1);
      expect(compare(5, 2)).toEqual(-1);
    });


    it('should throw an exception when injecting typedef without providing it', () {
      expect(() {
        var injector = injectorFactory([moduleFactory()..bind(WithTypeDefDependency)]);
        injector.get(WithTypeDefDependency);
      }).toThrowWith();
    });


    it('should instantiate via the default/unnamed constructor', () {
      var injector = injectorFactory([moduleFactory()..bind(MultipleConstructors)]);
      MultipleConstructors instance = injector.get(MultipleConstructors);
      expect(instance.instantiatedVia).toEqual('default');
    });

    // CHILD INJECTORS
    it('should inject from child', () {
      var module = moduleFactory()..bind(Engine, toImplementation: MockEngine);

      var parent = injectorFactory([moduleFactory()..bind(Engine)]);
      var child = parent.createChild([module]);

      var abcFromParent = parent.get(Engine);
      var abcFromChild = child.get(Engine);

      expect(abcFromParent.id).toEqual('v8-id');
      expect(abcFromChild.id).toEqual('mock-id');
    });


    it('should enumerate across children', () {
      var parent = injectorFactory([moduleFactory()..bind(Engine)]);
      var child = parent.createChild([moduleFactory()..bind(MockEngine)]);

      expect(parent.types).to(matcher.unorderedEquals([Engine, Injector]));
      expect(child.types).to(matcher.unorderedEquals([Engine, MockEngine, Injector]));
    });


    it('should inject instance from parent if not provided in child', () {
      var module = moduleFactory()..bind(Car);

      var parent = injectorFactory([moduleFactory()..bind(Car)..bind(Engine)]);
      var child = parent.createChild([module]);

      var complexFromParent = parent.get(Car);
      var complexFromChild = child.get(Car);
      var abcFromParent = parent.get(Engine);
      var abcFromChild = child.get(Engine);

      expect(complexFromChild).not.toBe(complexFromParent);
      expect(abcFromChild).toBe(abcFromParent);
    });


    it('should inject instance from parent but never use dependency from child', () {
      var module = moduleFactory()..bind(Engine, toImplementation: MockEngine);

      var parent = injectorFactory([moduleFactory()..bind(Car)..bind(Engine)]);
      var child = parent.createChild([module]);

      var complexFromParent = parent.get(Car);
      var complexFromChild = child.get(Car);
      var abcFromParent = parent.get(Engine);
      var abcFromChild = child.get(Engine);

      expect(complexFromChild).toBe(complexFromParent);
      expect(complexFromChild.engine).toBe(abcFromParent);
      expect(complexFromChild.engine).not.toBe(abcFromChild);
    });


    it('should provide child injector as Injector', () {
      var injector = injectorFactory([]);
      var child = injector.createChild([]);

      expect(child.get(Injector)).toBe(child);
    });


    it('should instantiate class only once (Issue #18)', () {
      var rootInjector = injectorFactory([]);
      var injector = rootInjector.createChild([
          moduleFactory()
            ..bind(Log)
            ..bind(ClassOne)
            ..bind(InterfaceOne, inject: [ClassOne])
      ]);

      expect(injector.get(InterfaceOne)).toBe(injector.get(ClassOne));
      expect(injector.get(Log).log.join(' ')).toEqual('ClassOne');
    });
  });
}


createKeySpec() {
  describe('Key', () {
    void expectEquals(x, y, bool truthValue) {
      expect(x == y).toEqual(truthValue);
      expect(identical(x, y)).toEqual(truthValue);
      if (truthValue == true) expect(x.hashCode).toEqual(y.hashCode);
    }

    it('should be equal to another key if type is the same', () {
      expectEquals(new Key(Car), new Key(Car), true);
    });

    it('should be equal to another key if type and annotation are the same', () {
      expectEquals(new Key(Car, Turbo), new Key(Car, Turbo), true);
    });

    it('should not be equal to another key where type and annotation are same '
        'but reversed', () {
      expectEquals(new Key(Car, Turbo), new Key(Turbo, Car), false);
    });

    it('should not be equal to another key if types are different', () {
      expectEquals(new Key(Car), new Key(Porsche), false);
    });

    it('should not be equal to another key if annotations are different', () {
      expectEquals(new Key(Car, Turbo), new Key(Car, Old), false);
    });

    it('should not be equal to another key if type is different and annotation'
        ' is same', () {
      expectEquals(new Key(Engine, Old), new Key(Car, Old), false);
    });

    it('should be equal to a mirrored key of the same type', () {
      ClassMirror classMirror = reflectType(Car);
      MethodMirror ctor = classMirror.declarations[classMirror.simpleName];

      ParameterMirror p = ctor.parameters[0];
      var pType = (p.type as ClassMirror).reflectedType;

      expectEquals(new Key(Engine), new Key(pType), true);
    });
  });
}
