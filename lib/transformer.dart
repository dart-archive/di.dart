/**
 * Static injection transformer which generates, for each injectable type:
 *
 * - typeFactory: which is a closure (a1, a2...) => new Type(a1, a2...) where
 *     args are injected dependency instances, as specified by
 * - paramKeys: List<Keys> corresponding to the dependency needing to be injected
 *    in the positional arguments of the typeFactory.
 *
 * These two give an injector the information needed to construct an instance of a
 * type without using mirrors. They are stored as a Map<Type, [typeFactory|paramKeys]>
 * and outputted to a file [entry_point_name]_generated_type_factory_maps.dart. Multiple
 * entry points (main functions) is not supported.
 *
 * The import in main is also modified to use import di_static.dart instead
 * of di.dart, and imports module_dynamic.dart.
 *
 * All of the above is taken care of by the transformer. The user needs to call
 * setupModuleTypeReflector in main, before any modules are initialized. User must also
 * annotate types for the transformer to add them to the generated type factories file,
 * in addition to enabling the transformer in pubspec.yaml.
 *
 * Types which are considered injectable can be annotated in the following ways:
 *
 * * Use the @inject annotation on a class from `package:inject/inject.dart`
 *     @inject
 *     class Engine {}
 *
 * or on the constructor:
 *
 *     class Engine {
 *       @inject
 *       Engine();
 *     }
 *
 * * Define a custom annotation in pubspec.yaml
 *
 *     transformers:
 *     - di:
 *       injectable_annotations:
 *       - library_name.ClassName
 *       - library_name.constInstance
 *
 * Annotate constructors or classes with those annotations
 *
 *     @ClassName()
 *     class Engine {}
 *
 *     class Engine {
 *       @constInstance
 *       Engine();
 *     }
 *
 * * Use package:di's Injectables
 *
 *     @Injectables(const [Engine])
 *     library my_lib;
 *
 *     import 'package:di/annotations.dart';
 *
 *     class Engine {}
 *
 * * Specify injected types via pubspec.yaml
 *
 *     transformers:
 *     - di:
 *       injected_types:
 *       - library_name.Engine
 */
library di.transformer;

import 'dart:io';
import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:path/path.dart' as path;
import 'transformer/injector_generator.dart';
import 'transformer/options.dart';

export 'transformer/options.dart';
export 'transformer/injector_generator.dart';

/**
 * The transformer, which will extract all classes being dependency injected
 * into a static injector.
 */
class DependencyInjectorTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  DependencyInjectorTransformerGroup(TransformOptions options)
      : phases = _createPhases(options);

  DependencyInjectorTransformerGroup.asPlugin(BarbackSettings settings)
      : this(_parseSettings(settings.configuration));
}

TransformOptions _parseSettings(Map args) {
  var annotations = _readStringListValue(args, 'injectable_annotations');
  var injectedTypes = _readStringListValue(args, 'injected_types');

  var sdkDir = _readStringValue(args, 'dart_sdk', required: false);
  if (sdkDir == null) sdkDir = dartSdkDirectory;

  return new TransformOptions(
      injectableAnnotations: annotations,
      injectedTypes: injectedTypes,
      sdkDirectory: sdkDir);
}

_readStringValue(Map args, String name, {bool required: true}) {
  var value = args[name];
  if (value == null) {
    if (required) {
      print('di transformer "$name" has no value.');
    }
    return null;
  }
  if (value is! String) {
    print('di transformer "$name" value is not a string.');
    return null;
  }
  return value;
}

_readStringListValue(Map args, String name) {
  var value = args[name];
  if (value == null) return [];
  var results = [];
  bool error;
  if (value is List) {
    results = value;
    error = value.any((e) => e is! String);
  } else if (value is String) {
    results = [value];
    error = false;
  } else {
    error = true;
  }
  if (error) {
    print('Invalid value for "$name" in di transformer .');
  }
  return results;
}

List<List<Transformer>> _createPhases(TransformOptions options) {
  var resolvers = new Resolvers(options.sdkDirectory);
  return [[new InjectorGenerator(options, resolvers)]];
}
