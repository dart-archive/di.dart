library di.generator;

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';

import 'dart:io';

const String PACKAGE_PREFIX = 'package:';
const String DART_PACKAGE_PREFIX = 'dart:';

main(args) {
  if (args.length < 4) {
    print('Usage: generator path_to_sdk file_to_resolve annotations output '
        '[package_roots+]');
    exit(0);
  }

  var pathToSdk = args[0];
  var entryPoint = args[1];
  var classAnnotations = args[2].split(',').toSet();
  var output = args[3];
  var packageRoots = (args.length < 5 ?
      [Platform.packageRoot] : args.sublist(4)).toSet();

  print('''pathToSdk: $pathToSdk
entryPoint: $entryPoint
classAnnotations: ${classAnnotations.join(', ')}
output: $output
packageRoots: ${packageRoots.join(', ')}''');

  var c = new SourceCrawler(pathToSdk, packageRoots);
  var imports = new Set<String>();
  var typeFactoryTypes = new Set<ClassElement>();
  Map<String, String> typeToImport = new Map<String, String>();
  c.crawl(entryPoint, (CompilationUnitElement compilationUnit, SourceFile source) {
      new CompilationUnitVisitor(c.context, source, classAnnotations, imports,
          typeToImport, typeFactoryTypes).visit(compilationUnit);
  });
  var code = printLibraryCode(typeToImport, imports, typeFactoryTypes);
  new File(output).writeAsStringSync(code);
}

String printLibraryCode(Map<String, String> typeToImport, Set<String> _imports,
                        Set<ClassElement> typeFactoryTypes) {
  final requiredImports = new Set<String>();
  final factories = new StringBuffer();
  final imports = _imports.toList();

  String resolveClassIdentifier(InterfaceType type) {
    if (type.element.library.isDartCore) return type.name;
    String import = typeToImport[getCanonicalName(type)];
    if (!requiredImports.contains(import)) {
      requiredImports.add(import);
    }
    return 'import_${imports.indexOf(import)}.${type.name}';
  }

  typeFactoryTypes.forEach((ClassElement clazz) {
    bool skip = false;
    ConstructorElement constr =
        clazz.constructors.firstWhere((c) => c.name.isEmpty,
        orElse: () {
          throw 'Unable to find default constructor for $clazz in ${clazz.source}';
        });

    var factory = new StringBuffer()
        ..write(
            'typeFactories[${resolveClassIdentifier(clazz.type)}] = (f) => ')
        ..write('new ${resolveClassIdentifier(clazz.type)}(')
        ..writeAll(constr.parameters.map((param) {
          if (param.type.element is! ClassElement) {
            throw 'Unable to resolve type for constructor parameter '
                  '"${param.name}" for type "$clazz" in ${clazz.source}';
          }
          if (_isParameterized(param)) {
            print('WARNING: parameterized types are not supported: $param in '
                '$clazz in ${clazz.source}. Skipping!');
            skip = true;
          }
          return 'f(${resolveClassIdentifier(param.type)})';
        }), ", ")
        ..write(');\n');
    if (!skip) factories.write(factory);
  });
  var code = new StringBuffer()
      ..write('library di.generated.type_factories;\n');
  requiredImports.forEach((import) {
    code.write ('import "$import" as import_${imports.indexOf(import)};\n');
  });
  code..write('var typeFactories = new Map();\n')
      ..write('main() {\n')
      ..write(factories)
      ..write('}\n');

  return code.toString();
}

bool _isParameterized(ParameterElement param) {
  var typeName = param.type.toString();

  if (typeName.indexOf('<') > -1) {
    String parameters =
        typeName.substring(typeName.indexOf('<') + 1, typeName.length - 1);
    return parameters.split(', ').any((p) => p != 'dynamic');
  }
  return false;
}

class CompilationUnitVisitor {
  final Set<String> imports;
  final Map<String, String> typeToImport;
  final Set<ClassElement> typeFactoryTypes;
  final Set<String> classAnnotations;
  final SourceFile source;
  final AnalysisContext context;

  CompilationUnitVisitor(this.context, this.source,
      this.classAnnotations, this.imports, this.typeToImport,
      this.typeFactoryTypes);

  void visit(CompilationUnitElement compilationUnit) {
    visitLibrary(compilationUnit.enclosingElement);

    var types = new Set<ClassElement>()..addAll(compilationUnit.types);

    for (CompilationUnitElement part in compilationUnit.enclosingElement.parts) {
      types.addAll(part.types);
    }

    types.forEach(visitClassElement);
  }

  void visitLibrary(LibraryElement libElement) {
    CompilationUnit resolvedUnit = context
        .resolveCompilationUnit(libElement.source, libElement);

    resolvedUnit.directives.forEach((Directive directive) {
      if (directive is LibraryDirective) {
        LibraryDirective library = directive;
        int annotationIdx = 0;
        library.metadata.forEach((Annotation ann) {
          if (ann.element is ConstructorElement &&
            getQualifiedName(
                (ann.element as ConstructorElement).enclosingElement.type) ==
                'di.annotations.Injectables') {
            var listLiteral =
                library.metadata[annotationIdx].arguments.arguments.first;
            for (Expression expr in listLiteral.elements) {
              Element element = (expr as SimpleIdentifier).bestElement;
              if (element == null || element is! ClassElement) {
                throw 'Unable to resolve type "$expr" from @Injectables '
                      'in ${library.element.source}';
              }
              typeFactoryTypes.add(element as ClassElement);
            }
          }
          annotationIdx++;
        });
      }
    });
  }

  visitClassElement(ClassElement classElement) {
    if (classElement.name[0] == '_') return; // ignore private classes.
    typeToImport[getCanonicalName(classElement.type)] =
        source.entryPointImport;
    imports.add(source.entryPointImport);
    for (ElementAnnotation ann in classElement.metadata) {
      if (ann.element is ConstructorElement) {
        ConstructorElement con = ann.element;
        if (classAnnotations
            .contains(getQualifiedName(con.enclosingElement.type))) {
          typeFactoryTypes.add(classElement);
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

String getCanonicalName(InterfaceType type) {
  var source = type.element.source.toString();
  return '$source:${type.name}';
}

typedef CompilationUnitCrawler(CompilationUnitElement compilationUnit,
                               SourceFile source);

class SourceCrawler {
  final Set<String> packageRoots;
  final String sdkPath;
  var context = AnalysisEngine.instance.createAnalysisContext();

  SourceCrawler(this.sdkPath, this.packageRoots);

  void crawl(String entryPoint, CompilationUnitCrawler _visitor) {
    JavaSystemIO.setProperty("com.google.dart.sdk", sdkPath);
    DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;

    var contextOptions = new AnalysisOptionsImpl()
        ..cacheSize = 256
        ..preserveComments = false
        ..analyzeFunctionBodies = false;
    context.analysisOptions = contextOptions;
    sdk.context.analysisOptions = contextOptions;

    var packageUriResolver =
        new PackageUriResolver(packageRoots.map(
            (pr) => new JavaFile.fromUri(new Uri.file(pr))).toList());
    context.sourceFactory = new SourceFactory.con2([
      new DartUriResolver(sdk),
      new FileUriResolver(),
      packageUriResolver
    ]);

    var entryPointFile;
    var entryPointImport;
    if (entryPoint.startsWith(PACKAGE_PREFIX)) {
      entryPointFile = new JavaFile(packageUriResolver
          .resolveAbsolute(context.sourceFactory.contentCache,
              Uri.parse(entryPoint)).toString());
      entryPointImport = entryPoint;
    } else {
      entryPointFile = new JavaFile(entryPoint);
      entryPointImport = entryPointFile.getAbsolutePath();
    }

    Source source = new FileBasedSource.con1(
        context.sourceFactory.contentCache, entryPointFile);
    ChangeSet changeSet = new ChangeSet()..added(source);
    context.applyChanges(changeSet);
    LibraryElement rootLib = context.computeLibraryElement(source);
    CompilationUnit resolvedUnit =
        context.resolveCompilationUnit(source, rootLib);

    var sourceFile = new SourceFile(
        entryPointFile.getAbsolutePath(),
        entryPointImport,
        resolvedUnit.element);
    var visited = new Set<SourceFile>();
    var toVisit = new Set<SourceFile>()..add(sourceFile);

    while (toVisit.isNotEmpty) {
      var currentFile = toVisit.first;
      toVisit.remove(currentFile);
      visited.add(currentFile);
      _visitor(currentFile.compilationUnit, currentFile);
      var visitor = new CrawlerVisitor(currentFile, context);
      visitor.accept(currentFile.compilationUnit);
      toVisit.addAll(visitor.toVisit.where((todo) => !visited.contains(todo)));
    }
  }
}

class CrawlerVisitor {
  final toVisit = new Set<SourceFile>();
  final SourceFile currentFile;
  final AnalysisContext context;

  CrawlerVisitor(this.currentFile, this.context);

  void accept(CompilationUnitElement cu) {
    cu.enclosingElement.imports.forEach((ImportElement import) =>
        visitImportElement(import.uri, import.importedLibrary.source));
    cu.enclosingElement.exports.forEach((ExportElement import) =>
        visitImportElement(import.uri, import.exportedLibrary.source));
  }

  void visitImportElement(String uri, Source source) {
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
    if (isSystem && systemImport[DART_PACKAGE_PREFIX.length] == '_') return;

    var nextCompilationUnit = context
        .resolveCompilationUnit(source, context.computeLibraryElement(source));

    if (uri.startsWith(PACKAGE_PREFIX)) {
      toVisit.add(new SourceFile(source.toString(), uri, nextCompilationUnit.element));
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
      toVisit.add(new SourceFile(
          source.toString(), newImport, nextCompilationUnit.element));
    }
  }
}

class SourceFile {
  final String canonicalPath;
  final String entryPointImport;
  final CompilationUnitElement compilationUnit;

  SourceFile(this.canonicalPath, this.entryPointImport, this.compilationUnit);

  operator ==(o) {
    if (o is String) return o == canonicalPath;
    return o is SourceFile ? o.canonicalPath == canonicalPath : false;
  }

  int get hashCode => canonicalPath.hashCode;

  String toString() => canonicalPath;
}
