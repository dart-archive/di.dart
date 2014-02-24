library di.transformer.injector_generator;

import 'dart:async';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:di/transformer/options.dart';
import 'package:path/path.dart' as path;

import 'refactor.dart';

const String _generateInjector = 'generated_static_injector.dart';

/**
 * Pub transformer which generates type factories for all injectable types
 * in the application.
 */
class InjectorGenerator extends Transformer {
  final TransformOptions options;
  /** Source for resolved AST of the application */
  final ResolverTransformer resolvers;
  /**
   * Current transform, for easy logging.
   *
   * Only valid while processing.
   */
  TransformLogger _logger;
  Resolver _resolver;
  /**
   * Resolved injectable annotations of the form `@Injectable()`.
   *
   * Only valid while processing.
   */
  List<TopLevelVariableElement> _injectableMetaConsts;
  /**
   * Resolved injectable annotations of the form `@injectable`.
   *
   * Only valid while processing.
   */
  List<ConstructorElement> _injectableMetaConstructors;

  InjectorGenerator(this.options, this.resolvers);

  Future<bool> isPrimary(Asset input) =>
      new Future.value(options.isDartEntry(input.id));

  Future apply(Transform transform) {
    _logger = transform.logger;
    _resolver = this.resolvers.getResolver(transform.primaryInput.id);

    // Update the resolver in case any previous transforms modified the source.
    return _resolver.updateSources(transform).then((_) {
      _resolveInjectableMetadata();
      var constructors = _gatherConstructors();

      var injectLibContents = _generateInjectLibrary(constructors);

      var outputId = new AssetId(transform.primaryInput.id.package,
          'lib/$_generateInjector');
      transform.addOutput(new Asset.fromString(outputId, injectLibContents));

      transformIdentifiers(transform, _resolver,
          identifier: 'di.auto_injector.defaultInjector',
          replacement: 'createStaticInjector',
          importPrefix: 'generated_static_injector',
          generatedFilename: _generateInjector);

      _logger = null;
      _resolver = null;
    });
  }

  /** Default list of injectable consts */
  static const List<String> _defaultInjectableMetaConsts = const [
    'inject.inject'
  ];

  /** Resolves the classes for the injectable annotations in the current AST. */
  void _resolveInjectableMetadata() {
    _injectableMetaConsts = <TopLevelVariableElement>[];
    _injectableMetaConstructors = <ConstructorElement>[];

    for (var constName in _defaultInjectableMetaConsts) {
      var variable = _resolver.getLibraryVariable(constName);
      if (variable != null) {
        _injectableMetaConsts.add(variable);
      }
    }

    // Resolve the user-specified annotations
    // These may be either type names (constructors) or consts.
    for (var metaName in options.injectableAnnotations) {
      var variable = _resolver.getLibraryVariable(metaName);
      if (variable != null) {
        _injectableMetaConsts.add(variable);
        continue;
      }
      var cls = _resolver.getType(metaName);
      if (cls != null && cls.unnamedConstructor != null) {
        _injectableMetaConstructors.add(cls.unnamedConstructor);
        continue;
      }
      _logger.warning('Unable to resolve injectable annotation $metaName');
    }
  }

  /** Finds all annotated constructors or annotated classes in the program. */
  Iterable<ConstructorElement> _gatherConstructors() {
    var constructors = _resolver.libraries
        .expand((lib) => lib.units)
        .expand((compilationUnit) => compilationUnit.types)
        .map(_findInjectedConstructor)
        .where((ctor) => ctor != null).toList();

    constructors.addAll(_gatherInjectablesContents());
    constructors.addAll(_gatherManuallyInjected());

    return constructors.toSet();
  }

  /**
   * Get the constructors for all elements in the library @Injectables
   * statements. These are used to mark types as injectable which would
   * otherwise not be injected.
   *
   * Syntax is:
   *
   *     @Injectables(const[ElementName])
   *     library my.library;
   */
  Iterable<ConstructorElement> _gatherInjectablesContents() {
    var injectablesClass = _resolver.getType('di.annotations.Injectables');
    if (injectablesClass == null) return const [];
    var injectablesCtor = injectablesClass.unnamedConstructor;

    var ctors = [];

    for (var lib in _resolver.libraries) {
      var annotationIdx = 0;
      for (var annotation in lib.metadata) {
        if (annotation.element == injectablesCtor) {
          var libDirective = lib.definingCompilationUnit.node.directives
              .where((d) => d is LibraryDirective).single;
          var annotationDirective = libDirective.metadata[annotationIdx];
          var listLiteral = annotationDirective.arguments.arguments.first;

          for (var expr in listLiteral.elements) {
            var element = (expr as SimpleIdentifier).bestElement;
            if (element == null || element is! ClassElement) {
              _logger.warning('Unable to resolve class $expr',
                  asset: _resolver.getSourceAssetId(element),
                  span: _resolver.getSourceSpan(element));
              continue;
            }
            var ctor = _findInjectedConstructor(element, true);
            if (ctor != null) {
              ctors.add(ctor);
            }
          }
        }
      }
    }
    return ctors;
  }

  /**
   * Finds all types which were manually specified as being injected in
   * the options file.
   */
  Iterable<ConstructorElement> _gatherManuallyInjected() {
    var ctors = [];
    for (var injectedName in options.injectedTypes) {
      var injectedClass = _resolver.getType(injectedName);
      if (injectedClass == null) {
        _logger.warning('Unable to resolve injected type name $injectedName');
        continue;
      }
      var ctor = _findInjectedConstructor(injectedClass, true);
      if (ctor != null) {
        ctors.add(ctor);
      }
    }
    return ctors;
  }

  /**
   * Checks if the element is annotated with one of the known injectablee
   * annotations.
   */
  bool _isElementAnnotated(Element e) {
    for (var meta in e.metadata) {
      if (meta.element is PropertyAccessorElement &&
          _injectableMetaConsts.contains(meta.element.variable)) {
        return true;
      } else if (meta.element is ConstructorElement &&
          _injectableMetaConstructors.contains(meta.element)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Find an 'injected' constructor for the given class.
   * If [noAnnotation] is true then this will assume that the class is marked
   * for injection and will use the default constructor.
   */
  ConstructorElement _findInjectedConstructor(ClassElement cls,
      [bool noAnnotation = false]) {
    var classInjectedConstructors = [];
    if (_isElementAnnotated(cls) || noAnnotation) {
      var defaultConstructor = cls.unnamedConstructor;
      if (defaultConstructor == null) {
        _logger.warning('${cls.name} cannot be injected because '
            'it does not have a default constructor.',
            asset: _resolver.getSourceAssetId(cls),
            span: _resolver.getSourceSpan(cls));
      } else {
        classInjectedConstructors.add(defaultConstructor);
      }
    }

    classInjectedConstructors.addAll(
        cls.constructors.where(_isElementAnnotated));

    if (classInjectedConstructors.isEmpty) return null;
    if (classInjectedConstructors.length > 1) {
      _logger.warning('${cls.name} has more than one constructor annotated for '
          'injection.',
          asset: _resolver.getSourceAssetId(cls),
          span: _resolver.getSourceSpan(cls));
      return null;
    }

    var ctor = classInjectedConstructors.single;
    if (!_validateConstructor(ctor)) return null;

    return ctor;
  }

  /**
   * Validates that the constructor is injectable and emits warnings for any
   * errors.
   */
  bool _validateConstructor(ConstructorElement ctor) {
    var cls = ctor.enclosingElement;
    if (cls.isAbstract && !ctor.isFactory) {
      _logger.warning('${cls.name} cannot be injected because '
          'it is an abstract type with no factory constructor.',
          asset: _resolver.getSourceAssetId(cls),
          span: _resolver.getSourceSpan(cls));
      return false;
    }
    if (cls.isPrivate) {
      _logger.warning('${cls.name} cannot be injected because it is a private '
          'type.',
          asset: _resolver.getSourceAssetId(cls),
          span: _resolver.getSourceSpan(cls));
      return false;
    }
    if (_resolver.getImportUri(cls.library) == null) {
      _logger.warning('${cls.name} cannot be injected because '
          'the containing file cannot be imported.',
          asset: _resolver.getSourceAssetId(ctor),
          span: _resolver.getSourceSpan(ctor));
      return false;
    }
    if (!cls.typeParameters.isEmpty) {
      _logger.warning('${cls.name} is a parameterized type.',
          asset: _resolver.getSourceAssetId(ctor),
          span: _resolver.getSourceSpan(ctor));
      // Only warn.
    }
    if (ctor.name != '') {
      _logger.warning('Named constructors cannot be injected.',
          asset: _resolver.getSourceAssetId(ctor),
          span: _resolver.getSourceSpan(ctor));
      return false;
    }
    for (var param in ctor.parameters) {
      var type = param.type;
      if (type is InterfaceType &&
          type.typeArguments.any((t) => !t.isDynamic)) {
        _logger.warning('${cls.name} cannot be injected because '
            '${param.type} is a parameterized type.',
            asset: _resolver.getSourceAssetId(ctor),
            span: _resolver.getSourceSpan(ctor));
        return false;
      }
      if (type.isDynamic) {
        _logger.warning('${cls.name} cannot be injected because parameter type '
          '${param.name} cannot be resolved.',
            asset: _resolver.getSourceAssetId(ctor),
            span: _resolver.getSourceSpan(ctor));
        return false;
      }
    }
    return true;
  }

  /**
   * Creates a library file for the specified constructors.
   */
  String _generateInjectLibrary(Iterable<ConstructorElement> constructors) {
    var outputBuffer = new StringBuffer();

    _writeStaticInjectorHeader(_resolver.entryPoint, outputBuffer);

    var prefixes = <LibraryElement, String>{};

    var ctorTypes = constructors.map((ctor) => ctor.enclosingElement).toSet();
    var paramTypes = constructors.expand((ctor) => ctor.parameters)
        .map((param) => param.type.element).toSet();

    var libs = ctorTypes..addAll(paramTypes);
    libs = libs.map((type) => type.library).toSet();

    for (var lib in libs) {
      if (lib.isDartCore) {
        prefixes[lib] = '';
      } else {
        var prefix = 'import_${prefixes.length}';
        var uri = _resolver.getImportUri(lib);
        outputBuffer.write('import \'$uri\' as $prefix;\n');
        prefixes[lib] = '$prefix.';
      }
    }

    _writePreamble(outputBuffer);

    for (var ctor in constructors) {
      var type = ctor.enclosingElement;
      var typeName = '${prefixes[type.library]}${type.name}';
      outputBuffer.write('  $typeName: (f) => new $typeName(');
      var params = ctor.parameters.map((param) {
        var type = param.type.element;
        var typeName = '${prefixes[type.library]}${type.name}';
        return 'f($typeName)';
      });
      outputBuffer.write('${params.join(', ')}),\n');
    }

    _writeFooter(outputBuffer);

    return outputBuffer.toString();
  }
}

void _writeStaticInjectorHeader(AssetId id, StringSink sink) {
  var libPath = path.withoutExtension(id.path).replaceAll('/', '.');
  sink.write('''
library ${id.package}.$libPath.generated_static_injector;

import 'package:di/di.dart';
import 'package:di/static_injector.dart';

@MirrorsUsed(override: const [
    'di.dynamic_injector',
    'mirrors',
    'di.src.reflected_type'])
import 'dart:mirrors';
''');
}

void _writePreamble(StringSink sink) {
  sink.write('''
Injector createStaticInjector({List<Module> modules, String name,
    bool allowImplicitInjection: false}) =>
  new StaticInjector(modules: modules, name: name,
      allowImplicitInjection: allowImplicitInjection,
      typeFactories: factories);

Module get staticInjectorModule => new Module()
    ..value(Injector, createStaticInjector(name: 'Static Injector'));

final Map<Type, TypeFactory> factories = <Type, TypeFactory>{
''');
}

void _writeFooter(StringSink sink) {
  sink.write('''
};
''');
}
