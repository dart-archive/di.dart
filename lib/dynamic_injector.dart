library di.dynamic_injector;

import 'di.dart';
import 'src/mirrors.dart';
import 'src/base_injector.dart';
import 'src/error_helper.dart';
import 'src/provider.dart';

export 'di.dart';

/**
 * Dynamic implementation of [Injector] that uses mirrors.
 */
class DynamicInjector extends BaseInjector {
  /// Types injected via a [TypeProvider] must have one of those annotations
  Set<Type> _assertAnnotations;
  /// Those types need not be annotated, see [di.annotations.Injectables]
  Set<Type> _annotationFreeTypes;

  /**
   * If [_assertAnnotations] is specified then all [Type]s instantiated by a
   * [TypeProvider] must have on of those annotations unless they are
   * white-listed in [_annotationFreeTypes].
   */
  DynamicInjector({List<Module> modules,
                  String name,
                  bool allowImplicitInjection: false,
                  Iterable<Type> assertAnnotations: null,
                  Iterable<Type> annotationFreeTypes: null})
      : _assertAnnotations = assertAnnotations == null ?
            null : new Set.from(assertAnnotations),
        _annotationFreeTypes = annotationFreeTypes == null ?
            null : new Set.from(annotationFreeTypes),
        super(modules: modules, name: name,
              allowImplicitInjection: allowImplicitInjection) {
    assert(_assertTypesHaveAnnotations(modules));
  }

  DynamicInjector._fromParent(List<Module> modules, Injector parent, {name})
      : super.fromParent(modules, parent, name: name) {
    assert(_assertTypesHaveAnnotations(modules));
  }

  Injector newFromParent(List<Module> modules, String name) =>
      new DynamicInjector._fromParent(modules, this, name: name);

  Object newInstanceOf(Type type, ObjectFactory objFactory, Injector requestor,
                       ResolutionContext resolving) {
    var classMirror = reflectType(type);
    if (classMirror is TypedefMirror) {
      throw new NoProviderError(error(resolving, 'No implementation provided '
          'for ${getSymbolName(classMirror.qualifiedName)} typedef!'));
    }

    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];

    if (ctor == null) {
      throw new NoProviderError('Unable to find default constructor for $type. '
          'Make sure class has a default constructor.' + (1.0 is int ?
              'Make sure you have correctly configured @MirrorsUsed.' : ''));
    }

    resolveArgument(int pos) {
      ParameterMirror p = ctor.parameters[pos];
      if (p.type.qualifiedName == #dynamic) {
        var name = MirrorSystem.getName(p.simpleName);
        throw new NoProviderError(
            error(resolving, "The '$name' parameter must be typed"));
      }
      if (p.type is TypedefMirror) {
        throw new NoProviderError(
            error(resolving,
                  'Cannot create new instance of a typedef ${p.type}'));
      }
      if (p.metadata.isNotEmpty) {
        assert(p.metadata.length == 1);
        var type = p.metadata.first.type.reflectedType;
        return objFactory.getInstanceByKey(
            new Key((p.type as ClassMirror).reflectedType, type),
            requestor, resolving);
      } else {
        return objFactory.getInstanceByKey(
            new Key((p.type as ClassMirror).reflectedType),
            requestor, resolving);
      }
    }

    var args = new List.generate(ctor.parameters.length, resolveArgument,
        growable: false);
    return classMirror.newInstance(ctor.constructorName, args).reflectee;
  }

  /**
   * Invoke given function and inject all its arguments.
   *
   * Returns whatever the function returns.
   */
  dynamic invoke(Function fn) {
    ClosureMirror cm = reflect(fn);
    MethodMirror mm = cm.function;
    int position = 0;
    List args = mm.parameters.map((ParameterMirror parameter) {
      try {
        if (parameter.metadata.isNotEmpty) {
          var annotation = parameter.metadata[0].type.reflectedType;
          return get((parameter.type as ClassMirror).reflectedType, annotation);
        } else {
          return get((parameter.type as ClassMirror).reflectedType);
        }
      } on NoProviderError catch (e) {
        throw new NoProviderError(e.message);
      } finally {
        position++;
      }
    }).toList();

    return cm.apply(args).reflectee;
  }

  /**
   * Asserts that types provided by [TypeProvider]s are annotated with one of
   * the [_assertAnnotations].
   *
   * This is useful so that the code will not break when switching to a
   * static injector.
   */
  bool _assertTypesHaveAnnotations(List<Module> modules) {
    if (parent != null) {
      _assertAnnotations = (parent as DynamicInjector)._assertAnnotations;
    }
    if (modules == null || _assertAnnotations == null) return true;
    var types = new Set<Type>();
    modules.forEach((module) {
      module.bindings.values.forEach((Provider p) {
        if (p is TypeProvider) types.add(p.type);
      });
    });
    if (_annotationFreeTypes != null) {
      types = types.difference(_annotationFreeTypes);
    }
    types.forEach((Type t) {
      var hasAnnotation = reflectType(t)
          .metadata
          .any((InstanceMirror im) {
            var cm = im.type;
            return cm.hasReflectedType &&
                   _assertAnnotations.contains(cm.reflectedType);
          });

      if (!hasAnnotation) {
        throw new NoAnnotationError("The type '$t' should be annotated with one"
                                    " of '${_assertAnnotations.join(', ')}'");
      }
    });

    return true;
  }
}
