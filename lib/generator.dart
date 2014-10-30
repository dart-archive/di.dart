/**
 * Generates Factory & paramKeys maps into a file by crawling source files and
 * finding all constructors that are annotated for injection. Does the same thing as
 * transformer.dart for when transformers are not available,  except without modifications
 * to the main function and DI. As such, the user needs to import the generated file, and run
 * `Module.DEFAULT_REFLECTOR = new GeneratedTypeFactories(typeFactories, parameterKeys)`
 * imported, before any modules are initialized. Import 'di_static.dart' instead of 'di.dart'
 * to avoid mirrors, and import 'reflector_static.dart' for GeneratedTypeFactories.
 * See transformer.dart for more info.
 */
library di.generator;

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:path/path.dart' as path;

import 'dart:io';

const String PACKAGE_PREFIX = 'package:';
const String DART_PACKAGE_PREFIX = 'dart:';
const List<String> _DEFAULT_INJECTABLE_ANNOTATIONS = const ['di.annotations.Injectable'];

main(List<String> args) {
  if (args.length < 4) {
    print('Usage: generator path_to_sdk file_to_resolve annotations output [package_roots+]');
    exit(0);
  }

  var pathToSdk = args[0];
  var entryPoint = args[1];
  var classAnnotations = args[2].split(',')..addAll(_DEFAULT_INJECTABLE_ANNOTATIONS);
  var output = args[3];
  var packageRoots = (args.length < 5) ? [Platform.packageRoot] : args.sublist(4);

  print('pathToSdk: $pathToSdk');
  print('entryPoint: $entryPoint');
  print('classAnnotations: ${classAnnotations.join(', ')}');
  print('output: $output');
  print('packageRoots: $packageRoots');

  var code = generateCode(entryPoint, classAnnotations, pathToSdk, packageRoots, output);
  code.forEach((chunk, code) {
    String fileName = output;
    if (chunk.library != null) {
      var lastDot = fileName.lastIndexOf('.');
      fileName = fileName.substring(0, lastDot) + '-' + chunk.library.name + fileName.substring(lastDot);
    }
    new File(fileName).writeAsStringSync(code);
  });
}

Map<Chunk, String> generateCode(String entryPoint, List<String> classAnnotations,
    String pathToSdk, List<String> packageRoots, String outputFilename) {

  var c = new SourceCrawler(pathToSdk, packageRoots);
  List<String> imports = <String>[];
  Map<Chunk, List<ClassElement>> typeFactoryTypes = <Chunk, List<ClassElement>>{};
  Map<String, String> typeToImport = new Map<String, String>();
  Map<String, InterfaceType> typeMappings = {};

  c.crawl(entryPoint, (CompilationUnitElement compilationUnit, SourceFile source) {
      new CompilationUnitVisitor(c.context, source, classAnnotations, imports, typeToImport,
          typeFactoryTypes, typeMappings, outputFilename).visit(compilationUnit, source);
  });
  return printLibraryCode(typeToImport, imports, typeFactoryTypes, typeMappings);
}

Map<Chunk, String> printLibraryCode(Map<String, String> typeToImport, List<String> imports,
                                    Map<Chunk, List<ClassElement>> typeFactoryTypes,
                                    Map<String, InterfaceType> typeMapping) {

  Map<Chunk, StringBuffer> factories = <Chunk, StringBuffer>{};
  Map<Chunk, StringBuffer> keys = <Chunk, StringBuffer>{};
  Map<Chunk, StringBuffer> paramLists = <Chunk, StringBuffer>{};
  Map<Chunk, String> result = <Chunk, String>{};

  typeFactoryTypes.forEach((Chunk chunk, List<ClassElement> classes) {
    List<String> requiredImports = <String>[];
    String resolveClassIdentifier(InterfaceType type, [List typeArgs,
        bool usedToGenerateConstructor = false]) {
      final TYPE_LITERAL = 'TypeLiteral';
      if (type.element.library.isDartCore) {

        //workaround for https://github.com/angular/di.dart/issues/183
        final canUseTypeLiteral = typeMapping.containsKey(TYPE_LITERAL) &&
            !usedToGenerateConstructor;

        if (type.typeParameters.isNotEmpty && canUseTypeLiteral) {
          return 'new ${resolveClassIdentifier(typeMapping[TYPE_LITERAL])}<$type>().type';
        }
        return type.name;
      }
      String import = typeToImport[getCanonicalName(type)];
      if (!requiredImports.contains(import)) {
        requiredImports.add(import);
      }
      String prefix = _calculateImportPrefix(import, imports);
      return '$prefix.${type.name}';
    }

    factories[chunk] = new StringBuffer();
    keys[chunk] = new StringBuffer();
    paramLists[chunk] = new StringBuffer();

    process_classes(classes, keys[chunk], factories[chunk], paramLists[chunk],
                    resolveClassIdentifier);

    StringBuffer code = new StringBuffer();
    String libSuffix = chunk.library == null ? '' : '.${chunk.library.name}';
    code.write('library di.generated.type_factories$libSuffix;\n');
    requiredImports.forEach((import) {
      String prefix = _calculateImportPrefix(import, imports);
      code.write ('import "$import" as $prefix;\n');
    });
    code..write('import "package:di/key.dart" show Key;\n')
        ..write(keys[chunk])
        ..write('Map<Type, Function> typeFactories = {\n${factories[chunk]}};\n')
        ..write('Map<Type, List<Key>> parameterKeys = {\n${paramLists[chunk]}};\n')
        ..write('main() {}\n');
    result[chunk] = code.toString();
  });

  return result;
}

typedef String IdentifierResolver(InterfaceType type, [List typeArgs, bool usedToGenerateConstructor]);
/**
 * Takes classes and writes to StringBuffers the corresponding keys, factories,
 * and paramLists needed for static injection.
 *
 * resolveClassIdentifier is a function passed in to be called to resolve imports
 */
void process_classes(Iterable<ClassElement> classes, StringBuffer keys,
                     StringBuffer factories, StringBuffer paramLists,
                     IdentifierResolver resolveClassIdentifier) {

  Map<String, String> toBeAdded = new Map<String, String>();
  Set<String> addedKeys = new Set();

  classes.forEach((ClassElement clazz) {
    StringBuffer factory = new StringBuffer();
    StringBuffer paramList = new StringBuffer();
    List<String> factoryKeys = new List<String>();
    bool skip = false;
    var className = getUniqueName(clazz.type);
    var classType = resolveClassIdentifier(clazz.type, [], true);
    if (addedKeys.add(className)) {
      toBeAdded[className] =
          'final Key _KEY_$className = new Key($classType);\n';
    }
    factoryKeys.add(className);

    ConstructorElement constr = clazz.constructors.firstWhere((c) => c.name.isEmpty,
        orElse: () {
          throw 'Unable to find default constructor for $clazz in ${clazz.source}';
        });

    var args = new List.generate(constr.parameters.length, (i) => 'a$i').join(', ');
    factory.write('$classType: ($args) => new $classType($args),\n');

    paramList.write('$classType: ');
    if (constr.parameters.isEmpty){
      paramList.write('const [');
    } else {
      paramList.write('[');
      paramList.write(constr.parameters.map((param) {
        if (param.type.element is! ClassElement) {
          throw 'Unable to resolve type for constructor parameter '
                '"${param.name}" for type "$clazz" in ${clazz.source}';
        }
        var annotations = [];
        if (param.metadata.isNotEmpty) {
          annotations = param.metadata.map((item) => item.element.returnType.name);
        }
        String keyName = annotations.isNotEmpty ?
            '${param.type.name}_${annotations.first}' :
              param.type.name;
        param.type.typeArguments.forEach((arg) => keyName = '${keyName}_${arg.name}');
        String output = '_KEY_${keyName}';
        if (addedKeys.add(keyName)){
          var annotationParam = "";
          if (param.metadata.isNotEmpty) {
            var p = resolveClassIdentifier(param.metadata.first.element.returnType);
            annotationParam = ", $p";
          }
          var clsId = resolveClassIdentifier(param.type, param.type.typeArguments);
          toBeAdded[keyName]='final Key _KEY_${keyName} = new Key($clsId$annotationParam);\n';
        }
        return output;
      }).join(', '));
    }
    paramList.write('],\n');
    if (!skip) {
      factoryKeys.forEach((key) {
        var keyString = toBeAdded.remove(key);
        keys.write(keyString);
      });
      factories.write(factory);
      paramLists.write(paramList);
    }
  });
  keys.writeAll(toBeAdded.values);
  toBeAdded.clear();
}

String _calculateImportPrefix(String import, List<String> imports) =>
    'import_${imports.indexOf(import)}';

class CompilationUnitVisitor {
  List<String> imports;
  Map<String, String> typeToImport;
  Map<Chunk, List<ClassElement>> typeFactoryTypes;
  List<String> classAnnotations;
  SourceFile source;
  AnalysisContext context;
  String outputFilename;
  Map<String, InterfaceType> typeMappings;

  CompilationUnitVisitor(this.context, this.source,
      this.classAnnotations, this.imports, this.typeToImport,
      this.typeFactoryTypes, this.typeMappings, this.outputFilename);

  visit(CompilationUnitElement compilationUnit, SourceFile source) {
    if (typeFactoryTypes[source.chunk] == null) {
      typeFactoryTypes[source.chunk] = <ClassElement>[];
    }
    visitLibrary(compilationUnit.enclosingElement, source);

    List<ClassElement> types = <ClassElement>[];
    types.addAll(compilationUnit.types);

    for (CompilationUnitElement part in compilationUnit.enclosingElement.parts) {
      types.addAll(part.types);
    }

    types.forEach((clazz) => visitClassElement(clazz, source));
  }

  visitLibrary(LibraryElement libElement, SourceFile source) {
    CompilationUnit resolvedUnit = context.resolveCompilationUnit(libElement.source, libElement);

    resolvedUnit.directives.forEach((Directive directive) {
      if (directive is LibraryDirective) {
        LibraryDirective library = directive;
        int annotationIdx = 0;
        library.metadata.forEach((Annotation ann) {
          if (ann.element is ConstructorElement &&
            getQualifiedName(
                (ann.element as ConstructorElement).enclosingElement.type) ==
                'di.annotations.Injectables') {
            var listLiteral = library.metadata[annotationIdx].arguments.arguments.first;
            for (Expression expr in listLiteral.elements) {
              Element element = (expr as SimpleIdentifier).bestElement;
              if (element == null || element is! ClassElement) {
                throw 'Unable to resolve type "$expr" from @Injectables '
                      'in ${library.element.source}';
              }
              if (!typeFactoryTypes[source.chunk].contains(element)) {
                typeFactoryTypes[source.chunk].add(element as ClassElement);
              }
            }
          }
          annotationIdx++;
        });
      }
    });
  }

  visitClassElement(ClassElement classElement, SourceFile source) {
    if (classElement.isPrivate) return; // ignore private classes.
    var importUri = source.entryPointImport;
    if (Uri.parse(importUri).scheme == '') {
      importUri = path.relative(importUri, from: path.dirname(outputFilename));
    }
    typeToImport[getCanonicalName(classElement.type)] = importUri;
    if (classElement.name == 'TypeLiteral' && classElement.library.name == 'di.type_literal') {
      typeMappings.putIfAbsent(classElement.name, () => classElement.type);
    }
    if (!imports.contains(importUri)) {
      imports.add(importUri);
    }
    for (ElementAnnotation ann in classElement.metadata) {
      if (ann.element is ConstructorElement) {
        ClassElement classEl = ann.element.enclosingElement;
        List<DartType> types = [classEl.type]..addAll(classEl.allSupertypes);
        if (types.any((DartType t) => classAnnotations.contains(getQualifiedName(t)))) {
          // The class is injectable when the metadata is either:
          // - an instance of any `classAnnotations` types,
          // - a subtype of any `classAnnotations` types.
          if (typeFactoryTypes[source.chunk] == null) {
            typeFactoryTypes[source.chunk] = <ClassElement>[];
          }
          if (!typeFactoryTypes[source.chunk].contains(classElement)) {
            typeFactoryTypes[source.chunk].add(classElement);
          }
        }
      }
    }
  }
}

String getQualifiedName(InterfaceType type) {
  var lib = type.element.library.displayName;
  var name = type.name;
  return lib == null ? name : '$lib.$name';
}

String getUniqueName(InterfaceType type) {
  var lib = type.element.library.displayName;
  var name = type.name;
  String qualName = lib == null ? name : '$lib.$name';
  return qualName.replaceAll('.', '_');
}

String getCanonicalName(InterfaceType type) {
  var source = type.element.source.toString();
  var name = type.name;
  return '$source:$name';
}

typedef CompilationUnitCrawler(CompilationUnitElement compilationUnit, SourceFile source);

class SourceCrawler {
  final List<String> packageRoots;
  final String sdkPath;
  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();

  SourceCrawler(this.sdkPath, this.packageRoots);

  void crawl(String entryPoint, CompilationUnitCrawler _visitor,
             {bool preserveComments : false}) {
    JavaSystemIO.setProperty("com.google.dart.sdk", sdkPath);
    DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;

    AnalysisOptionsImpl contextOptions = new AnalysisOptionsImpl();
    contextOptions.cacheSize = 256;
    contextOptions.preserveComments = preserveComments;
    contextOptions.analyzeFunctionBodies = false;
    context.analysisOptions = contextOptions;
    sdk.context.analysisOptions = contextOptions;

    var packageUriResolver = new PackageUriResolver(packageRoots.map(
        (pr) => new JavaFile.fromUri(new Uri.file(pr))).toList());
    context.sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      new FileUriResolver(),
      packageUriResolver
    ]);

    var entryPointFile;
    var entryPointImport;
    if (entryPoint.startsWith(PACKAGE_PREFIX)) {
      entryPointFile = new JavaFile(packageUriResolver
          .resolveAbsolute(Uri.parse(entryPoint)).toString());
      entryPointImport = entryPoint;
    } else {
      entryPointFile = new JavaFile(entryPoint);
      entryPointImport = entryPointFile.getAbsolutePath();
    }

    Source source = new FileBasedSource.con1(entryPointFile);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    LibraryElement rootLib = context.computeLibraryElement(source);
    CompilationUnit resolvedUnit =
        context.resolveCompilationUnit(source, rootLib);

    var sourceFile = new SourceFile(
        entryPointFile.getAbsolutePath(),
        entryPointImport,
        resolvedUnit,
        resolvedUnit.element,
        new Chunk()); // root chunk
    List<SourceFile> toVisit = <SourceFile>[sourceFile];
    List<SourceFile> deferred = <SourceFile>[sourceFile];

    while (deferred.isNotEmpty) {
      toVisit.add(deferred.removeAt(0));
      while (toVisit.isNotEmpty) {
        SourceFile currentFile = toVisit.removeAt(0);
        currentFile.chunk.addVisited(currentFile);
        _visitor(currentFile.compilationUnitElement, currentFile);
        var visitor = new CrawlerVisitor(currentFile, context);
        visitor.accept(currentFile.compilationUnit);
        visitor.toVisit.forEach((SourceFile todo) {
          if (!toVisit.contains(todo) && !currentFile.chunk.alreadyVisited(todo)) {
            toVisit.add(todo);
          }
        });
        visitor.deferred.forEach((SourceFile todo) {
          if (!deferred.contains(todo) && !currentFile.chunk.alreadyVisited(todo)) {
            deferred.add(todo);
          }
        });
      }
    }
  }
}

class CrawlerVisitor {
  List<SourceFile> toVisit = <SourceFile>[];
  List<SourceFile> deferred = <SourceFile>[];
  SourceFile currentFile;
  AnalysisContext context;
  String currentDir;

  CrawlerVisitor(this.currentFile, this.context);

  void accept(CompilationUnit cu) {
    cu.directives.forEach((Directive directive) {
      if (directive.element == null) return; // unresolvable, ignore
      if (directive is ImportDirective) {
        var import = directive.element;
        visitImportElement(
            new Library(import, import.uri, cu, import.importedLibrary.name),
            import.importedLibrary.source);
      }
      if (directive is ExportDirective) {
        var import = directive.element;
        visitImportElement(
            new Library(import, import.uri, cu, import.exportedLibrary.name),
            import.exportedLibrary.source);
      }
    });
  }

  void visitImportElement(Library library, Source source) {
    String uri = library.uri;
    if (uri == null) return; // dart:core

    String systemImport;
    bool isSystem = false;
    if (uri.startsWith(DART_PACKAGE_PREFIX)) {
      isSystem = true;
      systemImport = uri;
    } else if (currentFile.entryPointImport.startsWith(DART_PACKAGE_PREFIX)) {
      isSystem = true;
      systemImport = currentFile.entryPointImport;
    }
    // check if it's some internal hidden library
    if (isSystem && systemImport.substring(DART_PACKAGE_PREFIX.length).startsWith('_')) {
      return;
    }

    var nextCompilationUnit = context
        .resolveCompilationUnit(source, context.computeLibraryElement(source));

    SourceFile sourceFile;
    if (uri.startsWith(PACKAGE_PREFIX)) {
      sourceFile = new SourceFile(source.toString(), uri,
          nextCompilationUnit, nextCompilationUnit.element, currentFile.chunk);
    } else { // relative import.
      var newImport;
      if (isSystem) {
        newImport = systemImport; // original uri
      } else {
        // relative import
        String import = currentFile.entryPointImport;
        import = import.replaceAll('\\', '/'); // if at all needed, on Windows
        import = import.substring(0, import.lastIndexOf('/'));
        var currentDir = new File(currentFile.canonicalPath).parent.path;
        currentDir = currentDir.replaceAll('\\', '/'); // if at all needed, on Windows
        if (uri.startsWith('../')) {
          while (uri.startsWith('../')) {
            uri = uri.substring('../'.length);
            import = import.substring(0, import.lastIndexOf('/'));
            currentDir = currentDir.substring(0, currentDir.lastIndexOf('/'));
          }
        }
        newImport = '$import/$uri';
      }
      sourceFile = new SourceFile(
          source.toString(), newImport,
          nextCompilationUnit, nextCompilationUnit.element, currentFile.chunk);
    }
    if (library.isDeferred || isDeferredImport(library)) {
      var childChunk = currentFile.chunk.createChild(library);
      deferred.add(new SourceFile(source.toString(), sourceFile.entryPointImport,
          nextCompilationUnit, nextCompilationUnit.element, childChunk));
    } else {
      toVisit.add(sourceFile);
    }
  }
}

// TODO(cbracken) eliminate once support for old-style is removed in SDK 1.7.0
bool isDeferredImport(Library library) {
  var isDeferred = false;
  library.element.metadata.forEach((ElementAnnotation annotation) {
    if (annotation.element is PropertyAccessorElement) {
      PropertyAccessorElement pa = annotation.element;
      library.compilationUnit.declarations.forEach((CompilationUnitMember member) {
        if (member is TopLevelVariableDeclaration && member.variables.isConst) {
          TopLevelVariableDeclaration topLevel = member;
          topLevel.variables.variables.forEach((VariableDeclaration varDecl) {
            if (varDecl.initializer is InstanceCreationExpression &&
                (varDecl.initializer as InstanceCreationExpression).isConst &&
                (varDecl.initializer as InstanceCreationExpression).staticElement is ConstructorElement &&
                varDecl.name.name == pa.name) {
              ConstructorElement constr = (varDecl.initializer as InstanceCreationExpression).staticElement;
              if (constr.enclosingElement.library.name == 'dart.async' &&
                  constr.enclosingElement.type.name == 'DeferredLibrary') {
                isDeferred = true;
              }
            }
          });
        }
      });
    }
  });
  return isDeferred;
}

class Library {
  final Element element;
  final String uri;
  final CompilationUnit compilationUnit;
  final String name;

  Library(this.element, this.uri, this.compilationUnit, this.name);

  bool get isDeferred => element is ImportElement && (element as ImportElement).isDeferred;

  String toString() => 'Library[$name]';
}

class Chunk {
  final Chunk parent;
  Library library;
  List<SourceFile> _visited = <SourceFile>[];

  addVisited(SourceFile file) {
    _visited.add(file);
  }

  bool alreadyVisited(SourceFile file) {
    var cursor = this;
    while (cursor != null) {
      if (cursor._visited.contains(file)) {
        return true;
      }
      cursor = cursor.parent;
    }
    return false;
  }

  Chunk([this.parent, this.library]);

  Chunk createChild(Library library) => new Chunk(this, library);

  String toString() => 'Chunk[$library]';
}

class SourceFile {
  String canonicalPath;
  String entryPointImport;
  CompilationUnit compilationUnit;
  CompilationUnitElement compilationUnitElement;
  Chunk chunk;

  SourceFile(this.canonicalPath, this.entryPointImport, this.compilationUnit,
      this.compilationUnitElement, this.chunk);

  operator ==(o) {
    if (o is String) return o == canonicalPath;
    if (o is! SourceFile) return false;
    return o.canonicalPath == canonicalPath;
  }
}
