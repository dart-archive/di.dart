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
import 'package:di/src/reflector_static.dart';
import 'package:di/src/reflector_dynamic.dart';
import 'package:di/check_bind_args.dart';
import 'package:di/src/module.dart';

import 'test_annotations.dart';
// Generated file. Run ../test_tf_gen.sh.
import 'type_factories_gen.dart' as type_factories_gen;
import 'main_same_name.dart' as same_name;

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

@Injectable()
class SameEngine {
  same_name.Engine engine;
  SameEngine(this.engine);
}


const String STATIC_NAME = 'Static ModuleInjector';
const String DYNAMIC_NAME = 'Dynamic ModuleInjector';
void main() {
  testModule();

  var static_factory = new GeneratedTypeFactories(
      type_factories_gen.typeFactories, type_factories_gen.parameterKeys);
  createInjectorSpec(STATIC_NAME,
      () => new Module.withReflector(static_factory));

  TypeReflector reflector = new DynamicTypeFactories();
  createInjectorSpec(DYNAMIC_NAME,
      () => new Module.withReflector(reflector));

  testKey();
  testCheckBindArgs();
}

testModule() {

  describe('Module', () {

    const BIND_ERROR = 'Only one of following parameters can be specified: '
                       'toValue, toFactory, toImplementation, toInstanceOf';

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

      it('should throw when trying to bind primitive type', () {
        expect(() {
          new Module().bind(int, toValue: 3);
        }).toThrowWith(message: "Cannot bind primitive type 'int'.");
      });

      it('should accept a Type as toInstanceOf parameter', () {
        expect(() {
          new Module().bind(Engine, toInstanceOf: MockEngine);
        }).not.toThrow();
      });

      it('should accept a Key as toInstanceOf parameter', () {
        expect(() {
          new Module().bind(Engine, toInstanceOf: key(MockEngine));
        }).not.toThrow();

      });
    });

  });
}

typedef Module ModuleFactory();

createInjectorSpec(String injectorName, ModuleFactory moduleFactory) {

  describe(injectorName, () {

    it('should instantiate a type', () {
      var module = moduleFactory()..bind(Engine);
      var injector = new ModuleInjector([module]);
      var instance = injector.get(Engine);

      expect(instance).toBeAnInstanceOf(Engine);
      expect(instance.id).toEqual('v8-id');
    });

    it('should instantiate an annotated type', () {
      var injector = new ModuleInjector([moduleFactory()
          ..bind(Engine, withAnnotation: Turbo, toImplementation: TurboEngine)
          ..bind(Car, toValue: new Engine())
      ]);
      var instance = injector.getByKey(new Key(Engine, Turbo));

      expect(instance).toBeAnInstanceOf(TurboEngine);
      expect(instance.id).toEqual('turbo-engine-id');
    });

    it('should fail if the type was not bound at injector creation', () {
      var module = moduleFactory();
      var injector = new ModuleInjector([module]);
      module.bind(Engine);

      expect(() {
        injector.get(Engine);
      }).toThrowWith(message: 'No provider found for Engine! '
          '(resolving Engine)');
    });

    it('should fail if no binding is found resolving dependencies', () {
      var injector = new ModuleInjector([moduleFactory()..bind(Car)]);
      expect(() {
        injector.get(Car);
      }).toThrowWith(message: 'No provider found for Engine! '
                              '(resolving Car -> Engine)');
    });

    it('should resolve basic dependencies', () {
      var injector = new ModuleInjector([
          moduleFactory()
              ..bind(Car)
              ..bind(Engine)
      ]);
      var instance = injector.get(Car);

      expect(instance).toBeAnInstanceOf(Car);
      expect(instance.engine.id).toEqual('v8-id');
    });

    it('should resolve complex dependencies', () {
      var injector = new ModuleInjector([moduleFactory()
          ..bind(Porsche)
          ..bind(TurboEngine)
          ..bind(Engine, withAnnotation: Turbo, toImplementation: TurboEngine)
      ]);
      var instance = injector.get(Porsche);

      expect(instance).toBeAnInstanceOf(Porsche);
      expect(instance.engine.id).toEqual('turbo-engine-id');
    });

    it('should resolve annotated primitive type', () {
      var injector = new ModuleInjector([moduleFactory()
          ..bind(AnnotatedPrimitiveDependency)
          ..bind(String, toValue: 'Worked!', withAnnotation: Turbo)
      ]);
      var instance = injector.get(AnnotatedPrimitiveDependency);

      expect(instance).toBeAnInstanceOf(AnnotatedPrimitiveDependency);
      expect(instance.strValue).toEqual('Worked!');
    });

    it('should instantiate parameterized types', () {
      var module = moduleFactory()..bind(ParameterizedType);
      var injector = new ModuleInjector([module]);
      expect(injector.get(ParameterizedType)).toBeAnInstanceOf(ParameterizedType);
    });

    it('should inject generic parameterized types', () {
      var injector = new ModuleInjector([moduleFactory()
          ..bind(ParameterizedType)
          ..bind(GenericParameterizedDependency)
      ]);
      expect(injector.get(GenericParameterizedDependency))
          .toBeAnInstanceOf(GenericParameterizedDependency);
    });

    it('should error while resolving parameterized dependencies', () {
      var module = moduleFactory();
      expect(() => module.bind(ParameterizedDependency)).toThrowWith(
        message:
          injectorName == STATIC_NAME ?
          "Type 'ParameterizedDependency' not found in generated typeFactory maps. "
              "Is the type's constructor injectable and annotated for injection?" :
          "ParameterizedType<bool, int> cannot be injected because it is parameterized "
              "with non-generic types."
      );
    });

    it('should allow modules and overriding providers', () {
      var module = moduleFactory()..bind(Engine, toImplementation: MockEngine);

      // injector is immutable
      // you can't load more modules once it's instantiated
      // (you can create a child injector)
      var injector = new ModuleInjector([module]);
      var instance = injector.get(Engine);

      expect(instance.id).toEqual('mock-id');
    });

    it('should only create a single instance', () {
      var injector = new ModuleInjector([moduleFactory()..bind(Engine)]);
      var first = injector.get(Engine);
      var second = injector.get(Engine);

      expect(first).toBe(second);
    });

    it('should allow providing values', () {
      var module = moduleFactory()
          ..bind(Engine, toValue: 'str value')
          ..bind(Car, toValue: 123);

      var injector = new ModuleInjector([module]);
      var abcInstance = injector.get(Engine);
      var complexInstance = injector.get(Car);

      expect(abcInstance).toEqual('str value');
      expect(complexInstance).toEqual(123);
    });

    it('should allow providing null values', () {
      var module = moduleFactory()
          ..bind(Engine, toValue: null);

      var injector = new ModuleInjector([module]);
      var engineInstance = injector.get(Engine);

      expect(engineInstance).toBeNull();
    });


    it('should cache null values', () {
      var count = 0;
      factory() {
        if (count++ == 0) return null;
        return new Engine();
      }
      var module = moduleFactory()..bind(Engine, toFactory: factory);
      var injector = new ModuleInjector([module]);

      var engine = injector.get(Engine);
      engine = injector.get(Engine);

      expect(engine).toBeNull();
    });


    it('should only call factories once, even when circular', () {
      var count = 0;
      factory(injector) {
        count++;
        return injector.get(Engine);
      }
      var module = moduleFactory()..bind(Engine, toFactory: factory, inject: [Injector]);
      var injector = new ModuleInjector([module]);

      try {
        var engine = injector.get(Engine);
      } on CircularDependencyError catch (e) {
        expect(count).toEqual(1);
      }
    });


    it('should allow providing factory functions', () {
      var module = moduleFactory()..bind(Engine, toFactory: () {
        return 'factory-product';
      }, inject: []);

      var injector = new ModuleInjector([module]);
      var instance = injector.get(Engine);

      expect(instance).toEqual('factory-product');
    });

    it('should allow providing with emulated factory functions', () {
      var module = moduleFactory();
      module.bind(Engine, toFactory: new EmulatedMockEngineFactory());

      var injector = new ModuleInjector([module]);
      var instance = injector.get(Engine);

      expect(instance).toBeAnInstanceOf(MockEngine);
    });

    it('should inject injector into factory function', () {
      var module = moduleFactory()
          ..bind(Engine)
          ..bind(Car, toFactory: (Engine engine, Injector injector) {
              return new Car(engine, injector);
            }, inject: [Engine, Injector]);

      var injector = new ModuleInjector([module]);
      var instance = injector.get(Car);

      expect(instance).toBeAnInstanceOf(Car);
      expect(instance.engine.id).toEqual('v8-id');
    });

    it('should throw an exception when injecting a primitive type', () {
      var injector = new ModuleInjector([
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
      var injector = new ModuleInjector([moduleFactory()..bind(CircularA)
                                        ..bind(CircularB)]);

      expect(() {
        injector.get(CircularA);
      }).toThrowWith(
          anInstanceOf: CircularDependencyError,
          message: 'Cannot resolve a circular dependency! '
                   '(resolving CircularA -> CircularB -> CircularA)');
    });

    it('should throw an exception when circular dependency in factory', () {
      var injector = new ModuleInjector([moduleFactory()
          ..bind(CircularA, toInstanceOf: CircularA)
      ]);

      expect(() {
        injector.get(CircularA);
      }).toThrowWith(
          anInstanceOf: CircularDependencyError,
          message: 'Cannot resolve a circular dependency! '
                   '(resolving CircularA -> CircularA)');
    });

    it('should recover from errors', () {
      var injector = new ModuleInjector([moduleFactory()..bind(ThrowOnce)]);
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
      var injector = new ModuleInjector([]);

      expect(injector.get(Injector)).toBe(injector);
    });


    it('should inject a typedef', () {
      var module = moduleFactory()..bind(CompareInt, toValue: compareIntAsc);

      var injector = new ModuleInjector([module]);
      var compare = injector.get(CompareInt);

      expect(compare(1, 2)).toEqual(1);
      expect(compare(5, 2)).toEqual(-1);
    });

    it('should throw an exception when injecting typedef without providing it', () {
      expect(() {
        var injector = new ModuleInjector([moduleFactory()..bind(WithTypeDefDependency)]);
        injector.get(WithTypeDefDependency);
      }).toThrowWith();
    });

    it('should instantiate via the default/unnamed constructor', () {
      var injector = new ModuleInjector([moduleFactory()..bind(MultipleConstructors)]);
      MultipleConstructors instance = injector.get(MultipleConstructors);
      expect(instance.instantiatedVia).toEqual('default');
    });

    // CHILD INJECTORS
    it('should inject from child', () {
      var module = moduleFactory()..bind(Engine, toImplementation: MockEngine);

      var parent = new ModuleInjector([moduleFactory()..bind(Engine)]);
      var child = new ModuleInjector([module], parent);

      var abcFromParent = parent.get(Engine);
      var abcFromChild = child.get(Engine);

      expect(abcFromParent.id).toEqual('v8-id');
      expect(abcFromChild.id).toEqual('mock-id');
    });

    it('should enumerate across children', () {
      var parent = new ModuleInjector([moduleFactory()..bind(Engine)]);
      var child = new ModuleInjector([moduleFactory()..bind(MockEngine)], parent);

      expect(parent.types).to(matcher.unorderedEquals([Engine, Injector]));
      expect(child.types).to(matcher.unorderedEquals([Engine, MockEngine, Injector]));
    });

    it('should inject instance from parent if not provided in child', () {
      var module = moduleFactory()..bind(Car);

      var parent = new ModuleInjector([moduleFactory()..bind(Car)..bind(Engine)]);
      var child = new ModuleInjector([module], parent);

      var complexFromParent = parent.get(Car);
      var complexFromChild = child.get(Car);
      var abcFromParent = parent.get(Engine);
      var abcFromChild = child.get(Engine);

      expect(complexFromChild).not.toBe(complexFromParent);
      expect(abcFromChild).toBe(abcFromParent);
    });

    it('should inject instance from parent but never use dependency from child', () {
      var module = moduleFactory()..bind(Engine, toImplementation: MockEngine);

      var parent = new ModuleInjector([moduleFactory()..bind(Car)..bind(Engine)]);
      var child = new ModuleInjector([module], parent);

      var complexFromParent = parent.get(Car);
      var complexFromChild = child.get(Car);
      var abcFromParent = parent.get(Engine);
      var abcFromChild = child.get(Engine);

      expect(complexFromChild).toBe(complexFromParent);
      expect(complexFromChild.engine).toBe(abcFromParent);
      expect(complexFromChild.engine).not.toBe(abcFromChild);
    });

    it('should provide child injector as Injector', () {
      var injector = new ModuleInjector([]);
      var child = new ModuleInjector([], injector);

      expect(child.get(Injector)).toBe(child);
    });

    it('should instantiate class only once (Issue #18)', () {
      var rootInjector = new ModuleInjector([]);
      var injector = new ModuleInjector([
          moduleFactory()
              ..bind(Log)
              ..bind(ClassOne)
              ..bind(InterfaceOne, toInstanceOf: ClassOne)
      ], rootInjector);

      expect(injector.get(InterfaceOne)).toBe(injector.get(ClassOne));
      expect(injector.get(Log).log.join(' ')).toEqual('ClassOne');
    });
  });
}


testKey() {
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


testCheckBindArgs() {
  describe('CheckBindArgs', () {
    var _ = DEFAULT_VALUE;
    it('should return true when args are well formed', () {
      expect(checkBindArgs(_, (Engine e, Car c) => 0, null, [Engine, Car], null)).toBeTrue();
      expect(checkBindArgs(_, () => 0, null, [], null)).toBeTrue();
      expect(checkBindArgs(0, _, null, [], null)).toBeTrue();
      expect(checkBindArgs(_, _, Car, [], null)).toBeTrue();
      expect(checkBindArgs(_, _, null, [], Car)).toBeTrue();
      expect(checkBindArgs(_, _, null, [], key(Car))).toBeTrue();
    });

    it('should error when wrong number of args have been set', () {
      expect(() => checkBindArgs(_, () => 0, Car, [], null)).toThrowWith();
      expect(() => checkBindArgs(0, _, null, [Engine, Car], null)).toThrowWith();
      expect(() => checkBindArgs(_, () => 0, null, [], Car)).toThrowWith();
    });

    it('should error when toFactory argument count does not match inject length', () {
      expect(() => checkBindArgs(_, (Engine e, Car c) => 0, null, [Engine], null)).toThrowWith();
      expect(() => checkBindArgs(_, () => 0, null, [Engine, Car], null)).toThrowWith();
    });
  });
}
